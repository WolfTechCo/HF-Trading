[← Volver al README](../../README.md) | [English](../en/functional-spec.md)

# Especificación Funcional — HF-Trading

## Contenidos

- [Proceso de Negocio](#proceso-de-negocio)
- [Reglas de Negocio](#reglas-de-negocio)
- [Flujo Principal](#flujo-principal)
  - [Flujo 1 — Reclasificación FI](#flujo-1--reclasificación-fi)
  - [Flujo 2 — Acuse de Recibo de Entrega](#flujo-2--acuse-de-recibo-de-entrega)
- [Manejo de Errores](#manejo-de-errores)
- [Perfil de Usuario](#perfil-de-usuario)

---

## Proceso de Negocio

En operaciones **Trading Intercompany**, una sociedad del grupo actúa como
intermediaria: compra mercadería a un proveedor externo y la revende a otra
sociedad del grupo (cliente intercompany). Este proceso genera un flujo de
documentos que cruza los módulos SD y FI:

1. La sociedad vendedora crea un **pedido de ventas (SO)** para la sociedad compradora.
2. Se realiza la **entrega de salida** y se emite una **factura SD interna (tipo ZIV)**.
3. La factura SD genera automáticamente un **documento contable de compras (KT)**
   en la sociedad compradora (sociedad IRHO).
4. El valor de ese documento KT puede diferir del valor pactado en la transacción
   (importe acordado en la hoja de ruta o contrato marco). Esta diferencia debe
   ajustarse mediante un **documento contable de liquidación (SA)**.
5. Adicionalmente, la entrega física de la mercadería debe ser confirmada mediante
   un **documento de movimiento de mercancías (WA — Goods Issue)** que registra
   la disminución de stock en el sistema.

Este desarrollo automatiza los pasos 4 y 5, que de otro modo requerirían
creación manual de documentos contables.

---

## Reglas de Negocio

### Reclasificación FI (Flujo 1)

| Regla | Descripción |
|---|---|
| **Documento elegible** | Solo se pueden reclasificar documentos cuya factura SD sea de tipo ZIV, no esté cancelada y no sea temporal |
| **Sin reclasificación previa** | Un documento contable de compras (KT) solo puede registrarse una vez en el monitor; si ya tiene un registro activo en `ZTBFI_TRD_RECLAS`, se rechaza la carga |
| **Sin liquidación previa** | El documento KT no debe tener un documento de liquidación SA existente en el flujo al momento de la carga |
| **Campos obligatorios del CSV** | CompanyCode, DocumentReferenceID, PostingDate, Quantity, TransactionQuantityUnit, Amount, TransactionCurrency. Cualquier campo faltante impide el registro |
| **Validación de maestros** | La sociedad debe existir en `A_CompanyCode`, la moneda en `I_Currency` y la unidad en `I_UnitOfMeasure`; en caso contrario se rechaza la línea con mensaje de error |
| **Configuración previa obligatoria** | Debe existir en `ZTBFI_TRDRECL_PO` un registro para la sociedad origen del documento antes de ejecutar el procesamiento |
| **Documento SA con dos posiciones** | El documento de liquidación siempre tiene exactamente dos posiciones GL: una con el profit center origen y otra con el profit center destino configurados, por el importe de la diferencia y su negativo |
| **Cancelación solo en estado N** | Solo se pueden cancelar (eliminar del monitor) documentos en estado Sin Procesar (N). Los documentos en estado P, F, I, C o D no se pueden cancelar desde el monitor |
| **Referencias cruzadas en SA** | Los campos `XREF1_HD` y `XREF2_HD` del documento SA se llenan con el número de documento contable de compras y el número de factura SD respectivamente, vía BAdI |

### Acuse de Recibo de Entrega / Goods Issue (Flujo 2)

| Regla | Descripción |
|---|---|
| **Documento elegible para confirmar** | La factura intercompany debe tener documento contable de compras (KT) existente y no debe tener aún un Goods Issue (WA) registrado |
| **Documento elegible para cancelar** | La factura debe tener un GI registrado y no debe tener ya un documento de cancelación |
| **Fecha de contabilización obligatoria** | Antes de confirmar el GI, el sistema solicita al usuario ingresar la fecha de contabilización del documento WA |
| **Lock de entregas** | Antes de procesar el GI, el sistema verifica y adquiere locks sobre todas las entregas asociadas a la factura; si alguna entrega está bloqueada por otro usuario, el documento se salta con error |
| **Cuentas GL configuradas** | Las cuentas contables del documento WA (dos cuentas: una para activos, otra para contrapartida) se leen de la tabla `ZTXX_HARDCODES`; si no existen, el proceso se interrumpe |
| **Profit center según tipo de cuenta** | Para cuentas de tipo 'S' (Saldo) se usa el profit center configurado en `ZTBSD_CEBE` según la organización de ventas IC; para cuentas 'K' (Acreedor) el profit center va vacío |
| **Actualización del campo de acuse** | Al confirmar el GI, se actualiza el campo `LIKP-UVK01` a estado 'C' (confirmado); al cancelar, a estado 'A' (anulado) |

---

## Flujo Principal

### Flujo 1 — Reclasificación FI

```
PASO 1 — PREPARACIÓN
  El consultor FI accede a ZSD_MONI_TRADING_RCL.
  El sistema muestra el monitor ALV (inicialmente vacío).

PASO 2 — CARGA DEL ARCHIVO CSV
  Usuario selecciona "Cargar Archivo" en la toolbar.
  Pantalla popup 9001: usuario selecciona el archivo CSV en su PC.
  El sistema:
    a. Sube el archivo vía CL_GUI_FRONTEND_SERVICES.
    b. Convierte CSV a tabla interna ZTTFI_TRADING_RECLASS_FILE.
    c. Por cada línea:
       - Valida campos obligatorios.
       - Valida maestros (sociedad, moneda, unidad).
       - Consulta ZCDS_I_TRADINGDOCUMENTS para encontrar el documento
         KT sin liquidación previa y sin reclasificación existente.
       - Si encontrado: inserta en ZTBFI_TRD_RECLAS con estado N.
       - Si no encontrado: registra error en log de archivo.
    d. Muestra log de archivo (BAL) con resultado por línea.
    e. Refresca el ALV con los nuevos registros cargados.

PASO 3 — BÚSQUEDA / FILTRO
  Usuario puede buscar documentos ya registrados mediante la
  pantalla popup 9002 (múltiples criterios: sociedad, doc contable,
  estado, pedido, factura, referencia, fechas, etc.).
  El sistema consulta ZCDS_I_TRADINGRECLASSREPORT y refresca el ALV.

PASO 4 — PROCESAMIENTO
  Usuario selecciona uno o varios registros en estado N o F y
  presiona "Crear Documentos".
  Por cada documento seleccionado:
    a. Lee configuración de ZTBFI_TRDRECL_PO para la sociedad origen.
    b. Construye el documento SA con:
       - Fecha contabilización = fecha indicada en la carga.
       - Referencia = DocumentReferenceID.
       - Texto cabecera = "[SalesDocument] Cost Adjustment".
       - Pos.1: cuenta GL / profit center origen / importe diferencia.
       - Pos.2: cuenta GL / profit center destino / importe negativo.
       - EXTENSION2 con TS_ACC_DOC_EXT_FI (para BAdI).
    c. Llama BAPI_ACC_DOCUMENT_POST.
    d. BAdI escribe XREF1_HD y XREF2_HD en el documento.
    e. Actualiza ZTBFI_TRD_RECLAS:
       - Estado P si el documento SA fue creado correctamente.
       - Estado F si hubo error.
    f. Guarda log en ZTBFI_TRDRECLLOG con todos los mensajes BAPI.
    g. Hace COMMIT_WORK_AND_WAIT.
  Al finalizar refresca el ALV.

PASO 5 — CONSULTA DE LOG
  Usuario selecciona documento(s) y presiona "Ver Log".
  El sistema muestra el log BAL agrupado por:
    - UUID del documento (cabecera con sociedad, referencia, fecha).
    - Timestamp de ejecución.
    - Tipo de documento procesado.
    - Mensajes individuales de la BAPI.

PASO 6 — CANCELACIÓN (solo estado N)
  Usuario selecciona registros en estado N y presiona "Cancelar".
  Sistema pide confirmación. Al confirmar, elimina los registros
  de ZTBFI_TRD_RECLAS y refresca el ALV.
```

### Flujo 2 — Acuse de Recibo de Entrega

```
PASO 1 — SELECCIÓN
  El consultor SD/FI accede a ZSD_ENTR_PEND_ACUSE.
  Ingresa filtros opcionales: entregas, facturas IC, referencia, fecha GI.
  El checkbox "Cancelar doc." determina el modo:
    - Desmarcado: muestra facturas SIN Goods Issue (pendientes de confirmar).
    - Marcado: muestra facturas CON Goods Issue (pendientes de cancelar).

PASO 2 — VISUALIZACIÓN ALV
  El sistema consulta ZCDS_I_TRADINGACKRCPTGIREPORT y muestra:
  factura IC, sociedad, fecha factura, referencia externa, cantidad
  de entregas, fecha GI, cliente sold-to/ship-to, datos del doc KT y WA.
  Los documentos contables son hotspots que navegan a FB03.
  La factura IC es hotspot que navega a VF03.

PASO 3 — CONFIRMACIÓN DE GOODS ISSUE
  (Solo disponible si checkbox NO está marcado)
  Usuario selecciona facturas pendientes y presiona "Confirmar Acuse".
  Sistema solicita fecha de contabilización vía popup.
  Por cada factura:
    a. Lee cuentas GL de ZTXX_HARDCODES.
    b. Bloquea las entregas relacionadas (ENQUEUE_EVVBLKE).
    c. Lee posiciones del doc contable KT (I_JournalEntryItem).
    d. Construye doc WA (tipo WA, referencia = doc KT, "STOCK DECREASE").
    e. Posiciones GL con cuentas y profit centers según tipo de cuenta.
    f. Llama BAPI_ACC_DOCUMENT_POST.
    g. Actualiza LIKP-UVK01 = 'C' y libera locks.
    h. COMMIT_WORK_AND_WAIT.

PASO 4 — CANCELACIÓN DE GOODS ISSUE
  (Solo disponible si checkbox SÍ está marcado)
  Usuario selecciona facturas con GI y presiona "Cancelar Acuse".
  Por cada factura:
    a. Bloquea las entregas.
    b. Construye reverso BAPIACREV con el documento WA existente.
    c. Llama BAPI_ACC_DOCUMENT_REV_POST.
    d. Actualiza LIKP-UVK01 = 'A' y libera locks.
    e. COMMIT_WORK_AND_WAIT.

PASO 5 — LOG DE OPERACIONES
  Usuario presiona "Ver Log" para consultar los mensajes de la
  última sesión de procesamiento, agrupados por factura IC.
```

---

## Manejo de Errores

| Situación | Comportamiento |
|---|---|
| Línea del CSV con campos obligatorios faltantes | Se registra en log de archivo con mensaje de error específico por campo; la línea se omite; el proceso continúa con la siguiente |
| Línea del CSV con maestros inválidos (sociedad, moneda, unidad) | Igual que el caso anterior; mensaje específico del maestro faltante |
| Documento KT no encontrado o ya reclasificado | Mensaje de error en log de archivo; la línea se omite |
| Configuración ZTBFI_TRDRECL_PO inexistente para la sociedad | Se lanza `ZCX_TRADING` con mensaje E; el documento queda en estado F |
| BAPI_ACC_DOCUMENT_POST retorna mensaje tipo 'E' | Se hace BAPI_TRANSACTION_ROLLBACK; el documento queda en estado F en ZTBFI_TRD_RECLAS; los mensajes de error se persisten en ZTBFI_TRDRECLLOG |
| Entrega bloqueada por otro usuario al confirmar/cancelar GI | El documento se omite con mensaje de error indicando el usuario que tiene el lock; se continúa con el siguiente |
| Cuentas GL no configuradas en ZTXX_HARDCODES (ZRPSD028) | Se lanza ZCX_TRADING con mensaje E; el proceso de confirmación de GI se interrumpe completamente |
| GI ya existente al intentar confirmar | Mensaje de error; el documento se omite |
| GI ya cancelado al intentar cancelar nuevamente | Mensaje de error; el documento se omite |
| Excepción inesperada en el procesamiento | Se captura como `ZCX_TRADING` o subclase; se convierte a BAPIRET2 y se registra en el log |

---

## Perfil de Usuario

### Monitor de Reclasificación FI (ZSD_MONI_TRADING_RCL)

| Aspecto | Detalle |
|---|---|
| **Rol** | Consultor o analista de Finanzas (FI) |
| **Cuándo lo usa** | Periódicamente (mensual o según ciclo de cierre contable) cuando debe ajustar las diferencias entre el valor de compra intercompany y el valor de transacción pactado |
| **Acción principal** | Carga el archivo CSV con los datos de ajuste; revisa el monitor; procesa los documentos pendientes; verifica el log de resultados |
| **Prerrequisito** | El parámetro de configuración por sociedad debe estar mantenido en `ZTBFI_TRDRECL_PO` antes de ejecutar el procesamiento |

### Monitor de Acuse de Recibo (ZSD_ENTR_PEND_ACUSE)

| Aspecto | Detalle |
|---|---|
| **Rol** | Consultor o analista de SD o FI con conocimiento del proceso intercompany |
| **Cuándo lo usa** | Cuando las entregas intercompany han sido físicamente recibidas y deben confirmarse en el sistema mediante el movimiento de mercancías WA; o cuando un GI erróneo debe anularse |
| **Acción principal** | Filtra las facturas IC con entregas pendientes de acuse; selecciona los registros; ingresa la fecha de contabilización; confirma el Goods Issue |
| **Prerrequisito** | Las cuentas GL deben estar configuradas en `ZTXX_HARDCODES` y los centros de beneficio en `ZTBSD_CEBE` antes de ejecutar |

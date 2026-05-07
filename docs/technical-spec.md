[← Volver al README](../README.md)

# Especificacion Tecnica — HF-Trading

## Contenidos

- [Arquitectura General](#arquitectura-general)
- [Objetos ABAP](#objetos-abap)
  - [ZCL_FI_TRADING_RECLASS](#zcl_fi_trading_reclass)
  - [ZCL_APPLICATION_LOG](#zcl_application_log)
  - [ZCX_TRADING](#zcx_trading)
  - [ZCL_IM_ACC_DOCUM_EXTERNO](#zcl_im_acc_docum_externo)
  - [ZRPFI017](#zrpfi017)
  - [ZRPSD028](#zrpsd028)
  - [ZGFFI_TRADINGRECLASSGUI](#zgffi_tradingreclassgui)
  - [CDS Views](#cds-views)
- [Tablas SAP Utilizadas](#tablas-sap-utilizadas)
- [Transacciones Relacionadas](#transacciones-relacionadas)

---

## Arquitectura General

El desarrollo se compone de dos flujos independientes con una infraestructura
compartida de clases, tablas y vistas CDS:

```
FLUJO 1 — Monitor de Reclasificacion FI
  Transaccion ZSD_MONI_TRADING_RCL
      └─> Module Pool ZRPFI017
          └─> Function Group ZGFFI_TRADINGRECLASSGUI (GUI / Dynpros)
              └─> ZCL_FI_TRADING_RECLASS (Singleton)
                  ├─> Carga CSV  ──> ZCDS_I_TRADINGDOCUMENTS ──> INSERT ZTBFI_TRD_RECLAS
                  ├─> Busqueda   ──> ZCDS_I_TRADINGRECLASSREPORT (ALV)
                  ├─> Procesar   ──> BAPI_ACC_DOCUMENT_POST ──> BAdI ZACC_DOCUM_EXTERNO
                  │                  └─> UPDATE ZTBFI_TRD_RECLAS (estado P / F)
                  └─> Log        ──> ZCDS_I_TRADINGRECLASSLOG / ZCL_APPLICATION_LOG

FLUJO 2 — Acuse de Recibo de Entrega (Goods Issue)
  Transaccion ZSD_ENTR_PEND_ACUSE
      └─> Report ZRPSD028
          └─> LCL_REPORT
              ├─> Busqueda   ──> ZCDS_I_TRADINGACKRCPTGIREPORT (ALV)
              ├─> Confirmar  ──> BAPI_ACC_DOCUMENT_POST (tipo WA) ──> UPDATE LIKP
              └─> Cancelar   ──> BAPI_ACC_DOCUMENT_REV_POST ──> UPDATE LIKP

INFRAESTRUCTURA COMPARTIDA
  ZCX_TRADING        ──> Excepciones tipadas con T100
  ZCL_APPLICATION_LOG ──> Wrapper BAL (Business Application Log)
  BAdI ZACC_DOCUM_EXTERNO ──> Enriquece XREF1_HD / XREF2_HD en cualquier
                               documento contable creado via BAPI_ACC_DOCUMENT_POST
```

---

## Objetos ABAP

---

### ZCL_FI_TRADING_RECLASS

**Tipo:** Clase ABAP | **Patron:** Singleton (CREATE PRIVATE, metodo `GET_INSTANCE`)

Clase central del flujo de reclasificacion. Gestiona el ciclo completo: interfaz
de usuario (ALV + Dynpros), carga de archivos CSV, registro en monitor, lectura
de configuracion, creacion del documento contable de liquidacion y log de proceso.

#### Tipos y constantes publicos relevantes

| Nombre | Tipo ABAP | Descripcion |
|---|---|---|
| `TS_ACC_DOC_EXT_FI` | Estructura | Datos de referencia cruzada Trading: `ITEMNO` (POSNR_ACC), `XREF1_HD`, `XREF2_HD` |
| `DOCUMENT_CATEGORY_TRADING` | ENUM (base ZDE_DOCUMENT_TYPE_TRADING) | Categorias de documento: SO, PO, factura SD, nota de credito, factura entrante, etc. |
| `STATUS_TRADING_PRCS` | Constantes (ZDE_STATUS_TRADING_PROCESS) | Estados: N=Sin procesar, P=Procesado, I=Parcial, F=Error proceso, C=Cancelado, D=Error cancelacion, E=Error |

#### Metodos publicos

| Metodo | Parametros entrada | Retorno | Descripcion |
|---|---|---|---|
| `GET_INSTANCE` | `BATCHMODE` SAP_BOOL | `INSTANCE` ref a ZCL_FI_TRADING_RECLASS | Retorna la instancia unica Singleton |
| `DEFAULT_VIEW` | `DYNPRO`, `PROG`, `PFSTATUS`, `TITLE` | — | Establece la pantalla por defecto al iniciar |
| `FILE_OPEN_DIALOG` | Filtros y nombre de archivo | `FILENAME` RLGRAP-FILENAME | Abre dialogo de seleccion de archivo CSV |
| `HANDLE_EVENT` | `EVENT` SYST_UCOMM | — | Despachador central de eventos de GUI (INIT, PBO, acciones de toolbar) |
| `IS_OFFLINE` | — | `VALUE` SAP_BOOL | Indica si se ejecuta en modo batch/offline |
| `READ_VIEW` | — | `RESULT` TY_CALL_SCREEN_STACK | Retorna el contexto de pantalla activo |
| `SEND` | — | — | Navega a la pantalla registrada (normal o popup) |
| `SET_FILE_PARAMETERS` | `UL_FILENAME` STRING, `WITH_HEADER` SAP_BOOL | — | Establece ruta del archivo CSV y si tiene cabecera |

#### Logica principal (metodos privados clave)

| Metodo | Logica |
|---|---|
| `READ_SAVE_INTERCO_DOC_TO_MONI` | Lee `ZCDS_I_TRADINGDOCUMENTS` filtrado por sociedad y referencia externa; verifica que exista documento contable de compras sin liquidacion previa ni reclasificacion existente; inserta en `ZTBFI_TRD_RECLAS` |
| `READ_SETTINGS` | Lee `ZCDS_I_TRADINGRECLASSMDPO` por sociedad origen del documento; levanta `ZCX_TRADING` si no hay configuracion |
| `CREATE_SETTLEMENT_ACC_DOCUMENT` | Construye cabecera BAPI (tipo SA), dos posiciones GL (profit center origen y destino), importes con diferencia calculada, empaqueta `TS_ACC_DOC_EXT_FI` en `EXTENSION2` via `/DMBE/CLI_EXTENSION_IN_HELPER`; llama `BAPI_ACC_DOCUMENT_POST`; en error hace rollback; actualiza `ZTBFI_TRD_RECLAS` |
| `UPDATE_DOCUMENT_DB` | Actualiza estado del documento (P si tiene dockey de liquidacion, F si no), fecha/hora/usuario de modificacion; persiste el log en `ZTBFI_TRDRECLLOG`; hace COMMIT |
| `SEARCH_DOCUMENTS` | Lee parametros de la pantalla dinamicamente via `RS_REFRESH_FROM_SELECTOPTIONS`; consulta `ZCDS_I_TRADINGRECLASSREPORT` con los rangos; refresca ALV |
| `EXTRACT_DOCUMENTS_FROM_FILE` | Sube CSV, convierte a estructura `ZTTFI_TRADING_RECLASS_FILE`, valida campos obligatorios y maestros (sociedad, moneda, unidad), registra en monitor; muestra log de archivo |
| `IS_FILE_FIELDS_VALID` | Valida existencia de `CompanyCode` en `A_CompanyCode`, moneda en `I_Currency`, unidad en `I_UnitOfMeasure` |
| `CANCEL_DOCUMENTS` | Elimina de `ZTBFI_TRD_RECLAS` los registros seleccionados que esten en estado Sin Procesar |
| `READ_LOG` | Consulta `ZCDS_I_TRADINGRECLASSLOG` para los documentos seleccionados; muestra via BAL agrupado por UUID, timestamp y tipo de documento |

---

### ZCL_APPLICATION_LOG

**Tipo:** Clase ABAP (publica, final)

Wrapper del BAL (Business Application Log) de SAP. Encapsula apertura del log,
escritura de mensajes y visualizacion modal.

#### Atributos

| Atributo | Tipo | Descripcion |
|---|---|---|
| `CONTROL_HANDLE` | BALCNTHNDL | Handle del control de log BAL |
| `LOG_HANDLE` | BALLOGHNDL | Handle del log individual |
| `MAX_PROBCLASS` | BALPROBCL | Nivel maximo de problema para filtrado de visualizacion |

#### Metodos principales

| Metodo | Parametros entrada | Descripcion |
|---|---|---|
| `OPEN` | `LOG_OBJECT` BALOBJ_D, `MAX_PROBCLASS` BALPROBCL | Crea un nuevo log BAL en memoria |
| `ADD_MESSAGE` | `MSGTY`, `MSGID`, `MSGNO`, `MSGV1-4` | Agrega un mensaje T100 al log |
| `ADD_FREETEXT_MESSAGE` | `TYPE` BAPI_MTYPE, `TEXT` BAPI_MSG | Agrega un mensaje de texto libre |
| `ADD_SYSTEM_MESSAGE` | `DETAIL_LEVEL` BALLEVEL | Agrega el mensaje del sistema (`SY-MSG*`) al log |
| `ADD_MESSAGE_STRUCT` | `LOG_MESSAGE` BAL_S_MSG | Agrega un mensaje desde una estructura BAL |
| `DISPLAY_DETLEVEL` | `MODAL` SAP_BOOL | Muestra el log en pantalla, opcionalmente en modo modal |

---

### ZCX_TRADING

**Tipo:** Clase de excepcion (hereda `CX_STATIC_CHECK`)

Excepcion tipada para el proceso Trading. Implementa `IF_T100_MESSAGE` y
`IF_T100_DYN_MSG` para soporte de mensajes T100 con variables dinamicas.
Implementa `IF_ABAP_BEHV_MESSAGE` para compatibilidad con RAP.

#### Constructor

| Parametro | Tipo | Descripcion |
|---|---|---|
| `TEXTID` | IF_T100_MESSAGE=>T100KEY | Clave del mensaje T100 (opcional) |
| `PREVIOUS` | CX_ROOT | Excepcion previa para encadenamiento |
| `MSGTY` | SYMSGTY | Tipo de mensaje (E, W, I, S) |
| `MSGV1-4` | SYMSGV | Variables del mensaje |
| `SEVERITY` | T_SEVERITY | Severidad para contexto RAP |

---

### ZCL_IM_ACC_DOCUM_EXTERNO

**Tipo:** BAdI implementation | **BAdI:** `BADI_ACC_DOCUMENT` | **Enhancement:** `ZACC_DOCUM_EXTERNO`

Amplia la creacion de documentos contables para escritura de referencias cruzadas
del flujo Trading.

#### Metodo IF_EX_ACC_DOCUMENT~CHANGE

La logica relevante del desarrollo (bloque INSERT DESK9A0IMI) funciona asi:

1. Recorre `C_EXTENSION2` buscando registros cuyo campo `STRUCTURE` sea `'TS_ACC_DOC_EXT_FI'`.
2. Para cada registro, usa `/DMBE/CLI_EXTENSION_IN_HELPER=>READ_CONTAINER` para deserializar el container generico.
3. Convierte el resultado al tipo `ZCL_FI_TRADING_RECLASS=>TS_ACC_DOC_EXT_FI` (campos: `ITEMNO`, `XREF1_HD`, `XREF2_HD`).
4. Localiza la posicion correspondiente en `C_ACCIT` por `POSNR = ITEMNO`.
5. Escribe `XREF1_HD` (numero de documento contable de compras / Trading dockey) y `XREF2_HD` (numero de factura SD intercompany) en el item del documento contable.

Parametros del metodo `CHANGE` (BAdI `IF_EX_ACC_DOCUMENT`):

| Parametro | Tipo | Modo | Descripcion |
|---|---|---|---|
| `FLT_VAL` | AWTYP | IMPORTING | Transaccion de referencia |
| `C_ACCHD` | ACCHD | CHANGING | Cabecera del documento contable |
| `C_ACCIT` | ACCIT_TAB | CHANGING | Posiciones del documento contable |
| `C_ACCCR` | ACCCR_TAB | CHANGING | Informacion de moneda |
| `C_ACCWT` | ACCWT_TAB | CHANGING | Datos de retencion de impuestos |
| `C_ACCTX` | ACCTX_TAB | CHANGING | Segmento de impuestos |
| `C_ACCFI` | ACCFI_T | CHANGING | Cuentas individuales FI (opcional) |
| `C_EXTENSION2` | BAPIPAREX_TAB_AC | CHANGING | Extensiones IDoc (aqui se leen los datos Trading) |
| `C_RETURN` | BAPIRET2_T | CHANGING | Tabla de retorno |

---

### ZRPFI017

**Tipo:** Module Pool

Punto de entrada minimo a la GUI del monitor de reclasificacion. El programa no
contiene logica propia: en `START-OF-SELECTION` llama al function module de
mantenimiento `ZMFSD_TRADINGRECLASSGUI_MAINT` del function group
`ZGFFI_TRADINGRECLASSGUI`, que inicializa la instancia Singleton y lanza la
pantalla principal.

---

### ZRPSD028

**Tipo:** Report ALV con clase local `LCL_REPORT`

Monitor interactivo para el acuse de recibo de entregas intercompany (Goods Issue).

#### Pantalla de seleccion

| Campo | Tabla | Descripcion |
|---|---|---|
| `DELIVNUM` | LIKP-VBELN | Numero de entrega de salida |
| `ICINVOIC` | VBRK-VBELN | Numero de factura intercompany |
| `EXTNUM` | VBRK-XBLNR | Numero de referencia externa |
| `SMDATE` | LIKP-WADAT_IST | Fecha de movimiento de mercancias |
| `CANC_DOC` | — | Checkbox: si activo, muestra documentos para cancelar GI |

#### Clase local LCL_REPORT — metodos principales

| Metodo | Descripcion |
|---|---|
| `READ_DATA` | Consulta `ZCDS_I_TRADINGACKRCPTGIREPORT` con filtros de seleccion; agrupa por factura |
| `READ_SETTINGS` | Lee cuentas GL de `ZTXX_HARDCODES` (dos registros: GL_ACCOUNT secuencias 1 y 2) |
| `POST_GOODS_ISSUE` | Solicita fecha de contabilizacion; llama `READ_SETTINGS`, luego `CREATE_GOODS_ISSUE_DOCUMENT` por cada documento seleccionado |
| `CREATE_GOODS_ISSUE_DOCUMENT` | Bloquea entregas; lee posiciones de `I_JournalEntryItem`; construye cabecera (tipo WA), posiciones GL con profit centers de `ZTBSD_CEBE`, importes; llama `BAPI_ACC_DOCUMENT_POST`; actualiza campo `LIKP-UVK01` |
| `CANCEL_GOODS_ISSUE` | Llama `CANCEL_GOODS_ISSUE_DOCUMENT` para cada documento seleccionado |
| `CANCEL_GOODS_ISSUE_DOCUMENT` | Construye estructura de reverso `BAPIACREV`; llama `BAPI_ACC_DOCUMENT_REV_POST`; actualiza `LIKP-UVK01` |
| `LOCK_DELIVERIES` | Verifica y adquiere locks ENQUEUE sobre las entregas relacionadas a la factura |
| `UPDATE_ACK_RECEIPT_FIELD` | Actualiza `LIKP-UVK01` con estado de acuse (`'C'` confirmado / `'A'` cancelado) y libera locks |
| `DISPLAY_LOG` | Muestra log BAL agrupado por factura de las operaciones ejecutadas |

---

### ZGFFI_TRADINGRECLASSGUI

**Tipo:** Function Group

Contiene las pantallas (Dynpros) y la logica de navegacion de la GUI del monitor
de reclasificacion. Gestiona dos pantallas modales:

| Screen | Descripcion |
|---|---|
| 9001 | Upload de archivo CSV: campo de ruta de archivo y boton de seleccion |
| 9002 | Busqueda de documentos: subscreen 2000 con parametros de seleccion |

La pantalla principal (sin popup) aloja el ALV de `CL_SALV_TABLE` embebido en
un `CL_GUI_CUSTOM_CONTAINER`.

---

### CDS Views

#### ZCDS_I_TRADINGDOCUMENTS

Vista base del flujo completo Trading. Lee desde `I_BillingDocumentItem` y conecta
via asociaciones con:

| Asociacion | Vista estandar | Descripcion |
|---|---|---|
| `_BillingDocument` | I_BillingDocument | Cabecera de factura SD (filtro: tipo ZIV, no temporal, no cancelada) |
| `_SalesDocument` | I_SalesDocument | Pedido de ventas origen |
| `_OutboundDelivery` | I_OutboundDelivery | Entrega de salida |
| `_PurchaseAccDocumentItem` | I_JournalEntryItem | Pos. documento contable compras (tipo KT, sociedad IRHO, ledger 0L, no revertido) |
| `_AckReceiptGoodsIssueItem` | I_JournalEntryItem | Pos. documento Goods Issue (tipo WA, sociedad IRHO, ledger 0L, no revertido) |
| `_SettlementAccDocument` | I_JournalEntry | Documento de liquidacion (tipo SA, referenciado por factura SD) |
| `_TradingReclassification` | ZCDS_I_TRADINGRECLASSIFICATION | Estado de reclasificacion del documento |

#### ZCDS_I_TRADINGRECLASSIFICATION

Lee desde `ZTBFI_TRD_RECLAS`. Expone clave UUID, documento contable de compras,
estado del proceso, documentos SD relacionados y dockey del documento de liquidacion.

#### ZCDS_I_TRADINGRECLASSREPORT

Extiende `ZCDS_I_TRADINGRECLASSIFICATION`. Calcula via `SUM` sobre
`I_JournalEntryItem`:
- `QUANTITYINPURCHASEINVOICE`: suma de cantidades de las posiciones FI
- `PURCHASEINVOICEAMOUNT`: suma de importes en moneda de transaccion
- `DIFAMOUNTINTRANSACTIONCURRENCY`: diferencia entre importe acordado y factura de compras

#### ZCDS_I_TRADINGACKRCPTGIREPORT

Extiende `ZCDS_I_TRADINGDOCUMENTS`. Agrega datos de entrega (fecha GI, cliente
sold-to, ship-to, cliente intercompany, org.ventas IC) y expone el indicador
`ACKRECEIPTGOODSISSUEEXIST` para filtrar pendientes vs. procesados.

#### ZCDS_I_TRADINGRECLASSMDPO

Lee desde `ZTBFI_TRDRECL_PO`. Expone por sociedad: tipo de documento contable,
cuenta GL, profit center origen y destino para el documento de liquidacion.

#### ZCDS_I_TRADINGRECLASSLOG

Lee desde `ZTBFI_TRDRECLLOG`. Expone el log de mensajes agrupable por
`DOCUMENTUUID`, `DATETIMEL` y `TYPEDOCUMENT`.

---

## Tablas SAP Utilizadas

### Tablas Z del desarrollo

| Tabla | Clase | Descripcion | Uso |
|---|---|---|---|
| `ZTBFI_TRD_RECLAS` | Transparente | Facturas Trading — Reclasificacion | Registro principal de cada reclasificacion pendiente o procesada |
| `ZTBFI_TRDRECLLOG` | Transparente | Log de reclasificacion por documento | Auditoria de mensajes por cada ejecucion del proceso |
| `ZTBFI_TRDRECL_PO` | Transparente | Configuracion por sociedad | Tipo doc, cuenta GL y profit centers para el documento SA |
| `ZTBSD_CEBE` | Transparente (externa) | Profit centers por org. ventas IC | Utilizada en ZRPSD028 para asignar centros de beneficio al GI |
| `ZTXX_HARDCODES` | Transparente (externa) | Tabla generica de parametros | Utilizada en ZRPSD028 para leer las cuentas GL del Goods Issue |

Estructuras (INTTAB):

| Estructura | Descripcion |
|---|---|
| `ZSTFI_TRADING_RECLASS` | Estructura del monitor = ZTBFI_TRD_RECLAS + campos calculados (cantidades, importes, estado icono, sociedad origen) |
| `ZSTFI_TRADING_RECLASS_KEY` | Clave UUID del documento |
| `ZSTFI_TRADING_RECLASS_DOCKEY` | Clave del documento contable de compras (AccountingDocument, CompanyCode, FiscalYear) |
| `ZSTFI_TRADING_RECLASS_FILE` | Estructura del archivo CSV de entrada |
| `ZSTFI_TRADING_RECLASS_LOGFILE` | Estructura del log de archivo (mensajes de validacion CSV) |
| `ZSTFI_TRADING_RECLASS_STDOCKEY` | Clave del documento contable de liquidacion |
| `ZSTFI_TRADING_RECLASS_LOGKEY` | Clave del log (UUID + timestamp + secuencia) |
| `ZST_TRADING_LOG` | Estructura de mensaje de log del proceso |

### Tablas y CDS estandar SAP referenciadas

| Objeto | Uso |
|---|---|
| `VBRK` | Cabecera de facturas SD (check de FK en ZTBFI_TRD_RECLAS) |
| `VBAK` | Cabecera de pedidos de venta (check de FK) |
| `LIKP` | Cabecera de entregas de salida (actualizacion de UVK01 en acuse de recibo) |
| `I_BillingDocument` / `I_BillingDocumentItem` | Datos de factura SD intercompany |
| `I_SalesDocument` / `I_SalesDocumentItem` | Datos del pedido de ventas |
| `I_OutboundDelivery` / `I_OutboundDeliveryItem` | Datos de entrega de salida |
| `I_JournalEntry` / `I_JournalEntryItem` | Documentos contables FI (compras KT, liquidacion SA, GI WA) |
| `I_Customer` | Nombre del cliente para vistas de acuse de recibo |
| `A_CompanyCode` | Validacion de existencia de sociedad en carga CSV |
| `I_Currency` | Validacion de moneda en carga CSV |
| `I_UnitOfMeasure` | Validacion de unidad de medida en carga CSV |

---

## Transacciones Relacionadas

| Transaccion | Tipo | Programa | Descripcion |
|---|---|---|---|
| `ZSD_MONI_TRADING_RCL` | Custom | ZRPFI017 | Monitor de reclasificacion FI Trading |
| `ZSD_ENTR_PEND_ACUSE` | Custom | ZRPSD028 | Monitor de acuse de recibo de entregas intercompany |
| `ZCU99_ZRPFI017_TX` | Customizing | ZRPFI017 | Mantenimiento de parametros por sociedad (ZTBFI_TRDRECL_PO) |
| `VA03` | Estandar SAP SD | — | Navegacion a pedido de ventas (hotspot en ALV) |
| `VF03` | Estandar SAP SD | — | Navegacion a factura SD (hotspot en ALV) |
| `FB03` | Estandar SAP FI | — | Navegacion a documento contable (hotspot en ALV) |

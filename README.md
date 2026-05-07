[🇬🇧 English version](README.en.md)

# HF-Trading — Proceso Trading / Intercompany (HF)

Desarrollo Z para SAP S/4HANA que automatiza el flujo de documentos del proceso
**Trading Intercompany**: desde la factura SD interna (tipo ZIV) hasta la creación
del documento contable de liquidación (SA) y el acuse de recibo de la entrega
(Goods Issue WA). Incluye un monitor interactivo con carga de datos vía CSV,
procesamiento masivo y log de auditoría.

---

## Descripción funcional

En operaciones intercompany, una sociedad vendedora (SD) emite una factura interna
que genera un documento contable de compras (KT) en la sociedad compradora (FI).
Este desarrollo gestiona:

1. **Reclasificación FI**: carga de parámetros de ajuste (cantidad, importe,
   moneda) desde un archivo CSV; creación automática del documento contable de
   liquidación (SA) con la diferencia entre el valor de la factura de compras y
   el valor de transacción acordado.
2. **Acuse de recibo de entrega (Goods Issue)**: confirmación o cancelación del
   movimiento de mercancías (WA) asociado a las entregas intercompany pendientes.
3. **Ampliación del documento contable**: BAdI que escribe los números cruzados
   del flujo Trading en los campos de referencia `XREF1_HD` y `XREF2_HD` del
   documento contable al momento de su creación.

---

## Módulos SAP involucrados

| Módulo | Participación |
|---|---|
| **SD** — Sales & Distribution | Facturas intercompany (ZIV), pedidos de venta, entregas salida |
| **FI** — Financial Accounting | Creación de documentos contables SA y WA vía BAPI |
| **MM** — Materials Management | Goods Issue (tipo WA) en el acuse de recibo |
| **CO** — Controlling | Centros de beneficio en el documento de liquidación |

---

## Listado de objetos ABAP

| Objeto | Tipo | Descripción |
|---|---|---|
| `ZCL_FI_TRADING_RECLASS` | Clase ABAP (Singleton) | Clase principal: monitor ALV, carga CSV, búsqueda, creación y cancelación de documentos contables |
| `ZCL_APPLICATION_LOG` | Clase ABAP | Wrapper del Business Application Log (BAL): apertura, escritura y visualización |
| `ZCX_TRADING` | Clase de excepción | Excepción estática tipada para el proceso Trading, con soporte T100 |
| `ZCL_IM_ACC_DOCUM_EXTERNO` | BAdI implementation | Implementación de `BADI_ACC_DOCUMENT`: enriquece `XREF1_HD` / `XREF2_HD` en el documento contable |
| `ZRPFI017` | Module Pool | Punto de entrada al monitor de reclasificación; invoca la GUI del function group |
| `ZRPSD028` | Reporte ALV | Monitor de acuse de recibo de entregas intercompany (Goods Issue) |
| `ZGFFI_TRADINGRECLASSGUI` | Function Group | Dynpros y screens para la GUI del monitor de reclasificación |
| `ZCDS_I_TRADINGDOCUMENTS` | Vista CDS | Vista base: flujo completo SO → Factura → Doc. Contable → Liquidación → GI |
| `ZCDS_I_TRADINGRECLASSIFICATION` | Vista CDS | Documentos de reclasificación (join con `ZTBFI_TRD_RECLAS`) |
| `ZCDS_I_TRADINGRECLASSREPORT` | Vista CDS | Vista del monitor con cantidades calculadas y diferencias de importe |
| `ZCDS_I_TRADINGACKRCPTGIREPORT` | Vista CDS | Vista para el monitor de acuse de recibo de Goods Issue |
| `ZCDS_I_TRADINGDOCUMENTSTATUS` | Vista CDS | Textos de estado del proceso |
| `ZCDS_I_TRADINGDOCSTATUSICON` | Vista CDS | Íconos SAP por estado |
| `ZCDS_I_TRADINGDOCSTATUSTEXT` | Vista CDS | Textos de estado para CDS |
| `ZCDS_I_TRADINGRECLASSLOG` | Vista CDS | Log de ejecuciones por documento UUID |
| `ZCDS_I_TRADINGRECLASSMDPO` | Vista CDS | Parámetros de configuración por sociedad (tipo doc, GL, profit centers) |
| `ZTBFI_TRD_RECLAS` | Tabla transparente | Tabla principal de reclasificaciones por documento contable de compras |
| `ZTBFI_TRDRECLLOG` | Tabla transparente | Log de mensajes de proceso por documento y timestamp |
| `ZTBFI_TRDRECL_PO` | Tabla transparente | Customizing por sociedad: tipo doc contable, cuenta GL, profit centers |
| `ZSD_MONI_TRADING_RCL` | Transacción | Monitor de reclasificación Trading |
| `ZSD_ENTR_PEND_ACUSE` | Transacción | Acuse de recibo de entregas intercompany pendientes |
| `ZCU99_ZRPFI017_TX` | Transacción Customizing | Mantenimiento de parámetros de reclasificación (`ZTBFI_TRDRECL_PO`) |

---

## Prerrequisitos técnicos

| Requisito | Detalle |
|---|---|
| **SAP Release** | S/4HANA 2020 o superior |
| **Clase /DMBE/CLI_EXTENSION_IN_HELPER** | Debe existir en el sistema; utilizada por la BAdI y `ZCL_FI_TRADING_RECLASS` para empaquetar datos en `EXTENSION2` |
| **Tipo /PM0/ABD_OFFLINE_FG** | Requerido por `ZCL_FI_TRADING_RECLASS` para el modo offline/batch |
| **Tabla ZTBSD_CEBE** | Tabla Z externa a este paquete; debe contener profit centers por organización de ventas IC |
| **Tabla ZTXX_HARDCODES** | Tabla Z genérica; debe contener las cuentas GL para `ZRPSD028` |
| **BAdI BADI_ACC_DOCUMENT** | Implementación `ZACC_DOCUM_EXTERNO` debe estar activa |
| **Customizing ZTBFI_TRDRECL_PO** | Debe mantenerse antes de procesar documentos (`ZCU99_ZRPFI017_TX`) |

---

## Instalación y transporte al sistema

1. Clonar el repositorio con **abapGit** apuntando a la carpeta `/src/`.
2. Activar todos los objetos del diccionario en el orden: dominios → elementos de dato → estructuras → tablas → tipos de tabla.
3. Activar las clases ABAP en el orden: `ZCX_TRADING` → `ZCL_APPLICATION_LOG` → `ZCL_FI_TRADING_RECLASS`.
4. Activar las vistas CDS en el orden: `ZCDS_I_TRADINGDOCUMENTS` → `ZCDS_I_TRADINGRECLASSIFICATION` → resto de vistas.
5. Activar el function group `ZGFFI_TRADINGRECLASSGUI`.
6. Activar los reports `ZRPFI017` y `ZRPSD028`.
7. Transportar la implementación de la BAdI (`ZACC_DOCUM_EXTERNO`) y verificar que quede activa.
8. Mantener los parámetros de configuración vía `ZCU99_ZRPFI017_TX` y los registros de `ZTXX_HARDCODES` para `ZRPSD028`.

---

## Documentación

| Documento | Descripción |
|---|---|
| [Especificación Técnica](docs/es/technical-spec.md) | Objetos ABAP, parámetros y lógica |
| [Especificación Funcional](docs/es/functional-spec.md) | Proceso de negocio y reglas |
| [Changelog](docs/es/changelog.md) | Historial de versiones |

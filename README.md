# HF-Trading — Proceso Trading / Intercompany (HF)

Desarrollo Z para SAP S/4HANA que automatiza el flujo de documentos del proceso
**Trading Intercompany**: desde la factura SD interna (tipo ZIV) hasta la creacion
del documento contable de liquidacion (SA) y el acuse de recibo de la entrega
(Goods Issue WA). Incluye un monitor interactivo con carga de datos via CSV,
procesamiento masivo y log de auditoria.

---

## Descripcion funcional

En operaciones intercompany, una sociedad vendedora (SD) emite una factura interna
que genera un documento contable de compras (KT) en la sociedad compradora (FI).
Este desarrollo gestiona:

1. **Reclasificacion FI**: carga de parametros de ajuste (cantidad, importe,
   moneda) desde un archivo CSV; creacion automatica del documento contable de
   liquidacion (SA) con diferencia de importe entre la factura de compras y el
   valor de la transaccion acordado.
2. **Acuse de recibo de entrega (Goods Issue)**: confirmacion o cancelacion del
   movimiento de mercancias (WA) asociado a las entregas intercompany pendientes.
3. **Ampliacion del documento contable**: BAdI que escribe los numeros cruzados
   del flujo Trading en los campos de referencia `XREF1_HD` y `XREF2_HD` del
   documento contable al momento de su creacion.

---

## Modulos SAP involucrados

| Modulo | Participacion |
|---|---|
| **SD** — Sales & Distribution | Facturas intercompany (ZIV), pedidos de venta, entregas salida |
| **FI** — Financial Accounting | Creacion de documentos contables SA y WA via BAPI |
| **MM** — Materials Management | Goods Issue (tipo WA) en el acuse de recibo |
| **CO** — Controlling | Centros de beneficio en el documento de liquidacion |

---

## Listado de objetos ABAP

| Objeto | Tipo | Descripcion |
|---|---|---|
| `ZCL_FI_TRADING_RECLASS` | Clase ABAP (Singleton) | Clase principal: monitor ALV, carga CSV, busqueda, creacion y cancelacion de documentos contables |
| `ZCL_APPLICATION_LOG` | Clase ABAP | Wrapper del Business Application Log (BAL): apertura, escritura y visualizacion |
| `ZCX_TRADING` | Clase de excepcion | Excepcion estatica tipada para el proceso Trading, con soporte T100 |
| `ZCL_IM_ACC_DOCUM_EXTERNO` | BAdI implementation | Implementacion de `BADI_ACC_DOCUMENT`: enriquece `XREF1_HD` / `XREF2_HD` en el documento contable |
| `ZRPFI017` | Module Pool | Punto de entrada al monitor de reclasificacion; invoca la GUI del function group |
| `ZRPSD028` | Report ALV | Monitor de acuse de recibo de entregas intercompany (Goods Issue) |
| `ZGFFI_TRADINGRECLASSGUI` | Function Group | Dynpros y screens para la GUI del monitor de reclasificacion (upload CSV y busqueda) |
| `ZCDS_I_TRADINGDOCUMENTS` | CDS View | Vista base: flujo completo SO — Factura — Doc.Contable — Liquidacion — GI |
| `ZCDS_I_TRADINGRECLASSIFICATION` | CDS View | Documentos de reclasificacion (join con `ZTBFI_TRD_RECLAS`) |
| `ZCDS_I_TRADINGRECLASSREPORT` | CDS View | Vista del monitor con cantidades calculadas y diferencias de importe |
| `ZCDS_I_TRADINGACKRCPTGIREPORT` | CDS View | Vista para el monitor de acuse de recibo de Goods Issue |
| `ZCDS_I_TRADINGDOCUMENTSTATUS` | CDS View | Textos de estado del proceso |
| `ZCDS_I_TRADINGDOCSTATUSICON` | CDS View | Iconos SAP por estado |
| `ZCDS_I_TRADINGDOCSTATUSTEXT` | CDS View | Textos de estado para CDS |
| `ZCDS_I_TRADINGRECLASSLOG` | CDS View | Log de ejecuciones por documento UUID |
| `ZCDS_I_TRADINGRECLASSMDPO` | CDS View | Parametros de configuracion por sociedad (tipo doc, GL, profit centers) |
| `ZTBFI_TRD_RECLAS` | Tabla transparente | Tabla principal de reclasificaciones por documento contable de compras |
| `ZTBFI_TRDRECLLOG` | Tabla transparente | Log de mensajes de proceso por documento y timestamp |
| `ZTBFI_TRDRECL_PO` | Tabla transparente | Customizing por sociedad: tipo doc contable, cuenta GL, profit centers |
| `ZSD_MONI_TRADING_RCL` | Transaccion | Monitor de reclasificacion Trading |
| `ZSD_ENTR_PEND_ACUSE` | Transaccion | Acuse de recibo de entregas intercompany pendientes |
| `ZCU99_ZRPFI017_TX` | Transaccion Customizing | Mantenimiento de parametros de reclasificacion (`ZTBFI_TRDRECL_PO`) |
| `ZAPP_LOG` | Message Class | Mensajes del Application Log |
| `ZMC_TRADING_SRV` | Message Class | Mensajes del servicio Trading |
| `ZDD_DOCUMENT_TYPE_TRADING` | Dominio | Categorias de documento Trading |
| `ZDD_STATUS_TRADING_PROCESS` | Dominio | Estados del proceso Trading |
| `ZDD_TYPE_TRADING_PROCESS` | Dominio | Tipos de proceso Trading |

---

## Prerequisitos tecnicos

| Requisito | Detalle |
|---|---|
| **SAP Release** | S/4HANA 2020 o superior (uso de ABAP CDS estandar `I_JournalEntry`, `I_BillingDocument`, etc.) |
| **Clase /DMBE/CLI_EXTENSION_IN_HELPER** | Debe existir en el sistema; utilizada por la BAdI y `ZCL_FI_TRADING_RECLASS` para empaquetar datos en `EXTENSION2` |
| **Tipo /PM0/ABD_OFFLINE_FG** | Tipo requerido por `ZCL_FI_TRADING_RECLASS` para el modo offline/batch |
| **Tabla ZTBSD_CEBE** | Tabla Z externa a este paquete; debe existir con los centros de beneficio por organizacion de ventas intercompany |
| **Tabla ZTXX_HARDCODES** | Tabla Z generica de hardcodes; debe contener las cuentas GL configuradas para `ZRPSD028` |
| **BAdI BADI_ACC_DOCUMENT** | BAdI estandar de SAP FI; debe estar activa la implementacion `ZACC_DOCUM_EXTERNO` |
| **Customizing ZTBFI_TRDRECL_PO** | Debe mantenerse antes de procesar documentos (transaccion `ZCU99_ZRPFI017_TX`) |

---

## Instalacion y transporte al sistema

1. Clonar el repositorio con **abapGit** apuntando a la carpeta `/src/`.
2. Activar todos los objetos del diccionario en el orden: dominios → elementos de dato → estructuras → tablas → tipos de tabla.
3. Activar las clases ABAP en el orden: `ZCX_TRADING` → `ZCL_APPLICATION_LOG` → `ZCL_FI_TRADING_RECLASS`.
4. Activar las CDS views en el orden: `ZCDS_I_TRADINGDOCUMENTS` → `ZCDS_I_TRADINGRECLASSIFICATION` → resto de vistas.
5. Activar el function group `ZGFFI_TRADINGRECLASSGUI`.
6. Activar los reports `ZRPFI017` y `ZRPSD028`.
7. Transportar la implementacion de la BAdI (`ZACC_DOCUM_EXTERNO`) y verificar que quede activa.
8. Mantener los parametros de configuracion via `ZCU99_ZRPFI017_TX` y los registros de `ZTXX_HARDCODES` para `ZRPSD028`.

---

## Documentacion

| Documento | Descripcion |
|---|---|
| [Especificacion Tecnica](docs/technical-spec.md) | Objetos ABAP, parametros y logica |
| [Especificacion Funcional](docs/functional-spec.md) | Proceso de negocio y reglas |
| [Changelog](docs/changelog.md) | Historial de versiones |

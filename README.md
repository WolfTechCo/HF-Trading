# HF-Trading

[Español](#español) | [English](#english)

---

## Español

### Proceso Trading / Intercompany (HF)

Desarrollo Z para SAP S/4HANA que automatiza el flujo de documentos del proceso
**Trading Intercompany**: desde la factura SD interna (tipo ZIV) hasta la creación
del documento contable de liquidación (SA) y el acuse de recibo de la entrega
(Goods Issue WA). Incluye un monitor interactivo con carga de datos vía CSV,
procesamiento masivo y log de auditoría.

#### Descripción funcional

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

#### Módulos SAP involucrados

| Módulo | Participación |
|---|---|
| **SD** — Sales & Distribution | Facturas intercompany (ZIV), pedidos de venta, entregas salida |
| **FI** — Financial Accounting | Creación de documentos contables SA y WA vía BAPI |
| **MM** — Materials Management | Goods Issue (tipo WA) en el acuse de recibo |
| **CO** — Controlling | Centros de beneficio en el documento de liquidación |

#### Listado de objetos ABAP

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

#### Prerrequisitos técnicos

| Requisito | Detalle |
|---|---|
| **SAP Release** | S/4HANA 2020 o superior |
| **Clase /DMBE/CLI_EXTENSION_IN_HELPER** | Debe existir en el sistema; utilizada por la BAdI y `ZCL_FI_TRADING_RECLASS` para empaquetar datos en `EXTENSION2` |
| **Tipo /PM0/ABD_OFFLINE_FG** | Requerido por `ZCL_FI_TRADING_RECLASS` para el modo offline/batch |
| **Tabla ZTBSD_CEBE** | Tabla Z externa a este paquete; debe contener profit centers por organización de ventas IC |
| **Tabla ZTXX_HARDCODES** | Tabla Z genérica; debe contener las cuentas GL para `ZRPSD028` |
| **BAdI BADI_ACC_DOCUMENT** | Implementación `ZACC_DOCUM_EXTERNO` debe estar activa |
| **Customizing ZTBFI_TRDRECL_PO** | Debe mantenerse antes de procesar documentos (`ZCU99_ZRPFI017_TX`) |

#### Documentación

| Documento | Descripción |
|---|---|
| [Especificación Técnica](docs/es/technical-spec.md) | Objetos ABAP, parámetros y lógica |
| [Especificación Funcional](docs/es/functional-spec.md) | Proceso de negocio y reglas |
| [Changelog](docs/es/changelog.md) | Historial de versiones |

---

## English

### Trading / Intercompany Process (HF)

Custom Z development for SAP S/4HANA that automates the document flow of the
**Trading Intercompany** process: from the internal SD invoice (type ZIV) through
the creation of the settlement accounting document (SA) and the delivery
acknowledgement of receipt (Goods Issue WA). Includes an interactive monitor
with CSV data loading, mass processing, and audit log.

#### Functional description

In intercompany operations, a selling company (SD) issues an internal invoice
that generates a purchase accounting document (KT) in the buying company (FI).
This development manages:

1. **FI Reclassification**: loading of adjustment parameters (quantity, amount,
   currency) from a CSV file; automatic creation of the settlement accounting
   document (SA) with the difference between the purchase invoice value and the
   agreed transaction value.
2. **Delivery Acknowledgement of Receipt (Goods Issue)**: confirmation or
   cancellation of the goods movement (WA) associated with pending intercompany
   deliveries.
3. **Accounting document enhancement**: BAdI that writes the Trading flow
   cross-reference numbers into the `XREF1_HD` and `XREF2_HD` reference fields
   of the accounting document at creation time.

#### SAP modules involved

| Module | Participation |
|---|---|
| **SD** — Sales & Distribution | Intercompany invoices (ZIV), sales orders, outbound deliveries |
| **FI** — Financial Accounting | Creation of SA and WA accounting documents via BAPI |
| **MM** — Materials Management | Goods Issue (type WA) in acknowledgement of receipt |
| **CO** — Controlling | Profit centers in the settlement document |

#### ABAP objects

| Object | Type | Description |
|---|---|---|
| `ZCL_FI_TRADING_RECLASS` | ABAP Class (Singleton) | Main class: ALV monitor, CSV load, search, creation and cancellation of accounting documents |
| `ZCL_APPLICATION_LOG` | ABAP Class | Business Application Log (BAL) wrapper: creation, writing and display |
| `ZCX_TRADING` | Exception class | Typed static exception for the Trading process, with T100 support |
| `ZCL_IM_ACC_DOCUM_EXTERNO` | BAdI implementation | Implementation of `BADI_ACC_DOCUMENT`: enriches `XREF1_HD` / `XREF2_HD` in the accounting document |
| `ZRPFI017` | Module Pool | Entry point to the reclassification monitor; invokes the function group GUI |
| `ZRPSD028` | ALV Report | Intercompany delivery acknowledgement of receipt monitor (Goods Issue) |
| `ZGFFI_TRADINGRECLASSGUI` | Function Group | Dynpros and screens for the reclassification monitor GUI |
| `ZCDS_I_TRADINGDOCUMENTS` | CDS View | Base view: full flow SO → Invoice → Accounting Doc → Settlement → GI |
| `ZCDS_I_TRADINGRECLASSIFICATION` | CDS View | Reclassification documents (join with `ZTBFI_TRD_RECLAS`) |
| `ZCDS_I_TRADINGRECLASSREPORT` | CDS View | Monitor view with calculated quantities and amount differences |
| `ZCDS_I_TRADINGACKRCPTGIREPORT` | CDS View | View for the Goods Issue acknowledgement monitor |
| `ZCDS_I_TRADINGDOCUMENTSTATUS` | CDS View | Process status texts |
| `ZCDS_I_TRADINGDOCSTATUSICON` | CDS View | SAP icons by status |
| `ZCDS_I_TRADINGDOCSTATUSTEXT` | CDS View | Status texts for CDS |
| `ZCDS_I_TRADINGRECLASSLOG` | CDS View | Execution log per document UUID |
| `ZCDS_I_TRADINGRECLASSMDPO` | CDS View | Configuration parameters per company code (doc type, GL, profit centers) |
| `ZTBFI_TRD_RECLAS` | Transparent table | Main reclassification table per purchase accounting document |
| `ZTBFI_TRDRECLLOG` | Transparent table | Process message log per document and timestamp |
| `ZTBFI_TRDRECL_PO` | Transparent table | Customizing per company code: doc type, GL account, profit centers |
| `ZSD_MONI_TRADING_RCL` | Transaction | FI Trading reclassification monitor |
| `ZSD_ENTR_PEND_ACUSE` | Transaction | Pending intercompany delivery acknowledgement monitor |
| `ZCU99_ZRPFI017_TX` | Customizing transaction | Reclassification parameter maintenance (`ZTBFI_TRDRECL_PO`) |

#### Technical prerequisites

| Requirement | Detail |
|---|---|
| **SAP Release** | S/4HANA 2020 or higher |
| **Class /DMBE/CLI_EXTENSION_IN_HELPER** | Must exist in the system; used by the BAdI and `ZCL_FI_TRADING_RECLASS` to package data into `EXTENSION2` |
| **Type /PM0/ABD_OFFLINE_FG** | Required by `ZCL_FI_TRADING_RECLASS` for offline/batch mode |
| **Table ZTBSD_CEBE** | External Z table; must contain profit centers per IC sales organization |
| **Table ZTXX_HARDCODES** | Generic Z table; must contain the GL accounts for `ZRPSD028` |
| **BAdI BADI_ACC_DOCUMENT** | Implementation `ZACC_DOCUM_EXTERNO` must be active |
| **Customizing ZTBFI_TRDRECL_PO** | Must be maintained before processing documents (`ZCU99_ZRPFI017_TX`) |

#### Documentation

| Document | Description |
|---|---|
| [Technical Specification](docs/en/technical-spec.md) | ABAP objects, parameters and logic |
| [Functional Specification](docs/en/functional-spec.md) | Business process and rules |
| [Changelog](docs/en/changelog.md) | Version history |

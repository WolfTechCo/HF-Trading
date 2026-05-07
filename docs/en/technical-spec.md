[← Back to README](../../README.en.md) | [Español](../es/technical-spec.md)

# Technical Specification — HF-Trading

## Contents

- [General Architecture](#general-architecture)
- [ABAP Objects](#abap-objects)
  - [ZCL_FI_TRADING_RECLASS](#zcl_fi_trading_reclass)
  - [ZCL_APPLICATION_LOG](#zcl_application_log)
  - [ZCX_TRADING](#zcx_trading)
  - [ZCL_IM_ACC_DOCUM_EXTERNO](#zcl_im_acc_docum_externo)
  - [ZRPFI017](#zrpfi017)
  - [ZRPSD028](#zrpsd028)
  - [ZGFFI_TRADINGRECLASSGUI](#zgffi_tradingreclassgui)
  - [CDS Views](#cds-views)
- [SAP Tables Used](#sap-tables-used)
- [Related Transactions](#related-transactions)

---

## General Architecture

The development consists of two independent flows sharing a common infrastructure
of classes, tables, and CDS views:

```
FLOW 1 — FI Reclassification Monitor
  Transaction ZSD_MONI_TRADING_RCL
      └─> Module Pool ZRPFI017
          └─> Function Group ZGFFI_TRADINGRECLASSGUI (GUI / Dynpros)
              └─> ZCL_FI_TRADING_RECLASS (Singleton)
                  ├─> CSV Load   ──> ZCDS_I_TRADINGDOCUMENTS ──> INSERT ZTBFI_TRD_RECLAS
                  ├─> Search     ──> ZCDS_I_TRADINGRECLASSREPORT (ALV)
                  ├─> Process    ──> BAPI_ACC_DOCUMENT_POST ──> BAdI ZACC_DOCUM_EXTERNO
                  │                  └─> UPDATE ZTBFI_TRD_RECLAS (status P / F)
                  └─> Log        ──> ZCDS_I_TRADINGRECLASSLOG / ZCL_APPLICATION_LOG

FLOW 2 — Delivery Acknowledgement of Receipt (Goods Issue)
  Transaction ZSD_ENTR_PEND_ACUSE
      └─> Report ZRPSD028
          └─> LCL_REPORT
              ├─> Search     ──> ZCDS_I_TRADINGACKRCPTGIREPORT (ALV)
              ├─> Confirm    ──> BAPI_ACC_DOCUMENT_POST (type WA) ──> UPDATE LIKP
              └─> Cancel     ──> BAPI_ACC_DOCUMENT_REV_POST ──> UPDATE LIKP

SHARED INFRASTRUCTURE
  ZCX_TRADING         ──> Typed exceptions with T100
  ZCL_APPLICATION_LOG ──> BAL (Business Application Log) wrapper
  BAdI ZACC_DOCUM_EXTERNO ──> Enriches XREF1_HD / XREF2_HD in any accounting
                               document created via BAPI_ACC_DOCUMENT_POST
```

---

## ABAP Objects

---

### ZCL_FI_TRADING_RECLASS

**Type:** ABAP Class | **Pattern:** Singleton (CREATE PRIVATE, method `GET_INSTANCE`)

Central class of the reclassification flow. Manages the full cycle: user interface
(ALV + Dynpros), CSV file loading, monitor registration, settings retrieval,
settlement accounting document creation, and process logging.

#### Relevant public types and constants

| Name | ABAP Type | Description |
|---|---|---|
| `TS_ACC_DOC_EXT_FI` | Structure | Trading cross-reference data: `ITEMNO` (POSNR_ACC), `XREF1_HD`, `XREF2_HD` |
| `DOCUMENT_CATEGORY_TRADING` | ENUM (base ZDE_DOCUMENT_TYPE_TRADING) | Document categories: SO, PO, SD invoice, credit note, incoming invoice, etc. |
| `STATUS_TRADING_PRCS` | Constants (ZDE_STATUS_TRADING_PROCESS) | Statuses: N=Unprocessed, P=Processed, I=Partial, F=Processing error, C=Cancelled, D=Cancellation error, E=Error |

#### Public methods

| Method | Input parameters | Return | Description |
|---|---|---|---|
| `GET_INSTANCE` | `BATCHMODE` SAP_BOOL | `INSTANCE` ref to ZCL_FI_TRADING_RECLASS | Returns the unique Singleton instance |
| `DEFAULT_VIEW` | `DYNPRO`, `PROG`, `PFSTATUS`, `TITLE` | — | Sets the default screen on startup |
| `FILE_OPEN_DIALOG` | File filters and name | `FILENAME` RLGRAP-FILENAME | Opens CSV file selection dialog |
| `HANDLE_EVENT` | `EVENT` SYST_UCOMM | — | Central GUI event dispatcher (INIT, PBO, toolbar actions) |
| `IS_OFFLINE` | — | `VALUE` SAP_BOOL | Indicates whether running in batch/offline mode |
| `READ_VIEW` | — | `RESULT` TY_CALL_SCREEN_STACK | Returns the active screen context |
| `SEND` | — | — | Navigates to the registered screen (normal or popup) |
| `SET_FILE_PARAMETERS` | `UL_FILENAME` STRING, `WITH_HEADER` SAP_BOOL | — | Sets CSV file path and whether it has a header row |

#### Core logic (key private methods)

| Method | Logic |
|---|---|
| `READ_SAVE_INTERCO_DOC_TO_MONI` | Reads `ZCDS_I_TRADINGDOCUMENTS` filtered by company code and external reference; verifies a purchase accounting document (KT) exists without prior settlement or existing reclassification; inserts into `ZTBFI_TRD_RECLAS` |
| `READ_SETTINGS` | Reads `ZCDS_I_TRADINGRECLASSMDPO` by source company code of the document; raises `ZCX_TRADING` if no configuration found |
| `CREATE_SETTLEMENT_ACC_DOCUMENT` | Builds BAPI header (type SA), two GL line items (source and target profit centers), amounts with calculated difference, packages `TS_ACC_DOC_EXT_FI` into `EXTENSION2` via `/DMBE/CLI_EXTENSION_IN_HELPER`; calls `BAPI_ACC_DOCUMENT_POST`; on error performs rollback; updates `ZTBFI_TRD_RECLAS` |
| `UPDATE_DOCUMENT_DB` | Updates document status (P if settlement dockey exists, F otherwise), last change date/time/user; persists log into `ZTBFI_TRDRECLLOG`; executes COMMIT |
| `SEARCH_DOCUMENTS` | Reads screen parameters dynamically via `RS_REFRESH_FROM_SELECTOPTIONS`; queries `ZCDS_I_TRADINGRECLASSREPORT` with ranges; refreshes ALV |
| `EXTRACT_DOCUMENTS_FROM_FILE` | Uploads CSV, converts to `ZTTFI_TRADING_RECLASS_FILE` structure, validates mandatory fields and master data (company code, currency, unit), registers in monitor; displays file log |
| `IS_FILE_FIELDS_VALID` | Validates company code existence in `A_CompanyCode`, currency in `I_Currency`, unit in `I_UnitOfMeasure` |
| `CANCEL_DOCUMENTS` | Deletes selected records from `ZTBFI_TRD_RECLAS` that are in Unprocessed (N) status |
| `READ_LOG` | Queries `ZCDS_I_TRADINGRECLASSLOG` for selected documents; displays via BAL grouped by UUID, timestamp, and document type |

---

### ZCL_APPLICATION_LOG

**Type:** ABAP Class (public, final)

Wrapper for SAP's BAL (Business Application Log). Encapsulates log creation,
message writing, and modal display.

#### Attributes

| Attribute | Type | Description |
|---|---|---|
| `CONTROL_HANDLE` | BALCNTHNDL | BAL control handle |
| `LOG_HANDLE` | BALLOGHNDL | Individual log handle |
| `MAX_PROBCLASS` | BALPROBCL | Maximum problem class for display filtering |

#### Main methods

| Method | Input parameters | Description |
|---|---|---|
| `OPEN` | `LOG_OBJECT` BALOBJ_D, `MAX_PROBCLASS` BALPROBCL | Creates a new BAL log in memory |
| `ADD_MESSAGE` | `MSGTY`, `MSGID`, `MSGNO`, `MSGV1-4` | Adds a T100 message to the log |
| `ADD_FREETEXT_MESSAGE` | `TYPE` BAPI_MTYPE, `TEXT` BAPI_MSG | Adds a free-text message |
| `ADD_SYSTEM_MESSAGE` | `DETAIL_LEVEL` BALLEVEL | Adds the system message (`SY-MSG*`) to the log |
| `ADD_MESSAGE_STRUCT` | `LOG_MESSAGE` BAL_S_MSG | Adds a message from a BAL structure |
| `DISPLAY_DETLEVEL` | `MODAL` SAP_BOOL | Displays the log on screen, optionally in modal mode |

---

### ZCX_TRADING

**Type:** Exception class (inherits `CX_STATIC_CHECK`)

Typed exception for the Trading process. Implements `IF_T100_MESSAGE` and
`IF_T100_DYN_MSG` for T100 message support with dynamic variables.
Implements `IF_ABAP_BEHV_MESSAGE` for RAP compatibility.

#### Constructor

| Parameter | Type | Description |
|---|---|---|
| `TEXTID` | IF_T100_MESSAGE=>T100KEY | T100 message key (optional) |
| `PREVIOUS` | CX_ROOT | Previous exception for chaining |
| `MSGTY` | SYMSGTY | Message type (E, W, I, S) |
| `MSGV1-4` | SYMSGV | Message variables |
| `SEVERITY` | T_SEVERITY | Severity for RAP context |

---

### ZCL_IM_ACC_DOCUM_EXTERNO

**Type:** BAdI implementation | **BAdI:** `BADI_ACC_DOCUMENT` | **Enhancement:** `ZACC_DOCUM_EXTERNO`

Extends accounting document creation to write Trading cross-reference fields.

#### Method IF_EX_ACC_DOCUMENT~CHANGE

The development-relevant logic (INSERT block DESK9A0IMI) works as follows:

1. Iterates over `C_EXTENSION2` looking for records where `STRUCTURE = 'TS_ACC_DOC_EXT_FI'`.
2. For each record, uses `/DMBE/CLI_EXTENSION_IN_HELPER=>READ_CONTAINER` to deserialize the generic container.
3. Converts the result to type `ZCL_FI_TRADING_RECLASS=>TS_ACC_DOC_EXT_FI` (fields: `ITEMNO`, `XREF1_HD`, `XREF2_HD`).
4. Locates the corresponding line in `C_ACCIT` by `POSNR = ITEMNO`.
5. Writes `XREF1_HD` (purchase accounting document number / Trading dockey) and `XREF2_HD` (SD intercompany invoice number) into that accounting document item.

Method `CHANGE` parameters (BAdI `IF_EX_ACC_DOCUMENT`):

| Parameter | Type | Mode | Description |
|---|---|---|---|
| `FLT_VAL` | AWTYP | IMPORTING | Reference transaction |
| `C_ACCHD` | ACCHD | CHANGING | Accounting document header |
| `C_ACCIT` | ACCIT_TAB | CHANGING | Accounting document line items |
| `C_ACCCR` | ACCCR_TAB | CHANGING | Currency information |
| `C_ACCWT` | ACCWT_TAB | CHANGING | Withholding tax data |
| `C_ACCTX` | ACCTX_TAB | CHANGING | Tax segment |
| `C_ACCFI` | ACCFI_T | CHANGING | FI one-time accounts (optional) |
| `C_EXTENSION2` | BAPIPAREX_TAB_AC | CHANGING | IDoc extensions (Trading data is read here) |
| `C_RETURN` | BAPIRET2_T | CHANGING | Return table |

---

### ZRPFI017

**Type:** Module Pool

Minimal entry point to the reclassification monitor GUI. The program contains no
business logic of its own: in `START-OF-SELECTION` it calls the maintenance
function module `ZMFSD_TRADINGRECLASSGUI_MAINT` from function group
`ZGFFI_TRADINGRECLASSGUI`, which initializes the Singleton instance and launches
the main screen.

---

### ZRPSD028

**Type:** ALV Report with local class `LCL_REPORT`

Interactive monitor for the acknowledgement of receipt of intercompany deliveries
(Goods Issue).

#### Selection screen

| Field | Table | Description |
|---|---|---|
| `DELIVNUM` | LIKP-VBELN | Outbound delivery number |
| `ICINVOIC` | VBRK-VBELN | Intercompany invoice number |
| `EXTNUM` | VBRK-XBLNR | External reference number |
| `SMDATE` | LIKP-WADAT_IST | Actual goods movement date |
| `CANC_DOC` | — | Checkbox: if checked, shows documents with GI to cancel |

#### Local class LCL_REPORT — main methods

| Method | Description |
|---|---|
| `READ_DATA` | Queries `ZCDS_I_TRADINGACKRCPTGIREPORT` with selection filters; groups by invoice |
| `READ_SETTINGS` | Reads GL accounts from `ZTXX_HARDCODES` (two records: GL_ACCOUNT sequences 1 and 2) |
| `POST_GOODS_ISSUE` | Requests posting date; calls `READ_SETTINGS`, then `CREATE_GOODS_ISSUE_DOCUMENT` per selected document |
| `CREATE_GOODS_ISSUE_DOCUMENT` | Locks deliveries; reads positions from `I_JournalEntryItem`; builds WA header, GL items with profit centers from `ZTBSD_CEBE`, amounts; calls `BAPI_ACC_DOCUMENT_POST`; updates `LIKP-UVK01` |
| `CANCEL_GOODS_ISSUE` | Calls `CANCEL_GOODS_ISSUE_DOCUMENT` for each selected document |
| `CANCEL_GOODS_ISSUE_DOCUMENT` | Builds `BAPIACREV` reversal structure; calls `BAPI_ACC_DOCUMENT_REV_POST`; updates `LIKP-UVK01` |
| `LOCK_DELIVERIES` | Verifies and acquires ENQUEUE locks on all deliveries related to the invoice |
| `UPDATE_ACK_RECEIPT_FIELD` | Updates `LIKP-UVK01` with acknowledgement status (`'C'` confirmed / `'A'` cancelled) and releases locks |
| `DISPLAY_LOG` | Displays BAL log grouped by intercompany invoice for the operations executed in the session |

---

### ZGFFI_TRADINGRECLASSGUI

**Type:** Function Group

Contains the Dynpros and navigation logic for the reclassification monitor GUI.
Manages two modal screens:

| Screen | Description |
|---|---|
| 9001 | CSV file upload: file path field and browse button |
| 9002 | Document search: subscreen 2000 with selection parameters |

The main screen (non-popup) hosts the `CL_SALV_TABLE` ALV embedded in a
`CL_GUI_CUSTOM_CONTAINER`.

---

### CDS Views

#### ZCDS_I_TRADINGDOCUMENTS

Base view of the complete Trading flow. Reads from `I_BillingDocumentItem` and
connects via associations to:

| Association | Standard view | Description |
|---|---|---|
| `_BillingDocument` | I_BillingDocument | SD invoice header (filter: type ZIV, not temporary, not cancelled) |
| `_SalesDocument` | I_SalesDocument | Source sales order |
| `_OutboundDelivery` | I_OutboundDelivery | Outbound delivery |
| `_PurchaseAccDocumentItem` | I_JournalEntryItem | Purchase accounting document item (type KT, company IRHO, ledger 0L, not reversed) |
| `_AckReceiptGoodsIssueItem` | I_JournalEntryItem | Goods Issue document item (type WA, company IRHO, ledger 0L, not reversed) |
| `_SettlementAccDocument` | I_JournalEntry | Settlement document (type SA, referenced by SD invoice) |
| `_TradingReclassification` | ZCDS_I_TRADINGRECLASSIFICATION | Reclassification status of the document |

#### ZCDS_I_TRADINGRECLASSIFICATION

Reads from `ZTBFI_TRD_RECLAS`. Exposes UUID key, purchase accounting document,
process status, related SD documents, and settlement document dockey.

#### ZCDS_I_TRADINGRECLASSREPORT

Extends `ZCDS_I_TRADINGRECLASSIFICATION`. Calculates via `SUM` over
`I_JournalEntryItem`:
- `QUANTITYINPURCHASEINVOICE`: sum of quantities from FI line items
- `PURCHASEINVOICEAMOUNT`: sum of amounts in transaction currency
- `DIFAMOUNTINTRANSACTIONCURRENCY`: difference between agreed amount and purchase invoice

#### ZCDS_I_TRADINGACKRCPTGIREPORT

Extends `ZCDS_I_TRADINGDOCUMENTS`. Adds delivery data (GI date, sold-to/ship-to
customer, intercompany billing customer, IC sales org) and exposes the
`ACKRECEIPTGOODSISSUEEXIST` indicator to filter pending vs. processed.

#### ZCDS_I_TRADINGRECLASSMDPO

Reads from `ZTBFI_TRDRECL_PO`. Exposes per company code: accounting document type,
GL account, source profit center, and target profit center for the settlement document.

#### ZCDS_I_TRADINGRECLASSLOG

Reads from `ZTBFI_TRDRECLLOG`. Exposes the message log groupable by
`DOCUMENTUUID`, `DATETIMEL`, and `TYPEDOCUMENT`.

---

## SAP Tables Used

### Z tables of this development

| Table | Class | Description | Usage |
|---|---|---|---|
| `ZTBFI_TRD_RECLAS` | Transparent | Trading Invoices — Reclassification | Main record per purchase accounting document pending or processed |
| `ZTBFI_TRDRECLLOG` | Transparent | Reclassification log per document | Audit trail of messages per process execution |
| `ZTBFI_TRDRECL_PO` | Transparent | Configuration per company code | Document type, GL account, and profit centers for the SA document |
| `ZTBSD_CEBE` | Transparent (external) | Profit centers per IC sales org | Used in ZRPSD028 to assign profit centers to the GI document |
| `ZTXX_HARDCODES` | Transparent (external) | Generic parameter table | Used in ZRPSD028 to read GL accounts for the Goods Issue |

Structures (INTTAB):

| Structure | Description |
|---|---|
| `ZSTFI_TRADING_RECLASS` | Monitor structure = ZTBFI_TRD_RECLAS + calculated fields (quantities, amounts, status icon, origin company code) |
| `ZSTFI_TRADING_RECLASS_KEY` | Document UUID key |
| `ZSTFI_TRADING_RECLASS_DOCKEY` | Purchase accounting document key (AccountingDocument, CompanyCode, FiscalYear) |
| `ZSTFI_TRADING_RECLASS_FILE` | CSV input file structure |
| `ZSTFI_TRADING_RECLASS_LOGFILE` | File log structure (CSV validation messages) |
| `ZSTFI_TRADING_RECLASS_STDOCKEY` | Settlement accounting document key |
| `ZSTFI_TRADING_RECLASS_LOGKEY` | Log key (UUID + timestamp + sequence) |
| `ZST_TRADING_LOG` | Process log message structure |

### Standard SAP tables and CDS referenced

| Object | Usage |
|---|---|
| `VBRK` | SD invoice header (FK check in ZTBFI_TRD_RECLAS) |
| `VBAK` | Sales order header (FK check) |
| `LIKP` | Outbound delivery header (UVK01 update in acknowledgement of receipt) |
| `I_BillingDocument` / `I_BillingDocumentItem` | Intercompany SD invoice data |
| `I_SalesDocument` / `I_SalesDocumentItem` | Sales order data |
| `I_OutboundDelivery` / `I_OutboundDeliveryItem` | Outbound delivery data |
| `I_JournalEntry` / `I_JournalEntryItem` | FI accounting documents (purchase KT, settlement SA, GI WA) |
| `I_Customer` | Customer name for acknowledgement views |
| `A_CompanyCode` | Company code existence validation on CSV load |
| `I_Currency` | Currency validation on CSV load |
| `I_UnitOfMeasure` | Unit of measure validation on CSV load |

---

## Related Transactions

| Transaction | Type | Program | Description |
|---|---|---|---|
| `ZSD_MONI_TRADING_RCL` | Custom | ZRPFI017 | FI Trading reclassification monitor |
| `ZSD_ENTR_PEND_ACUSE` | Custom | ZRPSD028 | Intercompany delivery acknowledgement of receipt monitor |
| `ZCU99_ZRPFI017_TX` | Customizing | ZRPFI017 | Reclassification parameter maintenance (`ZTBFI_TRDRECL_PO`) |
| `VA03` | SAP Standard SD | — | Navigation to sales order (ALV hotspot) |
| `VF03` | SAP Standard SD | — | Navigation to SD invoice (ALV hotspot) |
| `FB03` | SAP Standard FI | — | Navigation to accounting document (ALV hotspot) |

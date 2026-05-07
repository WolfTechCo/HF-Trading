[← Back to README](../../README.md) | [Español](../es/functional-spec.md)

# Functional Specification — HF-Trading

## Contents

- [Business Process](#business-process)
- [Business Rules](#business-rules)
- [Main Flow](#main-flow)
  - [Flow 1 — FI Reclassification](#flow-1--fi-reclassification)
  - [Flow 2 — Delivery Acknowledgement of Receipt](#flow-2--delivery-acknowledgement-of-receipt)
- [Error Handling](#error-handling)
- [User Profile](#user-profile)

---

## Business Process

In **Trading Intercompany** operations, one group company acts as an intermediary:
it purchases goods from an external supplier and resells them to another group
company (intercompany customer). This process generates a document flow that spans
the SD and FI modules:

1. The selling company creates a **sales order (SO)** for the buying company.
2. An **outbound delivery** is performed and an **internal SD invoice (type ZIV)**
   is issued.
3. The SD invoice automatically generates a **purchase accounting document (KT)**
   in the buying company (company code IRHO).
4. The value of that KT document may differ from the transaction value agreed upon
   in the route sheet or framework contract. This difference must be adjusted via
   a **settlement accounting document (SA)**.
5. Additionally, the physical delivery of the goods must be confirmed through a
   **goods movement document (WA — Goods Issue)** that records the stock decrease
   in the system.

This development automates steps 4 and 5, which would otherwise require manual
creation of accounting documents.

---

## Business Rules

### FI Reclassification (Flow 1)

| Rule | Description |
|---|---|
| **Eligible document** | Only documents whose SD invoice is of type ZIV, is not cancelled, and is not temporary can be reclassified |
| **No prior reclassification** | A purchase accounting document (KT) can only be registered once in the monitor; if it already has an active record in `ZTBFI_TRD_RECLAS`, the load is rejected |
| **No prior settlement** | The KT document must not already have a settlement document (SA) in the flow at the time of loading |
| **Mandatory CSV fields** | CompanyCode, DocumentReferenceID, PostingDate, Quantity, TransactionQuantityUnit, Amount, TransactionCurrency. Any missing field prevents registration |
| **Master data validation** | The company code must exist in `A_CompanyCode`, the currency in `I_Currency`, and the unit in `I_UnitOfMeasure`; otherwise the line is rejected with an error message |
| **Mandatory prior configuration** | A record must exist in `ZTBFI_TRDRECL_PO` for the source company code before executing the processing |
| **SA document with two line items** | The settlement document always has exactly two GL items: one with the source profit center and one with the target profit center configured, for the difference amount and its negative |
| **Cancellation only in status N** | Only records in Unprocessed (N) status can be cancelled (deleted from the monitor). Documents in status P, F, I, C, or D cannot be cancelled from the monitor |
| **Cross-references in SA** | Fields `XREF1_HD` and `XREF2_HD` of the SA document are populated with the purchase accounting document number and the SD invoice number respectively, via BAdI |

### Delivery Acknowledgement of Receipt / Goods Issue (Flow 2)

| Rule | Description |
|---|---|
| **Eligible document for confirmation** | The intercompany invoice must have an existing purchase accounting document (KT) and must not yet have a Goods Issue (WA) registered |
| **Eligible document for cancellation** | The invoice must have a GI registered and must not already have a cancellation document |
| **Posting date required** | Before confirming the GI, the system prompts the user to enter the accounting document posting date |
| **Delivery locking** | Before processing the GI, the system checks and acquires locks on all deliveries associated with the invoice; if any delivery is locked by another user, the document is skipped with an error |
| **GL accounts must be configured** | The GL accounts for the WA document (two accounts: one for assets, one for contra entry) are read from `ZTXX_HARDCODES`; if they do not exist, the process is interrupted |
| **Profit center by account type** | For account type 'S' (Balance) the profit center configured in `ZTBSD_CEBE` by IC sales org is used; for type 'K' (Vendor) the profit center is left blank |
| **Acknowledgement field update** | Upon GI confirmation, `LIKP-UVK01` is updated to status 'C' (confirmed); upon cancellation, to status 'A' (annulled) |

---

## Main Flow

### Flow 1 — FI Reclassification

```
STEP 1 — PREPARATION
  The FI consultant accesses ZSD_MONI_TRADING_RCL.
  The system displays the ALV monitor (initially empty).

STEP 2 — CSV FILE LOAD
  User selects "Load File" on the toolbar.
  Popup screen 9001: user selects the CSV file on their PC.
  The system:
    a. Uploads the file via CL_GUI_FRONTEND_SERVICES.
    b. Converts CSV to internal table ZTTFI_TRADING_RECLASS_FILE.
    c. For each line:
       - Validates mandatory fields.
       - Validates master data (company code, currency, unit).
       - Queries ZCDS_I_TRADINGDOCUMENTS to find the KT document
         without prior settlement and without existing reclassification.
       - If found: inserts into ZTBFI_TRD_RECLAS with status N.
       - If not found: records error in file log.
    d. Displays file log (BAL) with result per line.
    e. Refreshes the ALV with the newly loaded records.

STEP 3 — SEARCH / FILTER
  User can search already-registered documents via popup screen 9002
  (multiple criteria: company code, accounting document, status,
  sales order, invoice, reference, dates, etc.).
  The system queries ZCDS_I_TRADINGRECLASSREPORT and refreshes the ALV.

STEP 4 — PROCESSING
  User selects one or more records in status N or F and presses
  "Create Documents".
  For each selected document:
    a. Reads configuration from ZTBFI_TRDRECL_PO for the source company.
    b. Builds the SA document with:
       - Posting date = date indicated at load time.
       - Reference = DocumentReferenceID.
       - Header text = "[SalesDocument] Cost Adjustment".
       - Item 1: GL account / source profit center / difference amount.
       - Item 2: GL account / target profit center / negative amount.
       - EXTENSION2 with TS_ACC_DOC_EXT_FI (for BAdI).
    c. Calls BAPI_ACC_DOCUMENT_POST.
    d. BAdI writes XREF1_HD and XREF2_HD into the document.
    e. Updates ZTBFI_TRD_RECLAS:
       - Status P if the SA document was successfully created.
       - Status F if there was an error.
    f. Saves log in ZTBFI_TRDRECLLOG with all BAPI messages.
    g. Executes COMMIT_WORK_AND_WAIT.
  At completion refreshes the ALV.

STEP 5 — LOG REVIEW
  User selects document(s) and presses "View Log".
  The system displays the BAL log grouped by:
    - Document UUID (header with company code, reference, date).
    - Execution timestamp.
    - Type of document processed.
    - Individual BAPI messages.

STEP 6 — CANCELLATION (status N only)
  User selects records in status N and presses "Cancel".
  System asks for confirmation. Upon confirming, deletes the records
  from ZTBFI_TRD_RECLAS and refreshes the ALV.
```

### Flow 2 — Delivery Acknowledgement of Receipt

```
STEP 1 — SELECTION
  The SD/FI consultant accesses ZSD_ENTR_PEND_ACUSE.
  Enters optional filters: deliveries, IC invoices, reference, GI date.
  The "Cancel doc." checkbox determines the mode:
    - Unchecked: shows invoices WITHOUT Goods Issue (pending confirmation).
    - Checked: shows invoices WITH Goods Issue (pending cancellation).

STEP 2 — ALV DISPLAY
  The system queries ZCDS_I_TRADINGACKRCPTGIREPORT and shows:
  IC invoice, company code, invoice date, external reference, delivery
  count, GI date, sold-to/ship-to customer, KT and WA document data.
  Accounting documents are hotspots navigating to FB03.
  The IC invoice is a hotspot navigating to VF03.

STEP 3 — GOODS ISSUE CONFIRMATION
  (Only available if checkbox is NOT checked)
  User selects pending invoices and presses "Confirm Acknowledgement".
  System requests posting date via popup.
  For each invoice:
    a. Reads GL accounts from ZTXX_HARDCODES.
    b. Locks related deliveries (ENQUEUE_EVVBLKE).
    c. Reads KT accounting document items (I_JournalEntryItem).
    d. Builds WA document (type WA, reference = KT doc, "STOCK DECREASE").
    e. GL items with accounts and profit centers by account type.
    f. Calls BAPI_ACC_DOCUMENT_POST.
    g. Updates LIKP-UVK01 = 'C' and releases locks.
    h. COMMIT_WORK_AND_WAIT.

STEP 4 — GOODS ISSUE CANCELLATION
  (Only available if checkbox IS checked)
  User selects invoices with GI and presses "Cancel Acknowledgement".
  For each invoice:
    a. Locks deliveries.
    b. Builds BAPIACREV reversal with the existing WA document.
    c. Calls BAPI_ACC_DOCUMENT_REV_POST.
    d. Updates LIKP-UVK01 = 'A' and releases locks.
    e. COMMIT_WORK_AND_WAIT.

STEP 5 — OPERATION LOG
  User presses "View Log" to review the messages from the last
  processing session, grouped by IC invoice.
```

---

## Error Handling

| Situation | Behavior |
|---|---|
| CSV line with missing mandatory fields | Recorded in file log with specific error message per field; line is skipped; process continues with the next line |
| CSV line with invalid master data (company, currency, unit) | Same as above; specific message for the missing master |
| KT document not found or already reclassified | Error message in file log; line is skipped |
| ZTBFI_TRDRECL_PO configuration missing for company code | `ZCX_TRADING` raised with error message; document remains in status F |
| BAPI_ACC_DOCUMENT_POST returns type 'E' message | BAPI_TRANSACTION_ROLLBACK is executed; document status set to F in ZTBFI_TRD_RECLAS; error messages persisted in ZTBFI_TRDRECLLOG |
| Delivery locked by another user during GI confirm/cancel | Document is skipped with error message indicating the locking user; processing continues with next document |
| GL accounts not configured in ZTXX_HARDCODES (ZRPSD028) | ZCX_TRADING raised with error message; GI confirmation process is interrupted completely |
| GI already exists when attempting confirmation | Error message; document is skipped |
| GI already cancelled when attempting cancellation again | Error message; document is skipped |
| Unexpected exception during processing | Caught as `ZCX_TRADING` or subclass; converted to BAPIRET2 and recorded in the log |

---

## User Profile

### FI Reclassification Monitor (ZSD_MONI_TRADING_RCL)

| Aspect | Detail |
|---|---|
| **Role** | Finance (FI) consultant or analyst |
| **When used** | Periodically (monthly or per accounting close cycle) when intercompany cost differences between the purchase value and the agreed transaction value need to be adjusted |
| **Main action** | Loads the CSV file with adjustment data; reviews the monitor; processes pending documents; verifies the results log |
| **Prerequisite** | Company code configuration must be maintained in `ZTBFI_TRDRECL_PO` via `ZCU99_ZRPFI017_TX` before running the process |

### Acknowledgement of Receipt Monitor (ZSD_ENTR_PEND_ACUSE)

| Aspect | Detail |
|---|---|
| **Role** | SD or FI consultant/analyst with knowledge of the intercompany process |
| **When used** | When intercompany deliveries have been physically received and must be confirmed in the system through the WA goods movement; or when an erroneous GI must be reversed |
| **Main action** | Filters IC invoices with pending delivery acknowledgements; selects records; enters the posting date; confirms the Goods Issue |
| **Prerequisite** | GL accounts must be configured in `ZTXX_HARDCODES` and profit centers in `ZTBSD_CEBE` before executing |

[🇪🇸 Versión en español](README.md)

# HF-Trading — Trading / Intercompany Process (HF)

Custom Z development for SAP S/4HANA that automates the document flow of the
**Trading Intercompany** process: from the internal SD invoice (type ZIV) through
the creation of the settlement accounting document (SA) and the delivery
acknowledgement of receipt (Goods Issue WA). Includes an interactive monitor
with CSV data loading, mass processing, and audit log.

---

## Functional description

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

---

## SAP modules involved

| Module | Participation |
|---|---|
| **SD** — Sales & Distribution | Intercompany invoices (ZIV), sales orders, outbound deliveries |
| **FI** — Financial Accounting | Creation of SA and WA accounting documents via BAPI |
| **MM** — Materials Management | Goods Issue (type WA) in acknowledgement of receipt |
| **CO** — Controlling | Profit centers in the settlement document |

---

## ABAP objects

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

---

## Technical prerequisites

| Requirement | Detail |
|---|---|
| **SAP Release** | S/4HANA 2020 or higher |
| **Class /DMBE/CLI_EXTENSION_IN_HELPER** | Must exist in the system; used by the BAdI and `ZCL_FI_TRADING_RECLASS` to package data into `EXTENSION2` |
| **Type /PM0/ABD_OFFLINE_FG** | Required by `ZCL_FI_TRADING_RECLASS` for offline/batch mode |
| **Table ZTBSD_CEBE** | External Z table; must contain profit centers per IC sales organization |
| **Table ZTXX_HARDCODES** | Generic Z table; must contain the GL accounts for `ZRPSD028` |
| **BAdI BADI_ACC_DOCUMENT** | Implementation `ZACC_DOCUM_EXTERNO` must be active |
| **Customizing ZTBFI_TRDRECL_PO** | Must be maintained before processing documents (`ZCU99_ZRPFI017_TX`) |

---

## Installation and transport

1. Clone the repository with **abapGit** pointing to the `/src/` folder.
2. Activate all dictionary objects in order: domains → data elements → structures → tables → table types.
3. Activate ABAP classes in order: `ZCX_TRADING` → `ZCL_APPLICATION_LOG` → `ZCL_FI_TRADING_RECLASS`.
4. Activate CDS views in order: `ZCDS_I_TRADINGDOCUMENTS` → `ZCDS_I_TRADINGRECLASSIFICATION` → remaining views.
5. Activate function group `ZGFFI_TRADINGRECLASSGUI`.
6. Activate reports `ZRPFI017` and `ZRPSD028`.
7. Transport the BAdI implementation (`ZACC_DOCUM_EXTERNO`) and verify it is active.
8. Maintain configuration parameters via `ZCU99_ZRPFI017_TX` and `ZTXX_HARDCODES` records for `ZRPSD028`.

---

## Documentation

| Document | Description |
|---|---|
| [Technical Specification](docs/en/technical-spec.md) | ABAP objects, parameters and logic |
| [Functional Specification](docs/en/functional-spec.md) | Business process and rules |
| [Changelog](docs/en/changelog.md) | Version history |

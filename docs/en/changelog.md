[← Back to README](../../README.en.md) | [Español](../es/changelog.md)

# Changelog — HF-Trading

## Contents

- [Versions](#versions)

---

## Versions

### v1.0.0 — 2026-05-07

Initial documentation release. Version capturing the complete repository state
at time of documentation.

**Scope of development:**

- FI reclassification interactive monitor (`ZSD_MONI_TRADING_RCL`): CSV data load,
  creation of settlement accounting documents (SA) with intercompany cost difference
  adjustments, process log, and cancellation of pending records.
- Intercompany delivery acknowledgement of receipt monitor (`ZSD_ENTR_PEND_ACUSE`):
  confirmation and cancellation of goods movement documents (WA) for Trading
  process deliveries.
- BAdI `BADI_ACC_DOCUMENT` enhancement (implementation `ZACC_DOCUM_EXTERNO`):
  writes Trading cross-references (`XREF1_HD`, `XREF2_HD`) into the accounting
  document at creation time via `BAPI_ACC_DOCUMENT_POST`.
- 9 CDS views for the Trading flow data model.
- Z tables: `ZTBFI_TRD_RECLAS`, `ZTBFI_TRDRECLLOG`, `ZTBFI_TRDRECL_PO`.
- Exception class `ZCX_TRADING` and application log wrapper `ZCL_APPLICATION_LOG`.

**Original development:** Jorge Lizama G. (FinisTech Consultores) — BAdI
enhancement (DESK928825, Nov-2019). Flow extension with delivery and
acknowledgement of receipt (DESK9A0KPX, DESK9A0IMI). Report ZRPSD028 — Carlos
Becar (Jul-2025).

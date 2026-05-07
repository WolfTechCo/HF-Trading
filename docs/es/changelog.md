[← Volver al README](../../README.md) | [English](../en/changelog.md)

# Changelog — HF-Trading

## Contenidos

- [Versiones](#versiones)

---

## Versiones

### v1.0.0 — 2026-05-07

Documentación inicial del desarrollo. Versión que incorpora el estado completo
del repositorio al momento de la documentación.

**Ámbito del desarrollo:**

- Monitor interactivo de reclasificación FI (`ZSD_MONI_TRADING_RCL`): carga de
  datos vía CSV, creación de documentos contables de liquidación (SA) con ajuste
  de diferencias intercompany, log de proceso y cancelación de registros pendientes.
- Monitor de acuse de recibo de entregas intercompany (`ZSD_ENTR_PEND_ACUSE`):
  confirmación y cancelación del documento de movimiento de mercancías (WA) para
  entregas del proceso Trading.
- Ampliación BAdI `BADI_ACC_DOCUMENT` (implementación `ZACC_DOCUM_EXTERNO`):
  escritura de referencias cruzadas Trading (`XREF1_HD`, `XREF2_HD`) en el
  documento contable al momento de su creación vía `BAPI_ACC_DOCUMENT_POST`.
- 9 vistas CDS para el modelo de datos del flujo Trading.
- Tablas Z: `ZTBFI_TRD_RECLAS`, `ZTBFI_TRDRECLLOG`, `ZTBFI_TRDRECL_PO`.
- Clase de excepción `ZCX_TRADING` y wrapper de log `ZCL_APPLICATION_LOG`.

**Desarrollo original:** Jorge Lizama G. (FinisTech Consultores) — ampliación
BAdI (DESK928825, nov-2019). Extensión del flujo con entrega y acuse de recibo
(DESK9A0KPX, DESK9A0IMI). Reporte ZRPSD028 — Carlos Becar (jul-2025).

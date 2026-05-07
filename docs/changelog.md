[← Volver al README](../README.md)

# Changelog — HF-Trading

## Contenidos

- [Versiones](#versiones)

---

## Versiones

### v1.0.0 — 2026-05-07

Documentacion inicial del desarrollo. Version que incorpora el estado completo
del repositorio al momento de la documentacion.

**Ambito del desarrollo:**

- Monitor interactivo de reclasificacion FI (`ZSD_MONI_TRADING_RCL`): carga de
  datos via CSV, creacion de documentos contables de liquidacion (SA) con ajuste
  de diferencias intercompany, log de proceso y cancelacion de registros pendientes.
- Monitor de acuse de recibo de entregas intercompany (`ZSD_ENTR_PEND_ACUSE`):
  confirmacion y cancelacion del documento de movimiento de mercancias (WA) para
  entregas del proceso Trading.
- Ampliacion BAdI `BADI_ACC_DOCUMENT` (implementacion `ZACC_DOCUM_EXTERNO`):
  escritura de referencias cruzadas Trading (`XREF1_HD`, `XREF2_HD`) en el
  documento contable al momento de su creacion via `BAPI_ACC_DOCUMENT_POST`.
- 9 vistas CDS para el modelo de datos del flujo Trading.
- Tablas Z: `ZTBFI_TRD_RECLAS`, `ZTBFI_TRDRECLLOG`, `ZTBFI_TRDRECL_PO`.
- Clase de excepcion `ZCX_TRADING` y wrapper de log `ZCL_APPLICATION_LOG`.

**Desarrollo original:** Jorge Lizama G. (FinisTech Consultores) — ampliacion
BAdI (DESK928825, nov-2019). Extension del flujo con entrega y acuse de recibo
(DESK9A0KPX, DESK9A0IMI). Reporte ZRPSD028 — Carlos Becar (jul-2025).

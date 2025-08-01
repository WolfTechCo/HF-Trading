*&---------------------------------------------------------------------*
*& Include          ZRPSD028_SEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.

  SELECT-OPTIONS delivnum FOR likp-vbeln.
  SELECT-OPTIONS icinvoic FOR vbrk-vbeln.
  SELECT-OPTIONS extnum FOR vbrk-xblnr.
  SELECT-OPTIONS smdate FOR likp-wadat_ist.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002.

  PARAMETERS canc_doc AS CHECKBOX MODIF ID cab USER-COMMAND cb.

SELECTION-SCREEN END OF BLOCK b2.

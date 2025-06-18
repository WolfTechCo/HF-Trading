*&---------------------------------------------------------------------*
*& Include          LZGFSD_TRADINGEXTGUISEL
*&---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF SCREEN 2000 AS SUBSCREEN.
  SELECTION-SCREEN BEGIN OF BLOCK intercoompany WITH FRAME TITLE TEXT-001.
    SELECT-OPTIONS:
      docuuid FOR ztbfi_trd_reclas-documentuuid NO-DISPLAY,
      ccode FOR ztbfi_trd_reclas-companycode,
      accdoc FOR ztbfi_trd_reclas-accountingdocument,
      fyear FOR ztbfi_trd_reclas-fiscalyear,
      status FOR ztbfi_trd_reclas-documentstatus,
      sorder FOR ztbfi_trd_reclas-salesdocument,
      billdoc FOR ztbfi_trd_reclas-billingdocument,
      docrefid FOR ztbfi_trd_reclas-documentreferenceid,
      cnt FOR vbak-zcontenedor,
      postdate FOR ztbfi_trd_reclas-to_postingdate,
      createat FOR ztbfi_trd_reclas-createdatdate,
      modifat FOR ztbfi_trd_reclas-lastchangedate.
  SELECTION-SCREEN END OF BLOCK intercoompany.
  SELECTION-SCREEN BEGIN OF BLOCK accountingdoc WITH FRAME TITLE TEXT-002.
    SELECT-OPTIONS:
      ccodest FOR ztbfi_trd_reclas-companycodesettlement,
      accdocst FOR ztbfi_trd_reclas-accountingdocumentsettlement,
      fyearst FOR ztbfi_trd_reclas-fiscalyearsettlement.
  SELECTION-SCREEN END OF BLOCK accountingdoc.
SELECTION-SCREEN END OF SCREEN 2000.

INITIALIZATION.
  CLEAR docuuid[].

AT SELECTION-SCREEN.
  CHECK sy-dynnr = 2000 AND ok_mcode = '_%READDOCS'.

* Screen field validations here
*  MESSAGE e013(f5).
*  CLEAR ok_mcode.

*---------------------------------------------------------------------*
*    view related data declarations
*---------------------------------------------------------------------*
*...processing: ZTBFI_TRDRECL_PO................................*
DATA:  BEGIN OF STATUS_ZTBFI_TRDRECL_PO              .   "state vector
         INCLUDE STRUCTURE VIMSTATUS.
DATA:  END OF STATUS_ZTBFI_TRDRECL_PO              .
CONTROLS: TCTRL_ZTBFI_TRDRECL_PO
            TYPE TABLEVIEW USING SCREEN '0010'.
*.........table declarations:.................................*
TABLES: *ZTBFI_TRDRECL_PO              .
TABLES: ZTBFI_TRDRECL_PO               .

* general table data declarations..............
  INCLUDE LSVIMTDT                                .

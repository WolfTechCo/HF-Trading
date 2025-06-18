FUNCTION-POOL zgffi_tradingreclassgui.          "MESSAGE-ID ..

TABLES ztbfi_trd_reclas.
TABLES vbak.

CONSTANTS:
  BEGIN OF default_view,
    prog     TYPE sy-repid VALUE sy-repid,
    dynpro   TYPE syst_dynnr VALUE '9000',
    pfstatus TYPE pfstatus VALUE 'MSCREEN',
    title    TYPE gui_title VALUE 'MSCREEN',
  END OF default_view.

DATA ul_filef TYPE file_table-filename.
DATA view_info TYPE zst99_call_screen_stack.
DATA ok_mcode TYPE sy-ucomm.
DATA monitor TYPE REF TO zcl_fi_trading_reclass.

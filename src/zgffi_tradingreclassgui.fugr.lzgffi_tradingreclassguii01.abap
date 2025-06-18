*----------------------------------------------------------------------*
***INCLUDE LZGFSD_TRADINGEXTGUII01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  PAI  INPUT
*&---------------------------------------------------------------------*
MODULE pai INPUT.
  monitor = zcl_fi_trading_reclass=>get_instance( ).
  monitor->get_instance( )->handle_event( ok_mcode ).
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  EVENT_PAI  INPUT
*&---------------------------------------------------------------------*
MODULE event_pai INPUT.
  monitor->get_instance( )->handle_event( ok_mcode ).
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  FILE_OPEN_DIALOG  INPUT
*&---------------------------------------------------------------------*
MODULE file_open_dialog INPUT.
  TRY.
      ul_filef = monitor->get_instance( )->file_open_dialog( fieldname = 'UL_FILEF' ).
    CATCH cx_cts_eps_io_exception INTO DATA(cx_io).
      MESSAGE cx_io->get_text( ) TYPE 'S'.
  ENDTRY.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  SET_FILE_PARAMETERS  INPUT
*&---------------------------------------------------------------------*
MODULE set_file_parameters INPUT.
  monitor->get_instance( )->set_file_parameters( ul_filename = CONV #( ul_filef ) ).
ENDMODULE.

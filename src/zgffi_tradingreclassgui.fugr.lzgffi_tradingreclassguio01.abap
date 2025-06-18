*----------------------------------------------------------------------*
***INCLUDE LZGFSD_TRADINGEXTGUIO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module PBO OUTPUT
*&---------------------------------------------------------------------*
MODULE pbo OUTPUT.
  monitor = zcl_fi_trading_reclass=>get_instance( ).
  monitor->handle_event( 'INIT').
  cl_gui_cfw=>flush( ).
  CLEAR ok_mcode.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module STATUS_9001 OUTPUT
*&---------------------------------------------------------------------*
MODULE event_9001 OUTPUT.
  monitor->get_instance( )->handle_event( 'PBO9001' ).
  cl_gui_cfw=>flush( ).
  CLEAR ok_mcode.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module EVENT_9002 OUTPUT
*&---------------------------------------------------------------------*
MODULE event_9002 OUTPUT.
  view_info = monitor->get_instance( )->read_view(  ).
  monitor->get_instance( )->handle_event( 'PBO9002' ).
  cl_gui_cfw=>flush( ).
  CLEAR ok_mcode.
ENDMODULE.
*&---------------------------------------------------------------------*
*& Module EVENT_9003 OUTPUT
*&---------------------------------------------------------------------*
MODULE event_9003 OUTPUT.
  monitor->get_instance( )->handle_event( 'PBO9003' ).
  cl_gui_cfw=>flush( ).
  CLEAR ok_mcode.
ENDMODULE.

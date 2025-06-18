FUNCTION zmfsd_tradingreclassgui_maint.
*"----------------------------------------------------------------------
*"*"Interfase local
*"----------------------------------------------------------------------

  DATA(mo_trading_reclass) = zcl_fi_trading_reclass=>get_instance( ).

  mo_trading_reclass->default_view( dynpro   = default_view-dynpro
                                    prog     = default_view-prog
                                    pfstatus = default_view-pfstatus
                                    title    = default_view-title ).
  mo_trading_reclass->send( ).

ENDFUNCTION.

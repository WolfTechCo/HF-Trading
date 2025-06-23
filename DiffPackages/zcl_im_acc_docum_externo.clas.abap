CLASS zcl_im_acc_docum_externo DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_badi_interface .
    INTERFACES if_ex_acc_document .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_im_acc_docum_externo IMPLEMENTATION.


  METHOD if_ex_acc_document~change.
*==============================================================================*
*                     AMPLIACION DOCUMENTO CONTABLE                            *
*DESCRIPCION:  Se crea ampliación para ingreso de datos no pasables por BAPI a *
* la creación del documento contable. Utilizando estructura extension2 de BAPI *
* se traspasa el valor indicando el campo al que corresponde para realizar el  *
* reemplazo en este método.                                                    *
**----------------------------------------------------------------------------**
*ANALISTA   :      Jorge Lizama G.     (FinisTech Consultores)                 *
*PROGRAMADOR:      Jorge Lizama G.     (FinisTech Consultores)                 *
**----------------------------------------------------------------------------**
*LOG DE MODIFICACION:                                                          *
*  FECHA        PROGRAMADOR        CORRECCION          DESCRIPCION             *
* 28-11-2019   Jorge Lizama        DESK928825        Creación                  *
* ddmmmaaaa   xxxxxxxxxxxxxx       C11K906167       xxxxxxxxxxxxxxxxxxxxxxxx   *
* ddmmmaaaa   xxxxxxxxxxxxxx       C11K906200       xxxxxxxxxxxxxxxxxxxxxxxx   *
*------------------------------------------------------------------------------*

    DATA: wa_extension LIKE LINE OF c_extension2,
          wa_accit     LIKE LINE OF c_accit,
          lv_posnr     TYPE posnr_acc.

*   Se busca por campo BSCHL en la extension2 de la BAPI para reemplazar en estructura c_accit.
    LOOP AT c_extension2 INTO wa_extension WHERE valuepart1 EQ 'BSCHL'.
      lv_posnr = wa_extension-structure.
      READ TABLE c_accit WITH KEY posnr = lv_posnr
            INTO wa_accit.
      IF sy-subrc EQ 0.
        wa_accit-bschl = wa_extension-valuepart2.
        MODIFY c_accit FROM wa_accit INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
*{   INSERT         DESK9A0IMI                                        1
* Issues Details: Assigning the trading document numbers of SD internal invoice
*                 and FI purchase invoice to field XREF1_HD and XREF2_HD
    DATA(extension_helper) = NEW /dmbe/cli_extension_in_helper( ).
    LOOP AT c_extension2 REFERENCE INTO DATA(ext2)
        WHERE structure = 'TS_ACC_DOC_EXT_FI'.

      DATA(container) = extension_helper->read_container( ext2->* ).
      DATA(acc_doc_ext_fi) = CONV zcl_fi_trading_reclass=>ts_acc_doc_ext_fi( container->* ).

      TRY.
          DATA(accit) = REF #( c_accit[ posnr = acc_doc_ext_fi-itemno ] ).
          accit->xref1_hd = acc_doc_ext_fi-xref1_hd.
          accit->xref2_hd = acc_doc_ext_fi-xref2_hd.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
    ENDLOOP.
*}   INSERT         DESK9A0IMI                                        1
  ENDMETHOD.


  METHOD if_ex_acc_document~fill_accit.
  ENDMETHOD.
ENDCLASS.

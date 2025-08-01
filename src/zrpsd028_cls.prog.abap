*&---------------------------------------------------------------------*
*& Include          ZRPSD028_CLS
*&---------------------------------------------------------------------*
CLASS lcl_report DEFINITION
  FINAL CREATE PRIVATE.

  PUBLIC SECTION.
    CLASS-METHODS create
      RETURNING VALUE(result) TYPE REF TO lcl_report.

    METHODS create_report.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ts_tradingackrcptgireport,
        billingdocument                TYPE zcds_i_tradingackrcptgireport-billingdocument,
        companycode                    TYPE zcds_i_tradingackrcptgireport-companycode,
        billingdocumentdate            TYPE zcds_i_tradingackrcptgireport-billingdocumentdate,
        documentreferenceid            TYPE zcds_i_tradingackrcptgireport-documentreferenceid,
        quantityoutbounddeliverytype   TYPE mm_a_numberofdeliveries,
        actualgoodsmovementdate        TYPE zcds_i_tradingackrcptgireport-actualgoodsmovementdate,
        soldtoparty                    TYPE zcds_i_tradingackrcptgireport-soldtoparty,
        soldtopartyfullname            TYPE zcds_i_tradingackrcptgireport-soldtopartyfullname,
        shiptoparty                    TYPE zcds_i_tradingackrcptgireport-shiptoparty,
        shiptopartyfullname            TYPE zcds_i_tradingackrcptgireport-shiptopartyfullname,
        intercompanybillingcustomer    TYPE zcds_i_tradingackrcptgireport-intercompanybillingcustomer,
        salesorgforintcobilling        TYPE zcds_i_tradingackrcptgireport-salesorgforintcobilling,
        purchaseaccdocumentledger      TYPE zcds_i_tradingackrcptgireport-purchaseaccdocumentledger,
        purchaseaccdocumentcompanycode TYPE zcds_i_tradingackrcptgireport-purchaseaccdocumentcompanycode,
        purchaseaccountingdocument     TYPE zcds_i_tradingackrcptgireport-purchaseaccountingdocument,
        purchaseaccdocumentfiscalyear  TYPE zcds_i_tradingackrcptgireport-purchaseaccdocumentfiscalyear,
        ackreceiptgoodsissueledger     TYPE zcds_i_tradingackrcptgireport-ackreceiptgoodsissueledger,
        ackreceiptgicompanycode        TYPE zcds_i_tradingackrcptgireport-ackreceiptgicompanycode,
        ackreceiptgiaccountingdocument TYPE zcds_i_tradingackrcptgireport-ackreceiptgiaccountingdocument,
        ackreceiptgoodsissuefiscalyear TYPE zcds_i_tradingackrcptgireport-ackreceiptgoodsissuefiscalyear,
        cancelackreceiptgidocument     TYPE fis_stblg,
        cancelackreceiptgidocumentfy   TYPE fis_stjah,
      END OF ts_tradingackrcptgireport.

    TYPES tt_tradingackrcptgireport     TYPE STANDARD TABLE OF ts_tradingackrcptgireport WITH EMPTY KEY.
    TYPES ts_ref_tradingackrcptgireport TYPE REF TO ts_tradingackrcptgireport.
    TYPES tt_ref_tradingackrcptgireport TYPE STANDARD TABLE OF ts_ref_tradingackrcptgireport WITH EMPTY KEY.

    TYPES:
      BEGIN OF ts_reportlog,
        billingdocument TYPE zcds_i_tradingackrcptgireport-BillingDocument.
        INCLUDE TYPE bal_s_msg AS bal_log_msg.
    TYPES:
      END OF ts_reportlog.

    TYPES tt_reportlog TYPE STANDARD TABLE OF ts_reportlog WITH EMPTY KEY.

    DATA contents       TYPE tt_tradingackrcptgireport.
    DATA deliveries     TYPE STANDARD TABLE OF vbeln_vl.
    DATA profit_centers TYPE STANDARD TABLE OF ztbsd_cebe WITH EMPTY KEY.
    DATA documentlog    TYPE tt_reportlog.
    DATA pgi_status     TYPE xsdboolean.
    DATA mo_report      TYPE REF TO cl_salv_table.
    DATA postingdate    TYPE bapiache09-pstng_date.
    DATA ack_status     TYPE uvk01.
    DATA dummy_message  TYPE string.
    DATA gl_account_1   TYPE bapiacgl09-gl_account.
    DATA gl_account_2   TYPE bapiacgl09-gl_account.

    CONSTANTS document_type_sm TYPE blart VALUE 'WA'.

    METHODS constructor.

    METHODS cancel_goods_issue_document
      CHANGING document TYPE REF TO lcl_report=>ts_tradingackrcptgireport.

    METHODS lock_deliveries
      IMPORTING document TYPE REF TO lcl_report=>ts_tradingackrcptgireport
      RAISING   zcx_trading.

    METHODS update_ack_receipt_field
      IMPORTING document TYPE REF TO lcl_report=>ts_tradingackrcptgireport.

    METHODS create_goods_issue_document
      CHANGING document TYPE REF TO lcl_report=>ts_tradingackrcptgireport.

    METHODS read_data
      RAISING zcx_trading.

    METHODS set_columns.
    METHODS set_functions.
    METHODS set_layout.
    METHODS set_selection.
    METHODS set_events.
    METHODS display.

    METHODS on_link_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

    METHODS read_content
      IMPORTING sel_row       TYPE syst_curow OPTIONAL
      RETURNING VALUE(result) TYPE tt_ref_tradingackrcptgireport
      RAISING   zcx_trading.
*
    METHODS is_selected_rows
      IMPORTING max_one      TYPE abap_bool OPTIONAL
      RETURNING VALUE(value) TYPE abap_bool.

    METHODS read_selected_rows
      RETURNING VALUE(value) TYPE salv_t_row.
*
    METHODS post_goods_issue.
*
    METHODS commit_work_and_wait.
*
    METHODS cancel_goods_issue.
*
    METHODS add_message
      IMPORTING !message TYPE ts_reportlog.

    METHODS add_system_message
      IMPORTING !key         TYPE zcds_i_tradingackrcptgireport-BillingDocument
                detail_level TYPE ballevel OPTIONAL.

    METHODS has_user_entered_posting_date
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS read_settings
      RAISING zcx_trading.

    METHODS progress_indicator
      IMPORTING !text     TYPE any
                processed TYPE sy-tabix
                !total    TYPE sy-tabix.

    METHODS exception_to_message
      IMPORTING !exception    TYPE REF TO cx_root
                msgtype       TYPE symsgty OPTIONAL
      RETURNING VALUE(result) TYPE rs_t_msg.

    METHODS add_table_messages
      IMPORTING !key         TYPE zcds_i_tradingackrcptgireport-BillingDocument
                detail_level TYPE detail_level OPTIONAL
                !messages    TYPE rs_t_msg.

    METHODS add_table_bapiret2_messages
      IMPORTING !key         TYPE zcds_i_tradingackrcptgireport-BillingDocument
                detail_level TYPE detail_level OPTIONAL
                !messages    TYPE bapiret2_tab.

    METHODS initialize_log.
    METHODS read_log.

    METHODS read_logical_system
      RETURNING VALUE(result) TYPE tbdls-logsys.

    METHODS display_log
      RAISING cx_adt_res_seg_param_not_found.
ENDCLASS.


CLASS lcl_report IMPLEMENTATION.
  METHOD create.
    result = NEW #( ).
  ENDMETHOD.

  METHOD constructor.
    pgi_status = xsdbool( canc_doc IS NOT INITIAL ).
    ack_status = SWITCH #( canc_doc WHEN abap_true THEN 'A' ELSE 'C' ).

    SELECT FROM ztbsd_cebe
      FIELDS *
      INTO TABLE @profit_centers.
  ENDMETHOD.

  METHOD create_report.
    TRY.
        read_data( ).

        cl_salv_table=>factory( IMPORTING r_salv_table = mo_report
                                CHANGING  t_table      = contents ).

        set_columns( ).
        set_functions( ).
        set_layout( ).
        set_selection( ).
        set_events( ).
        display( ).

      CATCH cx_salv_msg.
      CATCH zcx_trading INTO DATA(excp).
        MESSAGE excp->get_text( ) TYPE excp->msgty.
    ENDTRY.
  ENDMETHOD.

  METHOD read_data.
    SELECT FROM zcds_i_tradingackrcptgireport
      FIELDS billingdocument,
             companycode,
             billingdocumentdate,
             documentreferenceid,
             COUNT( DISTINCT outbounddelivery ) AS quantityoutbounddelivery,
             actualgoodsmovementdate,
             soldtoparty,
             soldtopartyfullname,
             shiptoparty,
             shiptopartyfullname,
             intercompanybillingcustomer,
             salesorgforintcobilling,
             purchaseaccdocumentledger,
             purchaseaccdocumentcompanycode,
             purchaseaccountingdocument,
             purchaseaccdocumentfiscalyear,
             ackreceiptgoodsissueledger,
             ackreceiptgicompanycode,
             ackreceiptgiaccountingdocument,
             ackreceiptgoodsissuefiscalyear
      WHERE billingdocument           IN @icinvoic
    AND outbounddelivery          IN @delivnum
        AND documentreferenceid       IN @extnum
        AND actualgoodsmovementdate   IN @smdate
        AND ackreceiptgoodsissueexist  = @pgi_status
      GROUP BY billingdocument,
               companycode,
               billingdocumentdate,
               documentreferenceid,
               actualgoodsmovementdate,
               soldtoparty,
               soldtopartyfullname,
               shiptoparty,
               shiptopartyfullname,
               intercompanybillingcustomer,
               salesorgforintcobilling,
               purchaseaccdocumentledger,
               purchaseaccdocumentcompanycode,
               purchaseaccountingdocument,
               purchaseaccdocumentfiscalyear,
               ackreceiptgoodsissueledger,
               ackreceiptgicompanycode,
               ackreceiptgiaccountingdocument,
               ackreceiptgoodsissuefiscalyear
      INTO TABLE @contents.
    IF sy-subrc IS INITIAL.
      MESSAGE s023 WITH sy-dbcnt.
    ELSE.
      RAISE EXCEPTION TYPE zcx_trading
            MESSAGE s490(vr).
    ENDIF.
  ENDMETHOD.

  METHOD set_columns.
    DATA o_columns TYPE REF TO cl_salv_columns_table.
    DATA o_column  TYPE REF TO cl_salv_column_table.

    TRY.
        o_columns = mo_report->get_columns( ).

        " Hotspot
        o_column ?= o_columns->get_column( 'BILLINGDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'PURCHASEACCOUNTINGDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'ACKRECEIPTGIACCOUNTINGDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'CANCELACKRECEIPTGIDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        " Custom texts
        o_column ?= o_columns->get_column( 'BILLINGDOCUMENT' ).
        o_column->set_short_text( CONV #( TEXT-c01 ) ).
        o_column->set_medium_text( CONV #( TEXT-c02 ) ).
        o_column->set_long_text( CONV #( TEXT-c01 )  ).
        o_column->set_tooltip( CONV #( TEXT-c01 )  ).

        o_column ?= o_columns->get_column( 'PURCHASEACCOUNTINGDOCUMENT' ).
        o_column->set_short_text( CONV #( TEXT-c03 ) ).
        o_column->set_medium_text( CONV #( TEXT-c04 ) ).
        o_column->set_long_text( CONV #( TEXT-c03 )  ).
        o_column->set_tooltip( CONV #( TEXT-c03 )  ).

        o_column ?= o_columns->get_column( 'ACKRECEIPTGIACCOUNTINGDOCUMENT' ).
        o_column->set_short_text( CONV #( TEXT-c05 ) ).
        o_column->set_medium_text( CONV #( TEXT-c06 ) ).
        o_column->set_long_text( CONV #( TEXT-c05 )  ).
        o_column->set_tooltip( CONV #( TEXT-c05 )  ).

        o_column ?= o_columns->get_column( 'CANCELACKRECEIPTGIDOCUMENT' ).
        o_column->set_short_text( CONV #( TEXT-c07 ) ).
        o_column->set_medium_text( CONV #( TEXT-c08 ) ).
        o_column->set_long_text( CONV #( TEXT-c07 ) ).
        o_column->set_tooltip( CONV #( TEXT-c07 ) ).

        " Hidden columns (Visible)
        o_column ?= o_columns->get_column( 'PURCHASEACCDOCUMENTLEDGER' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'ACKRECEIPTGOODSISSUELEDGER' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'CANCELACKRECEIPTGIDOCUMENTFY' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'SALESORGFORINTCOBILLING' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).

        o_columns->set_optimize( if_salv_c_bool_sap=>true ).
      CATCH cx_salv_msg
            cx_salv_not_found
            cx_salv_data_error ##NO_HANDLER.

    ENDTRY.
  ENDMETHOD.

  METHOD set_functions.
    TRY.
        mo_report->set_screen_status( pfstatus      = 'SALV_STANDARD'
                                      report        = sy-repid
                                      set_functions = mo_report->c_functions_all ).

        LOOP AT mo_report->get_functions( )->get_functions( ) INTO DATA(function_list).
        IF function_list-r_function->get_name( ) = CONV string( SWITCH #( canc_doc
                                                                            WHEN abap_true
                                                                            THEN '&CFM_AOR'
                                                                            ELSE '&CANC_AOR' ) ).
            function_list-r_function->set_visible( ' ' ).
          ENDIF.
        ENDLOOP.

      CATCH cx_salv_wrong_call
            cx_salv_existing ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD set_layout.
    DATA(key) = VALUE salv_s_layout_key( report = sy-repid ).
    DATA(layout) = mo_report->get_layout( ).

    layout->set_key( key ).
    layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
    layout->set_initial_layout( 'DEFAULT' ).

    mo_report->get_display_settings( )->set_striped_pattern( abap_true ).
  ENDMETHOD.

  METHOD set_selection.
    mo_report->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).
  ENDMETHOD.

  METHOD set_events.
    DATA(o_events) = mo_report->get_event( ).
    SET HANDLER me->on_link_click   FOR o_events.
    SET HANDLER me->on_user_command FOR o_events.
  ENDMETHOD.

  METHOD display.
    mo_report->display( ).
  ENDMETHOD.
*
  METHOD on_link_click.
    DATA(content) = REF #( contents[ row ] ).
    ASSIGN COMPONENT column OF STRUCTURE content->* TO FIELD-SYMBOL(<value>).
    IF <value> IS INITIAL.
      RETURN.
    ELSE.
      UNASSIGN <value>.
    ENDIF.

    CASE column.
      WHEN 'BILLINGDOCUMENT'.
        SET PARAMETER ID 'VF' FIELD content->billingdocument.
        CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
      WHEN 'PURCHASEACCOUNTINGDOCUMENT'.
        SET PARAMETER ID 'BLN' FIELD content->purchaseaccountingdocument.
        SET PARAMETER ID 'BUK' FIELD content->purchaseaccdocumentcompanycode.
        SET PARAMETER ID 'GJR' FIELD content->purchaseaccdocumentfiscalyear.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
      WHEN 'ACKRECEIPTGIACCOUNTINGDOCUMENT'.
        SET PARAMETER ID 'BLN' FIELD content->ackreceiptgiaccountingdocument.
        SET PARAMETER ID 'BUK' FIELD content->ackreceiptgicompanycode.
        SET PARAMETER ID 'GJR' FIELD content->ackreceiptgoodsissuefiscalyear.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
      WHEN 'CANCELACKRECEIPTGIDOCUMENT'.
        SET PARAMETER ID 'BLN' FIELD content->cancelackreceiptgidocument.
        SET PARAMETER ID 'BUK' FIELD content->ackreceiptgicompanycode.
        SET PARAMETER ID 'GJR' FIELD content->cancelackreceiptgidocumentfy.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
    ENDCASE.
  ENDMETHOD.
*
  METHOD on_user_command.
    CASE e_salv_function.
      WHEN '&CFM_AOR'.
        post_goods_issue( ).
      WHEN '&CANC_AOR'.
        cancel_goods_issue( ).
      WHEN '&LOG'.
        TRY.
            display_log( ).
          CATCH cx_adt_res_seg_param_not_found.
            " handle exception
        ENDTRY.
    ENDCASE.
  ENDMETHOD.

  METHOD is_selected_rows.
    mo_report->get_metadata( ).
    value = COND #( WHEN max_one = abap_true
                    THEN xsdbool( lines( mo_report->get_selections( )->get_selected_rows( ) ) = 1 )
                    ELSE xsdbool( mo_report->get_selections( )->get_selected_rows( ) ) ).
  ENDMETHOD.

  METHOD read_selected_rows.
    mo_report->get_metadata( ).
    value = mo_report->get_selections( )->get_selected_rows( ).
  ENDMETHOD.

  METHOD read_content.
    DATA(selected_rows) = COND salv_t_row( LET message = VALUE scx_t100key( msgid = 'VB'
                                                                            msgno = '609' ) IN
                                           WHEN sel_row > 0         THEN VALUE #( ( sel_row ) )
                                           WHEN is_selected_rows( ) THEN read_selected_rows( )
                                           ELSE                          THROW zcx_trading( textid = message ) ).

    LOOP AT selected_rows INTO DATA(row).
      DATA(document) = REF #( me->contents[ row ] ).

      SELECT FROM zcds_i_tradingackrcptgireport
        FIELDS billingdocument,
               ackreceiptgoodsissueledger,
               ackreceiptgicompanycode,
               ackreceiptgiaccountingdocument,
               ackreceiptgoodsissuefiscalyear,
               ackreceiptgoodsissueexist
        WHERE billingdocument = @document->billingdocument
        INTO TABLE @DATA(pgi_documents).
      IF sy-subrc IS NOT INITIAL.
        MESSAGE e076 INTO dummy_message.
        add_system_message( key          = document->billingdocument
                            detail_level = '2' ).
        CONTINUE.
      ENDIF.

      CASE pgi_status.
        WHEN abap_true.
          IF document->cancelackreceiptgidocument IS NOT INITIAL.
            MESSAGE e082 INTO dummy_message.
            add_system_message( key          = document->billingdocument
                                detail_level = '2' ).
            CONTINUE.
          ENDIF.

          IF NOT line_exists( pgi_documents[
                                  ackreceiptgiaccountingdocument = document->ackreceiptgiaccountingdocument ] ).
            SELECT SINGLE FROM I_JournalEntry
              FIELDS ReverseDocument,
                     ReverseDocumentFiscalYear
              WHERE CompanyCode        = @document->ackreceiptgicompanycode
                AND FiscalYear         = @document->ackreceiptgoodsissuefiscalyear
                AND AccountingDocument = @document->ackreceiptgiaccountingdocument
              INTO ( @document->cancelackreceiptgidocument,
                     @document->cancelackreceiptgidocumentfy ).

            MESSAGE e077 INTO dummy_message
                    WITH document->ackreceiptgiaccountingdocument
                         document->ackreceiptgicompanycode
                         document->ackreceiptgoodsissuefiscalyear
                         |{ document->cancelackreceiptgidocument } { document->cancelackreceiptgidocumentfy }|.

            add_system_message( key          = document->billingdocument
                                detail_level = '2' ).
            CONTINUE.
          ENDIF.
        WHEN abap_false.
          IF document->ackreceiptgiaccountingdocument IS NOT INITIAL.
            MESSAGE e082 INTO dummy_message.
            add_system_message( key          = document->billingdocument
                                detail_level = '2' ).
            CONTINUE.
          ENDIF.

          TRY.
              DATA(pgi_document) = pgi_documents[ ackreceiptgoodsissueexist = abap_true ].
              document->* = VALUE #( BASE document->*
                                     ackreceiptgoodsissueledger     = pgi_document-ackreceiptgoodsissueledger
                                     ackreceiptgicompanycode        = pgi_document-ackreceiptgicompanycode
                                     ackreceiptgiaccountingdocument = pgi_document-ackreceiptgiaccountingdocument
                                     ackreceiptgoodsissuefiscalyear = pgi_document-ackreceiptgoodsissuefiscalyear ).

              MESSAGE e078 INTO dummy_message
                      WITH document->ackreceiptgiaccountingdocument
                           document->ackreceiptgicompanycode
                           document->ackreceiptgoodsissuefiscalyear.

              add_system_message( key          = document->billingdocument
                                  detail_level = '2' ).
              CONTINUE.
            CATCH cx_sy_itab_line_not_found.
          ENDTRY.
      ENDCASE.

      APPEND document TO result.
    ENDLOOP.
  ENDMETHOD.
*
  METHOD post_goods_issue.
    IF NOT has_user_entered_posting_date( ).
      RETURN.
    ENDIF.

    TRY.
        read_settings( ).
        initialize_log( ).

        DATA(documents) = read_content( ).
        DATA(total_lines) = lines( documents ).
        LOOP AT documents INTO DATA(document).
          progress_indicator( text      = TEXT-t01
                              processed = sy-tabix
                              total     = total_lines ).

          create_goods_issue_document( CHANGING document = document ).
        ENDLOOP.
      CATCH zcx_trading INTO DATA(excp).
        MESSAGE excp->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

    mo_report->refresh( ).
  ENDMETHOD.
*
  METHOD create_goods_issue_document.
    DATA obj_key TYPE bapiache09-obj_key.
    DATA return  TYPE bapiret2_tab.

    TRY.
        lock_deliveries( document ).
      CATCH zcx_trading INTO DATA(excp).
        add_table_messages( key          = document->billingdocument
                            detail_level = '2'
                            messages     = exception_to_message( exception = excp ) ).
        RETURN.
    ENDTRY.

    SELECT FROM I_JournalEntryItem
      FIELDS *
      WHERE SourceLedger       = @document->purchaseaccdocumentledger
        AND CompanyCode        = @document->purchaseaccdocumentcompanycode
        AND FiscalYear         = @document->purchaseaccdocumentfiscalyear
        AND AccountingDocument = @document->purchaseaccountingdocument
      INTO TABLE @DATA(purchaseaccdocumentitems).

    DATA(documentheader) =
        VALUE bapiache09( obj_type   = 'BKPFF'
                          doc_date   = postingdate
                          doc_type   = document_type_sm
                          comp_code  = document->purchaseaccdocumentcompanycode
                          pstng_date = postingdate
                          ref_doc_no = document->purchaseaccountingdocument
                          header_txt = 'STOCK DECREASE'
                          username   = sy-uname ).

    DATA(accountgl) =
        VALUE bapiacgl09_tab(
                FOR item IN purchaseaccdocumentitems
            LET gl_account = SWITCH hkont( item-FinancialAccountType
                                           WHEN 'S' THEN me->gl_account_1
                                           WHEN 'K' THEN me->gl_account_2 )
                profit_ctr = SWITCH prctr( item-FinancialAccountType
                                           WHEN 'S'
                                           THEN profit_centers[ vkoiv = document->salesorgforintcobilling ]-profit_ctr
                                           ELSE space )
            IN  ( itemno_acc = CONV i( item-LedgerGLLineItem )
                  gl_account = gl_account
                  item_text  = item-DocumentItemText
                  material   = item-Material
                  quantity   = item-Quantity
                  base_uom   = item-BaseUnit
                  alloc_nmbr = item-AssignmentReference
                  profit_ctr = profit_ctr
                  sales_ord  = item-SalesDocument
                  s_ord_item = item-SalesDocumentItem ) ).

    DATA(currencyamount) =
       VALUE bapiaccr09_tab( FOR item IN purchaseaccdocumentitems
                             ( itemno_acc = CONV i( item-LedgerGLLineItem )
                               currency   = item-TransactionCurrency
                               amt_doccur = item-AmountInTransactionCurrency ) ).

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING documentheader = documentheader
      IMPORTING obj_key        = obj_key
      TABLES    accountgl      = accountgl
                currencyamount = currencyamount
                return         = return.

    add_table_bapiret2_messages( key          = document->billingdocument
                                 detail_level = '2'
                                 messages     = return ).

    IF line_exists( return[ type = 'E' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RETURN.
    ELSE.
      document->ackreceiptgoodsissueledger     = document->purchaseaccdocumentledger.
      document->ackreceiptgicompanycode        = obj_key+10(4).
      document->ackreceiptgiaccountingdocument = obj_key+0(10).
      document->ackreceiptgoodsissuefiscalyear = obj_key+14(4).

      update_ack_receipt_field( document ).
      commit_work_and_wait( ).
    ENDIF.
  ENDMETHOD.

  METHOD commit_work_and_wait.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = abap_true.
  ENDMETHOD.

  METHOD update_ack_receipt_field.
*     TODO: parameter DOCUMENT is never used (ABAP cleaner)

    LOOP AT deliveries INTO DATA(delivery).
      UPDATE likp SET uvk01 = @ack_status
                WHERE vbeln = @delivery.

      CALL FUNCTION 'DEQUEUE_EVVBLKE'
        EXPORTING vbeln = delivery.
    ENDLOOP.

    CLEAR deliveries.
  ENDMETHOD.
*
  METHOD lock_deliveries.
    DATA enqueue_details   TYPE tty_sm12_locks.
    DATA user_name_in_lock TYPE eqeuname.

    SELECT FROM zcds_i_tradingackrcptgireport
      FIELDS DISTINCT OutboundDelivery
      WHERE BillingDocument = @document->billingdocument
      INTO TABLE @deliveries.

    LOOP AT deliveries INTO DATA(chk_deliv).
      CLEAR enqueue_details.
      CLEAR user_name_in_lock.

      CALL FUNCTION 'ENQUEUE_READ'
        EXPORTING  gclient               = sy-mandt
                   gname                 = 'LIKP'
                   garg                  = CONV seqg3-garg( sy-mandt && chk_deliv )
                   guname                = CONV sy-uname( space )
        TABLES     enq                   = enqueue_details
        EXCEPTIONS communication_failure = 1
                   system_failure        = 2
                   OTHERS                = 3.
      IF sy-subrc IS INITIAL.
        TRY.
            user_name_in_lock = enqueue_details[ 1 ]-guname.
            RAISE EXCEPTION TYPE zcx_trading
                  MESSAGE e046(vl) WITH user_name_in_lock chk_deliv.
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.
      ENDIF.
    ENDLOOP.

    LOOP AT deliveries INTO DATA(delivery).
      CALL FUNCTION 'ENQUEUE_EVVBLKE'
        EXPORTING  vbeln          = delivery
        EXCEPTIONS foreign_lock   = 1
                   system_failure = 2
                   OTHERS         = 3.
      IF sy-subrc IS INITIAL.
        " do something
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
*
  METHOD cancel_goods_issue.
    TRY.
        initialize_log( ).

        DATA(documents) = read_content( ).
        DATA(total_lines) = lines( documents ).
        LOOP AT documents INTO DATA(document).
          progress_indicator( text      = TEXT-t01
                              processed = sy-tabix
                              total     = total_lines ).

          cancel_goods_issue_document( CHANGING document = document ).
        ENDLOOP.
      CATCH zcx_trading INTO DATA(excp).
        MESSAGE excp->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
    ENDTRY.

    mo_report->refresh( ).
  ENDMETHOD.

  METHOD cancel_goods_issue_document.
    DATA obj_key TYPE bapiacrev-obj_key.
    DATA return  TYPE bapiret2_tab.

    TRY.
        lock_deliveries( document ).
      CATCH zcx_trading INTO DATA(excp).
        add_table_messages( key          = document->billingdocument
                            detail_level = '2'
                            messages     = exception_to_message( exception = excp ) ).
        RETURN.
    ENDTRY.

    DATA(reversal) = VALUE bapiacrev(
        obj_type   = 'BKPFF'
        obj_sys    = read_logical_system( )
        reason_rev = '01'
        obj_key    = document->ackreceiptgiaccountingdocument && document->ackreceiptgicompanycode && document->ackreceiptgoodsissuefiscalyear
        obj_key_r  = document->ackreceiptgiaccountingdocument && document->ackreceiptgicompanycode && document->ackreceiptgoodsissuefiscalyear ).

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_REV_POST'
      EXPORTING reversal = reversal
                bus_act  = 'RFBU'
      IMPORTING obj_key  = obj_key
      TABLES    return   = return.

    add_table_bapiret2_messages( key          = document->billingdocument
                                 detail_level = '2'
                                 messages     = return ).

    IF line_exists( return[ type = 'E' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      RETURN.
    ELSE.
      document->cancelackreceiptgidocument   = obj_key+0(10).
      document->cancelackreceiptgidocumentfy = obj_key+14(4).

      update_ack_receipt_field( document ).
      commit_work_and_wait( ).
    ENDIF.
  ENDMETHOD.

  METHOD add_system_message.
    add_message( message = VALUE #( billingdocument = key
                                    msgty           = sy-msgty
                                    msgid           = sy-msgid
                                    msgno           = sy-msgno
                                    msgv1           = sy-msgv1
                                    msgv2           = sy-msgv2
                                    msgv3           = sy-msgv3
                                    msgv4           = sy-msgv4
                                    detlevel        = detail_level ) ).
  ENDMETHOD.

  METHOD add_table_messages.
    LOOP AT messages INTO DATA(message).
      message-detlevel = detail_level.
      add_message( message = VALUE #( billingdocument = key
                                      bal_log_msg     = message ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_table_bapiret2_messages.
    LOOP AT messages INTO DATA(message).
      add_message( message = VALUE #( billingdocument = key
                                      msgty           = message-type
                                      msgid           = message-id
                                      msgno           = message-number
                                      msgv1           = message-message_v1
                                      msgv2           = message-message_v2
                                      msgv3           = message-message_v3
                                      msgv4           = message-message_v4
                                      detlevel        = detail_level ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_message.
    INSERT message INTO TABLE documentlog.
  ENDMETHOD.

  METHOD has_user_entered_posting_date.
    DATA valueresult TYPE char1.
    DATA values      TYPE STANDARD TABLE OF sval.

    values = VALUE #( ( tabname   = 'BAPIACHE09'
                        fieldname = 'PSTNG_DATE'
                        field_obl = abap_true ) ).

    CALL FUNCTION 'POPUP_GET_VALUES'
      EXPORTING popup_title = TEXT-f01
      IMPORTING returncode  = valueresult
      TABLES    fields      = values.

    postingdate = VALUE #( values[ 1 ]-value OPTIONAL ).

    result = xsdbool( valueresult = space ).
  ENDMETHOD.

  METHOD read_settings.
    SELECT SINGLE valor FROM ztxx_hardcodes
      WHERE repid = @sy-repid
        AND tipoc = 'GL_ACCOUNT'
        AND nivel = '00001'
        AND secue = '00001'
      INTO @gl_account_1.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_trading
            MESSAGE e079.
    ENDIF.

    SELECT SINGLE valor FROM ztxx_hardcodes
      WHERE repid = @sy-repid
        AND tipoc = 'GL_ACCOUNT'
        AND nivel = '00001'
        AND secue = '00002'
      INTO @gl_account_2.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_trading
            MESSAGE e079.
    ENDIF.
  ENDMETHOD.

  METHOD progress_indicator.
    cl_progress_indicator=>progress_indicate( i_text               = text
                                              i_processed          = processed
                                              i_total              = total
                                              i_output_immediately = abap_true ).
  ENDMETHOD.

  METHOD exception_to_message.
    CALL FUNCTION 'RS_EXCEPTION_TO_MESSAGE'
      EXPORTING i_r_exception = exception
                i_msgty       = msgtype
      CHANGING  c_t_msg       = result.
  ENDMETHOD.

  METHOD initialize_log.
    CLEAR documentlog.
  ENDMETHOD.

  METHOD read_log.
  ENDMETHOD.

  METHOD read_logical_system.
    CALL FUNCTION 'OWN_LOGICAL_SYSTEM_GET'
      IMPORTING  own_logical_system             = result
      EXCEPTIONS own_logical_system_not_defined = 1
                 OTHERS                         = 2.
  ENDMETHOD.

  METHOD display_log.
    DATA(log_appl) = NEW zcl_application_log( ).

    IF documentlog IS INITIAL.
      MESSAGE s081 DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    log_appl->open( EXPORTING  log_object    = 'RSR_REPORT_CHECK'
                               max_probclass = '4'
                    EXCEPTIONS logging_error = 1 ).
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_adt_res_seg_param_not_found(
                              textid = cx_scwn_ds_failed_verification=>get_t100_message( ) ).
    ENDIF.

    LOOP AT documentlog REFERENCE INTO DATA(log_grp)
         GROUP BY log_grp->billingdocument.

      MESSAGE s080 INTO dummy_message
              WITH log_grp->billingdocument.
      log_appl->add_system_message( '1' ).

      LOOP AT GROUP log_grp REFERENCE INTO DATA(document_log).
        log_appl->add_message_struct( EXPORTING  log_message   = document_log->bal_log_msg
                                      EXCEPTIONS logging_error = 1 ).
        IF sy-subrc IS NOT INITIAL.
          RAISE EXCEPTION NEW cx_adt_res_seg_param_not_found(
                                  textid = cx_scwn_ds_failed_verification=>get_t100_message( ) ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    log_appl->display_detlevel( modal = abap_true ).
  ENDMETHOD.
ENDCLASS.

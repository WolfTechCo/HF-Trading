CLASS zcl_fi_trading_reclass DEFINITION
  PUBLIC FINAL
  CREATE PRIVATE.

  PUBLIC SECTION.
    TYPES:
      BEGIN OF ts_acc_doc_ext_fi,
        itemno   TYPE posnr_acc,
        xref1_hd TYPE xref1_hd,
        xref2_hd TYPE xref2_hd,
      END OF ts_acc_doc_ext_fi.

    TYPES ty_call_screen_stack TYPE zst99_call_screen_stack.
    TYPES tt_call_screen_stack TYPE STANDARD TABLE OF ty_call_screen_stack
                               WITH NON-UNIQUE KEY event prog screen subscreen.

    TYPES:
      BEGIN OF ENUM document_category_trading
        STRUCTURE doccattrading
        BASE TYPE zde_document_type_trading,

        configuration           VALUE IS INITIAL,
        salesorderorigin        VALUE '-',
        purchasecreditdebitmemo VALUE '1',
        settlementinvoice       VALUE '2',
        purchaserequisition     VALUE 'B',
        salesorder              VALUE 'C',
        purchaseorder           VALUE 'F',
        sdinvoice               VALUE 'M',
        creditnote              VALUE 'O',
        incominginvoice         VALUE 'R',
      END OF ENUM document_category_trading STRUCTURE doccattrading.

    CONSTANTS:
      BEGIN OF status_trading_prcs,
        unprocessed          TYPE zde_status_trading_process VALUE 'N',
        processed            TYPE zde_status_trading_process VALUE 'P',
        partially_processed  TYPE zde_status_trading_process VALUE 'I',
        error_processing     TYPE zde_status_trading_process VALUE 'F',
        cancelled            TYPE zde_status_trading_process VALUE 'C',
        cancelallation_error TYPE zde_status_trading_process VALUE 'D',
        error                TYPE zde_status_trading_process VALUE 'E',
      END OF status_trading_prcs.

    CLASS-DATA mo_instance TYPE REF TO zcl_fi_trading_reclass.
    CLASS-DATA offline     TYPE /pm0/abd_offline_fg.

    CLASS-METHODS get_instance
      IMPORTING batchmode       TYPE sap_bool DEFAULT abap_false
      RETURNING VALUE(instance) TYPE REF TO zcl_fi_trading_reclass.

    METHODS default_view
      IMPORTING !dynpro  TYPE syst_dynnr
                prog     TYPE syst_cprog
                pfstatus TYPE pfstatus
                !title   TYPE gui_title.

    METHODS file_open_dialog
      IMPORTING default_extension TYPE string         DEFAULT '*.CSV'
                default_filename  TYPE string         DEFAULT space
                file_filter       TYPE string         DEFAULT '*.CSV'
                fieldname         TYPE rsselread-name DEFAULT space
                save_param        TYPE sap_bool       DEFAULT abap_false
      RETURNING VALUE(filename)   TYPE rlgrap-filename
      RAISING   cx_cts_eps_io_exception.

    METHODS handle_event
      IMPORTING !event TYPE syst_ucomm.

    METHODS is_offline
      RETURNING VALUE(value) TYPE sap_bool.

    METHODS read_view
      RETURNING VALUE(result) TYPE ty_call_screen_stack.

    METHODS send.

    METHODS set_file_parameters
      IMPORTING ul_filename TYPE string
                with_header TYPE sap_bool DEFAULT abap_true.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_headername_file,
        field TYPE char50,
      END OF ty_headername_file.
    TYPES tt_headername_file TYPE STANDARD TABLE OF ty_headername_file WITH EMPTY KEY.
    TYPES tt_process_log     TYPE STANDARD TABLE OF zst_trading_log WITH EMPTY KEY.
    TYPES tt_rsdynnr         TYPE STANDARD TABLE OF rsdynnr WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_status_trading_prcs_icon,
        status TYPE zde_status_trading_process,
        icon   TYPE icon_d,
      END OF ty_status_trading_prcs_icon.
    TYPES tt_status_trading_prcs_icon TYPE SORTED TABLE OF ty_status_trading_prcs_icon WITH UNIQUE KEY status.
    TYPES:
      BEGIN OF ts_document_settings,
        purchase_accounting_document TYPE ztbfi_trdrecl_po,
      END OF ts_document_settings.
    TYPES:
      BEGIN OF ts_search_documents_parameters,
        docuuid  TYPE RANGE OF ztbfi_trd_reclas-documentuuid,
        ccode    TYPE RANGE OF ztbfi_trd_reclas-companycode,
        accdoc   TYPE RANGE OF ztbfi_trd_reclas-accountingdocument,
        fyear    TYPE RANGE OF ztbfi_trd_reclas-fiscalyear,
        status   TYPE RANGE OF ztbfi_trd_reclas-documentstatus,
        sorder   TYPE RANGE OF ztbfi_trd_reclas-salesdocument,
        billdoc  TYPE RANGE OF ztbfi_trd_reclas-billingdocument,
        docrefid TYPE RANGE OF ztbfi_trd_reclas-documentreferenceid,
        cnt      TYPE RANGE OF zcds_i_tradingreclassreport-container,
        postdate TYPE RANGE OF ztbfi_trd_reclas-to_postingdate,
        createat TYPE RANGE OF ztbfi_trd_reclas-createdatdate,
        modifat  TYPE RANGE OF ztbfi_trd_reclas-lastchangedate,
        ccodest  TYPE RANGE OF ztbfi_trd_reclas-companycodesettlement,
        accdocst TYPE RANGE OF ztbfi_trd_reclas-accountingdocumentsettlement,
        fyearst  TYPE RANGE OF ztbfi_trd_reclas-fiscalyearsettlement,
      END OF ts_search_documents_parameters.
    TYPES:
      BEGIN OF ty_default_view,
        dynpro   TYPE syst_dynnr,
        prog     TYPE syst_cprog,
        title    TYPE gui_title,
        pfstatus TYPE pfstatus,
      END OF ty_default_view.
    TYPES tt_trading_reclass_key TYPE SORTED TABLE OF zstfi_trading_reclass_key WITH UNIQUE KEY DocumentUUID.

    DATA call_view_stack          TYPE tt_call_screen_stack.
    DATA catprcs_trading_texts    TYPE dd07v_tab.
    DATA contents                 TYPE zttfi_trading_reclass.
    DATA def_view                 TYPE ty_default_view.
    DATA doccat_texts             TYPE dd07v_tab.
    DATA doccat_trading_texts     TYPE dd07v_tab.
    DATA document_settings        TYPE ts_document_settings.
    DATA dummy_message            TYPE string.
    DATA event_code               TYPE salv_de_function.
    DATA extension_helper         TYPE REF TO /dmbe/cli_extension_in_helper.
    DATA logfile                  TYPE zttfi_trading_reclass_logfile.
    DATA mo_salv_table            TYPE REF TO cl_salv_table.
    DATA mo_salv_table_popup      TYPE REF TO cl_salv_table.
    DATA process_log              TYPE tt_process_log.
    DATA status_trading_prcs_icon TYPE tt_status_trading_prcs_icon.
    DATA ul_filename              TYPE string.
    DATA view_info                TYPE ty_call_screen_stack.
    DATA with_header              TYPE sap_bool.

    METHODS add_message_file
      IMPORTING !key         TYPE zstfi_trading_reclass_file_key
                detail_level TYPE ballevel OPTIONAL.

    METHODS add_message_struc_doc
      IMPORTING !message         TYPE bapiret2
                documentcategory TYPE document_category_trading DEFAULT space.

    METHODS add_message_table_doc
      IMPORTING !messages        TYPE bapiret2_t
                documentcategory TYPE document_category_trading DEFAULT space.

    METHODS add_message_table_doc_conv
      IMPORTING !messages        TYPE fm_t_bapireturn1
                documentcategory TYPE document_category_trading DEFAULT space.

    METHODS add_system_message_doc
      IMPORTING documentcategory TYPE document_category_trading DEFAULT space.

    METHODS build_extension_in
      IMPORTING document      TYPE REF TO zstsd_trading_ext
      RETURNING VALUE(result) TYPE bapiparex_t.

    METHODS build_sample_template
      RETURNING VALUE(result) TYPE REF TO truxs_t_text_data
      RAISING   cx_cts_eps_io_exception.

    METHODS cancel_documents.

    METHODS center_window
      IMPORTING dynpro_height      TYPE int4
                dynpro_width       TYPE int4
      RETURNING VALUE(coordinates) TYPE zst99_screen_coordinates.

    METHODS close.
    METHODS commit_work_and_wait.

    METHODS complete_records
      IMPORTING !rows TYPE salv_t_row OPTIONAL.

    METHODS constructor
      IMPORTING batchmode TYPE /pm0/abd_offline_fg OPTIONAL.

    METHODS convert_csv_to_sap
      IMPORTING VALUE(csv)     TYPE truxs_t_text_data
      EXPORTING data_converted TYPE STANDARD TABLE
      RAISING   cx_cts_table_conversion.

    METHODS convert_currency
      IMPORTING !date            TYPE datum
                foreign_currency TYPE waers
                local_amount     TYPE any
                local_currency   TYPE waers
      RETURNING VALUE(result)    TYPE bapikbetr1.

    METHODS conv_currency_to_external
      IMPORTING !currency     TYPE tcurc-waers
                amt_internal  TYPE any
      RETURNING VALUE(result) TYPE bapicurext.

    "! <p class="shorttext synchronized" lang="es">Crear documentos trading</p>
    "!
    "! @parameter document | <p class="shorttext synchronized" lang="es">Monitor Trading Reclasificación  </p>
    METHODS create_settlement_acc_document
      CHANGING document TYPE REF TO zstfi_trading_reclass.

    METHODS create_documents
      CHANGING document TYPE REF TO zstfi_trading_reclass.

    METHODS datainput2convext
      CHANGING input_table TYPE ANY TABLE.

    METHODS delete_variant.

    METHODS display_logfile
      RAISING cx_adt_res_seg_param_not_found.

    METHODS display_msg_excepton
      IMPORTING !exception TYPE REF TO cx_root.

    METHODS download_file
      IMPORTING filename     TYPE string
                !directory   TYPE string OPTIONAL
                file_content TYPE REF TO data
      RAISING   cx_cts_eps_io_exception.

    METHODS download_template.

    METHODS exception_to_bapiret2
      IMPORTING !exception    TYPE REF TO cx_root
      RETURNING VALUE(result) TYPE bapirettab.

    METHODS extract_documents_from_file
      RAISING cx_ios_document.

    METHODS get_current_screen_fields
      RETURNING VALUE(result) TYPE rsparams_tt.

    METHODS get_timestamp
      RETURNING VALUE(result) TYPE timestamp.

    METHODS get_variant
      RETURNING VALUE(result) TYPE rsvar-variant
      RAISING   cx_ci_invalid_variant.

    METHODS has_completed_documents
      RETURNING VALUE(result) TYPE sap_bool.

    METHODS has_mandatory_fields
      IMPORTING !line                       TYPE zstfi_trading_reclass_file
      RETURNING VALUE(has_mandatory_fields) TYPE abap_bool.

    METHODS init_control.

    METHODS is_file_fields_valid
      IMPORTING !line        TYPE zstfi_trading_reclass_file
      RETURNING VALUE(value) TYPE abap_bool.

    METHODS is_selected_rows
      IMPORTING max_one      TYPE abap_bool OPTIONAL
      RETURNING VALUE(value) TYPE abap_bool.

    METHODS is_unprocessed_documents
      RETURNING VALUE(result) TYPE sap_bool.

    METHODS is_variant_exists
      RETURNING VALUE(result) TYPE abap_bool.

    METHODS load_variant.

    METHODS on_link_click
      FOR EVENT link_click OF cl_salv_events_table
      IMPORTING !row
                !column.

    METHODS on_user_command
      FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.

    METHODS process_documents.

    METHODS progress_indicator
      IMPORTING !text     TYPE any
                processed TYPE sy-tabix
                !total    TYPE sy-tabix.

    METHODS read_catprcs_trading_text
      IMPORTING catprcs       TYPE zde_type_trading_process
      RETURNING VALUE(result) TYPE ddtext.

    METHODS read_coordinates_dynpro
      IMPORTING !dynpro            TYPE ty_call_screen_stack
      RETURNING VALUE(coordinates) TYPE zst99_screen_coordinates.

    METHODS read_doccat_trading_text
      IMPORTING doccat        TYPE zde_document_type_trading
      RETURNING VALUE(result) TYPE ddtext.

    METHODS read_domaintexts.

    METHODS read_domvalues
      IMPORTING domain_name   TYPE domname
      RETURNING VALUE(result) TYPE dd07v_t.

    METHODS read_file_separator
      RETURNING VALUE(result) TYPE char1.

    METHODS read_log.

    METHODS read_message_text
      IMPORTING !message      TYPE zst_trading_log
      RETURNING VALUE(result) TYPE bapi_msg.

    METHODS read_selected_rows
      RETURNING VALUE(value) TYPE salv_t_row.

    METHODS read_settings
      IMPORTING document TYPE zstfi_trading_reclass
      RAISING   zcx_trading.

    METHODS register.

    METHODS save_document_log
      IMPORTING dockey TYPE ztbfi_trd_reclas-%key.

    METHODS save_invoice_remark
      IMPORTING document TYPE REF TO zstsd_trading_ext.

    METHODS save_variant.

    METHODS screenfields_to_structab
      IMPORTING structabname    TYPE seocpdname
      RETURNING VALUE(structab) TYPE REF TO data.

    METHODS search_documents.

    METHODS search_documents_by_keys
      IMPORTING !keys TYPE tt_trading_reclass_key.

    METHODS send_popup
      IMPORTING !screen    TYPE syst_dynnr
                starting_x TYPE syst_tabix
                starting_y TYPE syst_tabix
                ending_x   TYPE syst_tabix OPTIONAL
                ending_y   TYPE syst_tabix OPTIONAL.

    METHODS set_columns_details.
    METHODS set_columns.
    METHODS set_editable_column.
    METHODS set_events.

    METHODS set_functioncode
      IMPORTING functioncode TYPE syst_ucomm.

    METHODS set_functions.
    METHODS set_layout.

    METHODS set_pfstatus
      IMPORTING pfstatus TYPE pfstatus.

    METHODS set_selection.

    METHODS set_title
      IMPORTING !title TYPE gui_title.

    METHODS start_report.

    METHODS timestampl_to_datetime
      IMPORTING ts           TYPE timestampl
      RETURNING VALUE(value) TYPE char19.

    METHODS unregister.

    METHODS update_content
      IMPORTING !refresh TYPE abap_bool  DEFAULT abap_false
                sel_row  TYPE syst_curow OPTIONAL
      RAISING   cx_trpa_no_value_selected.

    METHODS update_document_db
      CHANGING document TYPE  zstfi_trading_reclass.

    METHODS upload_csv_file
      EXPORTING !result TYPE ANY TABLE
      RAISING   cx_cts_eps_io_exception.

    METHODS user_confirm_action
      IMPORTING !titlebar     TYPE any DEFAULT space
                text_question TYPE any
      RETURNING VALUE(result) TYPE boole_d.

    METHODS read_save_interco_doc_to_moni
      IMPORTING !line         TYPE zstfi_trading_reclass_file
      RETURNING VALUE(result) TYPE zstfi_trading_reclass_key.
ENDCLASS.


CLASS zcl_fi_trading_reclass IMPLEMENTATION.
  METHOD add_message_file.
    INSERT VALUE #( %key     = key
                    msgty    = sy-msgty
                    msgid    = sy-msgid
                    msgno    = sy-msgno
                    msgv1    = sy-msgv1
                    msgv2    = sy-msgv2
                    msgv3    = sy-msgv3
                    msgv4    = sy-msgv4
                    detlevel = detail_level )
           INTO TABLE logfile.
  ENDMETHOD.

  METHOD add_message_struc_doc.
    process_log = VALUE #( BASE process_log
                           ( type_process  = SWITCH #( event_code
                                                       WHEN '1CREATE_DOCUMENTS' THEN 'C'
                                                       WHEN '2CANCEL_DOCUMENTS' THEN 'R' )
                             type_document = CONV #( documentcategory )
                             msgty         = message-type
                             msgid         = message-id
                             msgno         = message-number
                             msgv1         = message-message_v1
                             msgv2         = message-message_v2
                             msgv3         = message-message_v3
                             msgv4         = message-message_v4 ) ).
  ENDMETHOD.

  METHOD add_message_table_doc.
    LOOP AT messages REFERENCE INTO DATA(message).
      add_message_struc_doc( message          = message->*
                             documentcategory = documentcategory ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_message_table_doc_conv.
    LOOP AT messages REFERENCE INTO DATA(message).
      add_message_struc_doc( message          = CORRESPONDING #( message->* )
                             documentcategory = documentcategory ).
    ENDLOOP.
  ENDMETHOD.

  METHOD add_system_message_doc.
    DATA(sys_message) = VALUE bapiret2( type       = sy-msgty
                                        id         = sy-msgid
                                        number     = sy-msgno
                                        message_v1 = sy-msgv1
                                        message_v2 = sy-msgv2
                                        message_v3 = sy-msgv3
                                        message_v4 = sy-msgv4 ).

    add_message_struc_doc( message          = sys_message
                           documentcategory = documentcategory ).
  ENDMETHOD.

  METHOD build_extension_in.
    DATA(extension_data) = VALUE bape_vbak( zcontenedor    = document->container
                                            zpto_conexion3 = document->destination_port
                                            zpuerto_emb    = document->loading_dock
                                            zconsignatario = document->consignee
                                            zfecha_emb     = document->shipment_date
                                            zetd           = document->eta
                                            zetd_real      = document->real_eta ).

    INSERT extension_helper->fill_container( extension_data ) INTO TABLE result.
  ENDMETHOD.

  METHOD build_sample_template.
    result = NEW #( ).
    ASSIGN result->* TO FIELD-SYMBOL(<result>).

    DATA(template_body) =
      VALUE zttfi_trading_reclass_file( companycode             = 'HFEX'
                                        documentreferenceid     = 'FX-100300'
                                        postingdate             = sy-datum
                                        transactionquantityunit = 'ST'
                                        transactioncurrency     = 'EUR'
                                        ( quantityintransaction       = 4000
                                          amountintransactioncurrency = 79000 )
                                        ( quantityintransaction       = 5000
                                          amountintransactioncurrency = 69000 ) ).

    DATA(template_header) =
      VALUE tt_headername_file( ( field = TEXT-h01 )
                                ( field = TEXT-h02 )
                                ( field = TEXT-h03 )
                                ( field = TEXT-h05 )
                                ( field = TEXT-h06 )
                                ( field = TEXT-h07 )
                                ( field = TEXT-h08 ) ).

    CALL FUNCTION 'SAP_CONVERT_TO_CSV_FORMAT'
      TABLES     i_tab_sap_data       = template_body
      CHANGING   i_tab_converted_data = <result>
      EXCEPTIONS conversion_failed    = 1
                 OTHERS               = 2.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_cts_eps_io_exception( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
    ENDIF.

    INSERT INITIAL LINE INTO <result> INDEX 1 ASSIGNING FIELD-SYMBOL(<headerline>).
    CONCATENATE LINES OF template_header INTO <headerline> SEPARATED BY ';'.
  ENDMETHOD.

  METHOD cancel_documents.
    IF read_selected_rows( ) IS INITIAL.
      MESSAGE s062 DISPLAY LIKE 'E'.
      RETURN.
    ELSEIF NOT user_confirm_action( titlebar      = TEXT-q07
                                    text_question = TEXT-q08 ).
      RETURN.
    ENDIF.

    DATA(keys) = VALUE tt_trading_reclass_key( FOR row IN read_selected_rows( )
                                               LET document = REF #( me->contents[ row ] ) IN
                                               ( LINES OF SWITCH #( document->documentstatus
                                                                    WHEN status_trading_prcs-unprocessed
                                                                    THEN VALUE #( ( document->%key ) )
                                                                    ELSE VALUE #( ) ) ) ).

    IF keys IS NOT INITIAL.
      DELETE ztbfi_trd_reclas FROM TABLE @( VALUE #( FOR key IN keys
                                                     ( DocumentUUID = key-DocumentUUID ) ) ).
      TRY.
          update_content( refresh = abap_true ).
        CATCH cx_trpa_no_value_selected ##NO_HANDLER.
      ENDTRY.
    ENDIF.

    MESSAGE s073.
  ENDMETHOD.

  METHOD center_window.
    CALL FUNCTION 'CY_CENTER_WINDOW'
      EXPORTING dynpro_height = dynpro_height
                dynpro_width  = dynpro_width
      IMPORTING winx1         = coordinates-starting_x
                winx2         = coordinates-ending_x
                winy1         = coordinates-starting_y
                winy2         = coordinates-ending_y.
  ENDMETHOD.

  METHOD close.
    LEAVE TO SCREEN 0.
  ENDMETHOD.

  METHOD commit_work_and_wait.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING wait = abap_true.
  ENDMETHOD.

  METHOD complete_records.
    DO.
      TRY.
          DATA(idx) = COND syst_index( WHEN lines( rows ) > 0
                                       THEN rows[ sy-index ]
                                       ELSE sy-index  ).
          " TODO: variable is assigned but never used (ABAP cleaner)
          DATA(content) = REF #( contents[ idx ] ).
        CATCH cx_sy_itab_line_not_found.
          EXIT.
      ENDTRY.

      " TODO: If it is necessary to complete other fields after the extraction of data from the database, you must do it here

    ENDDO.
  ENDMETHOD.

  METHOD constructor.
    offline = xsdbool( batchmode = abap_true OR is_offline( ) ).
    extension_helper = NEW #( ).
    status_trading_prcs_icon = VALUE #( ( status = status_trading_prcs-unprocessed icon = icon_generate )
                                        ( status = status_trading_prcs-processed icon = icon_led_green )
                                        ( status = status_trading_prcs-partially_processed icon = icon_led_yellow )
                                        ( status = status_trading_prcs-error_processing icon = icon_led_red )
                                        ( status = status_trading_prcs-cancelled icon = icon_locked )
                                        ( status = status_trading_prcs-cancelallation_error icon = icon_led_red )
                                        ( status = status_trading_prcs-error icon = icon_led_red ) ).
  ENDMETHOD.

  METHOD convert_csv_to_sap.
    CALL FUNCTION 'TEXT_CONVERT_CSV_TO_SAP'
      EXPORTING  i_line_header        = with_header
                 i_tab_raw_data       = csv
      TABLES     i_tab_converted_data = data_converted
      EXCEPTIONS conversion_failed    = 1
                 OTHERS               = 2.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_cts_table_conversion( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
    ENDIF.

    datainput2convext( CHANGING input_table = data_converted ).
  ENDMETHOD.

  METHOD convert_currency.
    DATA foreign_amount TYPE wrbtr.

    CALL FUNCTION 'CONVERT_TO_FOREIGN_CURRENCY'
      EXPORTING  date             = date
                 foreign_currency = foreign_currency
                 local_amount     = local_amount
                 local_currency   = local_currency
      IMPORTING  foreign_amount   = foreign_amount
      EXCEPTIONS OTHERS           = 0.

    result = conv_currency_to_external( currency     = foreign_currency
                                        amt_internal = foreign_amount ).
  ENDMETHOD.

  METHOD conv_currency_to_external.
    CALL FUNCTION 'BAPI_CURRENCY_CONV_TO_EXTERN_9'
      EXPORTING currency        = currency
                amount_internal = amt_internal
      IMPORTING amount_external = result.
  ENDMETHOD.

  METHOD create_documents.
    create_settlement_acc_document( CHANGING document = document ).
  ENDMETHOD.

  METHOD datainput2convext.
    LOOP AT input_table ASSIGNING FIELD-SYMBOL(<data_converted>).
      DO.
        ASSIGN COMPONENT sy-index OF STRUCTURE <data_converted> TO FIELD-SYMBOL(<field>).
        IF sy-subrc IS NOT INITIAL.
          EXIT.
        ENDIF.

        DESCRIBE FIELD <field>
                 TYPE DATA(field_type) EDIT MASK DATA(mask).
        IF field_type = 'C' AND mask IS NOT INITIAL.
          DATA(convexit) = replace( val  = |CONVERSION_EXIT_{ mask }_INPUT|
                                    sub  = '=='
                                    with = space ).

          CALL FUNCTION convexit
            EXPORTING input  = <field>
            IMPORTING output = <field>.
        ENDIF.
      ENDDO.
    ENDLOOP.
  ENDMETHOD.

  METHOD default_view.
    def_view = VALUE #( dynpro   = dynpro
                        prog     = prog
                        pfstatus = pfstatus
                        title    = title ).
  ENDMETHOD.

  METHOD delete_variant.
    TRY.
        DATA(variant) = get_variant( ).
      CATCH cx_ci_invalid_variant INTO DATA(excp). " TODO: variable is assigned but never used (ABAP cleaner)
        RETURN.
    ENDTRY.

    CALL FUNCTION 'RS_VARIANT_DELETE'
      EXPORTING  report               = view_info-prog
                 variant              = variant
      IMPORTING  variant              = variant
      EXCEPTIONS not_authorized       = 1
                 not_executed         = 2
                 no_report            = 3
                 report_not_existent  = 4
                 report_not_supplied  = 5
                 variant_locked       = 6
                 variant_not_existent = 7
                 no_corr_insert       = 8
                 variant_protected    = 9.
    CASE sy-subrc.
      WHEN 3.
        MESSAGE i257(db) WITH variant.
      WHEN 1.
        MESSAGE i626(db) WITH space.
      WHEN 6.
        MESSAGE s301(db) DISPLAY LIKE 'E' WITH variant.
      WHEN 8.
        MESSAGE i278(db) WITH variant.
      WHEN 2.
        IF sy-msgid = 'DB' AND sy-msgno = 294.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
    ENDCASE.
  ENDMETHOD.

  METHOD display_logfile.
    DATA(log_appl) = NEW zcl_application_log( ).

    log_appl->open( EXPORTING  log_object    = 'RSR_REPORT_CHECK'
                               max_probclass = '4'
                    EXCEPTIONS logging_error = 1 ).
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_adt_res_seg_param_not_found(
                              textid = cx_scwn_ds_failed_verification=>get_t100_message( ) ).
    ENDIF.

    LOOP AT logfile REFERENCE INTO DATA(document_log_gp)
         GROUP BY document_log_gp->%key.

      MESSAGE s075 INTO dummy_message
              WITH document_log_gp->%key-CompanyCode
                   document_log_gp->%key-DocumentReferenceID
                   document_log_gp->%key-PostingDate.
      log_appl->add_system_message( '1' ).

      LOOP AT GROUP document_log_gp REFERENCE INTO DATA(document_log).
        log_appl->add_message_struct( EXPORTING  log_message   = document_log->bal_log_msg
                                      EXCEPTIONS logging_error = 1 ).
        IF sy-subrc IS NOT INITIAL.
          RAISE EXCEPTION NEW cx_adt_res_seg_param_not_found(
                                  textid = cx_scwn_ds_failed_verification=>get_t100_message( ) ).
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    log_appl->display_detlevel( modal = abap_true ).
    CLEAR logfile.
  ENDMETHOD.

  METHOD display_msg_excepton.
    CALL FUNCTION 'RS_EXCEPTION_TO_SYMSG'
      EXPORTING i_r_exception = exception
                i_deepest     = abap_true.

    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
            DISPLAY LIKE 'E'.
  ENDMETHOD.

  METHOD download_file.
    DATA directory_path TYPE string.
    DATA fullpath       TYPE string.

    ASSIGN file_content->* TO FIELD-SYMBOL(<file_content>).

    IF directory IS INITIAL.
      cl_gui_frontend_services=>directory_browse( CHANGING   selected_folder      = directory_path
                                                  EXCEPTIONS cntl_error           = 1
                                                             error_no_gui         = 2
                                                             not_supported_by_gui = 3
                                                             OTHERS               = 4 ).
      IF sy-subrc IS NOT INITIAL.
        RAISE EXCEPTION NEW cx_cts_eps_io_exception( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
      ENDIF.

      IF directory_path IS INITIAL.
        RETURN.
      ENDIF.
    ELSE.
      directory_path = directory.
    ENDIF.

    fullpath = |{ directory_path && read_file_separator( ) && filename }|.

    cl_gui_frontend_services=>gui_download( EXPORTING  filename                = fullpath
                                            CHANGING   data_tab                = <file_content>
                                            EXCEPTIONS file_write_error        = 1
                                                       no_batch                = 2
                                                       gui_refuse_filetransfer = 3
                                                       invalid_type            = 4
                                                       no_authority            = 5
                                                       unknown_error           = 6
                                                       header_not_allowed      = 7
                                                       separator_not_allowed   = 8
                                                       filesize_not_allowed    = 9
                                                       header_too_long         = 10
                                                       dp_error_create         = 11
                                                       dp_error_send           = 12
                                                       dp_error_write          = 13
                                                       unknown_dp_error        = 14
                                                       access_denied           = 15
                                                       dp_out_of_memory        = 16
                                                       disk_full               = 17
                                                       dp_timeout              = 18
                                                       file_not_found          = 19
                                                       dataprovider_exception  = 20
                                                       control_flush_error     = 21
                                                       not_supported_by_gui    = 22
                                                       error_no_gui            = 23
                                                       OTHERS                  = 24 ).
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_cts_eps_io_exception( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
    ENDIF.
  ENDMETHOD.

  METHOD download_template.
    TRY.
        DATA(filename) = |{ TEXT-f01 && get_timestamp( ) }.CSV|.
        DATA(template) = build_sample_template( ).

        download_file( filename     = filename
                       file_content = template ).
      CATCH cx_cts_eps_io_exception INTO DATA(io_excp).
        display_msg_excepton( io_excp ).
    ENDTRY.
  ENDMETHOD.

  METHOD extract_documents_from_file.
    DATA documents TYPE zttfi_trading_reclass_file.

    TRY.
        upload_csv_file( IMPORTING result = documents ).

        DATA(keys) = VALUE tt_trading_reclass_key(
                               FOR document IN documents
                               ( LINES OF SWITCH #( is_file_fields_valid( document )
                                                    WHEN abap_true
                                                    THEN VALUE #( LET key = read_save_interco_doc_to_moni( document )
                                                                  IN  ( LINES OF COND #(
                                                                                 WHEN key IS INITIAL
                                                                                 THEN VALUE #( )
                                                                                 ELSE VALUE #( ( key ) ) ) )  )
                                                    ELSE VALUE #( ) )  ) ).

        display_logfile( ).
        search_documents_by_keys( keys ).
      CATCH cx_cts_eps_io_exception
            cx_adt_res_seg_param_not_found INTO DATA(io_excp).
        RAISE EXCEPTION NEW cx_ios_document( previous = io_excp ).
    ENDTRY.
  ENDMETHOD.

  METHOD file_open_dialog.
    DATA rc        TYPE i.
    DATA filetable TYPE filetable.

    DATA(dynpfields) = VALUE dynpread_t( ( fieldname = fieldname ) ).

    IF fieldname IS NOT INITIAL.
      CALL FUNCTION 'DYNP_VALUES_READ'
        EXPORTING  dyname     = view_info-prog
                   dynumb     = view_info-screen
        TABLES     dynpfields = dynpfields
        EXCEPTIONS OTHERS     = 0.

      filename = dynpfields[ fieldname = fieldname ]-fieldvalue.
    ENDIF.

    cl_gui_frontend_services=>file_open_dialog( EXPORTING  default_extension       = default_extension
                                                           default_filename        = default_filename
                                                           file_filter             = file_filter
                                                CHANGING   file_table              = filetable
                                                           rc                      = rc
                                                EXCEPTIONS file_open_dialog_failed = 1
                                                           cntl_error              = 2
                                                           error_no_gui            = 3
                                                           not_supported_by_gui    = 4
                                                           OTHERS                  = 5 ).
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_cts_eps_io_exception( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
    ENDIF.

    filename = VALUE #( filetable[ 1 ] DEFAULT filename ).

    IF save_param = abap_true.
      set_file_parameters( ul_filename = CONV #( filename ) ).
    ENDIF.
  ENDMETHOD.

  METHOD get_current_screen_fields.
    DATA screen_values         TYPE STANDARD TABLE OF rsparams.
    DATA current_screen_fields TYPE TABLE OF rsscr.

    DATA(dnum) = COND #( WHEN view_info-subscreen IS NOT INITIAL
                         THEN view_info-subscreen
                         ELSE view_info-screen ).

    CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
      EXPORTING  curr_report     = view_info-prog
      TABLES     selection_table = screen_values
      EXCEPTIONS OTHERS          = 0.

    CALL FUNCTION 'RS_ISOLATE_1_SELSCREEN'
      EXPORTING  program     = view_info-prog
                 dynnr       = dnum
      TABLES     screen_sscr = current_screen_fields
      EXCEPTIONS OTHERS      = 0.
    IF sy-subrc IS INITIAL.
      result = VALUE #(
          FOR screen_value IN screen_values
          ( LINES OF COND #( WHEN line_exists( current_screen_fields[ name = screen_value-selname ] )
                              AND (    screen_value-sign IS NOT INITIAL OR screen_value-option IS NOT INITIAL
                                    OR screen_value-low  IS NOT INITIAL OR screen_value-high   IS NOT INITIAL )
                             THEN VALUE #( ( CORRESPONDING #( screen_value ) ) )
                             ELSE VALUE #( ) ) ) ).
    ENDIF.
  ENDMETHOD.

  METHOD get_instance.
    IF mo_instance IS NOT BOUND.
      mo_instance = NEW #( batchmode ).
    ENDIF.
    instance = mo_instance.
  ENDMETHOD.

  METHOD get_timestamp.
    GET TIME STAMP FIELD result.
  ENDMETHOD.

  METHOD get_variant.
    DATA cancelled TYPE xflag.

    CALL FUNCTION 'RS_VARIANT_CATALOG'
      EXPORTING  report               = view_info-prog
                 dynnr                = view_info-screen
                 pop_up               = abap_true
      IMPORTING  sel_variant          = result
                 cancelled            = cancelled
      EXCEPTIONS no_report            = 1
                 report_not_existent  = 2
                 report_not_supplied  = 3
                 no_variants          = 4
                 no_variant_selected  = 5
                 variant_not_existent = 6
                 OTHERS               = 7.
    IF sy-subrc IS NOT INITIAL.
      IF cancelled = abap_false.
        MESSAGE ID sy-msgid
                TYPE 'I'
                NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      RAISE EXCEPTION NEW cx_ci_invalid_variant( ).
    ENDIF.
  ENDMETHOD.

  METHOD handle_event.
    event_code = event.

    CASE event.
      WHEN 'INIT'.
        init_control( ).
      WHEN 'PBO9001'.
        set_pfstatus( 'ULFILE' ).
        set_title( 'ULFILE' ).
      WHEN 'PBO9002'.
        set_pfstatus( 'READDOCS' ).
        set_title( 'READDOCS' ).
      WHEN '&BACK'.
        close( ).
      WHEN '_%SETTINGS'.
        CALL TRANSACTION 'ZCU99_ZRPFI017_TX'.
      WHEN '_%SCHRDOC'.
        send( ).
      WHEN '_%PATHFILE'.
        send( ).
      WHEN '_%SPOS'.
        save_variant( ).
      WHEN '_%GET'.
        load_variant( ).
      WHEN '_%DELE'.
        delete_variant( ).
      WHEN '_%READDOCS'.
        search_documents( ).
      WHEN '_%UL_FILE'.
        set_functioncode( 'READ_FILE' ).
        close( ).
      WHEN '_%DWL_TMPL'.
        download_template( ).
      WHEN 'READ_FILE'.
        TRY.
            extract_documents_from_file( ).
          CATCH cx_ios_document INTO DATA(io_excp).
            display_msg_excepton( io_excp ).
        ENDTRY.
    ENDCASE.

    cl_gui_cfw=>dispatch( ).
  ENDMETHOD.

  METHOD has_completed_documents.
    DATA(completed_documents) = REDUCE i( INIT i = 0
                                          FOR x IN read_selected_rows( )
                                          LET n = COND i( WHEN contains_any_of( val = contents[ x ]-DocumentStatus
                                                                                sub = 'NPE' )
                                                          THEN 1 )
                                          IN NEXT i += n ).

    result = xsdbool( completed_documents > 0 ).
  ENDMETHOD.

  METHOD has_mandatory_fields.
    DATA(components) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( line ) )->components.

    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE line TO FIELD-SYMBOL(<fieldvalue>).
      IF sy-subrc IS NOT INITIAL.
        EXIT.
      ENDIF.

      IF <fieldvalue> IS NOT INITIAL.
        CONTINUE.
      ENDIF.
      CASE components[ sy-index ]-name.
        WHEN 'COMPANYCODE'.
          MESSAGE e039 INTO dummy_message.
        WHEN 'DOCUMENTREFERENCEID'.
          MESSAGE e036 INTO dummy_message.
        WHEN 'POSTINGDATE'.
          MESSAGE e066 INTO dummy_message.
        WHEN 'CONTAINER'.
          MESSAGE e041 INTO dummy_message.
        WHEN 'QUANTITYINTRANSACTION'.
          MESSAGE e051 INTO dummy_message.
        WHEN 'TRANSACTIONQUANTITYUNIT'.
          MESSAGE e067 INTO dummy_message.
        WHEN 'AMOUNTINTRANSACTIONCURRENCY'.
          MESSAGE e049 INTO dummy_message.
        WHEN 'TRANSACTIONCURRENCY'.
          MESSAGE e040 INTO dummy_message.
        WHEN 'SEASON'.
          MESSAGE e067 INTO dummy_message.
        WHEN OTHERS.
          CONTINUE.
      ENDCASE.
      add_message_file( key          = line-%key
                        detail_level = '2' ).

      DATA(no_mandatory_field) = abap_true.
      EXIT.
    ENDDO.

    has_mandatory_fields = xsdbool( no_mandatory_field IS INITIAL ).
  ENDMETHOD.

  METHOD init_control.
    CHECK me->offline = abap_false.

    set_pfstatus( def_view-pfstatus ).
    set_title( def_view-title ).
    read_domaintexts( ).

    IF mo_salv_table IS NOT BOUND.
      start_report( ).
    ENDIF.
  ENDMETHOD.

  METHOD is_file_fields_valid.
    IF NOT has_mandatory_fields( line ).
      RETURN.
    ENDIF.

    SELECT SINGLE FROM A_CompanyCode
      FIELDS @abap_true
      WHERE CompanyCode = @line-companycode
      INTO @DATA(companycode_exist).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e055 WITH line-companycode INTO dummy_message.
      add_message_file( key          = line-%key
                        detail_level = '2' ).
    ENDIF.

    SELECT SINGLE FROM i_currency
      FIELDS @abap_true
      WHERE currency = @line-transactioncurrency
      INTO @DATA(currency_exist).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e056 WITH line-transactioncurrency INTO dummy_message.
      add_message_file( key          = line-%key
                        detail_level = '2' ).
    ENDIF.

    SELECT SINGLE FROM I_UnitOfMeasure
      FIELDS @abap_true
      WHERE UnitOfMeasure = @line-transactionquantityunit
      INTO @DATA(unit_exist).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e069 WITH line-transactionquantityunit INTO dummy_message.
      add_message_file( key          = line-%key
                        detail_level = '2' ).
    ENDIF.

    value = xsdbool(     companycode_exist = abap_true
                     AND unit_exist        = abap_true
                     AND currency_exist    = abap_true ).
  ENDMETHOD.

  METHOD is_offline.
    value = cl_salv_table=>is_offline( ).
  ENDMETHOD.

  METHOD is_selected_rows.
    mo_salv_table->get_metadata( ).
    value = COND #( WHEN max_one = abap_true
                    THEN xsdbool( lines( mo_salv_table->get_selections( )->get_selected_rows( ) ) = 1 )
                    ELSE xsdbool( mo_salv_table->get_selections( )->get_selected_rows( ) ) ).
  ENDMETHOD.

  METHOD is_unprocessed_documents.
    DATA(unprocessed_documents) = REDUCE i( INIT i = 0
                                            FOR x IN read_selected_rows( )
                                            LET n = COND i( WHEN contains_any_of(
                                                                val = contents[ x ]-DocumentStatus
                                                                sub = status_trading_prcs-error_processing && status_trading_prcs-unprocessed )
                                                            THEN 1 )
                                            IN NEXT i += n ).

    result = xsdbool( unprocessed_documents > 0 ).
  ENDMETHOD.

  METHOD is_variant_exists.
    DATA(dnum) = COND #( WHEN view_info-subscreen IS NOT INITIAL
                         THEN view_info-subscreen
                         ELSE view_info-screen ).

    CALL FUNCTION 'RS_VARIANT_FOR_ONE_SCREEN'
      EXPORTING program        = view_info-prog
                dynnr          = dnum
      IMPORTING variant_exists = result.
  ENDMETHOD.

  METHOD load_variant.
    DATA sscr TYPE STANDARD TABLE OF rsscr.

    TRY.
        DATA(variant) = get_variant( ).
        DATA(rkey) = VALUE rsvarkey( report  = view_info-prog
                                     variant = variant ).
      CATCH cx_ci_invalid_variant INTO DATA(excp). " TODO: variable is assigned but never used (ABAP cleaner)
        RETURN.
    ENDTRY.

    CALL FUNCTION 'RS_VARIANT_FETCH'
      EXPORTING  function             = 'CO26'
                 rkey                 = rkey
                 submode              = space
      TABLES     selctab              = sscr
      EXCEPTIONS variant_name         = 1
                 no_variants          = 2
                 variant_inconsistent = 3
                 only_background      = 4
                 OTHERS               = 5.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID 'DB' TYPE 'S' NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDMETHOD.

  METHOD on_link_click.
    DATA(content) = REF #( contents[ row ] ).
    ASSIGN COMPONENT column OF STRUCTURE content->* TO FIELD-SYMBOL(<value>).
    IF <value> IS INITIAL.
      RETURN.
    ELSE.
      UNASSIGN <value>.
    ENDIF.

    CASE column.
      WHEN 'SALESDOCUMENT'.
        SET PARAMETER ID 'AUN' FIELD content->salesdocument.
        CALL TRANSACTION 'VA03' AND SKIP FIRST SCREEN.
      WHEN 'BILLINGDOCUMENT'.
        SET PARAMETER ID 'VF' FIELD content->billingdocument.
        CALL TRANSACTION 'VF03' AND SKIP FIRST SCREEN.
      WHEN 'ACCOUNTINGDOCUMENT'.
        SET PARAMETER ID 'BLN' FIELD content->accountingdocument.
        SET PARAMETER ID 'BUK' FIELD content->companycode.
        SET PARAMETER ID 'GJR' FIELD content->fiscalyear.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
      WHEN 'ACCOUNTINGDOCUMENTSETTLEMENT'.
        SET PARAMETER ID 'BLN' FIELD content->accountingdocumentsettlement.
        SET PARAMETER ID 'BUK' FIELD content->companycodesettlement.
        SET PARAMETER ID 'GJR' FIELD content->fiscalyearsettlement.
        CALL TRANSACTION 'FB03' AND SKIP FIRST SCREEN.
    ENDCASE.
  ENDMETHOD.

  METHOD on_user_command.
    event_code = e_salv_function.
    CASE e_salv_function.
      WHEN '0REFRESH'.
        TRY.
            update_content( refresh = abap_true ).
          CATCH cx_trpa_no_value_selected INTO DATA(excp).
            MESSAGE excp->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
            RETURN.
        ENDTRY.
      WHEN '1CREATE_DOCUMENTS'.
        IF is_unprocessed_documents( ).
          process_documents( ).
        ELSE.
          MESSAGE s007 DISPLAY LIKE 'E'.
        ENDIF.
      WHEN '2CANCEL_DOCUMENTS'.
        cancel_documents( ).
      WHEN '3LOG'.
        read_log( ).
    ENDCASE.
  ENDMETHOD.

  METHOD process_documents.
    DATA(selected_rows) = read_selected_rows( ).
    DATA(total_lines) = lines( selected_rows ).

    TRY.
        update_content( ).

        LOOP AT selected_rows INTO DATA(row).
          DATA(document) = REF #( me->contents[ row ] ).

          progress_indicator( text      = TEXT-p01
                              processed = sy-tabix
                              total     = total_lines ).

          TRY.

              IF NOT contains_any_of( val = document->documentstatus
                                      sub = status_trading_prcs-error_processing && status_trading_prcs-unprocessed ).
                CONTINUE.
              ENDIF.

              read_settings( document->* ).
              create_documents( CHANGING document = document ).
            CATCH zcx_trading INTO DATA(excp).
              add_message_table_doc( exception_to_bapiret2( excp ) ).
              update_document_db( CHANGING document = document->* ).
          ENDTRY.
        ENDLOOP.

        update_content( refresh = abap_true ).
      CATCH cx_trpa_no_value_selected INTO DATA(excp_not_selected).
        MESSAGE excp_not_selected->get_text( ) TYPE 'S' DISPLAY LIKE 'E'.
        RETURN.
    ENDTRY.
  ENDMETHOD.

  METHOD progress_indicator.
    cl_progress_indicator=>progress_indicate( i_text               = text
                                              i_processed          = processed
                                              i_total              = total
                                              i_output_immediately = abap_true ).
  ENDMETHOD.

  METHOD read_catprcs_trading_text.
    result = VALUE #( catprcs_trading_texts[ domvalue_l = catprcs ]-ddtext OPTIONAL ).
  ENDMETHOD.

  METHOD read_coordinates_dynpro.
    IF dynpro-is_popup = abap_false.
      EXIT.
    ENDIF.

    SELECT SINGLE FROM d020s
      FIELDS bzmx,
             bzbr
      WHERE prog = @dynpro-prog
        AND dnum = @dynpro-screen
      INTO @DATA(dynpro_size).

    coordinates = center_window( dynpro_height = CONV i( dynpro_size-bzmx )
                                 dynpro_width  = CONV i( dynpro_size-bzbr ) ).
  ENDMETHOD.

  METHOD read_doccat_trading_text.
    result = VALUE #( doccat_trading_texts[ domvalue_l = doccat ]-ddtext OPTIONAL ).
  ENDMETHOD.

  METHOD read_domaintexts.
    doccat_texts = read_domvalues( 'VBTYP' ).
    catprcs_trading_texts = read_domvalues( 'ZDD_TYPE_TRADING_PROCESS' ).
    doccat_trading_texts = read_domvalues( 'ZDD_DOCUMENT_TYPE_TRADING' ).
  ENDMETHOD.

  METHOD read_domvalues.
    CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING  domname   = domain_name
                 text      = if_salv_c_bool_sap=>true
      TABLES     dd07v_tab = result
      EXCEPTIONS OTHERS    = 0.
  ENDMETHOD.

  METHOD read_file_separator.
    CASE sy-batch.
      WHEN abap_true.
        result = SWITCH #( sy-opsys
                           WHEN 'Windows NT' THEN '\'
                           WHEN 'Linux'      THEN '/'
                           WHEN 'HP-UX'      THEN '/'
                           WHEN 'OS400'      THEN '/'
                           ELSE                   '/' ) ##NO_TEXT.
      WHEN abap_false.
        cl_gui_frontend_services=>get_file_separator( CHANGING   file_separator = result
                                                      EXCEPTIONS OTHERS         = 0 ).
    ENDCASE.
  ENDMETHOD.

  METHOD read_log.
    IF is_selected_rows( ) = abap_false.
      MESSAGE s609(vb) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(documents) = VALUE tt_trading_reclass_key( FOR row IN read_selected_rows( )
                                                    ( contents[ row ]-%key  ) ).

    SELECT FROM ztbfi_trdrecllog
      FIELDS *
      FOR ALL ENTRIES IN @documents
      WHERE DocumentUUID = @documents-DocumentUUID
      INTO TABLE @DATA(log_documents).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE s485(vl) DISPLAY LIKE 'E'.
      RETURN.
    ENDIF.

    DATA(log_appl) = NEW zcl_application_log( ).

    log_appl->open( EXPORTING  log_object    = 'RSR_REPORT_CHECK'
                               max_probclass = '4'
                    EXCEPTIONS logging_error = 1 ).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              DISPLAY LIKE 'S'.
    ENDIF.

    SORT log_documents BY documentuuid
                          datetime_l
                          zaehl.
    LOOP AT log_documents REFERENCE INTO DATA(log).

      AT NEW DocumentUUID.
        DATA(dockey) = contents[ DocumentUUID = log->documentuuid ]-%dockey.
        MESSAGE s074 WITH dockey-AccountingDocument dockey-CompanyCode dockey-FiscalYear INTO dummy_message.
        log_appl->add_system_message( '1' ).
      ENDAT.

      AT NEW datetime_l.
        MESSAGE s001 INTO dummy_message
                WITH read_catprcs_trading_text( log->type_process )
                     timestampl_to_datetime( log->datetime_l ).

        log_appl->add_system_message( '2' ).
      ENDAT.

      AT NEW type_document.
        MESSAGE s001 INTO dummy_message
                WITH read_doccat_trading_text( log->type_document ).

        log_appl->add_system_message( '3' ).
      ENDAT.

      MESSAGE ID log->id
              TYPE log->type
              NUMBER log->nro
              WITH log->messagev1 log->messagev2
                   log->messagev3 log->messagev4
              INTO dummy_message.

      log_appl->add_system_message( '4' ).
    ENDLOOP.

    log_appl->display_detlevel( modal = abap_true ).
  ENDMETHOD.

  METHOD read_message_text.
    MESSAGE ID message-msgid TYPE message-msgty NUMBER message-msgno
            WITH message-msgv1 message-msgv2 message-msgv3 message-msgv4
            INTO result.
  ENDMETHOD.

  METHOD read_selected_rows.
    mo_salv_table->get_metadata( ).
    value = mo_salv_table->get_selections( )->get_selected_rows( ).
  ENDMETHOD.

  METHOD read_settings.
    CLEAR document_settings.

    SELECT SINGLE FROM ztbfi_trdrecl_po
      FIELDS *
      WHERE CompanyCode = @document-origincompanycode
      INTO @document_settings-purchase_accounting_document.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION TYPE zcx_trading
            MESSAGE e072 WITH document-CompanyCode.
    ENDIF.
  ENDMETHOD.

  METHOD read_view.
    result = view_info.
  ENDMETHOD.

  METHOD register.
    DATA(dynpro) =
      SWITCH ty_call_screen_stack( event_code
                                   WHEN space        THEN VALUE #( prog   = def_view-prog
                                                                   screen = def_view-dynpro )
                                   WHEN '_%PATHFILE' THEN VALUE #( prog     = def_view-prog
                                                                   event    = event_code
                                                                   screen   = '9001'
                                                                   is_popup = abap_true )
                                   WHEN '_%SCHRDOC'  THEN VALUE #( prog      = def_view-prog
                                                                   event     = event_code
                                                                   screen    = '9002'
                                                                   subscreen = '2000'
                                                                   is_popup  = abap_true ) ).
    IF NOT line_exists( call_view_stack[ event     = dynpro-event
                                         prog      = dynpro-prog
                                         screen    = dynpro-screen
                                         subscreen = dynpro-subscreen ] ).
      view_info = VALUE #( BASE dynpro
                           coordinates = read_coordinates_dynpro( dynpro ) ).
      INSERT view_info INTO TABLE call_view_stack.
    ENDIF.
  ENDMETHOD.

  METHOD save_document_log.
    DATA datetime    TYPE timestampl.
    DATA log_entries TYPE STANDARD TABLE OF ztbfi_trdrecllog.

    IF process_log IS INITIAL.
      RETURN.
    ENDIF.

    DELETE
      FROM ztbfi_trdrecllog
      WHERE documentuuid  = dockey-DocumentUUID
        AND type_document = space.

    GET TIME STAMP FIELD datetime.
    log_entries = VALUE #( FOR log_entry IN process_log
                           INDEX INTO idx
                           ( %parentkey    = dockey
                             datetime_l    = datetime
                             type_process  = log_entry-type_process
                             type_document = log_entry-type_document
                             zaehl         = idx
                             type          = log_entry-msgty
                             id            = log_entry-msgid
                             nro           = log_entry-msgno
                             message       = read_message_text( log_entry )
                             messagev1     = log_entry-msgv1
                             messagev2     = log_entry-msgv2
                             messagev3     = log_entry-msgv3
                             messagev4     = log_entry-msgv4
                             createdby     = sy-uname ) ).

    INSERT ztbfi_trdrecllog FROM TABLE log_entries.
    CLEAR process_log.
  ENDMETHOD.

  METHOD save_invoice_remark.
    IF document->invoice_remark IS INITIAL.
      RETURN.
    ENDIF.

    DATA(order_header_text_id) = VALUE thead( tdobject = 'VBBK'
                                              tdname   = document->invoiceno
                                              tdid     = 'CH01'
                                              tdspras  = sy-langu
                                              tdform   = '*' ).

    DATA(order_header_text_lines) = VALUE tttext( ( tdformat = '*' tdline = document->invoice_remark ) ).

    CALL FUNCTION 'SAVE_TEXT'
      EXPORTING  header          = order_header_text_id
                 savemode_direct = abap_true
      TABLES     lines           = order_header_text_lines
      EXCEPTIONS OTHERS          = 0.
  ENDMETHOD.

  METHOD save_variant.
    DATA variant TYPE massvar.

    CALL FUNCTION 'I_MASS_VARIANT_SAVE_DIALOG'
      CHANGING   wa_massvariant = variant
      EXCEPTIONS user_cancel    = 1
                 OTHERS         = 2.
    IF sy-subrc IS NOT INITIAL.
      RETURN.
    ENDIF.

    DATA(vari_contents) = get_current_screen_fields( ).
    DATA(vscreens) = VALUE tt_rsdynnr( ( dynnr = view_info-screen ) ).

    DATA(vari_description) = VALUE varid( mandt      = sy-mandt
                                          report     = view_info-prog
                                          variant    = variant-varname
                                          ename      = sy-uname
                                          edat       = sy-datum
                                          etime      = sy-uzeit
                                          environmnt = 'A' ).

    DATA(vari_texts) = VALUE diwps_varit_t( ( mandt   = sy-mandt
                                              langu   = sy-langu
                                              report  = view_info-prog
                                              variant = variant-varname
                                              vtext   = variant-vartext ) ).

    CALL FUNCTION 'RS_CREATE_VARIANT'
      EXPORTING  curr_report               = view_info-prog
                 curr_variant              = CONV rsvar-variant( variant-varname )
                 vari_desc                 = vari_description
      TABLES     vari_contents             = vari_contents
                 vari_text                 = vari_texts
                 vscreens                  = vscreens
      EXCEPTIONS illegal_report_or_variant = 1
                 illegal_variantname       = 2
                 not_authorized            = 3
                 not_executed              = 4
                 report_not_existent       = 5
                 report_not_supplied       = 6
                 variant_exists            = 7
                 variant_locked            = 8
                 OTHERS                    = 9.
    IF sy-subrc = 7.
      IF user_confirm_action( titlebar      = TEXT-q03
                              text_question = TEXT-q04 ).
        CALL FUNCTION 'RS_CHANGE_CREATED_VARIANT'
          EXPORTING  curr_report               = view_info-prog
                     curr_variant              = CONV rsvar-variant( variant-varname )
                     vari_desc                 = vari_description
          TABLES     vari_contents             = vari_contents
                     vari_text                 = vari_texts
          EXCEPTIONS illegal_report_or_variant = 1
                     illegal_variantname       = 2
                     not_authorized            = 3
                     not_executed              = 4
                     report_not_existent       = 5
                     report_not_supplied       = 6
                     variant_doesnt_exist      = 7
                     variant_locked            = 8
                     selections_no_match       = 9
                     OTHERS                    = 10.
        IF sy-subrc IS NOT INITIAL.
          MESSAGE ID sy-msgid
                  TYPE 'I'
                  NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          MESSAGE s617(db) WITH variant-varname.
        ENDIF.
      ELSE.
        RETURN.
      ENDIF.
    ELSEIF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid
              TYPE 'I'
              NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      MESSAGE s617(db) WITH variant-varname.
    ENDIF.
  ENDMETHOD.

  METHOD screenfields_to_structab.
    DATA new_line TYPE REF TO data.
    FIELD-SYMBOLS <table> TYPE STANDARD TABLE.

    CREATE DATA structab TYPE (structabname).
    ASSIGN structab->* TO FIELD-SYMBOL(<structab>).

    DATA(dynpro_content) = get_current_screen_fields( ).

    LOOP AT dynpro_content REFERENCE INTO DATA(dyn_field)
         GROUP BY ( name = dyn_field->selname
                    kind = dyn_field->kind ).

      ASSIGN COMPONENT dyn_field->selname
             OF STRUCTURE <structab>
             TO FIELD-SYMBOL(<field>).

      CASE dyn_field->kind.
        WHEN if_rsda_constants=>selkind-parameter.
          <field> = dyn_field->low.
        WHEN if_rsda_constants=>selkind-select_option.
          LOOP AT GROUP dyn_field REFERENCE INTO DATA(dyn_val).
            ASSIGN <field> TO <table>.
            CREATE DATA new_line LIKE LINE OF <table>.
            new_line->* = CORRESPONDING #( dyn_val->* ).
            INSERT new_line->* INTO TABLE <table>.
          ENDLOOP.
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.

  METHOD search_documents.
    DATA documents TYPE zttfi_trading_reclass.

    DATA(ref_structab) = screenfields_to_structab( 'TS_SEARCH_DOCUMENTS_PARAMETERS' ).
    DATA(parameters) = CONV ts_search_documents_parameters( ref_structab->* ).

    SELECT FROM zcds_i_tradingreclassreport
      FIELDS *
      WHERE documentuuid                 IN @parameters-docuuid
        AND accountingdocument           IN @parameters-accdoc
        AND companycode                  IN @parameters-ccode
        AND fiscalyear                   IN @parameters-fyear
        AND documentstatus               IN @parameters-status
        AND salesdocument                IN @parameters-sorder
        AND billingdocument              IN @parameters-billdoc
        AND documentreferenceid          IN @parameters-docrefid
        AND container                    IN @parameters-cnt
        AND to_postingdate               IN @parameters-postdate
        AND createdatdate                IN @parameters-createat
        AND lastchangedate               IN @parameters-modifat
        AND companycodesettlement        IN @parameters-ccodest
        AND accountingdocumentsettlement IN @parameters-accdocst
        AND fiscalyearsettlement         IN @parameters-fyearst
      INTO CORRESPONDING FIELDS OF TABLE @documents.
    IF sy-subrc IS INITIAL.
      contents = documents.
*      complete_records( ). " TODO: Additional data must be completed in this method
      MESSAGE s023 WITH sy-dbcnt.
      mo_salv_table->refresh( refresh_mode = if_salv_c_refresh=>full ).

      IF view_info-event = '_%SCHRDOC'.
        close( ).
      ENDIF.
    ELSE.
      MESSAGE s490(vr) DISPLAY LIKE 'E'.
      LEAVE TO LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.

  METHOD search_documents_by_keys.
    DATA documents      TYPE zttfi_trading_reclass.
    DATA documents_uuid TYPE RANGE OF ztbfi_trd_reclas-DocumentUUID.

    IF keys IS INITIAL OR NOT user_confirm_action( titlebar      = TEXT-q01
                                                   text_question = TEXT-q02 ).
      RETURN.
    ENDIF.

    documents_uuid = VALUE #( FOR key IN keys
                              ( sign = 'I' option = 'EQ' low = key-DocumentUUID ) ).

    SELECT FROM zcds_i_tradingreclassreport
      FIELDS *
      WHERE DocumentUUID IN @documents_uuid
      INTO CORRESPONDING FIELDS OF TABLE @documents.
    IF sy-subrc IS INITIAL.
      contents = documents.
*      complete_records( )." TODO: Additional data must be completed in this method
      MESSAGE s023 WITH sy-dbcnt.
      mo_salv_table->refresh( refresh_mode = if_salv_c_refresh=>full ).
    ELSE.
      MESSAGE s490(vr) DISPLAY LIKE 'E'.
      LEAVE TO LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.

  METHOD send.
    register( ).

    IF view_info-is_popup = abap_false.
      PERFORM call_screen IN PROGRAM (view_info-prog) USING view_info-screen.
    ELSE.
      PERFORM call_popup IN PROGRAM (view_info-prog)
        USING view_info-screen
              view_info-starting_x
              view_info-starting_y
              view_info-ending_x
              view_info-ending_y.
    ENDIF.

    unregister( ).
  ENDMETHOD.

  METHOD send_popup.
    PERFORM call_popup IN PROGRAM (view_info-prog)
      USING screen
            starting_x
            starting_y
            ending_x
            ending_y.
  ENDMETHOD.

  METHOD set_columns.
    DATA o_columns TYPE REF TO cl_salv_columns_table.
    DATA o_column  TYPE REF TO cl_salv_column_table.

    TRY.
        o_columns = mo_salv_table->get_columns( ).

        " Hotspot
        o_column ?= o_columns->get_column( 'ACCOUNTINGDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'SALESDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'BILLINGDOCUMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        o_column ?= o_columns->get_column( 'ACCOUNTINGDOCUMENTSETTLEMENT' ).
        o_column->set_cell_type( if_salv_c_cell_type=>hotspot ).

        " Custom texts
        o_column ?= o_columns->get_column( 'DOCUMENTSTATUSICON' ).
        o_column->set_short_text( o_columns->get_column( 'DOCUMENTSTATUS' )->get_short_text( ) ).
        o_column->set_medium_text( o_columns->get_column( 'DOCUMENTSTATUS' )->get_medium_text( ) ).
        o_column->set_long_text( o_columns->get_column( 'DOCUMENTSTATUS' )->get_long_text( ) ).

        " Set columns position
        o_columns->set_column_position( columnname = 'DOCUMENTSTATUSICON'
                                        position   = 1 ).
        o_columns->set_column_position( columnname = 'CONTAINER'
                                        position   = o_columns->get_column_position( 'SALESDOCUMENT' ) + 1 ).
        o_columns->set_column_position( columnname = 'QUANTITYINPURCHASEINVOICE'
                                        position   = o_columns->get_column_position( 'TRANSACTIONQUANTITYUNIT' ) + 1 ).
        o_columns->set_column_position( columnname = 'PURCHASEINVOICEQUANTITYUNIT'
                                        position   = o_columns->get_column_position( 'QUANTITYINPURCHASEINVOICE' ) + 1 ).

        " Hidden columns (Technical)
        o_column ?= o_columns->get_column( 'MANDT' ).
        o_column->set_technical( if_salv_c_bool_sap=>true ).
        o_column ?= o_columns->get_column( 'DOCUMENTSTATUS' ).
        o_column->set_technical( if_salv_c_bool_sap=>true ).
        o_column ?= o_columns->get_column( 'SDDOCUMENTCATEGORY' ).
        o_column->set_technical( if_salv_c_bool_sap=>true ).

        " Hidden columns (Visible)
        o_column ?= o_columns->get_column( 'DOCUMENTUUID' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'ORIGINCOMPANYCODE' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'CREATEDATDATE' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'CREATEDATTIME' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'CREATEDBY' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'LASTCHANGEDATE' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'LASTCHANGETIME' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'LASTCHANGEDBY' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).

        o_columns->set_optimize( if_salv_c_bool_sap=>true ).
      CATCH cx_salv_msg
            cx_salv_not_found
            cx_salv_data_error ##NO_HANDLER.
        BREAK-POINT.
    ENDTRY.
  ENDMETHOD.

  METHOD set_columns_details.
    DATA o_columns TYPE REF TO cl_salv_columns_table.
    DATA o_column  TYPE REF TO cl_salv_column_table.

    TRY.
        o_columns = mo_salv_table_popup->get_columns( ).

        o_column ?= o_columns->get_column( 'MANDT' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'GROWER' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'EXTDOCUMENT' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).
        o_column ?= o_columns->get_column( 'SEQNR' ).
        o_column->set_visible( if_salv_c_bool_sap=>false ).

        " Custom texts
        o_column ?= o_columns->get_column( 'UNIT_GROSS_WEIGHT' ).
        o_column->set_short_text( CONV scrtext_s( TEXT-f02 )  ).
        o_column->set_medium_text( CONV scrtext_m( TEXT-f03 ) ).
        o_column->set_long_text( CONV scrtext_l( TEXT-f04 ) ).
        o_column->set_tooltip( CONV scrtext_l( TEXT-f04 ) ).

        o_column ?= o_columns->get_column( 'UNIT_NET_WEIGHT' ).
        o_column->set_short_text( CONV scrtext_s( TEXT-f05 )  ).
        o_column->set_medium_text( CONV scrtext_m( TEXT-f06 ) ).
        o_column->set_long_text( CONV scrtext_l( TEXT-f07 ) ).
        o_column->set_tooltip( CONV scrtext_l( TEXT-f07 ) ).

        o_columns->set_optimize( if_salv_c_bool_sap=>true ).
      CATCH cx_salv_msg
            cx_salv_not_found
            cx_salv_data_error ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD set_editable_column.
*    TRY.
*        DATA(mo_salv_gui_edit) = mo_salv_table->extended_grid_api( )->editable_restricted( ).
*        mo_salv_gui_edit->set_attributes_for_columnname(
*          columnname              = 'COLUMN_NAME_HERE'
*          all_cells_input_enabled = abap_true ).
*      CATCH cx_salv_not_found.
*    ENDTRY.
*
*    mo_salv_gui_edit->validate_changed_data( ).
*    mo_salv_table->refresh( refresh_mode = if_salv_c_refresh=>full ).
  ENDMETHOD.

  METHOD set_events.
    DATA(o_events) = mo_salv_table->get_event( ).
    SET HANDLER me->on_link_click   FOR o_events.
    SET HANDLER me->on_user_command FOR o_events.
  ENDMETHOD.

  METHOD set_file_parameters.
    me->ul_filename = ul_filename.
    me->with_header = with_header.
  ENDMETHOD.

  METHOD set_functioncode.
    DATA(fc) = CONV syst_ucomm( |={ functioncode }| ).

    CALL FUNCTION 'SAPGUI_SET_FUNCTIONCODE'
      EXPORTING  functioncode = fc
      EXCEPTIONS OTHERS       = 0.
  ENDMETHOD.

  METHOD set_functions.
    DATA o_functions TYPE REF TO cl_salv_functions_list.
    DATA icon        TYPE string.
    DATA text        TYPE string.
    DATA tooltip     TYPE string.

    o_functions = mo_salv_table->get_functions( ).
    o_functions->set_all( if_salv_c_bool_sap=>true ).
    o_functions->set_detail( abap_false ).

    TRY.
        icon = icon_refresh.
        tooltip = TEXT-t03.
        o_functions->add_function( name     = '0REFRESH'
                                   icon     = icon
                                   tooltip  = tooltip
                                   position = if_salv_c_function_position=>left_of_salv_functions ).
        icon = icon_execute_object.
        tooltip = TEXT-t02.
        text = tooltip.
        o_functions->add_function( name     = '1CREATE_DOCUMENTS'
                                   icon     = icon
                                   text     = text
                                   tooltip  = tooltip
                                   position = if_salv_c_function_position=>right_of_salv_functions ).

        icon = icon_bw_simulate_cancel.
        tooltip = TEXT-t08.
        text = tooltip.
        o_functions->add_function( name     = '2CANCEL_DOCUMENTS'
                                   icon     = icon
                                   text     = text
                                   tooltip  = tooltip
                                   position = if_salv_c_function_position=>right_of_salv_functions ).

        icon = icon_protocol.
        tooltip = TEXT-t01.
        text = tooltip.
        o_functions->add_function( name     = '3LOG'
                                   icon     = icon
                                   text     = text
                                   tooltip  = tooltip
                                   position = if_salv_c_function_position=>right_of_salv_functions ).

      CATCH cx_salv_wrong_call
            cx_salv_existing ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD set_layout.
    DATA(key) = VALUE salv_s_layout_key( report = sy-repid ).
    DATA(layout) = mo_salv_table->get_layout( ).

    layout->set_key( key ).
    layout->set_save_restriction( if_salv_c_layout=>restrict_none ).
    layout->set_initial_layout( 'DEFAULT' ).

    mo_salv_table->get_display_settings( )->set_striped_pattern( abap_true ).
  ENDMETHOD.

  METHOD set_pfstatus.
    DATA excl TYPE syucomm_t.

    IF view_info-event = '_%SCHRDOC' AND NOT is_variant_exists( ).
      excl = VALUE #( ( '_%GET' ) ( '_%DELE' ) ).
    ENDIF.

    SET PF-STATUS pfstatus EXCLUDING excl OF PROGRAM view_info-prog.
  ENDMETHOD.

  METHOD set_selection.
    mo_salv_table->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>row_column ).
  ENDMETHOD.

  METHOD set_title.
    SET TITLEBAR title OF PROGRAM view_info-prog.
  ENDMETHOD.

  METHOD start_report.
    TRY.
        cl_salv_table=>factory( EXPORTING r_container  = cl_gui_custom_container=>default_screen
                                IMPORTING r_salv_table = mo_salv_table
                                CHANGING  t_table      = contents ).
      CATCH cx_salv_msg.
        RETURN.
    ENDTRY.

    set_columns( ).
    set_functions( ).
    set_selection( ).
    set_layout( ).
    set_events( ).
    mo_salv_table->display( ).
    set_editable_column( ).
  ENDMETHOD.

  METHOD timestampl_to_datetime.
    value = |{ ts TIMESTAMP = ENVIRONMENT TIMEZONE = sy-zonlo } |.
  ENDMETHOD.

  METHOD unregister.
    DATA last TYPE i.

    DO 2 TIMES.
      last = lines( call_view_stack ).
      CASE sy-index.
        WHEN 1.
          DELETE call_view_stack INDEX last.
        WHEN 2.
          view_info = VALUE #( call_view_stack[ last ] OPTIONAL ).
      ENDCASE.
    ENDDO.
  ENDMETHOD.

  METHOD update_content.
    DATA(selected_rows) = COND salv_t_row( LET message = VALUE scx_t100key( msgid = 'VB'
                                                                            msgno = '609' ) IN
                                           WHEN sel_row > 0         THEN VALUE #( ( sel_row ) )
                                           WHEN is_selected_rows( ) THEN read_selected_rows( )
                                           ELSE                          THROW cx_trpa_no_value_selected(
                                                                                   textid = message ) ).

    LOOP AT selected_rows INTO DATA(row).
      TRY.
          DATA(document) = REF #( contents[ row ] ).

          SELECT FROM zcds_i_tradingreclassreport
            FIELDS *
            WHERE DocumentUUID = @document->%key-DocumentUUID
            INTO TABLE @DATA(documents)
            UP TO 1 ROWS.
          IF sy-subrc IS NOT INITIAL.
            DELETE TABLE contents FROM VALUE #( DocumentUUID = document->documentuuid ).
          ELSE.
            document->* = CORRESPONDING #( documents[ 1 ] ).
          ENDIF.
        CATCH cx_sy_itab_line_not_found.
          CONTINUE.
      ENDTRY.
    ENDLOOP.

    IF refresh = abap_true.
*      complete_records( selected_rows )." TODO: Additional data must be completed in this method
      mo_salv_table->refresh( ).
    ENDIF.
  ENDMETHOD.

  METHOD update_document_db.
    DATA(is_completely_created) = xsdbool( document-%settlementdockey IS NOT INITIAL ).

    document = VALUE #( BASE document
                        Mandt          = sy-mandt
                        DocumentStatus = COND #( WHEN is_completely_created = abap_true
                                                 THEN status_trading_prcs-processed
                                                 ELSE status_trading_prcs-error_processing )
                        LastChangeDate = sy-datum
                        LastChangeTime = sy-uzeit
                        LastChangedBy  = sy-uname ).

    MODIFY ztbfi_trd_reclas FROM document-%reclass.

    save_document_log( document-%key ).
    commit_work_and_wait( ).
  ENDMETHOD.

  METHOD upload_csv_file.
    DATA csv_data TYPE truxs_t_text_data.

    cl_gui_frontend_services=>gui_upload( EXPORTING  filename = ul_filename
                                          CHANGING   data_tab = csv_data
                                          EXCEPTIONS OTHERS   = 1 ).
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_cts_eps_io_exception( textid = cx_scwn_sds_note_failed_dwld=>get_t100_message( ) ).
    ELSEIF csv_data IS INITIAL.
      RAISE EXCEPTION TYPE cx_cts_eps_io_exception
            MESSAGE ID 'SRF_RUNTIME' TYPE 'E' NUMBER 082.
    ENDIF.
    TRY.
        convert_csv_to_sap( EXPORTING csv            = csv_data
                            IMPORTING data_converted = result ).
      CATCH cx_cts_table_conversion INTO DATA(excp).
        RAISE EXCEPTION NEW cx_cts_eps_io_exception( previous = excp ).
    ENDTRY.
  ENDMETHOD.

  METHOD user_confirm_action.
    DATA answer TYPE char1.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING  titlebar              = titlebar
                 text_question         = text_question
                 display_cancel_button = abap_false
      IMPORTING  answer                = answer
      EXCEPTIONS OTHERS                = 0.

    result = xsdbool( answer = 1 ).
  ENDMETHOD.

  METHOD read_save_interco_doc_to_moni.
    DATA reclassification TYPE STANDARD TABLE OF ztbfi_trd_reclas WITH EMPTY KEY.

    SELECT FROM zcds_i_tradingdocuments
      FIELDS uuid( )                           AS documentuuid,
             purchaseaccountingdocument        AS accountingdocument,
             purchaseaccdocumentcompanycode    AS companycode,
             purchaseaccdocumentfiscalyear     AS fiscalyear,
             @status_trading_prcs-unprocessed  AS documentstatus,
             salesdocument,
             billingdocument,
             documentreferenceid,
             @line-postingdate                 AS to_postingdate,
             @line-quantityintransaction       AS quantityintransaction,
             @line-transactionquantityunit     AS transactionquantityunit,
             @line-amountintransactioncurrency AS amountintransactioncurrency,
             @line-transactioncurrency         AS transactioncurrency,
             @sy-datum                         AS createdatdate,
             @sy-uzeit                         AS createdattime,
             @sy-uname                         AS createdby
      WHERE companycode = @line-companycode
        AND documentreferenceid = @line-documentreferenceid
        AND purchaseaccountingdocument             IS NOT NULL
        AND settelementaccountingdocument          IS NULL
        AND \_tradingreclassification-DocumentUUID IS NULL
      INTO CORRESPONDING FIELDS OF TABLE @reclassification
      UP TO 1 ROWS.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE e070 INTO dummy_message.
      add_message_file( key          = line-%key
                        detail_level = '2' ).
      RETURN.
    ENDIF.

    INSERT ztbfi_trd_reclas FROM TABLE reclassification.
    commit_work_and_wait( ).

    MESSAGE s071 INTO dummy_message
            WITH reclassification[ 1 ]-AccountingDocument
                 reclassification[ 1 ]-CompanyCode
                 reclassification[ 1 ]-FiscalYear.

    add_message_file( key          = line-%key
                      detail_level = '2' ).

    result = reclassification[ 1 ]-%key.
  ENDMETHOD.

  METHOD create_settlement_acc_document.
    CHECK document->accountingdocumentsettlement IS INITIAL.

    DATA(obj_key) = VALUE bapiache09-obj_key( ).
    DATA(return) = VALUE bapiret2_tab( ).

    DATA(documentheader) =
        VALUE bapiache09( obj_type   = 'BKPFF'
                          doc_date   = sy-datum
                          doc_type   = document_settings-purchase_accounting_document-accountingdocumenttype
                          comp_code  = document->companycode
                          pstng_date = document->to_postingdate
                          ref_doc_no = document->documentreferenceid
                          header_txt = |{ document->salesdocument } Cost Adjustment|
                          username   = sy-uname ).

    DATA(accountgl) =
        VALUE bapiacgl09_tab(
                  gl_account = document_settings-purchase_accounting_document-glaccount
                  alloc_nmbr = document->documentreferenceid
                  item_text  = |{ document->salesdocument } Cost Adjustment|
                  ( itemno_acc = 1 profit_ctr = document_settings-purchase_accounting_document-fromprofitcenter )
                  ( itemno_acc = 2 profit_ctr = document_settings-purchase_accounting_document-toprofitcenter ) ).

    DATA(currencyamount) =
       VALUE bapiaccr09_tab( currency = document->purchaseinvoicecurrency
                             ( itemno_acc = 1 amt_doccur = document->difamountintransactioncurrency )
                             ( itemno_acc = 2 amt_doccur = ( document->difamountintransactioncurrency * -1 ) ) ).
    DATA(extension2) =
        VALUE bapiparextab( FOR idx = 1 UNTIL idx > 2
                            LET doc_ext_fi = VALUE ts_acc_doc_ext_fi( itemno   = idx
                                                                      xref1_hd = document->%dockey
                                                                      xref2_hd = document->billingdocument )
                            IN  ( extension_helper->fill_container( doc_ext_fi ) ) ).

    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING documentheader = documentheader
      IMPORTING obj_key        = obj_key
      TABLES    accountgl      = accountgl
                currencyamount = currencyamount
                extension2     = extension2
                return         = return.

    add_message_table_doc( messages         = return
                           documentcategory = doccattrading-settlementinvoice ).

    IF line_exists( return[ type = 'E' ] ).
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
    ELSE.
      document->%settlementdockey = obj_key.
*      commit_work_and_wait( ).
    ENDIF.

    update_document_db( CHANGING document = document->* ).
  ENDMETHOD.

  METHOD exception_to_bapiret2.
    CALL FUNCTION 'RS_EXCEPTION_TO_BAPIRET2'
      EXPORTING i_r_exception = exception
      CHANGING  c_t_bapiret2  = result.
  ENDMETHOD.
ENDCLASS.

"! <p class="shorttext synchronized" lang="es">Application Log</p>
CLASS zcl_application_log DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES ty_bal_s_msg_tab TYPE STANDARD TABLE OF bal_s_msg.
    TYPES:
      BEGIN OF ts_free_message,
        type      TYPE bapiret2-type,
        message   TYPE bapiret2-message,
        time_stmp TYPE baltimstmp,
        params    TYPE bal_s_parm,
      END OF ts_free_message.
    TYPES tt_free_message TYPE STANDARD TABLE OF ts_free_message.

    DATA control_handle TYPE balcnthndl.
    "! <p class="shorttext synchronized" lang="es">Log de aplicación: Programa de control de un log</p>
    DATA log_handle     TYPE balloghndl VALUE '' ##NO_TEXT.
    "! <p class="shorttext synchronized" lang="es">Log aplicación: Clase de problema de mensaje</p>
    DATA max_probclass  TYPE balprobcl  VALUE '' ##NO_TEXT.

    CONSTANTS:
      BEGIN OF bal_onsubscreen,
        prog  TYPE sy-repid VALUE 'SAPLSBAL_DISPLAY',
        dynnr TYPE sy-dynnr VALUE '0101',
      END OF bal_onsubscreen.

    "! <p class="shorttext synchronized" lang="es">Abre un nuevo registro</p>
    METHODS open
      IMPORTING  VALUE(log_object)    TYPE balobj_d
                 VALUE(log_subobject) TYPE balsubobj  DEFAULT ''
                 VALUE(extnumber)     TYPE balnrext   DEFAULT ''
                 VALUE(max_probclass) TYPE balprobcl  DEFAULT '2'
                 VALUE(default_msgid) TYPE symsgid    DEFAULT ''
                 VALUE(log_handle)    TYPE balloghndl OPTIONAL
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Añade un mensaje al registro de la aplicación</p>
    "!
    "! @parameter msgty         | <p class="shorttext synchronized" lang="es">Tipo de mensaje</p>
    "! @parameter msgid         | <p class="shorttext synchronized" lang="es">Clase de mensajes</p>
    "! @parameter msgno         | <p class="shorttext synchronized" lang="es">Número de mensaje</p>
    "! @parameter msgv1         | <p class="shorttext synchronized" lang="es">Variable de mensaje</p>
    "! @parameter msgv2         | <p class="shorttext synchronized" lang="es">Variable de mensaje</p>
    "! @parameter msgv3         | <p class="shorttext synchronized" lang="es">Variable de mensaje</p>
    "! @parameter msgv4         | <p class="shorttext synchronized" lang="es">Variable de mensaje</p>
    "! @parameter detail_level  | <p class="shorttext synchronized" lang="es">Log aplicación: Nivel de especificación</p>
    "! @exception logging_error | <p class="shorttext synchronized" lang="es">Logging API returned an error</p>
    METHODS add_message
      IMPORTING  msgty        TYPE symsgty  DEFAULT 'I'
                 msgid        TYPE symsgid  DEFAULT ''
                 msgno        TYPE symsgno
                 msgv1        TYPE symsgv   DEFAULT ''
                 msgv2        TYPE symsgv   DEFAULT ''
                 msgv3        TYPE symsgv   DEFAULT ''
                 msgv4        TYPE symsgv   DEFAULT ''
                 detail_level TYPE ballevel DEFAULT ''
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Añade mensaje al resgistro desde variable de sistema</p>
    METHODS add_system_message
      IMPORTING  iv_detail_level TYPE ballevel DEFAULT '5'
      EXCEPTIONS logging_error.

    METHODS add_freetext_message
      IMPORTING  !type        TYPE bapi_mtype
                 !text        TYPE bapi_msg
                 params       TYPE bal_s_parm OPTIONAL
                 detail_level TYPE ballevel   DEFAULT '1'
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Añade un mensaje BAL_S_MSG al registro de la aplicación</p>
    METHODS add_message_struct
      IMPORTING  log_message TYPE bal_s_msg
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Añade mensajes al registro desde una tabla</p>
    METHODS add_message_table
      IMPORTING  message_table TYPE ty_bal_s_msg_tab
      EXCEPTIONS logging_error.

    METHODS add_message_bapireturn_table
      IMPORTING  !messages TYPE ewa_bapireturn_tab
      EXCEPTIONS logging_error.

    METHODS add_message_bapiret2_table
      IMPORTING  !messages TYPE bapirettab
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Muestra el registro guardado</p>
    METHODS display
      EXCEPTIONS display_error.

    "! <p class="shorttext synchronized" lang="es">Muestra el registro guardado (Modo por Detalle-Nivel)</p>
    METHODS display_detlevel
      IMPORTING  modal TYPE abap_bool DEFAULT abap_false
      EXCEPTIONS display_error.

    METHODS control_refresh
      EXCEPTIONS display_error.

    METHODS display_oncontrol
      IMPORTING dsp_profile TYPE bal_s_prof
                container   TYPE REF TO cl_gui_container
      RAISING   cx_salv_msg.

    METHODS set_modal_to_profile
      IMPORTING coordinates            TYPE zst99_screen_coordinates
                VALUE(dsp_profile_in)  TYPE bal_s_prof
      RETURNING VALUE(dsp_profile_out) TYPE bal_s_prof.

    METHODS set_profile_detlevel
      IMPORTING tree_ontop         TYPE baltrontop               DEFAULT abap_true
                modal_coordinates  TYPE zst99_screen_coordinates OPTIONAL
                disvariant         TYPE disvariant
      RETURNING VALUE(dsp_profile) TYPE bal_s_prof.

    METHODS set_profile_single_log
      RETURNING VALUE(dsp_profile) TYPE bal_s_prof.

    METHODS output_init
      IMPORTING dsp_profile TYPE bal_s_prof.

    METHODS output_set_data
      EXCEPTIONS display_error.

    METHODS output_clear_and_refresh.

    METHODS output_free
      EXCEPTIONS display_error.

    METHODS delete_all_messages
      EXCEPTIONS logging_error.

    "! <p class="shorttext synchronized" lang="es">Escribe el registro de la aplicación en la base de datos</p>
    "!
    "! @parameter log_number | <p class="shorttext synchronized" lang="es">Log de aplicación: Número de log</p>
    METHODS close
      EXPORTING  log_number TYPE balognr
      EXCEPTIONS logging_error.

  PROTECTED SECTION.
    "! <p class="shorttext synchronized" lang="es">Clase de mensajes</p>
    DATA default_msgid         TYPE symsgid    VALUE '' ##NO_TEXT.
    "! <p class="shorttext synchronized" lang="es">Log aplicación: Identificación externa</p>
    DATA extnumber             TYPE balnrext   VALUE '' ##NO_TEXT.
    DATA log_control_open_flag TYPE c LENGTH 1.
    "! <p class="shorttext synchronized" lang="es">Log aplicación: Nombre objeto (sigla de aplicación)</p>
    DATA log_object            TYPE balobj_d   VALUE '' ##NO_TEXT.
    DATA log_open_flag         TYPE c LENGTH 1 VALUE '' ##NO_TEXT.
    "! <p class="shorttext synchronized" lang="es">Log aplicación: Objeto inferior</p>
    DATA log_subobject         TYPE balsubobj  VALUE '' ##NO_TEXT.
    DATA log_subsc_open_flag   TYPE c LENGTH 1.

  PRIVATE SECTION.
    "! <p class="shorttext synchronized" lang="es">Deriva la clase de problema del tipo de mensaje</p>
    METHODS get_probclass
      IMPORTING  VALUE(message_type)  TYPE symsgty
      RETURNING  VALUE(problem_class) TYPE balprobcl
      EXCEPTIONS logging_error.
ENDCLASS.


CLASS zcl_application_log IMPLEMENTATION.
  METHOD add_message.
    DATA msg TYPE bal_s_msg.

    msg-msgty    = msgty.
    msg-msgid    = msgid.
    msg-msgno    = msgno.
    msg-msgv1    = msgv1.
    msg-msgv2    = msgv2.
    msg-msgv3    = msgv3.
    msg-msgv4    = msgv4.
    msg-detlevel = detail_level.

    add_message_struct( EXPORTING  log_message   = msg
                        EXCEPTIONS logging_error = 1
                                   OTHERS        = 2 ).
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.
  ENDMETHOD.

  METHOD add_message_struct.
    DATA message TYPE bal_s_msg.

    message = log_message.
    " determine log level from message type
    get_probclass( EXPORTING  message_type  = message-msgty
                   RECEIVING  problem_class = message-probclass
                   EXCEPTIONS logging_error = 1
                              OTHERS        = 2 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.

    IF log_handle IS INITIAL OR message-probclass > max_probclass.
      RETURN.
    ENDIF.

    IF message-msgid IS INITIAL.
      message-msgid = default_msgid.
    ENDIF.
    IF message-msgid IS INITIAL.
      MESSAGE e001 WITH message-msgty message-msgno RAISING logging_error.
      " Message id initial. Message type: &, message number: &
    ENDIF.

    " why are the Sys Messages cleared. This will result in problems of some extractions.
    " therefore i comment this code. No regressions expected.
*    CLEAR: sy-msgid, sy-msgty, sy-msgno, sy-msgv1, sy-msgv2, sy-msgv3, sy-msgv4.

    IF message-detlevel IS INITIAL.
      message-detlevel = message-probclass.
    ENDIF.

    CONDENSE: message-msgv1, message-msgv2, message-msgv3, message-msgv4.
    " get time stamp field message-time_stmp.

    CALL FUNCTION 'BAL_LOG_MSG_ADD'
      EXPORTING  i_log_handle     = log_handle
                 i_s_msg          = message
      EXCEPTIONS log_not_found    = 1
                 msg_inconsistent = 2
                 log_is_full      = 3
                 OTHERS           = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.
  ENDMETHOD.

  METHOD add_message_table.
    DATA message TYPE bal_s_msg.

    LOOP AT message_table INTO message.
      add_message_struct( EXPORTING  log_message   = message
                          EXCEPTIONS logging_error = 1
                                     OTHERS        = 2 ).
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                RAISING logging_error.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD add_system_message.
    DATA ls_message TYPE bal_s_msg.

    " get system messages
    ls_message-msgty    = sy-msgty.
    ls_message-msgid    = sy-msgid.
    ls_message-msgno    = sy-msgno.
    ls_message-msgv1    = sy-msgv1.
    ls_message-msgv2    = sy-msgv2.
    ls_message-msgv3    = sy-msgv3.
    ls_message-msgv4    = sy-msgv4.

    ls_message-detlevel = iv_detail_level.

    add_message_struct( EXPORTING  log_message   = ls_message
                        EXCEPTIONS logging_error = 1
                                   OTHERS        = 2 ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.
  ENDMETHOD.

  METHOD close.
    DATA handle_table     TYPE bal_t_logh.
    DATA log_number_table TYPE bal_t_lgnm.
    DATA log_number_wa    TYPE bal_s_lgnm.

    CLEAR log_open_flag.

    IF log_handle IS NOT INITIAL.
      APPEND log_handle TO handle_table.

      CLEAR: sy-msgid,
             sy-msgty,
             sy-msgno,
             sy-msgv1,
             sy-msgv2,
             sy-msgv3,
             sy-msgv4.

      CALL FUNCTION 'BAL_DB_SAVE'
        EXPORTING  i_t_log_handle   = handle_table
        IMPORTING  e_new_lognumbers = log_number_table
        EXCEPTIONS log_not_found    = 1
                   save_not_allowed = 2
                   numbering_error  = 3
                   OTHERS           = 4.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                RAISING logging_error.
      ENDIF.
      READ TABLE log_number_table INDEX 1 INTO log_number_wa.
      log_number = log_number_wa-lognumber.

      IF sy-batch IS NOT INITIAL.
        CALL FUNCTION 'BP_ADD_APPL_LOG_HANDLE'
          EXPORTING  loghandle                  = log_handle
          EXCEPTIONS could_not_set_handle       = 1
                     not_running_in_batch       = 2
                     could_not_get_runtime_info = 3
                     handle_already_exists      = 4
                     locking_error              = 5
                     OTHERS                     = 6.
        IF sy-subrc IS INITIAL.
          MESSAGE s002 WITH |{ shift_left( val = log_number_wa-lognumber
                                           sub = '0' ) }|
                              log_object log_subobject.
        ENDIF.
      ENDIF.
    ELSE.
      CLEAR log_number.
    ENDIF.
  ENDMETHOD.

  METHOD display.
    DATA display_profile TYPE bal_s_prof.
    DATA t_log_handle    TYPE bal_t_logh.
    DATA mess_fcat       TYPE bal_s_fcat.
    DATA new_line        TYPE bal_s_fcat.

    CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      IMPORTING e_s_display_profile = display_profile.

    " add one line to display the time stamp.
    new_line-ref_table = 'BAL_S_SHOW'.
    new_line-ref_field = 'MSG_STMP'.
    new_line-no_out    = ''.
    new_line-outputlen = 20.
    new_line-col_pos   = 0.
    " determine highest column position
    LOOP AT display_profile-mess_fcat INTO mess_fcat WHERE col_pos <> 0.
      IF mess_fcat-col_pos > new_line-col_pos.
        new_line-col_pos = mess_fcat-col_pos.
      ENDIF.
    ENDLOOP.
    new_line-col_pos += 1.
    APPEND new_line TO display_profile-mess_fcat.

    display_profile-cwidth_opt = 'X'.
    APPEND me->log_handle TO t_log_handle.

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING  i_t_log_handle       = t_log_handle
                 i_s_display_profile  = display_profile
      EXCEPTIONS profile_inconsistent = 1
                 internal_error       = 2
                 no_data_available    = 3
                 no_authority         = 4
                 OTHERS               = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING display_error.
    ENDIF.
  ENDMETHOD.

  METHOD display_detlevel.
    DATA display_profile TYPE bal_s_prof.

    DATA(loghndls) = VALUE bal_t_logh( ( me->log_handle ) ).

    CALL FUNCTION 'BAL_DSP_PROFILE_DETLEVEL_GET'
      IMPORTING  e_s_display_profile = display_profile
      EXCEPTIONS OTHERS              = 1.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    display_profile = COND #( LET def_prof = VALUE bal_s_prof( BASE display_profile
                                                               disvariant-report = sy-repid
                                                               disvariant-handle = 'LOG' )
                              IN
                              WHEN modal = abap_true
                              THEN VALUE #( BASE def_prof
                                            start_col = 5
                                            start_row = 3
                                            end_col   = 70
                                            end_row   = 20
                                            pop_adjst = abap_true )
                              ELSE VALUE #( BASE def_prof
                                            cwidth_opt = abap_true ) ).

    CALL FUNCTION 'BAL_DSP_LOG_DISPLAY'
      EXPORTING  i_t_log_handle       = loghndls
                 i_s_display_profile  = display_profile
      EXCEPTIONS profile_inconsistent = 1
                 internal_error       = 2
                 no_data_available    = 3
                 no_authority         = 4
                 OTHERS               = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING display_error.
    ENDIF.
  ENDMETHOD.

  METHOD get_probclass.
    " determine log level from message type
    CASE message_type.
      WHEN 'E' OR 'A' OR 'X'.
        problem_class = '1'. " very important
      WHEN 'W'.
        problem_class = '2'. " important
      WHEN 'S'.
        problem_class = '3'. " medium
      WHEN 'I'.
        problem_class = '4'. " additional info
      WHEN OTHERS.
        MESSAGE e000 WITH message_type RAISING logging_error.
    ENDCASE.
  ENDMETHOD.

  METHOD open.
    DATA log_header    TYPE bal_s_log.
    DATA lt_log_handle TYPE bal_t_logh.

    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lt_log_loaded TYPE bal_t_logh.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lt_msg_handle TYPE bal_t_msgh.

    IF log_open_flag IS NOT INITIAL.
      RETURN.
    ENDIF.

    log_header-object    = log_object.
    log_header-subobject = log_subobject.
    log_header-extnumber = extnumber.
    me->max_probclass = max_probclass.
    IF me->max_probclass IS INITIAL.
      me->max_probclass = '4'.
    ENDIF.
    me->default_msgid = default_msgid.
    me->log_object    = log_object.
    me->log_subobject = log_subobject.
    me->extnumber     = extnumber.

    CLEAR: sy-msgid,
           sy-msgty,
           sy-msgno,
           sy-msgv1,
           sy-msgv2,
           sy-msgv3,
           sy-msgv4.

    " Sets the flag that the log is open. This is cleared by the close method.
    " One has to use a separate flag as the LOG_HANDLE is used by the DISPLAY method
    " after CLOSE. One can't clear the LOG_HANDLE in the CLOSE method.
    log_open_flag = 'X'.

    IF log_handle IS NOT INITIAL.
      " An existing log is reopened
      me->log_handle = log_handle.

      REFRESH lt_log_handle.
      APPEND log_handle TO lt_log_handle.

      CALL FUNCTION 'BAL_DB_LOAD'
        EXPORTING  i_t_log_handle     = lt_log_handle
        IMPORTING  e_t_log_handle     = lt_log_loaded
                   e_t_msg_handle     = lt_msg_handle
        EXCEPTIONS no_logs_specified  = 1
                   log_not_found      = 2
                   log_already_loaded = 3
                   OTHERS             = 4.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                RAISING logging_error.
      ENDIF.

    ELSE.
      CALL FUNCTION 'BAL_LOG_CREATE'
        EXPORTING  i_s_log                 = log_header
        IMPORTING  e_log_handle            = me->log_handle
        EXCEPTIONS log_header_inconsistent = 1
                   OTHERS                  = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                RAISING logging_error.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD add_freetext_message.
    DATA(probclass) = get_probclass( message_type = type ).

    CALL FUNCTION 'BAL_LOG_MSG_ADD_FREE_TEXT'
      EXPORTING  i_log_handle     = log_handle
                 i_msgty          = type
                 i_probclass      = probclass
                 i_text           = text
                 i_s_params       = params
                 i_detlevel       = detail_level
      EXCEPTIONS log_not_found    = 1
                 msg_inconsistent = 2
                 log_is_full      = 3
                 OTHERS           = 4.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.
  ENDMETHOD.

  METHOD add_message_bapireturn_table.
    DATA(converted_messages) =
        VALUE bapirettab( FOR msg IN messages
                          (  VALUE #( BASE CORRESPONDING #( msg )
                                      id     = msg-code(2)
                                      number = msg-code+2(3) ) ) ).

    add_message_bapiret2_table( converted_messages ).
  ENDMETHOD.

  METHOD add_message_bapiret2_table.
    DATA bal_msg TYPE bal_s_msg.

    GET TIME STAMP FIELD DATA(ts).

    LOOP AT messages INTO DATA(message).
      IF message-number IS INITIAL OR message-id IS INITIAL.
        add_freetext_message( EXPORTING  type          = message-type
                                         text          = message-message
                              EXCEPTIONS logging_error = 1
                                         OTHERS        = 2 ).
        IF sy-subrc IS NOT INITIAL.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                  RAISING logging_error.
        ENDIF.
      ELSE.
        bal_msg = VALUE #( msgty     = message-type
                           msgid     = message-id
                           msgno     = message-number
                           msgv1     = message-message_v1
                           msgv2     = message-message_v2
                           msgv3     = message-message_v3
                           msgv4     = message-message_v4
                           time_stmp = ts ).

        add_message_struct( EXPORTING  log_message   = bal_msg
                            EXCEPTIONS logging_error = 1
                                       OTHERS        = 2 ).
        IF sy-subrc IS NOT INITIAL.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
                  RAISING logging_error.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD control_refresh.
    DATA(loghndls) = VALUE bal_t_logh( ( log_handle ) ).

    CALL FUNCTION 'BAL_CNTL_REFRESH'
      EXPORTING  i_control_handle = control_handle
                 i_t_log_handle   = loghndls
      EXCEPTIONS OTHERS           = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING display_error.
    ENDIF.
  ENDMETHOD.

  METHOD display_oncontrol.
    DATA(loghndls) = VALUE bal_t_logh( ( log_handle ) ).

    IF log_control_open_flag IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF container IS NOT BOUND OR container IS INITIAL.
      RAISE EXCEPTION NEW cx_salv_msg( msgid = 'SALV_EXCEPTION'
                                       msgno = 025 ).
    ENDIF.

    CALL FUNCTION 'BAL_CNTL_CREATE'
      EXPORTING  i_container          = container
                 i_s_display_profile  = dsp_profile
                 i_t_log_handle       = loghndls
      IMPORTING  e_control_handle     = control_handle
      EXCEPTIONS profile_inconsistent = 1
                 internal_error       = 2
                 OTHERS               = 3.
    IF sy-subrc IS NOT INITIAL.
      RAISE EXCEPTION NEW cx_salv_msg( msgid = sy-msgid
                                       msgty = sy-msgty
                                       msgno = sy-msgno
                                       msgv1 = sy-msgv1
                                       msgv2 = sy-msgv2
                                       msgv3 = sy-msgv3
                                       msgv4 = sy-msgv4 ).
    ENDIF.

    log_control_open_flag = abap_true.
  ENDMETHOD.

  METHOD delete_all_messages.
    CALL FUNCTION 'BAL_LOG_MSG_DELETE_ALL'
      EXPORTING  i_log_handle = log_handle
      EXCEPTIONS OTHERS       = 1.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING logging_error.
    ENDIF.
  ENDMETHOD.

  METHOD output_clear_and_refresh.
    delete_all_messages( ).
    output_set_data( ).
  ENDMETHOD.

  METHOD output_free.
    CALL FUNCTION 'BAL_DSP_OUTPUT_FREE'
      EXCEPTIONS OTHERS = 1.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING display_error.
    ENDIF.
  ENDMETHOD.

  METHOD output_init.
    IF log_subsc_open_flag IS NOT INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BAL_DSP_OUTPUT_INIT'
      EXPORTING i_s_display_profile = dsp_profile.

    log_subsc_open_flag = abap_true.
  ENDMETHOD.

  METHOD output_set_data.
    DATA(loghndls) = VALUE bal_t_logh( ( me->log_handle ) ).

    CALL FUNCTION 'BAL_DSP_OUTPUT_SET_DATA'
      EXPORTING  i_t_log_handle       = loghndls
      EXCEPTIONS internal_error       = 1
                 profile_inconsistent = 2
                 OTHERS               = 3.
    IF sy-subrc IS NOT INITIAL.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4
              RAISING display_error.
    ENDIF.
  ENDMETHOD.

  METHOD set_modal_to_profile.
    dsp_profile_out = VALUE #( BASE dsp_profile_in
                               start_col = coordinates-starting_x
                               start_row = coordinates-starting_y
                               end_col   = coordinates-ending_x
                               end_row   = coordinates-ending_y
                               pop_adjst = abap_true ).
  ENDMETHOD.

  METHOD set_profile_detlevel.
    " TODO: parameter MODAL_COORDINATES is never used (ABAP cleaner)

    CALL FUNCTION 'BAL_DSP_PROFILE_DETLEVEL_GET'
      IMPORTING e_s_display_profile = dsp_profile.

    dsp_profile = VALUE #( BASE dsp_profile
                           disvariant = disvariant
                           tree_ontop = tree_ontop
                           tree_size  = SWITCH #( tree_ontop WHEN abap_false THEN 80 ELSE dsp_profile-tree_size )
                           exp_level  = 9
                           cwidth_opt = abap_true ).
  ENDMETHOD.

  METHOD set_profile_single_log.
    CALL FUNCTION 'BAL_DSP_PROFILE_SINGLE_LOG_GET'
      IMPORTING e_s_display_profile = dsp_profile.

    dsp_profile = VALUE #( BASE dsp_profile
                           cwidth_opt = abap_true
                           mess_fcat  = VALUE #( BASE dsp_profile-mess_fcat
                                                 ( ref_table = 'BAL_S_SHOW'
                                                   ref_field = 'MSG_STMP'
                                                   no_out    = space
                                                   outputlen = 20
                                                   col_pos   = REDUCE #( INIT max = VALUE int4( )
                                                                         FOR row IN dsp_profile-mess_fcat
                                                                         NEXT max = COND #( WHEN row-col_pos > max
                                                                                            THEN row-col_pos
                                                                                            ELSE max ) ) + 1 ) ) ).
  ENDMETHOD.
ENDCLASS.

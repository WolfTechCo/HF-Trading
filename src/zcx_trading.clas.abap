"! <p class="shorttext synchronized" lang="es">Superclass for Trading process exception</p>
CLASS zcx_trading DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_dyn_msg.
    INTERFACES if_t100_message.
    INTERFACES if_abap_behv_message.

    ALIASES default_textid FOR if_t100_message~default_textid.
    ALIASES msgty          FOR if_t100_dyn_msg~msgty.
    ALIASES msgv1          FOR if_t100_dyn_msg~msgv1.
    ALIASES msgv2          FOR if_t100_dyn_msg~msgv2.
    ALIASES msgv3          FOR if_t100_dyn_msg~msgv3.
    ALIASES msgv4          FOR if_t100_dyn_msg~msgv4.
    ALIASES severity       FOR if_abap_behv_message~m_severity.
    ALIASES t100key        FOR if_t100_message~t100key.
    ALIASES t_severity     FOR if_abap_behv_message~t_severity.

    "! <p class="shorttext synchronized" lang="es">CONSTRUCTOR</p>
    METHODS constructor
      IMPORTING textid    LIKE if_t100_message=>t100key OPTIONAL
                !previous LIKE previous                 OPTIONAL
                msgty     TYPE symsgty                  OPTIONAL
                msgv1     TYPE symsgv                   OPTIONAL
                msgv2     TYPE symsgv                   OPTIONAL
                msgv3     TYPE symsgv                   OPTIONAL
                msgv4     TYPE symsgv                   OPTIONAL
                severity  TYPE t_severity               OPTIONAL.

  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS ZCX_TRADING IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( previous = previous ).
    me->msgty    = msgty.
    me->msgv1    = msgv1.
    me->msgv2    = msgv2.
    me->msgv3    = msgv3.
    me->msgv4    = msgv4.
    me->severity = severity.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

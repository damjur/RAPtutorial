CLASS zdj_cx_tutpos_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_abap_behv_message .
    INTERFACES if_t100_message .
    INTERFACES if_t100_dyn_msg .

    METHODS constructor
      IMPORTING
        !textid   LIKE if_t100_message=>t100key OPTIONAL
        !previous LIKE previous OPTIONAL
        !var1     TYPE string OPTIONAL.

    CONSTANTS:
      BEGIN OF no_unit,
        msgid TYPE symsgid VALUE 'ZDJ_MC_TUTPOS',
        msgno TYPE symsgno VALUE '000',
        attr1 TYPE scx_attrname VALUE 'VAR1',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_unit ,
      BEGIN OF no_currency,
        msgid TYPE symsgid VALUE 'ZDJ_MC_TUTPOS',
        msgno TYPE symsgno VALUE '001',
        attr1 TYPE scx_attrname VALUE 'VAR1',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_currency,
      BEGIN OF no_items,
        msgid TYPE symsgid VALUE 'ZDJ_MC_TUTPOS',
        msgno TYPE symsgno VALUE '002',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF no_items,
      BEGIN OF adjust_numbers,
        msgid TYPE symsgid VALUE 'ZDJ_MC_TUTPOS',
        msgno TYPE symsgno VALUE '003',
        attr1 TYPE scx_attrname VALUE '',
        attr2 TYPE scx_attrname VALUE '',
        attr3 TYPE scx_attrname VALUE '',
        attr4 TYPE scx_attrname VALUE '',
      END OF adjust_numbers .
  PROTECTED SECTION.
    DATA:var1 TYPE string .
  PRIVATE SECTION.
ENDCLASS.



CLASS zdj_cx_tutpos_error IMPLEMENTATION.


  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    CALL METHOD super->constructor
      EXPORTING
        previous = previous.
    CLEAR me->textid.
    IF textid IS INITIAL.
      if_t100_message~t100key = if_t100_message=>default_textid.
    ELSE.
      if_t100_message~t100key = textid.
    ENDIF.

    me->if_abap_behv_message~m_severity = if_abap_behv_message=>severity-error .
    me->var1 = var1 .
  ENDMETHOD.
ENDCLASS.

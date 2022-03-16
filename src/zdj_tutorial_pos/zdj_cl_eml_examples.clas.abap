CLASS zdj_cl_eml_examples DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
    METHODS:
      simple_select IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      select_fields IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      select_all_fields IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      select_by_association IMPORTING out TYPE REF TO if_oo_adt_classrun_out,
      select_errors  IMPORTING out TYPE REF TO if_oo_adt_classrun_out.
  PRIVATE SECTION.
ENDCLASS.



CLASS zdj_cl_eml_examples IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
*    simple_select( out ).
*    select_all_fields( out ).
*    select_fields( out ).
*    select_by_association( out ).
*    select_errors( out ).
  ENDMETHOD.



  METHOD select_all_fields.
    READ ENTITIES OF zdj_i_tutposheader
        ENTITY tutposheader
        ALL FIELDS
        WITH VALUE #( ( id = '0000000001' ) )
        RESULT DATA(result)
        .

    out->write( result ).
  ENDMETHOD.

  METHOD select_by_association.
    READ ENTITIES OF zdj_i_tutposheader
        ENTITY tutposheader BY \_items
        ALL FIELDS
        WITH VALUE #( ( id = '0000000001' ) )
        RESULT DATA(result)
        .

    out->write( result ).
  ENDMETHOD.

  METHOD select_fields.
    READ ENTITIES OF zdj_i_tutposheader
        ENTITY tutposheader
        FIELDS ( id description )
        WITH VALUE #( ( id = '0000000001' ) )
        RESULT DATA(result)
        .

    out->write( result ).
  ENDMETHOD.

  METHOD simple_select.
    READ ENTITIES OF zdj_i_tutposheader
        ENTITY tutposheader
        FROM VALUE #( ( id = '0000000001' ) )
        RESULT DATA(result)
        .

    out->write( result ).

  ENDMETHOD.

  METHOD select_errors.
    READ ENTITIES OF zdj_i_tutposheader
        ENTITY tutposheader
        FROM VALUE #( ( id = 'X' ) )
        RESULT DATA(result)
        FAILED DATA(failed)
        .

    out->write( result ).
    out->write( failed-tutposheader ).
    out->write( failed-tutposheader[ 1 ]-%fail ).
  ENDMETHOD.

ENDCLASS.

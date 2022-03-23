CLASS zcl_dj_tutorial_hello_world DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      ty_lt_partners TYPE STANDARD TABLE OF i_businesspartner WITH DEFAULT KEY.

    METHODS new_method
      RETURNING
        value(rt_partners) TYPE ty_lt_partners.
ENDCLASS.



CLASS zcl_dj_tutorial_hello_world IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA(lt_partners) = new_method( ).

    out->write( data = lt_partners name = CONV #( 'Partners'(002) ) ).
  ENDMETHOD.

  METHOD new_method.

    SELECT *
            FROM i_businesspartner
            INTO TABLE @rt_partners .

  ENDMETHOD.



ENDCLASS.

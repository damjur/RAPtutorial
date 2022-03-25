CLASS zdj_tutorial_hello_world_2 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PROTECTED SECTION.
    TYPES:
      ty_lt_partners TYPE STANDARD TABLE OF i_businesspartner WITH DEFAULT KEY.

    "! <p class="shorttext synchronized" lang="en">Test</p>
    "!
    "! @parameter rt_partners | <p class="shorttext synchronized" lang="en"> Test 1</p>
    METHODS get_partners
      RETURNING
        VALUE(rt_partners) TYPE ty_lt_partners.
  PRIVATE SECTION.
ENDCLASS.



CLASS zdj_tutorial_hello_world_2 IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA(lt_partners) = get_partners( ).

    out->write( data = lt_partners name = CONV #( 'Partners'(001) ) ).
  ENDMETHOD.


  METHOD get_partners.

    SELECT * FROM i_businesspartner INTO TABLE @rt_partners.

  ENDMETHOD.

ENDCLASS.

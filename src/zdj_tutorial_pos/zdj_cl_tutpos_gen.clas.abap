CLASS zdj_cl_tutpos_gen DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zdj_cl_tutpos_gen IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DELETE FROM zdj_tut_pos_head.
    DELETE FROM zdj_tut_pos_item.

    DATA: lt_headers TYPE TABLE OF zdj_tut_pos_head,
          lt_items   TYPE TABLE OF zdj_tut_pos_item.
    GET TIME STAMP FIELD  DATA(lv_timestamp).

    lt_headers = VALUE #(
        ( created_at = lv_timestamp creator = sy-uname currency = 'PLN'
          customer = 'Test Testowy' description = 'Test 1' id = '0000000001'
          modificator = sy-uname modified_at = lv_timestamp status = 'S' )
        ( created_at = lv_timestamp creator = sy-uname currency = 'PLN'
          customer = 'Test Testowy' description = 'Test 2' id = '0000000002'
          modificator = sy-uname modified_at = lv_timestamp status = 'C' )
        ( created_at = lv_timestamp creator = sy-uname currency = 'CZK'
          customer = 'Test Testowy' description = 'Test 3' id = '0000000003'
          modificator = sy-uname modified_at = lv_timestamp status = 'S' )
        ( created_at = lv_timestamp creator = sy-uname currency = 'PLN'
          customer = 'Testowy Test' description = 'Test 4' id = '0000000004'
          modificator = sy-uname modified_at = lv_timestamp status = 'S' )
        ( created_at = lv_timestamp creator = sy-uname currency = 'PLN'
          customer = 'Testowy Test' description = 'Test 5' id = '0000000005'
          modificator = sy-uname modified_at = lv_timestamp status = 'S' )
        ( created_at = lv_timestamp creator = sy-uname currency = 'PLN'
          customer = 'Testowy Test' description = 'Test 6' id = '0000000006'
          modificator = sy-uname modified_at = lv_timestamp status = 'S' )
    ).
    lt_items = VALUE #(
        ( description = 'Produkt A' id = '0000000001' item = '001'
          quantity = 2 unit = 'KG' unit_price = 13 )
        ( description = 'Produkt A' id = '0000000002' item = '001'
          quantity = 3 unit = 'KG' unit_price = 14 )
        ( description = 'Produkt A' id = '0000000002' item = '002'
          quantity = 4 unit = 'KG' unit_price = 15 )
        ( description = 'Produkt A' id = '0000000003' item = '001'
          quantity = 5 unit = 'KG' unit_price = 16 )
        ( description = 'Produkt A' id = '0000000003' item = '002'
          quantity = 6 unit = 'KG' unit_price = 17 )
        ( description = 'Produkt A' id = '0000000003' item = '003'
          quantity = 7 unit = 'KG' unit_price = 18 )
        ( description = 'Produkt A' id = '0000000004' item = '001'
          quantity = 8 unit = 'KG' unit_price = 19 )
        ( description = 'Produkt A' id = '0000000004' item = '002'
          quantity = 9 unit = 'KG' unit_price = 20 )
        ( description = 'Produkt A' id = '0000000004' item = '003'
          quantity = 10 unit = 'KG' unit_price = 21 )
        ( description = 'Produkt A' id = '0000000004' item = '004'
          quantity = 11 unit = 'KG' unit_price = 22 )
        ( description = 'Produkt A' id = '0000000005' item = '001'
          quantity = 1 unit = 'KG' unit_price = 5 )
        ( description = 'Produkt A' id = '0000000006' item = '001'
          quantity = 1 unit = 'KG' unit_price = -5 ) ).
    INSERT zdj_tut_pos_head FROM TABLE @lt_headers.
    CHECK sy-subrc = 0.
    INSERT zdj_tut_pos_item FROM TABLE @lt_items.
    CHECK sy-subrc = 0.

    out->write( 'Successfull generation' ).

  ENDMETHOD.
ENDCLASS.

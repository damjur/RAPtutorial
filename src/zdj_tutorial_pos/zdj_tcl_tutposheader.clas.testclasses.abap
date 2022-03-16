"!@testing ZDJ_I_TUTPOSHEADER
CLASS ltc_zdj_i_tutposheader
DEFINITION FINAL FOR TESTING
DURATION SHORT
RISK LEVEL HARMLESS.
  PRIVATE SECTION.

    CLASS-DATA:
      environment TYPE REF TO if_cds_test_environment.

    CLASS-METHODS:
      class_setup RAISING cx_static_check,
      class_teardown.

    DATA:
      act_results TYPE STANDARD TABLE OF zdj_i_tutposheadercalc WITH EMPTY KEY,
      lt_header   TYPE STANDARD TABLE OF zdj_tut_pos_head WITH EMPTY KEY,
      lt_item     TYPE STANDARD TABLE OF zdj_tut_pos_item WITH EMPTY KEY.

    METHODS:
      setup RAISING cx_static_check,
      prepare_testdata_set,
      no_item_overallprices FOR TESTING RAISING cx_static_check,
      one_item_overallprice FOR TESTING RAISING cx_static_check,
      two_item_overallprices FOR TESTING RAISING cx_static_check,
      three_item_overallprices FOR TESTING RAISING cx_static_check.

ENDCLASS.


CLASS ltc_zdj_i_tutposheader IMPLEMENTATION.

  METHOD class_setup.
    environment = cl_cds_test_environment=>create(
      i_for_entity      = 'ZDJ_I_TUTPOSHEADERCALC'
      test_associations = abap_true
      i_dependency_list = VALUE #(
        ( name = 'ZDJ_TUT_POS_HEAD' type = 'TABLE' )
        ( name = 'ZDJ_TUT_POS_ITEM' type = 'TABLE' )
      )
    ).
  ENDMETHOD.

  METHOD setup.
    environment->clear_doubles( ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD prepare_testdata_set.

    "Prepare test data for 'zdj_tut_pos_head'
    lt_header = VALUE #(
        ( id = '1' currency = 'PLN' )
        ( id = '2' currency = 'PLN' )
        ( id = '3' currency = 'PLN' )
        ( id = '4' currency = 'PLN' )
        ( id = '5' currency = 'PLN' ) ).
    lt_item = VALUE #(
        ( id = '2' item = '1' quantity = 2 unit_price = 3 )"nc
        ( id = '3' item = '1' quantity = 3 unit_price = 4 )"mc
        ( id = '3' item = '2' quantity = 4 unit_price = 5 )
        ( id = '4' item = '1' quantity = 5 unit_price = 6 )"hc
        ( id = '4' item = '2' quantity = 6 unit_price = 7 )
        ( id = '4' item = '3' quantity = 7 unit_price = 8 )
        ( id = '5' item = '1' quantity = 2 unit_price = -5 )"o
    ).
    environment->insert_test_data( i_data = lt_header ).
    environment->insert_test_data( i_data = lt_item ).

  ENDMETHOD.

  METHOD no_item_overallprices.
    prepare_testdata_set( ).
    SELECT *
        FROM zdj_i_tutposheadercalc
        WHERE id = '1'
        INTO TABLE @act_results.
    cl_abap_unit_assert=>assert_equals(
      act = sy-subrc
      exp = 4 ).
  ENDMETHOD.

  METHOD one_item_overallprice.
    prepare_testdata_set( ).
    SELECT *
        FROM zdj_i_tutposheadercalc
        WHERE id = '2'
        INTO TABLE @act_results.
    cl_abap_unit_assert=>assert_equals(
      act = act_results[ 1 ]-overallprice
      exp = 2 * 3 ).
  ENDMETHOD.

  METHOD two_item_overallprices.
    prepare_testdata_set( ).
    SELECT *
        FROM zdj_i_tutposheadercalc
        WHERE id = '3'
        INTO TABLE @act_results.
    cl_abap_unit_assert=>assert_equals(
      act = act_results[ 1 ]-overallprice
      exp = 3 * 4 + 4 * 5 ).
  ENDMETHOD.

  METHOD three_item_overallprices.
    prepare_testdata_set( ).
    SELECT *
        FROM zdj_i_tutposheadercalc
        WHERE id = '4'
        INTO TABLE @act_results.
    cl_abap_unit_assert=>assert_equals(
      act = act_results[ 1 ]-overallprice
      exp = 5 * 6 + 6 * 7 + 7 * 8 ).
  ENDMETHOD.

ENDCLASS.

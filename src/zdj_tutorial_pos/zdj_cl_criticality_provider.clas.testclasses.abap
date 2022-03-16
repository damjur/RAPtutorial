*"* use this source file for your ABAP unit test classes
CLASS ltcl_criticality_calculation DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    TYPES: BEGIN OF ty_result,
             criticality TYPE zdj_c_tutorialheader-criticality,
           END OF ty_result,
           tt_result TYPE STANDARD TABLE OF ty_result.
    METHODS:
      criticality_selected FOR TESTING RAISING cx_static_check,
      criticality_not_selected FOR TESTING RAISING cx_static_check,
      different_entity FOR TESTING RAISING cx_static_check,
      is_not_critical FOR TESTING RAISING cx_static_check,
      is_highly_critical FOR TESTING RAISING cx_static_check,
      is_critical FOR TESTING RAISING cx_static_check,
      is_undefined FOR TESTING RAISING cx_static_check,
      wasnt_asked FOR TESTING RAISING cx_static_check
      .
ENDCLASS.


CLASS ltcl_criticality_calculation IMPLEMENTATION.

  METHOD criticality_selected.
    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~get_calculation_info(
      EXPORTING
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
        iv_entity                  = 'ZDJ_C_TUTORIALHEADER'
      IMPORTING
        et_requested_orig_elements = DATA(lt_requested)
    ).

    cl_abap_unit_assert=>assert_table_contains( line = `OVERALLPRICE` table = lt_requested ).
  ENDMETHOD.

  METHOD different_entity.
    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~get_calculation_info(
      EXPORTING
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
        iv_entity                  = 'SOMERANDOMENTITY'
      IMPORTING
        et_requested_orig_elements = DATA(lt_requested)
    ).

    cl_abap_unit_assert=>assert_table_not_contains( line = `OVERALLPRICE` table = lt_requested ).
  ENDMETHOD.

  METHOD criticality_not_selected.
    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~get_calculation_info(
      EXPORTING
        it_requested_calc_elements = VALUE #( ( `SOMERANDOMNAME` ) )
        iv_entity                  = 'ZDJ_C_TUTORIALHEADER'
      IMPORTING
        et_requested_orig_elements = DATA(lt_requested)
    ).

    cl_abap_unit_assert=>assert_table_not_contains( line = `OVERALLPRICE` table = lt_requested ).
  ENDMETHOD.


  METHOD is_critical.
    DATA: lt_headers  TYPE STANDARD TABLE OF zdj_c_tutorialheader,
          lt_results  TYPE tt_result,
          lt_expected TYPE tt_result.
    lt_headers = VALUE #( ( overallprice = 50 ) ).
    lt_expected =  VALUE #( ( criticality = 2 ) ).

    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data           = lt_headers
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
      CHANGING
        ct_calculated_data         = lt_results
    ).

    cl_abap_unit_assert=>assert_equals( exp = lt_expected act = lt_results ).
  ENDMETHOD.

  METHOD is_highly_critical.
    DATA: lt_headers  TYPE STANDARD TABLE OF zdj_c_tutorialheader,
          lt_results  TYPE tt_result,
          lt_expected TYPE tt_result.
    lt_headers = VALUE #( ( overallprice = 500 ) ).
    lt_expected =  VALUE #( ( criticality = 1 ) ).

    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data           = lt_headers
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
      CHANGING
        ct_calculated_data         = lt_results
    ).

    cl_abap_unit_assert=>assert_equals( exp = lt_expected act = lt_results ).
  ENDMETHOD.

  METHOD is_not_critical.
    DATA: lt_headers  TYPE STANDARD TABLE OF zdj_c_tutorialheader,
          lt_results  TYPE tt_result,
          lt_expected TYPE tt_result.
    lt_headers = VALUE #( ( overallprice = 5 ) ).
    lt_expected =  VALUE #( ( criticality = 3 ) ).

    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data           = lt_headers
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
      CHANGING
        ct_calculated_data         = lt_results
    ).

    cl_abap_unit_assert=>assert_equals( exp = lt_expected act = lt_results ).
  ENDMETHOD.

  METHOD is_undefined.
    DATA: lt_headers  TYPE STANDARD TABLE OF zdj_c_tutorialheader,
          lt_results  TYPE tt_result,
          lt_expected TYPE tt_result.
    lt_headers = VALUE #( ( overallprice = -5 ) ).
    lt_expected =  VALUE #( ( criticality = 0 ) ).

    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data           = lt_headers
        it_requested_calc_elements = VALUE #( ( `CRITICALITY` ) )
      CHANGING
        ct_calculated_data         = lt_results
    ).

    cl_abap_unit_assert=>assert_equals( exp = lt_expected act = lt_results ).
  ENDMETHOD.

  METHOD wasnt_asked.
    DATA: lt_headers  TYPE STANDARD TABLE OF zdj_c_tutorialheader,
          lt_results  TYPE tt_result,
          lt_expected TYPE tt_result.
    lt_headers = VALUE #( ( overallprice = 5 ) ).
    lt_expected =  VALUE #( ( criticality = 0 ) ).


    NEW zdj_cl_criticality_provider( )->if_sadl_exit_calc_element_read~calculate(
      EXPORTING
        it_original_data           = lt_headers
        it_requested_calc_elements = VALUE #( ( `SOMERANDOMFIELD` ) )
      CHANGING
        ct_calculated_data         = lt_results
    ).

    cl_abap_unit_assert=>assert_equals( exp = lt_expected act = lt_results ).
  ENDMETHOD.

ENDCLASS.

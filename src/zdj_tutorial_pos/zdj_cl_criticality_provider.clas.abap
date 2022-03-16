CLASS zdj_cl_criticality_provider DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_sadl_exit_calc_element_read .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zdj_cl_criticality_provider IMPLEMENTATION.


  METHOD if_sadl_exit_calc_element_read~calculate.
    DATA: lt_calculated_data TYPE STANDARD TABLE OF zdj_c_tutorialheader .
    CHECK it_original_data IS NOT INITIAL .
    lt_calculated_data = CORRESPONDING #( it_original_data ).
    IF line_exists(
        it_requested_calc_elements[ table_line = `CRITICALITY` ] ).
      LOOP AT lt_calculated_data ASSIGNING FIELD-SYMBOL(<wa_original_data>).
        <wa_original_data>-criticality = COND #(
            WHEN <wa_original_data>-overallprice > 0 AND <wa_original_data>-overallprice <= 10 THEN 3
            WHEN <wa_original_data>-overallprice > 10 AND <wa_original_data>-overallprice <= 100 THEN 2
            WHEN <wa_original_data>-overallprice > 100 THEN 1
            ELSE 0
        ).
      ENDLOOP.
    ENDIF.
    ct_calculated_data = CORRESPONDING #( lt_calculated_data ).
  ENDMETHOD.


  METHOD if_sadl_exit_calc_element_read~get_calculation_info.
    CASE iv_entity.
      WHEN 'ZDJ_C_TUTORIALHEADER'.
        IF line_exists(
            it_requested_calc_elements[ table_line = `CRITICALITY` ] ).
          APPEND `OVERALLPRICE` TO et_requested_orig_elements .
        ENDIF.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.

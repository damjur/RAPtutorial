CLASS zcl_dj_products_via_rfc_s4h DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_dj_products_via_rfc_s4h IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    TYPES:
      tt_bapi_epm_product_id_range TYPE RANGE OF zi_dj_products_s4h-productid,
      tt_bapi_epm_supplier_name_ra TYPE RANGE OF zi_dj_products_s4h-suppliername,
      tt_bapi_epm_product_categ_ra TYPE RANGE OF zi_dj_products_s4h-category
      .
    DATA: lt_product TYPE STANDARD TABLE OF zi_dj_products_s4h .

    CHECK io_request->is_data_requested(  ).

    TRY.
        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_cloud_destination( 'S4H_DJ' ).
        DATA(lv_destination) = lo_destination->get_destination_name(  ).
      CATCH cx_root INTO DATA(lx_root).
    ENDTRY.

    TRY.
        DATA(lo_paging) = io_request->get_paging(  ).
        DATA(lo_filtering) = io_request->get_filter( ).
*        DATA(lt_fields) = io_request->get_requested_elements(  ).

        DATA(lv_top) = lo_paging->get_page_size(  ).
        DATA(lv_skip) = lo_paging->get_offset(  ).
        DATA(lv_maxrows) = lv_top + lv_skip .
        TRY.
            DATA(lt_condition) = lo_filtering->get_as_ranges( )."No support for OR operator
          CATCH cx_rap_query_filter_no_range .
        ENDTRY.


        IF line_exists( lt_condition[ name = 'PRODUCTID' ] ).
          DATA(lr_productid) = VALUE tt_bapi_epm_product_id_range( ).
          LOOP AT lt_condition[ name = 'PRODUCTID' ]-range INTO DATA(ls_range).
            APPEND CORRESPONDING #( ls_range ) TO lr_productid .
          ENDLOOP .
        ENDIF.
        IF line_exists( lt_condition[ name = 'SUPPLIERNAME' ] ).
          DATA(lr_suppliername) = VALUE tt_bapi_epm_supplier_name_ra( ).
          LOOP AT lt_condition[ name = 'SUPPLIERNAME' ]-range INTO ls_range.
            APPEND CORRESPONDING #( ls_range ) TO lr_productid .
          ENDLOOP .
        ENDIF.
        IF line_exists( lt_condition[ name = 'CATEGORY' ] ).
          DATA(lr_category) = VALUE tt_bapi_epm_product_categ_ra( ).
          LOOP AT lt_condition[ name = 'CATEGORY' ]-range INTO ls_range.
            APPEND CORRESPONDING #( ls_range ) TO lr_productid .
          ENDLOOP .
        ENDIF.
*        DATA(lv_select_string) = COND string(
*            WHEN lt_fields IS NOT INITIAL THEN REDUCE string( INIT res = '' sep = '' FOR ls_field IN lt_fields NEXT res = res && |{ sep }{ ls_field }| sep = ',' )
*            ELSE '*'
*        ).
        CALL FUNCTION 'BAPI_EPM_PRODUCT_GET_LIST'
          DESTINATION lv_destination
          EXPORTING
            max_rows              = lv_maxrows
          TABLES
            headerdata            = lt_product
            selparamproductid     = lr_productid
            selparamcategories    = lr_category
            selparamsuppliernames = lr_suppliername.

        IF io_request->is_total_numb_of_rec_requested( ).
          io_response->set_total_number_of_records( lines( lt_product ) ).
        ENDIF.

        io_response->set_data( lt_product ).
      CATCH cx_root INTO lx_root.
    ENDTRY.

  ENDMETHOD.
ENDCLASS.

CLASS zcl_dj_rfc_s4h DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.

    TYPES : BEGIN OF ty_bapi_epm_product_header,
              productid     TYPE c LENGTH 10,
              typecode      TYPE c LENGTH 2,
              category      TYPE c LENGTH 40,
              name          TYPE c LENGTH 255,
              description   TYPE c LENGTH 255,
              supplierid    TYPE c LENGTH 10,
              suppliername  TYPE c LENGTH 80,
              taxtarifcode  TYPE int1,
              measureunit   TYPE c LENGTH 3,
              weightmeasure TYPE p LENGTH 7 DECIMALS 3,
              weightunit    TYPE c LENGTH 3,
              price         TYPE p LENGTH 12 DECIMALS 4,
              currencycode  TYPE c LENGTH 5,
              width         TYPE p LENGTH 7 DECIMALS 3,
              depth         TYPE p LENGTH 7 DECIMALS 3,
              height        TYPE p LENGTH 7 DECIMALS 3,
              dimunit       TYPE c LENGTH 3,
              productpicurl TYPE c LENGTH 255,
            END OF ty_bapi_epm_product_header.

ENDCLASS.



CLASS zcl_dj_rfc_s4h IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    DATA: msg(500)   TYPE c,
          lv_result  TYPE c LENGTH 200,
          lt_product TYPE STANDARD TABLE OF  ty_bapi_epm_product_header.
    .
    TRY.
        DATA(lo_destination) = cl_rfc_destination_provider=>create_by_cloud_destination( i_name = 'S4H_DJ' ).
        DATA(lv_destination) = lo_destination->get_destination_name( ).
        CALL FUNCTION 'RFC_SYSTEM_INFO'
          DESTINATION lv_destination
          IMPORTING
            rfcsi_export          = lv_result
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.
        out->write( SWITCH #( sy-subrc
            WHEN 0 THEN lv_result
            WHEN 1 THEN |SYSTEM_FAILURE { msg }|
            WHEN 2 THEN |COMMUNICATION_FAILURE { msg }|
            WHEN 3 THEN |OTHERS|
        ) ).

        CALL FUNCTION 'BAPI_EPM_PRODUCT_GET_LIST'
          DESTINATION lv_destination
          EXPORTING
            max_rows              = 30
          TABLES
            headerdata            = lt_product
          EXCEPTIONS
            system_failure        = 1 MESSAGE msg
            communication_failure = 2 MESSAGE msg
            OTHERS                = 3.
        IF sy-subrc = 0.
          LOOP AT lt_product INTO DATA(ls_product).
            out->write( |{ ls_product-productid }   { ls_product-name }  { ls_product-category }  { ls_product-suppliername }  { ls_product-description }| ).
          ENDLOOP.
        ELSE.
          out->write( SWITCH #( sy-subrc
           WHEN 1 THEN |SYSTEM_FAILURE { msg }|
           WHEN 2 THEN |COMMUNICATION_FAILURE { msg }|
           WHEN 3 THEN |OTHERS|
       ) ).
        ENDIF.
      CATCH cx_root INTO DATA(lx_root).
        out->write( lx_root->get_text(  ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

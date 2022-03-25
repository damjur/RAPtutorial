CLASS zdj_cl_tutpos_gen2 DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
    METHODS report_results
      IMPORTING
                i_out          TYPE REF TO if_oo_adt_classrun_out
                i_failed       TYPE any
                i_reported     TYPE any
                i_phase_name   TYPE string
      RETURNING VALUE(proceed) TYPE abap_bool.
  PRIVATE SECTION.

    "! <p class="shorttext synchronized" lang="en">Test</p>
    "!
    "! @parameter i_out | <p class="shorttext synchronized" lang="en">Test 1</p>
    "! @parameter result | <p class="shorttext synchronized" lang="en">Test 2</p>
    METHODS delete
      IMPORTING
        i_out         TYPE REF TO if_oo_adt_classrun_out
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS create
      IMPORTING
        i_out         TYPE REF TO if_oo_adt_classrun_out
      RETURNING
        VALUE(result) TYPE abap_bool.
    METHODS commit
      IMPORTING
        i_out TYPE REF TO if_oo_adt_classrun_out
      RETURNING
        VALUE(result) type abap_bool.
ENDCLASS.



CLASS zdj_cl_tutpos_gen2 IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    CHECK delete( out ).

    CHECK create( out ).

    CHECK commit( out ).

    out->write( 'Finished.' ).

  ENDMETHOD.


  METHOD report_results.

    IF i_failed IS NOT INITIAL.
      i_out->write( 'There are errors:' ).
    ELSE.
      proceed = abap_true.
    ENDIF.
    IF i_reported IS NOT INITIAL.
      ASSIGN COMPONENT '%OWN' OF STRUCTURE i_reported TO FIELD-SYMBOL(<field>).
      DATA(structdescr) = CAST cl_abap_structdescr( cl_abap_structdescr=>describe_by_data( <field> ) ).
      CHECK structdescr->kind = cl_abap_structdescr=>kind_struct.

      LOOP AT structdescr->get_components(  ) INTO DATA(component).
        ASSIGN COMPONENT component-name OF STRUCTURE i_reported TO FIELD-SYMBOL(<table>).
        CHECK sy-subrc = 0.
        LOOP AT <table> ASSIGNING FIELD-SYMBOL(<row>).
          ASSIGN COMPONENT '%MSG' OF STRUCTURE <row> TO  FIELD-SYMBOL(<message>) .
          CHECK sy-subrc = 0.
          ASSIGN COMPONENT 'ID' OF STRUCTURE <row> TO  FIELD-SYMBOL(<key>) .
          DATA(message) = CAST if_abap_behv_message( <message> ).
          i_out->write( data = <key> && ':' && message->if_message~get_text( ) name = component-name ).
        ENDLOOP .
      ENDLOOP.
    ENDIF.

    i_out->write( |{ i_phase_name } phase finished| ).

  ENDMETHOD.


  METHOD delete.

    SELECT id FROM zdj_c_tutorialheader INTO TABLE @DATA(ids).

    MODIFY ENTITIES OF zdj_c_tutorialheader
        ENTITY header
        DELETE FROM VALUE #( FOR id IN ids ( id = id-id ) )
        FAILED DATA(failed_delete)
        REPORTED DATA(reported_delete).

    result = report_results(
      i_out        = i_out
      i_failed     = failed_delete
      i_reported   = reported_delete
      i_phase_name = 'DELETE' ).

  ENDMETHOD.


  METHOD create.

    DATA: headers TYPE TABLE FOR CREATE zdj_c_tutorialheader,
          items   TYPE TABLE FOR CREATE zdj_c_tutorialheader\_items.

    headers = VALUE #( (
        %cid = '1'
        description = 'Test 1'
        currency = 'PLN'
        customer = 'Tester Testowy'
    ) (
        %cid = '2'
        description = 'Test 2'
        currency = 'PLN'
        customer = 'Tester Testowy'
    ) (
        %cid = '3'
        description = 'Test 3'
        currency = 'CZK'
        customer = 'Tester Testowy'
    ) (
        %cid = '4'
        description = 'Test 4'
        currency = 'PLN'
        customer = 'Tester Testowy'
    ) (
        %cid = '5'
        description = 'Test 5'
        currency = 'PLN'
        customer = 'Tester Testowy'
    ) (
        %cid = '6'
        description = 'Test 6'
        currency = 'PLN'
        customer = 'Tester Testowy'
    ) ) .
    items = VALUE #( (
        %cid_ref = '1'
        %target = VALUE #( (
            %cid = '7'
            description = 'Test Product A'
            quantity = 2
            unit = 'KG'
            unitprice = 13
        )  ) ) (
        %cid_ref = '2'
        %target = VALUE #( (
            %cid = '8'
            description = 'Test Product A'
            quantity = 3
            unit = 'KG'
            unitprice = 14
        ) (
            %cid = '9'
            description = 'Test Product B'
            quantity = 4
            unit = 'KG'
            unitprice = 15
        )  ) ) (
        %cid_ref = '3'
        %target = VALUE #( (
            %cid = '10'
            description = 'Test Product A'
            quantity = 5
            unit = 'KG'
            unitprice = 16
        ) (
            %cid = '11'
            description = 'Test Product B'
            quantity = 6
            unit = 'KG'
            unitprice = 17
        ) (
            %cid = '12'
            description = 'Test Product C'
            quantity = 7
            unit = 'KG'
            unitprice = 18
        )  ) ) (
        %cid_ref = '4'
        %target = VALUE #( (
            %cid = '13'
            description = 'Test Product A'
            quantity = 8
            unit = 'KG'
            unitprice = 19
        ) (
            %cid = '14'
            description = 'Test Product B'
            quantity = 9
            unit = 'KG'
            unitprice = 20
        ) (
            %cid = '15'
            description = 'Test Product C'
            quantity = 10
            unit = 'KG'
            unitprice = 21
        ) (
            %cid = '16'
            description = 'Test Product D'
            quantity = 11
            unit = 'KG'
            unitprice = 22
        )  ) ) (
        %cid_ref = '5'
        %target = VALUE #( (
            %cid = '17'
            description = 'Test Product A'
            quantity = 1
            unit = 'KG'
            unitprice = 5
        )  )  ) (
        %cid_ref = '6'
        %target = VALUE #( (
            %cid = '18'
            description = 'Test Product A'
            quantity = 1
            unit = 'KG'
            unitprice = -5
        )  )
    ) ).

    MODIFY ENTITIES OF zdj_c_tutorialheader
      ENTITY header CREATE SET FIELDS WITH headers
      ENTITY header CREATE BY \_items SET FIELDS WITH items
      FAILED DATA(failed_create)
      REPORTED DATA(reported_create).

    result = report_results(
      i_out        = i_out
      i_failed     = failed_create
      i_reported   = reported_create
      i_phase_name = 'CREATE_HEADER' ).

  ENDMETHOD.


  METHOD commit.

    COMMIT ENTITIES
            RESPONSE OF zdj_c_tutorialheader
            FAILED DATA(failed_commit)
            REPORTED DATA(reported_commit).

    result = report_results(
      i_out        = i_out
      i_failed     = failed_commit
      i_reported   = reported_commit
      i_phase_name = 'COMMIT' ).

  ENDMETHOD.

ENDCLASS.

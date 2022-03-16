*CLASS lsc_zdj_i_tutposheader DEFINITION INHERITING FROM cl_abap_behavior_saver.
*
*  PROTECTED SECTION.
*
*    METHODS adjust_numbers REDEFINITION.
*
*ENDCLASS.
*
*CLASS lsc_zdj_i_tutposheader IMPLEMENTATION.
*
*  METHOD adjust_numbers.
*
*    LOOP AT mapped-tutposheader ASSIGNING FIELD-SYMBOL(<header>)  USING KEY entity WHERE id IS INITIAL.
*      TRY.
*          cl_numberrange_runtime=>number_get(
*            EXPORTING
*              object      = 'ZDJ_NR_ID'
*              nr_range_nr = '01'
*            IMPORTING
*              number      = DATA(id)
*          ).
*        CATCH cx_number_ranges.
*          APPEND VALUE #(
*            %key = <header>-%key
*            %state_area = 'ADJUST_NUMBERS'
*            %element-id = if_abap_behv=>mk-on
*            %msg = NEW zdj_cx_tutpos_error(
*              textid = zdj_cx_tutpos_error=>adjust_numbers
*            )
*        ) TO reported-tutposheader .
*      ENDTRY.
*      LOOP AT mapped-tutpositem ASSIGNING FIELD-SYMBOL(<item>) USING KEY entity WHERE %key-id IS INITIAL.
*        <item>-%key-id = id.
*      ENDLOOP.
*
*      <header>-%key-id = id .
*    ENDLOOP.
*
*    LOOP AT mapped-tutpositem ASSIGNING <item> USING KEY entity WHERE %key-id IS INITIAL.
*      <item>-%key-id = <item>-%tmp-id.
*    ENDLOOP.
*
*    SELECT id, item
*        FROM zdj_i_tutpositem
*        FOR ALL ENTRIES IN @mapped-tutpositem
*        WHERE id = @mapped-tutpositem-id
*        INTO TABLE @DATA(dbitems).
*
*    SORT dbitems BY id  ASCENDING  item DESCENDING.
*
*    SORT mapped-tutpositem BY id ASCENDING item DESCENDING.
*
*    CLEAR id.
*    DATA: item LIKE <item>-item .
*    LOOP AT mapped-tutpositem ASSIGNING <item> WHERE item IS INITIAL.
*      IF id <> <item>-id.
*        id = <item>-id .
*        IF line_exists( dbitems[ id = id ] ).
*          item = dbitems[ id = id ] + 1 .
*        ELSE.
*          item = <item>-item + 1 .
*        ENDIF.
*      ELSE.
*        item = item + 1.
*      ENDIF.
*
*      <item>-%key-item = item.
*    ENDLOOP.
*
*  ENDMETHOD.
*
*ENDCLASS.

CLASS lhc_tutpositem DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.
    CLASS-DATA: processedkeys TYPE TABLE FOR ACTION IMPORT zdj_i_tutpositem~recalcpriceint .
    METHODS:
      recalcprice FOR DETERMINE ON MODIFY IMPORTING keys FOR tutpositem~recalcprice,
      recalcpriceint FOR MODIFY IMPORTING keys FOR ACTION tutpositem~recalcpriceint .

    METHODS validateunit FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutpositem~validateunit.
    METHODS oncreate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR tutpositem~oncreate.

ENDCLASS.

CLASS lhc_tutpositem IMPLEMENTATION.

  METHOD recalcpriceint.
    TYPES: BEGIN OF ty_conversion_cube ,
             id                      TYPE zdj_i_tutpositem-id,
             item                    TYPE zdj_i_tutpositem-item,
             converted_currency      TYPE zdj_i_tutpositem-unitprice,
             converted_quantity      TYPE zdj_i_tutpositem-quantity,
             converted_currency_code TYPE zdj_i_tutpositem-currency,
           END OF ty_conversion_cube ,
           tt_conversion_cube TYPE STANDARD TABLE OF ty_conversion_cube WITH DEFAULT KEY.

    DATA(localkeys) = keys[].
    LOOP AT localkeys INTO DATA(localkey).
      CHECK line_exists( processedkeys[ KEY draft COMPONENTS %tky = localkey-%tky   ] ).
      DELETE localkeys.
    ENDLOOP .

    CHECK localkeys IS NOT INITIAL.

    APPEND LINES OF localkeys TO processedkeys .

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutpositem
      ALL FIELDS
      WITH CORRESPONDING #( localkeys )
      RESULT DATA(items).

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutpositem BY \_header
      ALL FIELDS
      WITH CORRESPONDING #( localkeys )
      RESULT DATA(headers).

    CHECK items IS NOT INITIAL .

    SELECT
        i~id,
        i~item,
        currency_conversion(
            amount = i~unitprice,
            source_currency = i~currency,
            target_currency = header~currency,
            exchange_rate_date = @sy-datum
        ) AS converted_currency,
        header~currency AS converted_currency_code
        FROM zdj_tutpos_ditem AS i
        INNER JOIN @headers AS header
            ON i~id = header~id
        WHERE header~currency <> i~currency
          AND i~currency <> @( VALUE #( ) )
          AND header~currency <> @( VALUE #(  ) )
        INTO TABLE @DATA(converted_currency_values)
    .

    SELECT
        i~id,
        i~item,
        unit_conversion(
            quantity = i~quantity,
            source_unit = i~unit,
            target_unit = item~unit
        ) AS converted_quantity

        FROM zdj_tutpos_ditem AS i
        INNER JOIN @items AS item
            ON i~id = item~id
            AND i~item = item~item
        WHERE i~unit <> item~unit
         AND i~unit <> @( VALUE #( ) )
         AND item~unit <> @( VALUE #( ) )
        INTO TABLE @DATA(converted_unit_values)
.

    DATA(convertkeys) = localkeys[] .
    DATA(pricekeys) = items[].
    DATA(converted_values) = VALUE tt_conversion_cube( ).
    LOOP AT pricekeys INTO DATA(item).
      DATA(converted_value) = VALUE ty_conversion_cube( ).
      IF line_exists( converted_currency_values[ id = item-id item = item-item ] ).
        converted_value = CORRESPONDING #( converted_currency_values[ id = item-id item = item-item ] ).
      ENDIF.
      IF line_exists( converted_unit_values[ id = item-id item = item-item ] ).
        converted_value = CORRESPONDING #( converted_unit_values[ id = item-id item = item-item ] ).
      ENDIF.

      IF converted_value IS NOT INITIAL .
        IF converted_value-converted_currency IS INITIAL.
          converted_value-converted_currency = item-unitprice .
        ENDIF.
        IF converted_value-converted_quantity IS INITIAL.
          converted_value-converted_quantity = item-quantity .
        ENDIF.
        APPEND converted_value TO converted_values .
        DELETE pricekeys .
      ELSE.
        DELETE convertkeys WHERE id = item-id AND item = item-item .
      ENDIF.
    ENDLOOP.

    IF convertkeys IS NOT INITIAL.
      MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
          ENTITY tutpositem
          UPDATE FIELDS ( unitprice quantity price currency )
          WITH VALUE #( FOR key IN convertkeys LET converted_value_tmp = converted_values[ id = key-id item = key-item ] IN (
              %tky = key-%tky
              unitprice = converted_value_tmp-converted_currency
              quantity = converted_value_tmp-converted_quantity
              price = converted_value_tmp-converted_currency * converted_value_tmp-converted_quantity
              currency = converted_value_tmp-converted_currency_code
          ) ) REPORTED DATA(reported_data)
          .
    ENDIF.

    IF pricekeys IS NOT INITIAL.
      MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
          ENTITY tutpositem
          UPDATE FIELDS (  price currency )
          WITH VALUE #( FOR item_tmp IN pricekeys (
              %tky = item_tmp-%tky
              price = item_tmp-unitprice * item_tmp-quantity
              currency = headers[ KEY entity COMPONENTS id = item_tmp-id ]-currency
          ) ) REPORTED DATA(reported_data2)
          .
    ENDIF.

    LOOP AT processedkeys INTO DATA(processedkey).
      CHECK line_exists( localkeys[ KEY draft COMPONENTS %tky = processedkey-%tky   ] ).
      DELETE processedkeys.
    ENDLOOP .

    reported = CORRESPONDING #( DEEP reported_data ).
    APPEND LINES OF reported_data2-%other TO reported-%other.
    APPEND LINES OF reported_data2-tutposheader TO reported-tutposheader.
    APPEND LINES OF reported_data2-tutpositem TO reported-tutpositem.
  ENDMETHOD.

  METHOD validateunit.
    CONSTANTS:lc_validate_unit TYPE string VALUE 'VALIDATE_UNIT'.
    DATA: a4cunits TYPE SORTED TABLE OF i_unitofmeasure WITH UNIQUE KEY unitofmeasure .

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem
        FIELDS ( unit )
        WITH CORRESPONDING #( keys )
        RESULT DATA(tutposunits).

    a4cunits = CORRESPONDING #( tutposunits DISCARDING DUPLICATES MAPPING unitofmeasure = unit EXCEPT * ).

    CHECK a4cunits IS NOT INITIAL .

    SELECT *
        FROM i_unitofmeasure
        FOR ALL ENTRIES IN @a4cunits
        WHERE unitofmeasure = @a4cunits-unitofmeasure
        ORDER BY PRIMARY KEY
        INTO TABLE @DATA(dbunits).

    LOOP AT tutposunits INTO DATA(tutposunit).
      APPEND VALUE #(
          %tky = tutposunit-%tky
          %state_area = lc_validate_unit
      ) TO reported-tutpositem .
      IF NOT line_exists( dbunits[ unitofmeasure = tutposunit-unit ] ).
        APPEND VALUE #( %tky = tutposunit-%tky ) TO failed-tutpositem .
        APPEND VALUE #(
          %tky = tutposunit-%tky
          %state_area = lc_validate_unit
          %element-unit = if_abap_behv=>mk-on
          %msg = NEW zdj_cx_tutpos_error(
            textid = zdj_cx_tutpos_error=>no_unit
            var1 = |{ tutposunit-unit ALPHA = OUT }|
          )
      ) TO reported-tutpositem .
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD recalcprice.

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem
        EXECUTE recalcpriceint
        FROM CORRESPONDING #( keys )
        REPORTED DATA(exec_result).

    reported = CORRESPONDING #( DEEP exec_result ).
  ENDMETHOD.

  METHOD oncreate.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem
        FIELDS ( currency )
        WITH CORRESPONDING #( keys )
        RESULT DATA(items)
        .
    DELETE items WHERE currency IS NOT INITIAL .
    CHECK items IS NOT INITIAL .

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem BY \_header
        FIELDS ( currency )
        WITH CORRESPONDING #( items )
        RESULT DATA(headers)
        .
    CHECK headers IS NOT INITIAL .

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem
        UPDATE FIELDS ( currency )
        WITH VALUE #( FOR item IN items (
            %tky = item-%tky
            currency = headers[ KEY entity COMPONENTS id = item-id ]-currency
        ) )
        REPORTED DATA(reported_data)
        .

    reported = CORRESPONDING #( DEEP reported_data ).
  ENDMETHOD.

ENDCLASS.

CLASS lhc_tutposheader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR tutposheader RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR tutposheader RESULT result.

    METHODS cancel FOR MODIFY
      IMPORTING keys FOR ACTION tutposheader~cancel RESULT result.

    METHODS changedescription FOR MODIFY
      IMPORTING keys FOR ACTION tutposheader~changedescription RESULT result.

    METHODS validateitemsexist FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutposheader~validateitemsexist.
    METHODS controlfieldsoncreate FOR DETERMINE ON SAVE
      IMPORTING keys FOR tutposheader~controlfieldsoncreate.

    METHODS controlfieldsonupdate FOR DETERMINE ON SAVE
      IMPORTING keys FOR tutposheader~controlfieldsonupdate.

    METHODS recalculateoveravllprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR tutposheader~recalculateoveravllprice.

    METHODS validatecurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutposheader~validatecurrency.

ENDCLASS.

CLASS lhc_tutposheader IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(headers).

    result = VALUE #( FOR header IN headers LET activation = COND #(
            WHEN header-%is_draft = if_abap_behv=>mk-on
            THEN if_abap_behv=>fc-o-enabled
            ELSE  if_abap_behv=>fc-o-disabled
        ) IN (
        %tky = header-%tky
        %action-cancel = activation
        %action-changedescription = activation
    ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD cancel.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutposheader
      UPDATE FIELDS ( status modifiedat modificator )
      WITH VALUE #( FOR key IN keys (
        %tky = key-%tky
        status = 'C'
        modifiedat = lv_timestamp
        modificator = sy-uname
      ) )
      FAILED failed
      REPORTED reported
      .

    READ  ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutposheader
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    result = VALUE #( FOR header IN headers ( %tky = header-%tky %param = header  ) ).
  ENDMETHOD.

  METHOD changedescription.
    GET TIME STAMP FIELD DATA(lv_timestamp).
    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutposheader
      UPDATE FIELDS ( description modifiedat modificator )
      WITH VALUE #( FOR key IN keys (
        %tky = key-%tky
        description = key-%param
        modifiedat = lv_timestamp
        modificator = sy-uname
      ) )
      FAILED failed
      REPORTED reported
      .

    READ  ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
      ENTITY tutposheader
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    result = VALUE #( FOR header IN headers ( %tky = header-%tky %param = header  ) ).
  ENDMETHOD.

  METHOD validateitemsexist.
    CONSTANTS: lc_validate_items TYPE string VALUE 'VALIDATE_ITEMS'.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader BY \_items
        FROM CORRESPONDING #( keys )
        RESULT DATA(items).

    LOOP AT keys INTO DATA(key).
      APPEND VALUE #(
        %tky = key-%tky
        %state_area = lc_validate_items
      ) TO reported-tutposheader .
      CHECK NOT line_exists( items[ KEY entity COMPONENTS id = key-id ] ).

      APPEND VALUE #( %tky = key-%tky ) TO failed-tutposheader .
      APPEND VALUE #(
          %tky = key-%tky
          %state_area = lc_validate_items
*          %element-currency = if_abap_behv=>mk-on
          %msg = NEW zdj_cx_tutpos_error(
            textid = zdj_cx_tutpos_error=>no_items
          )
      ) TO reported-tutposheader .

    ENDLOOP.

  ENDMETHOD.

  METHOD controlfieldsoncreate.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        FIELDS ( createdat creator status )
        WITH CORRESPONDING #( keys )
        RESULT DATA(headers).

*Zapewnienie idempotencji - tą metodę można wykonac ile razy ma się ochotę,
*a efekt będzie "ten sam":
    DELETE headers WHERE createdat IS NOT INITIAL .
    CHECK headers IS NOT INITIAL .

    GET TIME STAMP FIELD DATA(lv_timestamp).

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        UPDATE FIELDS ( createdat creator status )
        WITH VALUE #( FOR header IN headers (
            %tky = header-%tky
            createdat = lv_timestamp
            creator = sy-uname
        ) ) REPORTED DATA(reported_data).

    reported = CORRESPONDING #( DEEP reported_data ).

  ENDMETHOD.

  METHOD controlfieldsonupdate.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        FIELDS ( modifiedat modificator )
        WITH CORRESPONDING #( keys )
        RESULT DATA(headers).

    GET TIME STAMP FIELD DATA(lv_timestamp).
    DATA(lv_timestamp2) = CONV timestamp( lv_timestamp - 60 ).

    DELETE headers WHERE modifiedat IS NOT INITIAL AND modifiedat >= lv_timestamp2 .
    CHECK headers IS NOT INITIAL .

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        UPDATE FIELDS ( modifiedat modificator status )
        WITH VALUE #( FOR key IN keys (
            %tky = key-%tky
            modifiedat = lv_timestamp
            modificator = sy-uname
            status = 'S'
        ) ) REPORTED DATA(reported_data).

    reported = CORRESPONDING #( DEEP reported_data ).
  ENDMETHOD.

  METHOD recalculateoveravllprice.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader BY \_items
        FROM CORRESPONDING #( keys )
        RESULT DATA(items).

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutpositem
        EXECUTE recalcpriceint
        FROM CORRESPONDING #( items ).

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader BY \_items
        FIELDS ( price )
        WITH CORRESPONDING #( keys )
        RESULT items.

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        UPDATE FIELDS ( overallprice )
        WITH VALUE #( FOR key IN keys (
            %tky = key-%tky
            overallprice = REDUCE #(
                INIT x = '0.000'
                FOR item IN items
                USING KEY entity
                WHERE ( id = key-id )
                NEXT x += item-price
        ) ) ).

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        ALL FIELDS
        WITH CORRESPONDING #( keys )
        RESULT DATA(result)
        REPORTED DATA(execute_reported_headers).

    reported = CORRESPONDING #( DEEP execute_reported_headers ).
  ENDMETHOD.

  METHOD validatecurrency.
    CONSTANTS:lc_validate_currency TYPE string VALUE 'VALIDATE_CURRENCY'.
    DATA: a4ccurrencies TYPE SORTED TABLE OF i_currency WITH UNIQUE KEY currency .

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        FIELDS ( currency )
        WITH CORRESPONDING #( keys )
        RESULT DATA(tutposcurrencies).

    a4ccurrencies = CORRESPONDING #( tutposcurrencies DISCARDING DUPLICATES MAPPING currency = currency EXCEPT * ).

    CHECK a4ccurrencies IS NOT INITIAL .

    SELECT *
        FROM i_currency
        FOR ALL ENTRIES IN @a4ccurrencies
        WHERE currency = @a4ccurrencies-currency
        ORDER BY PRIMARY KEY
        INTO TABLE @DATA(dbcurrencies).

    LOOP AT tutposcurrencies INTO DATA(tutposcurrency).
      APPEND VALUE #(
          %tky = tutposcurrency-%tky
          %state_area = lc_validate_currency
      ) TO reported-tutposheader .
      IF NOT line_exists( dbcurrencies[ currency = tutposcurrency-currency ] ).
        APPEND VALUE #( %tky = tutposcurrency-%tky ) TO failed-tutposheader .
        APPEND VALUE #(
          %tky = tutposcurrency-%tky
          %state_area = lc_validate_currency
          %element-currency = if_abap_behv=>mk-on
          %msg = NEW zdj_cx_tutpos_error(
            textid = zdj_cx_tutpos_error=>no_currency
            var1 = |{ tutposcurrency-currency ALPHA = OUT }|
          )
      ) TO reported-tutposheader .
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

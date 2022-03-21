CLASS lhc_tutpositem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    CLASS-DATA: processedkeys TYPE TABLE FOR ACTION IMPORT zdj_i_tutpositem~recalcpriceint .

    METHODS recalcpriceint FOR MODIFY
      IMPORTING keys FOR ACTION tutpositem~recalcpriceint.

    METHODS oncreate FOR DETERMINE ON MODIFY
      IMPORTING keys FOR tutpositem~oncreate.

    METHODS recalcprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR tutpositem~recalcprice.

    METHODS validateunit FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutpositem~validateunit.

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
           tt_conversion_cube TYPE STANDARD
                    TABLE OF ty_conversion_cube WITH DEFAULT KEY.

    DATA(localkeys) = keys[].
    LOOP AT localkeys INTO DATA(localkey).
      CHECK line_exists( processedkeys[ KEY draft
                COMPONENTS %tky = localkey-%tky   ] ).
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

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader BY \_items
        FIELDS ( price )
        WITH CORRESPONDING #( headers )
        RESULT items.

    MODIFY ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        UPDATE FIELDS ( overallprice )
        WITH VALUE #( FOR header IN headers (
            %tky = header-%tky
            overallprice = REDUCE #(
                INIT x = '0.000'
                FOR itemtmp IN items
                USING KEY entity
                WHERE ( id = header-id )
                NEXT x += itemtmp-price
        ) ) ).

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

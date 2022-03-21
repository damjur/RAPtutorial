CLASS lhc_tutposheader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR tutposheader RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR tutposheader RESULT result.

    METHODS changedescription FOR MODIFY
      IMPORTING keys FOR ACTION tutposheader~changedescription RESULT result.

    METHODS validateitemsexist FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutposheader~validateitemsexist.
    METHODS controlfieldsoncreate FOR DETERMINE ON SAVE
      IMPORTING keys FOR tutposheader~controlfieldsoncreate.

    METHODS controlfieldsonupdate FOR DETERMINE ON SAVE
      IMPORTING keys FOR tutposheader~controlfieldsonupdate.

    METHODS: recalculateoveravllprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR tutposheader~recalculateoveravllprice.

    METHODS validatecurrency FOR VALIDATE ON SAVE
      IMPORTING keys FOR tutposheader~validatecurrency.

    METHODS cancel FOR MODIFY
      IMPORTING keys FOR ACTION tutposheader~cancel RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR tutposheader RESULT result.

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
        %action-cancel = SWITCH #( header-status WHEN 'C' THEN if_abap_behv=>fc-o-disabled ELSE activation )
        %action-changedescription = activation
    ) ).
  ENDMETHOD.

  METHOD get_instance_authorizations.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        FIELDS ( status ) WITH CORRESPONDING #( keys )
        RESULT DATA(headers).

    AUTHORITY-CHECK OBJECT 'ZDJAUTPSTA' ID 'ZDJAFTPSTA' FIELD 'C' ID 'ACTVT' FIELD '02' .
    DATA(lv_decision_c) = SWITCH #( sy-subrc WHEN 0 THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ) .
    AUTHORITY-CHECK OBJECT 'ZDJAUTPSTA' ID 'ZDJAFTPSTA' FIELD 'S' ID 'ACTVT' FIELD '02' .
    DATA(lv_decision_s) = SWITCH #( sy-subrc WHEN 0 THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ) .

    result = VALUE #( FOR header IN headers LET lv_decision2 = SWITCH #(
         header-status
         WHEN 'C' THEN lv_decision_c
         WHEN 'S' THEN lv_decision_s
         ELSE if_abap_behv=>auth-allowed
        ) IN (
        %tky = header-%tky
        %update = lv_decision2
        %action-edit = lv_decision2
        %action-cancel = lv_decision2
        %action-changedescription = lv_decision2
    ) ).
  ENDMETHOD.

  METHOD get_global_authorizations.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM' ID 'TABLE' FIELD 'ZDJ_TUT_POS_HEAD' ID 'ACTVT' FIELD '02'.
    DATA(lv_decision) = SWITCH #( sy-subrc WHEN 0 THEN if_abap_behv=>auth-allowed ELSE if_abap_behv=>auth-unauthorized ) .
    result = VALUE #(
        %create = lv_decision
        %delete = lv_decision
        %update = lv_decision
        %action-edit = lv_decision
        %action-cancel = lv_decision
        %action-changedescription = lv_decision
    ).
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
      FIELDS ( description )
      WITH CORRESPONDING #( keys )
      RESULT DATA(headers).

    result = VALUE #( FOR header IN headers ( %tky = header-%tky %param = header  ) ).
  ENDMETHOD.

  METHOD validateitemsexist.
    CONSTANTS: lc_validate_items TYPE string VALUE 'VALIDATE_ITEMS'.
    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader
        FROM CORRESPONDING #( keys )
        RESULT DATA(headers).

    CHECK headers IS NOT INITIAL .

    READ ENTITIES OF zdj_i_tutposheader IN LOCAL MODE
        ENTITY tutposheader BY \_items
        FROM CORRESPONDING #( keys )
        RESULT DATA(items).

    LOOP AT headers INTO DATA(key).
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

    SELECT DISTINCT currency
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

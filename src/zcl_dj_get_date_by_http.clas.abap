"! <p class="shorttext synchronized" lang="en">Handlerclass for HTTP Service ZDJ_GET_DATE_BY_HTTP</p>
CLASS zcl_dj_get_date_by_http DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_http_service_extension .
    METHODS:
      "! <p class="shorttext synchronized" lang="en">Loads system date and formats it to be displayed in the browser</p>
      "!
      "! @parameter re_html | <p class="shorttext synchronized" lang="en">HTML with system date</p>
      get_html RETURNING VALUE(re_html) TYPE string
               RAISING
                         cx_abap_context_info_error.
  PROTECTED SECTION.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_dj_get_date_by_http IMPLEMENTATION.


  METHOD if_http_service_extension~handle_request.
    response->set_text( me->get_html(  ) ).
  ENDMETHOD.
  METHOD get_html.
    DATA(user_formatted_name) = cl_abap_context_info=>get_user_formatted_name( ).
    DATA(system_date) = cl_abap_context_info=>get_system_date( ) .

    re_html =  |<html> \n| &&
        |<body> \n| &&
        |<title>General Information</title> \n| &&
        |<p style="color:DodgerBlue;"> Hello there, { user_formatted_name } </p> \n | &&
        |<p> Today, the date is:  { system_date }| &&
        |<p> | &&
        |</body> \n| &&
        |</html> | .
  ENDMETHOD.

ENDCLASS.

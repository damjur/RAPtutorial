CLASS zcl_dj_streetmap DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_dj_streetmap IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.
    TRY.
        DATA(lo_destination) = cl_http_destination_provider=>create_by_cloud_destination(
          i_name       = 'Streetmap'
          i_authn_mode = if_a4c_cp_service=>service_specific
        ).

        DATA(lo_http_client) = cl_web_http_client_manager=>create_by_http_destination( i_destination = lo_destination ).
        DATA(lo_response) = lo_http_client->execute(
          i_method = if_web_http_client=>get
        ).
        out->write( lo_response->get_text(  ) ).
      CATCH cx_root INTO DATA(lx_error).
        out->write( lx_error->get_text(  ) ).
        out->write( lx_error->get_longtext(  ) ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.

CLASS zcl_cust DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA : lt_ledger TYPE TABLE OF ztb_customer,
           ls_ledger TYPE ztb_customer.
    INTERFACES if_rap_query_provider .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CUST IMPLEMENTATION.


  METHOD if_rap_query_provider~select.
    DATA(lv_top)     = io_request->get_paging( )->get_page_size( ).
    DATA(lv_skip)    = io_request->get_paging( )->get_offset( ).
    DATA(lt_clause)  = io_request->get_filter( )->get_as_sql_string( ).
    DATA(lt_fields)  = io_request->get_requested_elements( ).
    DATA(lt_sort)    = io_request->get_sort_elements( ).

    TRY.
        DATA(lt_filter_cond) = io_request->get_filter( )->get_as_ranges( ).
      CATCH cx_rap_query_filter_no_range INTO DATA(lx_no_sel_option).
    ENDTRY.

    DATA(lr_koart)   = VALUE #( lt_filter_cond[ name   = 'KOART' ]-range             OPTIONAL ).
    DATA(lr_ledger)    = VALUE #( lt_filter_cond[ name   = 'LEDGER' ]-range        OPTIONAL ).
    DATA(lr_companycode) = VALUE #( lt_filter_cond[ name   = 'COMPANYCODE' ]-range          OPTIONAL ).
    DATA(lr_kunnr)    = VALUE #( lt_filter_cond[ name   = 'KUNNR' ]-range          OPTIONAL ).
    DATA(lr_fromdt)   = VALUE #( lt_filter_cond[ name   = 'FROM_DT' ]-range           OPTIONAL ).
    DATA(lr_todate)   = VALUE #( lt_filter_cond[ name   = 'TO_DT' ]-range             OPTIONAL ).

    READ TABLE lr_fromdt INTO DATA(ls_fromdt) INDEX 1.
    IF sy-subrc = 0 AND ls_fromdt-low NE '00000000'.
      ls_ledger-from_dt = ls_fromdt-low.
    ENDIF.
    READ TABLE lr_todate INTO DATA(ls_todt) INDEX 1.
    IF sy-subrc = 0  AND ls_todt-low NE '00000000'.
      ls_ledger-to_dt = ls_todt-low.
    ENDIF.
    READ TABLE lr_ledger INTO DATA(ls_led) INDEX 1.
    IF sy-subrc = 0 AND ls_led-low IS NOT INITIAL.
      ls_ledger-ledger = ls_led-low.
    ENDIF.
    READ TABLE lr_koart INTO DATA(ls_koart) INDEX 1.
    IF sy-subrc = 0 AND ls_koart-low IS NOT INITIAL.
      ls_ledger-koart = ls_koart-low.
    ENDIF.
    READ TABLE lr_kunnr INTO DATA(ls_kunnr) INDEX 1.
    IF sy-subrc = 0 AND ls_kunnr-low IS NOT INITIAL.
      ls_ledger-kunnr = ls_kunnr-low.
    ENDIF.
    READ TABLE lr_companycode INTO DATA(ls_coco) INDEX 1.
    IF sy-subrc = 0 AND ls_coco-low IS NOT INITIAL.
      ls_ledger-companycode = ls_coco-low.
    ENDIF.

    IF ls_ledger IS NOT INITIAL.
      TRY.


          DATA lo_pfd TYPE REF TO zcl_cust_ledger_print.



          CREATE OBJECT lo_pfd.

          lo_pfd->get_pdf_64( EXPORTING
          io_koart = ls_ledger-koart
           io_ledger = ls_ledger-ledger
          io_companycode = ls_ledger-companycode
              io_kunnr = ls_ledger-kunnr
              io_from_dt = ls_ledger-from_dt
              io_to_dt = ls_ledger-to_dt
          RECEIVING pdf_64 = DATA(pdf_64) ).
          ls_ledger-base64 = pdf_64.
          APPEND ls_ledger TO lt_ledger.

          CLEAR ls_ledger.

          io_response->set_data( it_data = lt_ledger ).
          IF io_request->is_total_numb_of_rec_requested( ).
            io_response->set_total_number_of_records( iv_total_number_of_records = lines( lt_ledger ) ).

          ENDIF.
        CATCH cx_rap_query_response_set_twic.
        ##NO_HANDLER
      ENDTRY.
    ENDIF.


  ENDMETHOD.
ENDCLASS.

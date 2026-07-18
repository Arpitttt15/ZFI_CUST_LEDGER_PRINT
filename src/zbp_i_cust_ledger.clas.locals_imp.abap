CLASS lhc_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_date_buffer,
             customer      TYPE i_customer-customer,
             companycode   TYPE i_companycode-companycode,
             customer_name TYPE i_customer-customername,
             date_from     TYPE zdats,
             date_to       TYPE zdats,
           END OF ty_date_buffer.

    " Use strong unique key (important)
    CLASS-DATA: mt_date_buffer TYPE HASHED TABLE OF ty_date_buffer
                               WITH UNIQUE KEY customer companycode.
ENDCLASS.

CLASS lhc_buffer IMPLEMENTATION.
ENDCLASS.

CLASS lhc_zi_cust_ledger_doc DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR zi_cust_ledger_doc RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zi_cust_ledger_doc RESULT result.

    METHODS zprint FOR MODIFY
      IMPORTING keys FOR ACTION zi_cust_ledger_doc~zprint RESULT result.

ENDCLASS.

CLASS lhc_zi_cust_ledger_doc IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD zprint.

    " 1. Read current data
    READ ENTITIES OF zi_cust_ledger IN LOCAL MODE
      ENTITY zi_cust_ledger_doc
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_result).

    LOOP AT lt_result INTO DATA(lw_result).

      " Read action parameters
      READ TABLE keys INTO DATA(ls_key) WITH KEY %tky = lw_result-%tky.

      IF sy-subrc = 0 AND ls_key-%param-date_from IS NOT INITIAL.

        " Store full data in buffer
        INSERT VALUE #(
            customer       = lw_result-customer
            customer_name  = lw_result-customername
            date_from      = ls_key-%param-date_from
            date_to        = ls_key-%param-date_to
            companycode    = ls_key-%param-company_cd
        ) INTO TABLE lhc_buffer=>mt_date_buffer.

      ENDIF.

    ENDLOOP.


    " 2. Trigger save phase
    MODIFY ENTITIES OF zi_cust_ledger IN LOCAL MODE
      ENTITY zi_cust_ledger_doc
      UPDATE FIELDS ( base64 )
      WITH VALUE #(
        FOR k IN keys
        ( %tky = k-%tky base64 = 'A' )
      )
      REPORTED reported
      FAILED failed.


    " 3. Refresh UI
    result = VALUE #(
      FOR lw_res IN lt_result
      ( %tky = lw_res-%tky
        %param = lw_res )
    ).


    " 4. Success message
    APPEND VALUE #(
      %tky = keys[ 1 ]-%tky
      %msg = new_message_with_text(
        severity = if_abap_behv_message=>severity-success
        text     = 'PDF Generation Queued. Please wait 30 seconds.'
      )
    ) TO reported-zi_cust_ledger_doc.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_zi_cust_ledger DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_zi_cust_ledger IMPLEMENTATION.

  METHOD save_modified.

  LOOP AT update-zi_cust_ledger_doc INTO DATA(ls_update)
         WHERE base64 = 'A'.

      " Get buffer data
      READ TABLE lhc_buffer=>mt_date_buffer INTO DATA(ls_dates) "#EC CI_HASHSEQ
        WITH KEY customer = ls_update-customer.

      IF sy-subrc = 0.

        TRY.

            " Create BG operation with ALL parameters
            DATA(lo_op) = NEW zbg_cust_ledger(
              iv_bill          = ls_update-customer
              iv_m_ind         = abap_true
              iv_companycode   = ls_dates-companycode
              iv_customer_name = ls_dates-customer_name
              iv_date_from     = ls_dates-date_from
              iv_date_to       = ls_dates-date_to
            ).

            " Queue background job
            cl_bgmc_process_factory=>get_default( )->create(
              )->set_operation_tx_uncontrolled( lo_op
              )->save_for_execution( ).

            " Update DB table (FIXED TABLE NAME)
            MODIFY ztb_cust_ledger FROM @( VALUE #(
                client      = sy-mandt
                customer    = ls_update-customer
                base64      = 'PROCESSING'
                m_ind       = abap_true ) ).

          CATCH cx_bgmc INTO DATA(lx_bg).
            " Optional logging
        ENDTRY.

      ENDIF.

    ENDLOOP.

    " Cleanup buffer
    CLEAR lhc_buffer=>mt_date_buffer.

  ENDMETHOD.

ENDCLASS.

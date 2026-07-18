CLASS zbg_cust_ledger DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_bgmc_operation .
    INTERFACES if_bgmc_op_single_tx_uncontr .
    INTERFACES if_serializable_object .

    METHODS constructor
      IMPORTING
        iv_bill          TYPE i_customer-customer
        iv_m_ind         TYPE abap_boolean
        iv_companycode   TYPE i_companycode-companycode
        iv_customer_name TYPE i_customer-customername
        iv_date_from     TYPE i_operationalacctgdocitem-documentdate OPTIONAL
        iv_date_to       TYPE i_operationalacctgdocitem-documentdate OPTIONAL.



  PROTECTED SECTION.
    DATA : im_bill          TYPE  zde_ledger,
           im_ind           TYPE abap_boolean,
           im_companycode   TYPE i_companycode-companycode,
           im_customer_name TYPE i_customer-customername,
           im_date_from     TYPE i_operationalacctgdocitem-documentdate,
           im_date_to       TYPE i_operationalacctgdocitem-documentdate.
    METHODS modify
      RAISING
        cx_bgmc_operation.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZBG_CUST_LEDGER IMPLEMENTATION.


  METHOD constructor.
    im_bill = iv_bill.
    im_ind  = iv_m_ind.
    im_companycode = iv_companycode.
    im_customer_name = iv_customer_name.
    im_date_from = iv_date_from.
    im_date_to   = iv_date_to.
  ENDMETHOD.


  METHOD if_bgmc_op_single_tx_uncontr~execute.
    modify( ).
  ENDMETHOD.


  METHOD modify.
    DATA : wa_data TYPE ztb_cust_ledger.  "<-write your table name
    DATA :lv_pdftest TYPE string.
    DATA lo_pfd TYPE REF TO zcl_cust_ledger.  "<-write your logic class


    CREATE OBJECT lo_pfd.

    lo_pfd->get_pdf_64( EXPORTING io_customer = im_bill
                                       io_company_cd =  im_companycode
                                       io_customername = im_customer_name
                                       iv_date_from = im_date_from
        iv_date_to   = im_date_to
                                     RECEIVING pdf_64 = DATA(pdf_64) ).

    wa_data-customer    = im_bill.
    wa_data-company_cd = im_companycode.
    wa_data-base64 = pdf_64.
    wa_data-m_ind    = im_ind.

    MODIFY ztb_cust_ledger FROM @wa_data.  "<-write your table name

  ENDMETHOD.
ENDCLASS.

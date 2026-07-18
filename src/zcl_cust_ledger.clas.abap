CLASS zcl_cust_ledger DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    METHODS get_pdf_64
      IMPORTING
                VALUE(io_customer)     TYPE i_customer-customer    "<-write your input name and type
                VALUE(io_company_cd)   TYPE i_companycode-companycode
                VALUE(io_customername) TYPE i_customer-customername
                VALUE(iv_date_from)    TYPE zdats
                VALUE(iv_date_to)      TYPE zdats
      RETURNING VALUE(pdf_64)          TYPE string.

    METHODS convert_to_indian_format
      IMPORTING
        iv_amount        TYPE string
      RETURNING
        VALUE(rv_amount) TYPE string.



  PRIVATE SECTION.

    METHODS build_xml
      IMPORTING
        VALUE(io_customer)     TYPE i_customer-customer     "<-write your input name and type
        VALUE(io_company_cd)   TYPE i_companycode-companycode
        VALUE(io_customername) TYPE i_customer-customername
        VALUE(iv_date_from)    TYPE zdats
        VALUE(iv_date_to)      TYPE zdats
      RETURNING
        VALUE(rv_xml)          TYPE string.
ENDCLASS.



CLASS ZCL_CUST_LEDGER IMPLEMENTATION.


  METHOD get_pdf_64.

    DATA(lv_xml) = build_xml( io_customer = io_customer io_company_cd = io_company_cd io_customername = io_customername   iv_date_from = iv_date_from
      iv_date_to   = iv_date_to )  . " <- input param

    IF lv_xml IS INITIAL.
      RETURN.
    ENDIF.

    CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = 'ZCUST_LEDGER/ZCUST_LEDGER'
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.
      pdf_64 = lv_result.
    ENDIF.

  ENDMETHOD.


  METHOD build_xml.

    DATA lv_running_bal TYPE p DECIMALS 2 VALUE 0.
    DATA :lt_full_data           TYPE TABLE OF zce_ven_ledger,
          ls_full_data           TYPE zce_ven_ledger,
          lv_total_credit_am(16) TYPE p DECIMALS 2, "TYPE decfloat34,
          lv_total_debit_am(16)  TYPE p DECIMALS 2, "  TYPE decfloat34,
          lv_from_dt             TYPE string,
          lv_to_dt               TYPE string,
          lv_pos_dt              TYPE string,
          lv_fromdt              TYPE string,
          lv_todt                TYPE string,
          lv_closingstr          TYPE string,
          lv_openingstr          TYPE string,
          lv_supp_inv            TYPE i_billingdocument-purchaseorderbycustomer.

    DATA: company_nm        TYPE i_companycode-companycodename,
          company_addr(200) TYPE c.

    DATA lv_item_xml TYPE string.

    DATA :
      lv_debit_count      TYPE i VALUE 0,
      lv_credit_count     TYPE i VALUE 0,
      lv_closing_bal(16)  TYPE p DECIMALS 2 , "decfloat34 VALUE 0,
      lv_running_bal2(16) TYPE p DECIMALS 2, "TYPE decfloat34 VALUE 0,
      lv_balance(16)      TYPE p DECIMALS 2,
      lv_cin              TYPE i_bupaidentification-bpidentificationnumber.   "      TYPE decfloat34 VALUE 0.

    DATA: wa_po TYPE i_suplrinvcitempurordrefapi01,
          w_po  TYPE i_supplierinvoiceapi01.

    DATA: lv_amo_str   TYPE string,
          lv_amo_cdr   TYPE string,
          lv_debit_am  TYPE string,
          lv_credit_am TYPE string,
          ls_balances  TYPE string,
          lv_bal       TYPE string.

    SELECT SINGLE a~customer,
               a~customername,
               a~streetname,
               a~cityname,
               a~postalcode
   FROM i_customer WITH PRIVILEGED ACCESS AS a
   WHERE a~customer     = @io_customer
     AND customername = @io_customername
   INTO @DATA(ls_item).

    SELECT SINGLE SUM( amountincompanycodecurrency )
       FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS
       WHERE customer          = @io_customer
         AND companycode       = @io_company_cd
         AND postingdate      < @iv_date_from
         AND financialaccounttype = 'D'
         AND specialglcode        = ''
       INTO @lv_running_bal.

    IF lv_running_bal IS INITIAL.
      lv_running_bal = 0.
    ELSE.
      ls_full_data-narration   = 'Opening Balance'.
      ls_full_data-balance_inr = lv_running_bal.
      APPEND ls_full_data TO lt_full_data.
      CLEAR ls_full_data.
    ENDIF.

    IF  ls_item-customer IS NOT INITIAL.
      CLEAR : lv_cin .
      SELECT SINGLE bpidentificationnumber FROM  i_bupaidentification WHERE businesspartner =  @ls_item-customer
          AND bpidentificationtype = 'CIN' INTO @lv_cin .

    ENDIF.

    SELECT     a~companycode,
               a~fiscalyear,
               a~postingdate,
               a~accountingdocument,
               a~accountingdocumentitem,
               a~accountingdocumenttype,
               a~salesdocument,
               a~documentdate,
               a~documentitemtext,
               a~amountincompanycodecurrency,
               a~customer,
               a~debitcreditcode,
               a~originalreferencedocument,
               b~accountingdocumenttypename,
               c~purchaseorderbycustomer,
               c~assignmentreference

          FROM i_operationalacctgdocitem WITH PRIVILEGED ACCESS AS a
          LEFT OUTER JOIN i_accountingdocumenttypetext WITH PRIVILEGED ACCESS AS b
          ON a~accountingdocumenttype = b~accountingdocumenttype
          AND b~language = 'E'
          LEFT OUTER JOIN i_billingdocument AS c
          ON a~originalreferencedocument = c~billingdocument
          LEFT OUTER JOIN i_journalentry AS d
          ON a~accountingdocument = d~accountingdocument
          AND a~fiscalyear = d~fiscalyear
          AND a~companycode = d~companycode
          WHERE a~customer             = @io_customer
          AND a~companycode            = @io_company_cd
          AND financialaccounttype = 'D'
          AND specialglcode        = ''
*          and postingdate <= @iv_date_from
*          and postingdate >= @iv_date_to
          AND a~postingdate BETWEEN @iv_date_from AND @iv_date_to
          AND d~reversedocument IS INITIAL
          AND a~accountingdocumenttype <> 'SU'
          INTO TABLE @DATA(lt_items).

*    SORT lt_items BY accountingdocument ASCENDING.
    SORT lt_items BY postingdate ASCENDING.

    IF iv_date_from IS NOT INITIAL.

      lv_fromdt = |{ iv_date_from+6(2) }/{ iv_date_from+4(2) }/{ iv_date_from+0(4) }|.

    ENDIF.

    IF iv_date_to IS NOT INITIAL.

      lv_todt = |{ iv_date_to+6(2) }/{ iv_date_to+4(2) }/{ iv_date_to+0(4) }|.

    ENDIF.

    lv_openingstr = lv_running_bal .

    SELECT SINGLE * FROM i_companycode
    WHERE companycode = @io_company_cd
    INTO @DATA(company_data).

    SELECT SINGLE emailaddress FROM zi_addr_email
 WHERE addressid = @company_data-addressid
 INTO @DATA(wa_email).
    SELECT SINGLE * FROM z_i_address_2
 WHERE addressid = @company_data-addressid
 INTO @DATA(wa_addr).
    SELECT SINGLE * FROM i_regiontext
  WHERE region = @wa_addr-region
  INTO @DATA(wa_region).

    company_addr = |{ wa_addr-streetprefixname1 } { wa_addr-streetname } { wa_addr-streetsuffixname1 } { wa_addr-streetsuffixname2 } { wa_addr-streetprefixname1 }|.

    DATA(ledg_addr) = |{ ls_item-streetname },{ ls_item-cityname },{ ls_item-postalcode }|.

    DATA(lv_header_xml) =
    |<form1>| &&
    |<company_nm>{ zcl_excapexml=>escape_xml( company_data-companycodename ) }</company_nm>| &&
    |<addr>{ zcl_excapexml=>escape_xml( company_addr ) }</addr>|  &&
    |<region_pincode>{ zcl_excapexml=>escape_xml( |{ wa_addr-cityname } { wa_addr-postalcode }| ) }</region_pincode>|  &&
    | <state>{ zcl_excapexml=>escape_xml( wa_region-regionname ) }</state>| &&
    |<email>email : { zcl_excapexml=>escape_xml( wa_email ) }</email>| &&
    |<LedgerName>{ zcl_excapexml=>escape_xml( ls_item-customername ) }</LedgerName>| &&
    |<LedgerAddress>{ zcl_excapexml=>escape_xml( ledg_addr ) }</LedgerAddress>| &&
    |<from_dt>{ zcl_excapexml=>escape_xml( lv_fromdt ) }</from_dt>| &&
    |<to_dt>{ zcl_excapexml=>escape_xml( lv_todt ) }</to_dt>| &&
    |<Item>| &&
    |<Table1>| &&
    |<Row1>| &&
    |<opening_balance>{ zcl_excapexml=>escape_xml( lv_running_bal ) }</opening_balance>| &&
    |</Row1>|.




    lv_running_bal2 = lv_running_bal .
    LOOP AT lt_items INTO DATA(ls_items).

      DATA(ls_out) = VALUE zce_customer_ledger(
            journal_entry   = ls_items-accountingdocument
            line_item       = ls_items-accountingdocumentitem
            posting_date    = ls_items-postingdate
            customer        = ls_items-customer
            doc_type        = ls_items-accountingdocumenttype
            po_number       = ls_items-purchaseorderbycustomer
            invoice_no_date = |{ ls_items-originalreferencedocument+0(10) } / { ls_items-documentdate }|
            narration       = ls_items-documentitemtext
      ).



      " Format Posting Date (Corrected)
      IF ls_items-postingdate IS NOT INITIAL.
        lv_pos_dt = |{ ls_items-postingdate+6(2) }/{ ls_items-postingdate+4(2) }/{ ls_items-postingdate+0(4) }|.
      ENDIF.

      " Debit / Credit Logic + Count
      IF ls_items-debitcreditcode = 'S'.
        ls_out-debit_amount  = ls_items-amountincompanycodecurrency.
        lv_total_debit_am += ls_items-amountincompanycodecurrency.
        " Count Debit
        ADD 1 TO lv_debit_count.

      ELSEIF ls_items-debitcreditcode = 'H'.
        ls_out-credit_amount = abs( ls_items-amountincompanycodecurrency ).
        lv_total_credit_am  += ls_items-amountincompanycodecurrency .
        " Count Credit
        ADD 1 TO lv_credit_count.
      ENDIF.

      " Running Balance
      lv_running_bal2 += ls_items-amountincompanycodecurrency.
      ls_out-balance_inr = lv_running_bal2.

      APPEND ls_out TO lt_full_data.
      IF ls_items-purchaseorderbycustomer IS NOT INITIAL .
        lv_supp_inv = ls_items-purchaseorderbycustomer .
      ENDIF.

*      SELECT SINGLE * FROM i_suplrinvcitempurordrefapi01
*      WHERE supplierinvoice = @lv_supp_inv
*      AND   purchaseorder IS NOT INITIAL
*            INTO @DATA(wa_po).
*
*
*if wa_po-SupplierInvoice is not inITIAL.
*      SELECT SINGLE *
*      FROM i_supplierinvoiceapi01 WITH PRIVILEGED ACCESS
*      WHERE supplierinvoice = @lv_supp_inv
*      AND companycode      = @io_company_cd
*      INTO @DATA(w_po).
*endiF.

      " First attempt (with PO)
*      SELECT SINGLE *
*        FROM i_suplrinvcitempurordrefapi01
*        WHERE supplierinvoice = @lv_supp_inv
*          AND purchaseorder IS NOT INITIAL
*        INTO @wa_po.
*
*      IF wa_po-supplierinvoice IS NOT INITIAL.
*
*        " Found → go to header
*        SELECT SINGLE *
*          FROM i_supplierinvoiceapi01 WITH PRIVILEGED ACCESS
*          WHERE supplierinvoice = @lv_supp_inv
*            AND companycode     = @io_company_cd
*          INTO @w_po.
*
*      ELSE.

      " Fallback → without PO condition
      SELECT SINGLE documentreferenceid
        FROM i_journalentry
        WHERE  accountingdocument = @ls_items-accountingdocument
         AND  companycode     = @io_company_cd
         AND  documentreferenceid IS NOT INITIAL
        INTO  @DATA(lv_documentrefid).

      w_po-supplierinvoiceidbyinvcgparty = lv_documentrefid .
      CLEAR : lv_documentrefid .
*      ENDIF.

*    DELETE ADJACENT DUPLICATES FROM w_po COMPARING SupplierInvoiceIDByInvcgParty.

      lv_amo_str = |{ ls_out-debit_amount }|.
      CONDENSE lv_amo_str.

      lv_debit_am =
        convert_to_indian_format( iv_amount = lv_amo_str ).

      "-------------------------------------------------------------------------------
      lv_amo_cdr = |{ ls_out-credit_amount }|.
      CONDENSE lv_amo_cdr.

      lv_credit_am =
        convert_to_indian_format( iv_amount = lv_amo_cdr ).
      "-------------------------------------------------------------------------------
      lv_bal = |{ ls_out-balance_inr }|.
      CONDENSE lv_bal.

      ls_balances =
        convert_to_indian_format( iv_amount = lv_bal ).

      DATA(lv_narration) = ls_items-documentitemtext.

      REPLACE ALL OCCURRENCES OF 'This is an example text'
             IN lv_narration
             WITH ''.
      CONDENSE lv_narration.

      " XML Building
      lv_item_xml &&=
            |<Row2>| &&
            |<post_date>{ zcl_excapexml=>escape_xml( lv_pos_dt ) }</post_date>| &&
            |<doc_type>{ zcl_excapexml=>escape_xml( ls_items-accountingdocumenttype ) }</doc_type>| &&
            |<doc_desc>{ zcl_excapexml=>escape_xml( ls_items-accountingdocumenttypename ) }</doc_desc>| &&
            |<entry_no>{ zcl_excapexml=>escape_xml( ls_items-accountingdocument ) }</entry_no>| &&
            |<po_no>{ zcl_excapexml=>escape_xml( ls_items-purchaseorderbycustomer ) }</po_no>| &&
            |<inv_no_date>{ zcl_excapexml=>escape_xml( |{ ls_items-originalreferencedocument } { ls_items-documentdate }| ) }</inv_no_date>| &&
            |<narration>{ zcl_excapexml=>escape_xml( lv_narration ) }</narration>| &&
            |<debit_amt>{ zcl_excapexml=>escape_xml( lv_debit_am ) }</debit_amt>| &&
            |<credit_amt>{ zcl_excapexml=>escape_xml( lv_credit_am ) }</credit_amt>| &&
            |<balance>{ zcl_excapexml=>escape_xml( ls_balances ) }</balance>| &&
            |</Row2>|.

      " Totals


**      lv_total_debit_am  += ls_out-debit_amount.
**      lv_total_credit_am += ls_out-credit_amount.

      " Closing Balance (Corrected Logic)
      lv_balance += ls_out-balance_inr.
*  lv_closing_bal = lv_balance + lv_running_bal.
      CLEAR : lv_supp_inv , wa_po ,w_po.
    ENDLOOP.

    lv_closing_bal = lv_total_debit_am + lv_total_credit_am + lv_running_bal .
    lv_closingstr = lv_closing_bal .

*----By AM for ABS of Credit Total amount    06062026
    lv_total_credit_am = abs( lv_total_credit_am ).
*----By AM for ABS of Credit Total amount    06062026

    DATA: lv_amount_str    TYPE string,
          lv_amount_cdr    TYPE string,
          lv_amount_indian TYPE string,
          lv_total_debit   TYPE string,
          lv_total_credit  TYPE string,
          lv_clos_bal      TYPE string,
          lv_clo_bl        TYPE string.

    lv_amount_str = |{ lv_total_debit_am }|.
    CONDENSE lv_amount_str.

    lv_total_debit =
      convert_to_indian_format( iv_amount = lv_amount_str ).
*  ------------------------------------------------------------------------------------------

    lv_amount_cdr = |{ lv_total_credit_am }|.
    CONDENSE lv_amount_cdr.

    lv_total_credit =
      convert_to_indian_format( iv_amount = lv_amount_cdr ).
*  ------------------------------------------------------------------------------------------
    lv_clo_bl = |{ lv_closing_bal }|.
    CONDENSE lv_clo_bl.

    lv_clos_bal =
      convert_to_indian_format( iv_amount = lv_clo_bl ).



    DATA(lv_footer_xml) =
        |<Row3>| &&
        |<Deb_amt_tran_total>{ lv_total_debit }</Deb_amt_tran_total>| &&
        |<cred_amt_tran_total>{ lv_total_credit }</cred_amt_tran_total>| &&
        |</Row3>| &&
        |<Row4>| &&
        |<deb_amt_grand_total>{ lv_total_debit }</deb_amt_grand_total>| &&
        |<cred_amt_grand_total>{ lv_total_credit }</cred_amt_grand_total>| &&
        |</Row4>| &&
        |<Row5>| &&
        |<closing_bal>{ lv_clos_bal }</closing_bal>| &&
        |</Row5>| &&
        |</Table1>| &&
        |</Item>| &&
        |</form1>|.

*    rv_xml = lv_header_xml && lv_item_xml && lv_footer_xml.

    rv_xml = |{ lv_header_xml }{ lv_item_xml }{ lv_footer_xml }|.

    DATA(lv_len) = strlen( rv_xml ).

  ENDMETHOD.


  METHOD convert_to_indian_format.

    DATA: lv_int   TYPE string,
          lv_dec   TYPE string,
          lv_len   TYPE i,
          lv_left  TYPE string,
          lv_right TYPE string,
          lv_temp  TYPE string,
          lv_sign  TYPE string.  " <-- NEW

    rv_amount = iv_amount.
    CONDENSE rv_amount.

    " 🔥 Handle negative sign
    IF rv_amount CP '-*'.
      lv_sign = '-'.
      rv_amount = rv_amount+1. " remove minus
    ENDIF.

    " Split integer and decimal part
    SPLIT rv_amount AT '.' INTO lv_int lv_dec.

    lv_len = strlen( lv_int ).

    IF lv_len > 3.

      DATA(lv_off) = lv_len - 3.
      DATA lv_len2 TYPE i.

      " Last 3 digits
      lv_right = lv_int+lv_off(3).

      " Remaining digits
      lv_left  = lv_int(lv_off).

      WHILE strlen( lv_left ) > 2.

        lv_len2 = strlen( lv_left ) - 2.

        lv_temp = ',' && lv_left+lv_len2(2) && lv_temp.
        lv_left = lv_left(lv_len2).

      ENDWHILE.

      rv_amount = lv_left && lv_temp && ',' && lv_right.

    ELSE.
      rv_amount = lv_int.
    ENDIF.

    " Decimal handling
    IF lv_dec IS INITIAL.
      rv_amount = rv_amount && '.00'.
    ELSE.
      rv_amount = rv_amount && '.' && lv_dec+0(2).
    ENDIF.

    " 🔥 Add sign back
    rv_amount = lv_sign && rv_amount.

  ENDMETHOD.
ENDCLASS.

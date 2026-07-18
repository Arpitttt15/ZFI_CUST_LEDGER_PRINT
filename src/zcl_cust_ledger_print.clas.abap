CLASS zcl_cust_ledger_print DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA : lv_amount  TYPE dmbtr, "p DECIMALS 2,
           lv_balance TYPE p DECIMALS 2.
    TYPES : BEGIN OF ty_header ,
              address(250)   TYPE c,
              name(20)       TYPE c,
              date(60)       TYPE c,
              co_nm(30)      TYPE c,
              cust_addr(100) TYPE c,
              opening_bal    LIKE lv_amount,
            END OF ty_header.

    TYPES : BEGIN OF ty_table ,
              date1(15)         TYPE c,
              doc_type(50)      TYPE c,
              journal_entry(30) TYPE c,
              ass_ref(30)       TYPE c,
              vch_typ(30)       TYPE c,
              debit             LIKE lv_amount,
              credit            LIKE lv_amount,
              remarks(50)       TYPE c,
              balance           LIKE lv_amount,
            END OF ty_table.

    TYPES : BEGIN OF ty_footer ,
              close_bal        LIKE lv_amount,
              close_bal_debit  LIKE lv_amount,
              close_bal_credit LIKE lv_amount,
              debit_tot        LIKE lv_amount,
              credit_tot       LIKE lv_amount,
            END OF ty_footer.

    TYPES : BEGIN OF ty_dates,
              dt     TYPE string,
              dt_txt TYPE string,
            END OF ty_dates.

    TYPES: BEGIN OF ty_accdocjournal,
             companycode                TYPE i_accountingdocumentjournal-companycode,
             accountingdocument         TYPE i_accountingdocumentjournal-accountingdocument,
             ledger                     TYPE i_accountingdocumentjournal-ledger,
             fiscalyear                 TYPE i_accountingdocumentjournal-fiscalyear,
             ledgergllineitem           TYPE i_accountingdocumentjournal-ledgergllineitem,
             debitamountincocodecrcy    TYPE i_accountingdocumentjournal-debitamountincocodecrcy,
             creditamountincocodecrcy   TYPE i_accountingdocumentjournal-creditamountincocodecrcy,
             postingdate                TYPE i_accountingdocumentjournal-postingdate,
             accountingdocumenttypename TYPE i_accountingdocumentjournal-accountingdocumenttypename,
             invoicereference           TYPE i_accountingdocumentjournal-invoicereference,
             assignmentreference        TYPE i_billingdocumentitem-billingdocument,
             documentitemtext           TYPE i_accountingdocumentjournal-documentitemtext,
           END OF ty_accdocjournal.

    DATA : gt_i_acc TYPE TABLE OF ty_accdocjournal.

    DATA: gt_dates TYPE  TABLE OF ty_dates,
          gs_dates TYPE ty_dates.


    DATA : gs_data TYPE ztb_customer.
    DATA : lv_item   TYPE string,
           lv_header TYPE string,
           lv_footer TYPE string,
           lv_xml    TYPE string.
    DATA template TYPE string.
    DATA : gs_header TYPE ty_header,
           gs_footer TYPE ty_footer,
           gt_table  TYPE TABLE OF ty_table,
           gs_table  TYPE ty_table.

    DATA: lv_from_dt   TYPE string,
          lv_to_dt     TYPE string,
          lv_day       TYPE string,
          lv_month     TYPE string,
          lv_year      TYPE string,
          lv_month_num TYPE string.
    DATA: lv_date     TYPE d,
          lv_new_date TYPE d.
    DATA : lv_template TYPE string.
    DATA : lv_dr_cr(3)  TYPE c,
           lv_dr_cr4(3) TYPE c,
           lv_dr_cr3(3) TYPE c.

    METHODS get_pdf_64
      IMPORTING
                VALUE(io_koart)       TYPE koart
                VALUE(io_ledger)      TYPE zchar10
                VALUE(io_companycode) TYPE  bukrs
                VALUE(io_kunnr)       TYPE  kunnr
                VALUE(io_from_dt)     TYPE datum
                VALUE(io_to_dt)       TYPE datum
      RETURNING VALUE(pdf_64)         TYPE string .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZCL_CUST_LEDGER_PRINT IMPLEMENTATION.


  METHOD get_pdf_64.
*HEADER DATA

    CASE io_companycode  .
      WHEN '1000'.
        gs_header-co_nm = | { 'MPM Private Limited.' } |.
*        gs_header-address = | { 'Delhi Road,Partapur' } { cl_abap_char_utilities=>newline } { 'Meerut,250103' }  { cl_abap_char_utilities=>newline } { 'UTTAR PRADESH' }  {
*        cl_abap_char_utilities=>newline } { 'CIN:U24121UP1978PTC004680' } { cl_abap_char_utilities=>newline } { 'email-info@dayalgroup.com' }|.
        lv_template = 'ZCUST_LEDGER_1000/ZCUST_LEDGER_1000'.
      WHEN '2000'.
        gs_header-co_nm = | { 'MPM Durrans Refracoat Private Limited' } |.
*        gs_header-address = | { 'Delhi Road,Partapur' } { cl_abap_char_utilities=>newline } { 'Meerut,250103' }  { cl_abap_char_utilities=>newline } { 'UTTAR PRADESH' }  {
*        cl_abap_char_utilities=>newline } { 'CIN:U74899UP1988PTC123472' }  { cl_abap_char_utilities=>newline } { 'email-info@dayalgroup.com' }|.
        lv_template = 'ZCUST_LEDGER_2000/ZCUST_LEDGER_2000'.
*      WHEN '3000'.
*        gs_header-co_nm = | { 'Dayal Crop Care Pvt. Ltd.' } |.
*        gs_header-address = | { '10 KM, Delhi Road, Near Gagol Road, Partapur' } { cl_abap_char_utilities=>newline } { 'Meerut,250103' }  { cl_abap_char_utilities=>newline } { 'UTTAR PRADESH' }  {
*        cl_abap_char_utilities=>newline } { 'CIN:U24233UP2015PTC069091' }  { cl_abap_char_utilities=>newline } { 'email-info@dayalgroup.com' }|.
*        lv_template = 'ZCUST_LEDGER_3000/ZCUST_LEDGER_3000'.
*      WHEN '4000'.
*        gs_header-co_nm = | { 'Dayal Seeds Pvt. Ltd.' } |.
*        gs_header-address = |{ 'Delhi Road,Partapur' } { cl_abap_char_utilities=>newline } { 'Meerut,250103' }  { cl_abap_char_utilities=>newline } { 'UTTAR PRADESH' }  {
*        cl_abap_char_utilities=>newline } { 'CIN:U51311UP1998PTC123473' }  { cl_abap_char_utilities=>newline } { 'email-info@dayalgroup.com' }|.
*        lv_template = 'ZCUST_LEDGER_4000/ZCUST_LEDGER_4000'.
    ENDCASE.

    SELECT SINGLE  businesspartnername FROM i_businesspartner WHERE businesspartner = @io_kunnr INTO @gs_header-name.
    SELECT SINGLE customer, cityname, postalcode , streetname FROM i_customer  WHERE customer = @io_kunnr INTO @DATA(ls_cust).
    IF ls_cust IS NOT INITIAL.
      gs_header-cust_addr = |{ 'Address : ' }  { ls_cust-streetname }  { cl_abap_char_utilities=>newline } { 'Postal Code : ' } { ls_cust-postalcode } |.
    ENDIF.



    lv_day       = io_from_dt+6(2).
    lv_month_num = io_from_dt+4(2).
    lv_year      = io_from_dt+0(4).


    CASE lv_month_num.
      WHEN '01'. lv_month = 'Jan'.
      WHEN '02'. lv_month = 'Feb'.
      WHEN '03'. lv_month = 'Mar'.
      WHEN '04'. lv_month = 'Apr'.
      WHEN '05'. lv_month = 'May'.
      WHEN '06'. lv_month = 'Jun'.
      WHEN '07'. lv_month = 'Jul'.
      WHEN '08'. lv_month = 'Aug'.
      WHEN '09'. lv_month = 'Sep'.
      WHEN '10'. lv_month = 'Oct'.
      WHEN '11'. lv_month = 'Nov'.
      WHEN '12'. lv_month = 'Dec'.
      WHEN OTHERS. lv_month = '???'.
    ENDCASE.

    lv_from_dt = |{ lv_day }-{ lv_month }-{ lv_year }|.
    CLEAR : lv_day,lv_month_num,lv_year,lv_month.
    lv_day       = io_to_dt+6(2).
    lv_month_num = io_to_dt+4(2).
    lv_year      = io_to_dt+0(4).
    CASE lv_month_num.
      WHEN '01'. lv_month = 'Jan'.
      WHEN '02'. lv_month = 'Feb'.
      WHEN '03'. lv_month = 'Mar'.
      WHEN '04'. lv_month = 'Apr'.
      WHEN '05'. lv_month = 'May'.
      WHEN '06'. lv_month = 'Jun'.
      WHEN '07'. lv_month = 'Jul'.
      WHEN '08'. lv_month = 'Aug'.
      WHEN '09'. lv_month = 'Sep'.
      WHEN '10'. lv_month = 'Oct'.
      WHEN '11'. lv_month = 'Nov'.
      WHEN '12'. lv_month = 'Dec'.
      WHEN OTHERS. lv_month = '???'.
    ENDCASE.

    lv_to_dt = |{ lv_day }-{ lv_month }-{ lv_year }|.

    gs_header-date = |{ 'Ledger Accounts/Statement' } { cl_abap_char_utilities=>newline } { lv_from_dt } { 'to' } { lv_to_dt }|.

    lv_date = io_from_dt.
    lv_new_date = lv_date - 1.

    SELECT
    SUM( debitamountincocodecrcy ) AS total_debit,
    SUM( creditamountincocodecrcy ) AS total_credit
  FROM i_accountingdocumentjournal
  WHERE customer          = @io_kunnr
    AND companycode = @io_companycode
    AND ledger = @io_ledger
    AND postingdate < @io_from_dt
    AND  financialaccounttype = @io_koart
    INTO @DATA(ls_i_acc).

    gs_header-opening_bal = ls_i_acc-total_credit + ls_i_acc-total_debit.

*    lv_header = |<form1>| &&
*                |<SUBFORM3>| .
*                &&
*                   |<Subform1>| &&
*                   |<Address>{ gs_header-address }</Address>| &&
*                   |<CurrentPage></CurrentPage>| &&
*                   |<PageCount></PageCount>| &&
**                   |<co_nm>{ gs_header-co_nm }</co_nm>| &&
*                   |<Name>{ gs_header-name }</Name>| &&
*                   |<cust_addr>{ gs_header-cust_addr }</cust_addr>| &&
*                   |<Date> { 'Ledger Accounts/Statement' } { cl_abap_char_utilities=>newline } { gs_header-date } </Date>| &&
**                   |<Subform4>| &&
*                   |<data>| &&
*                   |<Main>| &&
*                    |<co_nm>{ gs_header-co_nm }</co_nm>| && "
*                    |</Main>| &&
*                    |</data>| &&
**                    |</Subform4>| &&
*                   |</Subform1>|
    .
*END OF HEADER DATA
*TABLE DATA
    SELECT companycode,
           accountingdocument,
           ledger,
           fiscalyear,
           ledgergllineitem,
           debitamountincocodecrcy,
           creditamountincocodecrcy,
           postingdate,
           accountingdocumenttypename,
            invoicereference,
            assignmentreference,
            documentitemtext
           FROM i_accountingdocumentjournal
           WHERE customer          = @io_kunnr
             AND companycode = @io_companycode
             AND ledger = @io_ledger
             AND  financialaccounttype = @io_koart
             AND postingdate BETWEEN @io_from_dt AND @io_to_dt
             AND financialaccounttype = 'D'
      INTO TABLE @gt_i_acc.

    SORT gt_i_acc BY  postingdate ASCENDING.

    IF gt_i_acc IS NOT INITIAL.
      SELECT billingdocument,
      billingdocumentitem,
      creationdate,
      salesdocument FROM i_billingdocumentitem
      FOR ALL ENTRIES IN @gt_i_acc
      WHERE billingdocument = @gt_i_acc-assignmentreference AND creationdate = @gt_i_acc-postingdate
      INTO TABLE @DATA(gt_billingdocumentitem).
      IF gt_billingdocumentitem IS NOT INITIAL.
        SELECT salesdocument,
        purchaseorderbycustomer FROM i_salesdocument
        FOR ALL ENTRIES IN @gt_billingdocumentitem
        WHERE salesdocument = @gt_billingdocumentitem-salesdocument
        INTO TABLE @DATA(gt_salesdocument).
      ENDIF.

      SELECT billingdocument,
      purchaseorderbycustomer FROM i_billingdocument
      FOR ALL ENTRIES IN @gt_i_acc
      WHERE billingdocument = @gt_i_acc-assignmentreference
     INTO TABLE @DATA(gt_billingdocument).
    ENDIF.

    IF  gs_header-opening_bal < 0.
      lv_dr_cr = ' Cr'.
    ELSEIF gs_header-opening_bal > 0.
      lv_dr_cr = ' Dr'.
    ENDIF.

    lv_item =   |<form1>| &&
*    |<Subform1>| &&
*
*      |<data>| &&
*                   |<Main>| &&
*                   |<Date>{ gs_header-date }</Date>| &&
*                   |<cust_addr>{ gs_header-cust_addr }</cust_addr>| &&
*                   |<Name>{ gs_header-name }</Name>| &&
*                   |<Address>{ gs_header-address }</Address>| &&
*                   |<co_nm>{ gs_header-co_nm }</co_nm>| &&
*                   |</Main>| &&
*                    |</data>| &&
*    |</Subform1>| &&
                |<SUBFORM3>| &&
    |<SUBFORM2>| &&
                     |<Table1>| &&
                     |<HeaderRow1/>| &&
                     |<Opening_bal>{ gs_header-opening_bal }{ lv_dr_cr }</Opening_bal>| &&
                     |<HeaderRow2/>| .

    LOOP AT gt_i_acc INTO DATA(gs_i_acc).
      lv_day       = gs_i_acc-postingdate+6(2).
      lv_month_num =  gs_i_acc-postingdate+4(2).
      lv_year      =  gs_i_acc-postingdate+0(4).

      gs_table-date1 = |{ lv_day }.{ lv_month_num }.{ lv_year }|.

      gs_table-debit = gs_i_acc-debitamountincocodecrcy.
      gs_table-credit = gs_i_acc-creditamountincocodecrcy.
      gs_table-journal_entry = gs_i_acc-accountingdocument.
      gs_table-doc_type = gs_i_acc-accountingdocumenttypename.
      gs_table-remarks = gs_i_acc-documentitemtext.

      gs_table-ass_ref = VALUE #( gt_billingdocument[ billingdocument = gs_i_acc-assignmentreference ]-purchaseorderbycustomer OPTIONAL ).

      DATA(lv_sales_doc) = VALUE #( gt_billingdocumentitem[ billingdocument = gs_i_acc-assignmentreference creationdate = gs_i_acc-postingdate ]-salesdocument OPTIONAL ).
      gs_table-vch_typ = VALUE #( gt_salesdocument[ salesdocument = lv_sales_doc ]-purchaseorderbycustomer OPTIONAL ).

      IF sy-tabix = 1.
        lv_balance = gs_header-opening_bal + gs_table-debit + gs_table-credit.
      ELSE.
        lv_balance = lv_balance + gs_table-debit + gs_table-credit.
      ENDIF.

      gs_table-balance = lv_balance.

      lv_item = lv_item &&
                |<Row1>| &&
                |<Date1> { gs_table-date1 }</Date1>| &&
                |<doc_type> { gs_table-doc_type }</doc_type>| &&
                |<journal_entry> { gs_table-journal_entry }</journal_entry>| &&
                |<ass_ref> { gs_table-ass_ref }</ass_ref>| &&
                |<vch_typ> { gs_table-vch_typ }</vch_typ>| &&
                 |<remarks> { gs_table-remarks }</remarks>| &&
                |<debit>{ gs_table-debit }</debit>| &&
                |<credit>{ gs_table-credit }</credit>| &&
                |<balance>{ gs_table-balance }</balance>| &&
                |</Row1>|.

      gs_footer-debit_tot = gs_footer-debit_tot + gs_table-debit.
      gs_footer-credit_tot = gs_footer-credit_tot + gs_table-credit.

      CLEAR gs_table.
    ENDLOOP.

    CLEAR lv_balance.

*END OF TABLE DATA
*FOOTER

    gs_footer-close_bal = gs_header-opening_bal +  gs_footer-credit_tot +  gs_footer-debit_tot .

    IF gs_footer-close_bal  < 0.
      gs_footer-close_bal_credit = gs_footer-close_bal.
      lv_dr_cr4 = ' Cr'.
    ENDIF.

    IF gs_footer-close_bal  > 0.
      gs_footer-close_bal_debit = gs_footer-close_bal.
      lv_dr_cr3 = ' Dr'.
    ENDIF.


    lv_footer = |<FooterRow1>| &&
    |<debit_tot>{ gs_footer-debit_tot }</debit_tot>| &&
    |<credit_tot>{ gs_footer-credit_tot }</credit_tot>| &&
    |</FooterRow1>| &&
    |<FooterRow2>| &&
    |<close_bal_debit>{ gs_footer-close_bal_debit }</close_bal_debit>| && "{ lv_dr_cr3 }
    |<close_bal_credit>{ gs_footer-close_bal_credit }</close_bal_credit>| && "{ lv_dr_cr4 }
    |</FooterRow2>| &&
    |</Table1>| &&
*     |<data>| &&
*                   |<Main>| &&
*                    |<Address>{ gs_header-address }</Address>| &&
*                   |<CurrentPage></CurrentPage>| &&
*                   |<PageCount></PageCount>| &&
**                   |<co_nm>{ gs_header-co_nm }</co_nm>| &&
*                   |<Name>{ gs_header-name }</Name>| &&
*                   |<cust_addr>{ gs_header-cust_addr }</cust_addr>| &&
*                   |<Date>{ gs_header-date }</Date>| &&
*                    |<co_nm>{ gs_header-co_nm }</co_nm>| && "
*                    |</Main>| &&
*                    |</data>| &&
*                    |</Subform1>| &&

    |</SUBFORM2>| &&
    |</SUBFORM3>| &&
|<Date>{ gs_header-date }</Date>| &&
                   |<cust_addr>{ gs_header-cust_addr }</cust_addr>| &&
                   |<Name>{ gs_header-name }</Name>| &&
                   |<Address>{ gs_header-address }</Address>| &&
                   |<co_nm>{ gs_header-co_nm }</co_nm>| &&
    |</form1>|.
*END OF FOOTER

    lv_xml = |{ lv_header }{ lv_item }{ lv_footer }|.

    CALL METHOD zadobe_call=>getpdf
      EXPORTING
        template = lv_template
        xmldata  = lv_xml
      RECEIVING
        result   = DATA(lv_result).

    IF lv_result IS NOT INITIAL.

      pdf_64 = lv_result.
      gs_data-companycode = io_companycode .
      gs_data-kunnr = io_kunnr  .
      gs_data-koart = io_koart .
      gs_data-ledger =  io_ledger.
      gs_data-from_dt = io_from_dt.
      gs_data-to_dt = io_to_dt .
      gs_data-base64 = pdf_64.

      MODIFY ztb_customer FROM @gs_data.
    ENDIF.


  ENDMETHOD.
ENDCLASS.

@ObjectModel: {
  query: {
    implementedBy: 'ABAP:ZCL_CUST_LEDGER'
  }
}
@EndUserText.label: 'CE for Customer Ledger'
@Metadata.allowExtensions: true
define custom entity zce_customer_ledger

{

  key company_code    : abap.char(4); 
  key fiscal_year     : abap.char(4); 
  key journal_entry   : abap.char(10);
  key line_item       : abap.numc(6);
      posting_date    : abap.dats;
      customer        : abap.char(10);
      doc_type        : abap.char(4);
      po_number       : abap.char(10);
      invoice_no_date : abap.string;
      narration       : abap.string;
      debit_amount    : abap.dec(16,2);
      credit_amount   : abap.dec(16,2);
      balance_inr     : abap.dec(16,2);
}

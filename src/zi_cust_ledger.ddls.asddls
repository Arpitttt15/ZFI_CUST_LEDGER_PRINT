@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface View for Customer Ledger'
@Metadata.allowExtensions: true
define root view entity ZI_CUST_LEDGER
  as select from    I_Customer      as a
    left outer join ztb_cust_ledger as b on a.Customer = b.customer
{
  key a.Customer,
      a.CustomerName,
      b.base64,
      b.m_ind
}

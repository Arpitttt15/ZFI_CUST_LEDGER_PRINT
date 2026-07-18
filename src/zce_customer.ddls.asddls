@ObjectModel: {
query: {
   implementedBy: 'ABAP:ZCL_CUST'
}
}
@UI:{
    headerInfo:{
    typeName: 'Customer Ledger Summary print',
    typeNamePlural: 'Customer Ledger Summary print' }

    }
define custom entity ZCE_CUSTOMER
{
    
      @UI                : {
      identification     : [{ position: 10 }],
      selectionField     : [{ position: 10 }],
      lineItem           : [{ position: 10 }] }

      @EndUserText.label : 'Account Type'
      @Consumption.valueHelpDefinition: [
          { entity       :  { name:    'I_FinancialAccountTypeStdVH',
                       element: 'FinancialAccountType' }
          }]
  key koart              : abap.char(1);

      @UI                : {
      identification     : [{ position: 20 }],
      selectionField     : [{ position: 20 }],
      lineItem           : [{ position: 20 }] }
      @EndUserText.label : 'Ledger'
      @Consumption.valueHelpDefinition: [
              { entity   :  { name:    'I_Ledger',
                           element: 'Ledger' }
              }]
  key ledger             : abap.char(10); //ledger;
      @UI                : {
       identification    : [{ position: 30 }],
       selectionField    : [{ position: 30 }],
       lineItem          : [{ position: 30 }] }
      @EndUserText.label : 'Company Code'
      @Consumption.filter: { mandatory:true }
      @Consumption.valueHelpDefinition: [
            { entity     :  { name:    'I_CompanyCode',
                         element: 'CompanyCode' }
            }]
  key CompanyCode        : bukrs;

      @UI                : {
      identification     : [{ position: 40 }],
      selectionField     : [{ position: 40 }],
      lineItem           : [{ position: 40 }] }
      @EndUserText.label : 'Customer'
      @Consumption.filter: { mandatory:true }
      @Consumption.valueHelpDefinition: [
            { entity     :  { name:    'I_BusinessPartner',
                         element: 'BusinessPartner' }
            }]
  key kunnr              : kunnr;

      @UI                : {
      identification     : [{ position: 50 }],
      selectionField     : [{ position: 50 }],
      lineItem           : [{ position: 50 }] }
      @EndUserText.label : 'From Date'
      @Consumption.filter: { mandatory:true }
  key From_dt            : abap.dats;
      @UI                : {
      identification     : [{ position: 60 }],
          selectionField : [{ position: 60 }],
      lineItem           : [{ position: 60 }] }
      @EndUserText.label : 'To Date'
      @Consumption.filter: { mandatory:true }
  key To_dt              : abap.dats;
      AccountingDocument : belnr_d;
      @UI.hidden         : true
      FiscalYear         : gjahr;
      @UI.hidden         : true
      LedgerGLLineItem   : abap.char(10);

      @UI.hidden         : true
      Base64             : abap.string(0);
}

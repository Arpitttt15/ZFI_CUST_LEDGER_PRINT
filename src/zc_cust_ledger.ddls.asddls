@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption for Customer Ledger'
@Metadata.allowExtensions: true
@UI.headerInfo:{
    typeName: 'Customer Ledger',
    typeNamePlural: 'Customer Ledger',
    title:{ type: #STANDARD, value: 'Customer' } }
define root view entity ZC_CUST_LEDGER
provider contract transactional_query
  as projection on ZI_CUST_LEDGER
{

      @UI.facet: [{ id : 'Customer',
      purpose: #STANDARD,
      type: #IDENTIFICATION_REFERENCE,
      label: 'Customer Ledger',
      position: 10 }]
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'Customer' } }]
      @UI.lineItem:       [{ position: 10, label: 'Customer' },{ type: #FOR_ACTION , dataAction: 'ZPRINT', label: 'Generate Print'}]
      @UI.identification: [{ position: 10, label: 'Customer' }]
      @UI.selectionField: [{ position: 10 }]
      @UI.textArrangement: #TEXT_SEPARATE
  key Customer,
      
      @Consumption.valueHelpDefinition: [{ entity: { name: 'I_Customer', element: 'CustomerName' } }]
      @UI.lineItem:       [{ position: 20, label: 'Customer Name' }]
      @UI.identification: [{ position: 20, label: 'Customer Name' }]
      @UI.selectionField: [{ position: 20 }]

      CustomerName,
      base64,
      m_ind
}

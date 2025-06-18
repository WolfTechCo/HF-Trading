@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Reclassification Report'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCDS_I_TradingReclassReport
  as select from ZCDS_I_TradingReclassification
  association [1..1] to ZCDS_I_TradingDocumentStatus as _TradingDocumentStatus on  $projection.DocumentStatus = _TradingDocumentStatus.DocumentStatus
  association [1..1] to ZCDS_I_TradingDocStatusIcon  as _TradingDocStatusIcon  on  $projection.DocumentStatus = _TradingDocStatusIcon.DocumentStatus
  association [1..1] to I_SalesDocument              as _SalesDocument         on  $projection.SalesDocument = _SalesDocument.SalesDocument
  association [1..1] to I_BillingDocument            as _BillingDocument       on  $projection.BillingDocument = _BillingDocument.BillingDocument
  association [1..*] to I_JournalEntryItem           as _JournalEntryItem      on  $projection.CompanyCode                = _JournalEntryItem.CompanyCode
                                                                               and $projection.FiscalYear                 = _JournalEntryItem.FiscalYear
                                                                               and $projection.AccountingDocument         = _JournalEntryItem.AccountingDocument
                                                                               and _JournalEntryItem.SourceLedger         = '0L'
                                                                               and _JournalEntryItem.FinancialAccountType = 'S'
{
  key DocumentUUID,
      AccountingDocument,
      CompanyCode,
      FiscalYear,
      DocumentStatus,
      _TradingDocStatusIcon.iconID                                                           as DocumentStatusIcon,
      SalesDocument,
      _SalesDocument.ZZ1_Container                                                           as container,
      _BillingDocument.CompanyCode                                                           as OriginCompanyCode,
      BillingDocument,
      DocumentReferenceID,
      _BillingDocument.SDDocumentCategory                                                    as SDDocumentCategory,
      AccountingDocumentSettlement,
      CompanyCodeSettlement,
      FiscalYearSettlement,
      ToPostingDate                                                                          as To_PostingDate,

      @Semantics.quantity.unitOfMeasure: 'Transactionquantityunit'
      QuantityInTransaction,
      TransactionQuantityUnit,

      @Semantics.quantity.unitOfMeasure: 'PurchaseInvoiceQuantityUnit'
      sum( _JournalEntryItem.Quantity )                                                      as QuantityInPurchaseInvoice,
      _JournalEntryItem.BaseUnit                                                             as PurchaseInvoiceQuantityUnit,

      @Semantics.amount.currencyCode: 'Transactioncurrency'
      AmountInTransactionCurrency,
      TransactionCurrency,

      @Semantics.amount.currencyCode: 'PurchaseInvoiceCurrency'
      sum( _JournalEntryItem.AmountInTransactionCurrency )                                   as PurchaseInvoiceAmount,
      _JournalEntryItem.TransactionCurrency                                                  as PurchaseInvoiceCurrency,

      @Semantics.amount.currencyCode: 'PurchaseInvoiceCurrency'
      ( AmountInTransactionCurrency - sum( _JournalEntryItem.AmountInTransactionCurrency ) ) as DifAmountInTransactionCurrency,

      CreatedAtDate,
      CreatedAtTime,
      CreatedBy,
      LastChangeDate,
      LastChangeTime,
      LastChangedBy,

      //Associations
      _TradingDocumentStatus,
      _SalesDocument,
      _BillingDocument,
      _JournalEntryItem

}
group by
  DocumentUUID,
  CompanyCode,
  AccountingDocument,
  FiscalYear,
  DocumentStatus,
  _TradingDocStatusIcon.iconID,
  SalesDocument,
  BillingDocument,
  _BillingDocument.SDDocumentCategory,
  CompanyCodeSettlement,
  AccountingDocumentSettlement,
  FiscalYearSettlement,
  DocumentReferenceID,
  _SalesDocument.ZZ1_Container,
  ToPostingDate,
  QuantityInTransaction,
  TransactionQuantityUnit,
  AmountInTransactionCurrency,
  TransactionCurrency,
  CreatedAtDate,
  CreatedAtTime,
  CreatedBy,
  LastChangeDate,
  LastChangeTime,
  LastChangedBy,
  _JournalEntryItem.BaseUnit,
  _JournalEntryItem.TransactionCurrency,
  _BillingDocument.CompanyCode

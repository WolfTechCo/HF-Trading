@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading ACK. of Receipt - Goods Issue'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

define view entity ZCDS_I_TradingAckRcptGIReport
  as select from ZCDS_I_TradingDocuments

  association [1..*] to I_BillingDocumentItem  as _BillingDocumentItem         on  $projection.BillingDocument = _BillingDocumentItem.BillingDocument
  association [1..*] to I_OutboundDeliveryItem as _OutboundDeliveryItem        on  $projection.OutboundDelivery = _OutboundDeliveryItem.OutboundDelivery
  association [0..1] to I_Customer             as _IntercompanyBillingCustomer on  $projection.intercompanybillingcustomer = _IntercompanyBillingCustomer.Customer
  association [1..*] to I_JournalEntryItem     as _PurchaseAccDocumentItem     on  $projection.PurchaseAccDocumentLedger      = _PurchaseAccDocumentItem.SourceLedger
                                                                               and $projection.PurchaseAccDocumentCompanyCode = _PurchaseAccDocumentItem.CompanyCode
                                                                               and $projection.PurchaseAccDocumentFiscalYear  = _PurchaseAccDocumentItem.FiscalYear
                                                                               and $projection.PurchaseAccountingDocument     = _PurchaseAccDocumentItem.AccountingDocument
  association [1..*] to I_JournalEntryItem     as _AckReceiptGoodsIssueItem    on  $projection.AckReceiptGoodsIssueLedger     = _AckReceiptGoodsIssueItem.SourceLedger
                                                                               and $projection.AckReceiptGICompanyCode        = _AckReceiptGoodsIssueItem.CompanyCode
                                                                               and $projection.AckReceiptGoodsIssueFiscalYear = _AckReceiptGoodsIssueItem.FiscalYear
                                                                               and $projection.AckReceiptGIAccountingDocument = _AckReceiptGoodsIssueItem.AccountingDocument
{
  key BillingDocument,
      CompanyCode,
      _BillingDocument.BillingDocumentDate,
      _BillingDocument.DocumentReferenceID,
      OutboundDelivery,
      _OutboundDelivery.ActualGoodsMovementDate,
      _OutboundDelivery.SoldToParty,
      _OutboundDelivery._SoldToParty.CustomerFullName as SoldToPartyFullName,
      _OutboundDelivery.ShipToParty,
      _OutboundDelivery._ShipToParty.CustomerFullName as ShipToPartyFullName,
      _OutboundDelivery.IntercompanyBillingCustomer,
      _OutboundDelivery.SalesOrgForIntcoBilling,      
      PurchaseAccDocumentLedger,
      PurchaseAccDocumentCompanyCode,
      PurchaseAccountingDocument,
      PurchaseAccDocumentFiscalYear,
      AckReceiptGoodsIssueLedger,
      AckReceiptGICompanyCode,
      AckReceiptGIAccountingDocument,
      AckReceiptGoodsIssueFiscalYear,
      case when AckReceiptGIAccountingDocument is null then ''
        when AckReceiptGIAccountingDocument is not null then 'X'
        else '' 
      end as AckReceiptGoodsIssueExist,

      /* Associations */
      _OutboundDelivery._SoldToParty,
      _OutboundDelivery._ShipToParty,
      _IntercompanyBillingCustomer,

      _BillingDocument,
      _BillingDocumentItem,
      _OutboundDelivery,
      _OutboundDeliveryItem,
      _PurchaseAccDocument,
      _PurchaseAccDocumentItem,
      _AckReceiptGoodsIssue,
      _AckReceiptGoodsIssueItem

}
where
  PurchaseAccountingDocument is not null
group by
    BillingDocument,
    CompanyCode,
    _BillingDocument.BillingDocumentDate,
    _BillingDocument.DocumentReferenceID,
    OutboundDelivery,
    _OutboundDelivery.ActualGoodsMovementDate,
    _OutboundDelivery.SoldToParty,
    _OutboundDelivery._SoldToParty.CustomerFullName,
    _OutboundDelivery.ShipToParty,
    _OutboundDelivery._ShipToParty.CustomerFullName,
    _OutboundDelivery.IntercompanyBillingCustomer,
    _OutboundDelivery.SalesOrgForIntcoBilling,
    PurchaseAccDocumentLedger,
    PurchaseAccDocumentCompanyCode,
    PurchaseAccountingDocument,
    PurchaseAccDocumentFiscalYear,
    AckReceiptGoodsIssueLedger,
    AckReceiptGICompanyCode,
    AckReceiptGIAccountingDocument,
    AckReceiptGoodsIssueFiscalYear


@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Reclassification Basic'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType:#BASIC
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCDS_I_TradingReclassification
  as select from ztbfi_trd_reclas
  association [1..1] to ZCDS_I_TradingDocumentStatus   as _TradingDocumentStatus   on  $projection.DocumentStatus = _TradingDocumentStatus.DocumentStatus
  association [1..1] to ZCDS_I_TradingDocStatusIcon    as _TradingDocStatusIcon    on  $projection.DocumentStatus = _TradingDocStatusIcon.DocumentStatus
{
  key documentuuid                                                                     as DocumentUUID,
      cast( accountingdocument as fis_belnr preserving type )                          as AccountingDocument,
      companycode                                                                      as CompanyCode,
      fiscalyear                                                                       as FiscalYear,
      documentstatus                                                                   as DocumentStatus,
      cast( salesdocument as vdm_sales_order preserving type )                         as SalesDocument,
      billingdocument                                                                  as BillingDocument,
      cast( accountingdocumentsettlement as /accgo/e_settl_doc_sales preserving type ) as AccountingDocumentSettlement,
      companycodesettlement                                                            as CompanyCodeSettlement,
      fiscalyearsettlement                                                             as FiscalYearSettlement,
      documentreferenceid                                                              as DocumentReferenceID,
      to_postingdate                                                                   as ToPostingDate,
      @Semantics.quantity.unitOfMeasure: 'Transactionquantityunit'
      quantityintransaction                                                            as QuantityInTransaction,
      transactionquantityunit                                                          as TransactionQuantityUnit,
      @Semantics.amount.currencyCode: 'transactioncurrency'
      amountintransactioncurrency                                                      as AmountInTransactionCurrency,
      transactioncurrency                                                              as TransactionCurrency,
      createdatdate                                                                    as CreatedAtDate,
      createdattime                                                                    as CreatedAtTime,
      createdby                                                                        as CreatedBy,
      lastchangedate                                                                   as LastChangeDate,
      lastchangetime                                                                   as LastChangeTime,
      lastchangedby                                                                    as LastChangedBy,
      
      //Associations
      _TradingDocumentStatus,
      _TradingDocStatusIcon
}

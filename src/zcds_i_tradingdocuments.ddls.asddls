@AbapCatalog.viewEnhancementCategory: [ #NONE ]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Documents Flow'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: { serviceQuality: #X, sizeCategory: #S, dataClass: #MIXED }

/*+[hideWarning] { "IDS" : [ "CARDINALITY_CHECK" ]  } */
define view entity ZCDS_I_TradingDocuments
  as select from I_BillingDocumentItem

  association [1..1] to I_BillingDocument              as _BillingDocument         on  $projection.BillingDocument = _BillingDocument.BillingDocument
  association [1..1] to I_BillingDocumentItem          as _BillingDocumentItem     on  $projection.BillingDocument     = _BillingDocumentItem.BillingDocument
                                                                                   and $projection.BillingDocumentItem = _BillingDocumentItem.BillingDocumentItem
  association [1..1] to I_SalesDocument                as _SalesDocument           on  $projection.SalesDocument = _SalesDocument.SalesDocument
  association [1..1] to I_SalesDocumentItem            as _SalesDocumentItem       on  $projection.SalesDocument     = _SalesDocumentItem.SalesDocument
                                                                                   and $projection.SalesDocumentItem = _SalesDocumentItem.SalesDocumentItem
  association [0..1] to I_JournalEntryItem             as _PurchaseAccDocumentItem on  $projection.SalesDocument                       = _PurchaseAccDocumentItem.SalesDocument
                                                                                   and $projection.SalesDocumentItem                   = _PurchaseAccDocumentItem.SalesDocumentItem
                                                                                   and _PurchaseAccDocumentItem.SourceLedger           = '0L'
                                                                                   and _PurchaseAccDocumentItem.CompanyCode            = 'IRHO'
                                                                                   and _PurchaseAccDocumentItem.AccountingDocumentType = 'KT'
                                                                                   and _PurchaseAccDocumentItem.Ledger                 = '0L'
                                                                                   and _PurchaseAccDocumentItem.IsReversed             = ''
                                                                                   and _PurchaseAccDocumentItem.IsReversal             = ''
  association [0..1] to I_JournalEntry                 as _PurchaseAccDocument     on  $projection.PurchaseAccDocumentCompanyCode = _PurchaseAccDocument.CompanyCode
                                                                                   and $projection.PurchaseAccDocumentFiscalYear  = _PurchaseAccDocument.FiscalYear
                                                                                   and $projection.PurchaseAccountingDocument     = _PurchaseAccDocument.AccountingDocument
                                                                                   and _PurchaseAccDocument.IsReversed            = ''
                                                                                   and _PurchaseAccDocument.IsReversal            = ''
  association [0..1] to I_JournalEntry                 as _SettlementAccDocument   on  $projection.BillingDocument                   = _SettlementAccDocument.Reference2InDocumentHeader
                                                                                   and _SettlementAccDocument.CompanyCode            = 'IRHO'
                                                                                   and _SettlementAccDocument.AccountingDocumentType = 'SA'
                                                                                   and _SettlementAccDocument.IsReversed             = ''
                                                                                   and _SettlementAccDocument.IsReversal             = ''
  association [0..1] to ZCDS_I_TradingReclassification as _TradingReclassification on  $projection.PurchaseAccountingDocument     = _TradingReclassification.AccountingDocument
                                                                                   and $projection.PurchaseAccDocumentCompanyCode = _TradingReclassification.CompanyCode
                                                                                   and $projection.PurchaseAccDocumentFiscalYear  = _TradingReclassification.FiscalYear

{
      // Billing
      @Consumption.valueHelpDefinition: [
            { entity:  { name:    'I_BillingDocumentBasicStdVH',
                         element: 'BillingDocument' }
            }]
      @ObjectModel.foreignKey.association: '_BillingDocument'
  key BillingDocument                                                    as BillingDocument,
  key cast( BillingDocumentItem as posnr_vf preserving type )            as BillingDocumentItem,
      @ObjectModel.foreignKey.association: '_SDDocumentCategory'
      _BillingDocument.SDDocumentCategory,

      @ObjectModel.foreignKey.association: '_BillingDocumentType'
      _BillingDocument.BillingDocumentType,
      _BillingDocument.CompanyCode                                       as CompanyCode,

      _BillingDocument.DocumentReferenceID                               as DocumentReferenceID,

      // Sales
      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_SalesDocumentStdVH',
                     element: 'SalesDocument' }
        }]
      @ObjectModel.foreignKey.association: '_SalesDocument'
      SalesDocument                                                      as SalesDocument,

      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_SalesDocumentItemStdVH',
                     element: 'SalesDocumentItem' },
          additionalBinding: [{ localElement: 'SalesDocument',
                                element: 'SalesDocument' }]
        }]
      @ObjectModel.foreignKey.association: '_SalesDocumentItem'
      SalesDocumentItem                                                  as SalesDocumentItem,

      @ObjectModel.foreignKey.association: '_SalesSDDocumentCategory'
      SalesSDDocumentCategory                                            as SalesSDDocumentCategory,

      @ObjectModel.foreignKey.association: '_SalesDocumentType'
      _SalesDocument.SalesDocumentType                                   as SalesDocumentType,

      // Purchase Accounting Document
      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_LedgerStdVH',
                     element: 'Ledger' }
        }]
      @ObjectModel.text.association: '_SourceLedgerText'
      @ObjectModel.foreignKey.association: '_SourceLedger'
      _PurchaseAccDocumentItem.SourceLedger                              as PurchaseAccDocumentLedger,

      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_CompanyCodeStdVH',
                     element: 'CompanyCode' }
        }]
      @ObjectModel.foreignKey.association: '_PurchaseAccountingCompanyCode'
      _PurchaseAccDocumentItem.CompanyCode                               as PurchaseAccDocumentCompanyCode,

      @ObjectModel.foreignKey.association: '_PurchaseAccountingFiscalYear'
      @Semantics.fiscal.year: true
      _PurchaseAccDocumentItem.FiscalYear                                as PurchaseAccDocumentFiscalYear,

      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_JournalEntryStdVH',
                     element: 'AccountingDocument' },
          additionalBinding: [{ localElement: 'PurchaseAccDocumentCompanyCode',
                                element: 'CompanyCode' },
                              { localElement: 'PurchaseAccDocumentFiscalYear',
                                element: 'FiscalYear' }]
        }]
      @ObjectModel.foreignKey.association: '_PurchaseJournalEntry'
      _PurchaseAccDocumentItem.AccountingDocument                        as PurchaseAccountingDocument,
      _PurchaseAccDocumentItem.LedgerGLLineItem                          as PurchaseAccountingDocumentItem,
      _PurchaseAccDocumentItem.AccountingDocumentType                    as PurchaseAccountingDocumentType,

      // Settlement Accounting Document
      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_CompanyCodeStdVH',
                     element: 'CompanyCode' }
        }]
      @ObjectModel.foreignKey.association: '_SettAccountingCompanyCode'
      _SettlementAccDocument.CompanyCode                                 as SettAccountingCompanyCode,

      @ObjectModel.foreignKey.association: '_SettAccountingFiscalYear'
      @Semantics.fiscal.year: true
      _SettlementAccDocument.FiscalYear                                  as SettAccountingFiscalYear,

      @Consumption.valueHelpDefinition: [
        { entity:  { name:    'I_CompanyCodeStdVH',
                     element: 'CompanyCode' }
        }]
      _SettlementAccDocument.AccountingDocument                          as SettelementAccountingDocument,
      _SettlementAccDocument.AccountingDocumentType                      as SettAccountingDocumentType,


      /* Associations */

      // Sales Document
      _SalesDocument,
      _SalesDocument._SalesDocumentType,
      _SalesDocumentItem,

      // Billing
      _BillingDocument,
      _BillingDocument._SDDocumentCategory,
      _BillingDocument._BillingDocumentType,
      _BillingDocumentItem,

      // Purchase Accounting Document
      _PurchaseAccDocument,
      _PurchaseAccDocumentItem,
      _PurchaseAccDocumentItem._CompanyCode                              as _PurchaseAccountingCompanyCode,
      _PurchaseAccDocumentItem._FiscalYear                               as _PurchaseAccountingFiscalYear,
      _PurchaseAccDocumentItem._JournalEntry                             as _PurchaseJournalEntry,
      _PurchaseAccDocumentItem._SourceLedgerText,
      _PurchaseAccDocumentItem._SourceLedger,
    
      // Trading Reclassification
      _TradingReclassification,
        
      // Settlement Accounting Document
      _SettlementAccDocument,
      _SettlementAccDocument._CompanyCode                                as _SettAccountingCompanyCode,
      _SettlementAccDocument._FiscalYear                                 as _SettAccountingFiscalYear,
      _SettlementAccDocument._JournalEntryItem[ *: SourceLedger = '0L' ] as _SettlementAccDocumentItem,
        
      // Others
      _SalesSDDocumentCategory

}
where
      _BillingDocument.BillingDocumentType        = 'ZIV'
  and _BillingDocument.BillingDocumentIsTemporary = ''
  and _BillingDocument.BillingDocumentIsCancelled = ''

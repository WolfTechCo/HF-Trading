 @AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Document Status Text'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel: {
    dataCategory: #TEXT,
    representativeKey: 'DocumentStatus',
    usageType:{
        serviceQuality: #A,
        sizeCategory: #S,
        dataClass: #META
    },
    modelingPattern: #ANALYTICAL_DIMENSION,
    supportedCapabilities:  [  #SQL_DATA_SOURCE,
                                        #CDS_MODELING_DATA_SOURCE,
                                        #CDS_MODELING_ASSOCIATION_TARGET,
                                        #ANALYTICAL_DIMENSION,
                                        #EXTRACTION_DATA_SOURCE,
                                        #SEARCHABLE_ENTITY  ]
}
@Analytics.dataExtraction.enabled: true
@VDM.viewType: #BASIC
@Search.searchable: true

/*+[hideWarning] { "IDS" : [ "KEY_CHECK", "CALCULATED_FIELD_CHECK" ]  } */
define view entity ZCDS_I_TradingDocStatusText
  as select from dd07t

  association [0..1] to ZCDS_I_TradingDocumentStatus as _TradingDocumentStatus on $projection.DocumentStatus = _TradingDocumentStatus.DocumentStatus
  association [0..1] to I_Language                   as _Language              on $projection.Language = _Language.Language
{
      @ObjectModel.foreignKey.association: '_TradingDocumentStatus'
  key cast(substring( domvalue_l, 1, 1) as zde_status_trading_process preserving type ) as DocumentStatus,

      @ObjectModel.foreignKey.association: '_Language'
      @Semantics.language: true
  key ddlanguage                                                                        as Language,

      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @Semantics.text: true
      cast(ddtext as zde_tradingdocumentstatusname preserving type)                     as DocumentStatusName,

      @Consumption.hidden: true
      dd07t.domvalue_l                                                                  as DomainValue,

      //Associations
      _TradingDocumentStatus,
      _Language
}
where
  (
    domname  = 'ZDD_STATUS_TRADING_PROCESS'
  )
  and(
    as4local = 'A'
  );

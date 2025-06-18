@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Document Status'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel: {
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
@Analytics: {
    dataCategory: #DIMENSION,
    dataExtraction.enabled: true
}
@VDM.viewType: #BASIC
@Search.searchable: true

/*+[hideWarning] { "IDS" : [ "CALCULATED_FIELD_CHECK", "KEY_CHECK" ]  } */
define view entity ZCDS_I_TradingDocumentStatus
  as select from dd07l

  association [0..*] to ZCDS_I_TradingDocStatusText as _Text on $projection.DocumentStatus = _Text.DocumentStatus
{
      @ObjectModel.text.association: '_Text'
  key cast(substring( domvalue_l, 1, 1) as zde_status_trading_process preserving type ) as DocumentStatus,

      @Consumption.hidden: true
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      dd07l.domvalue_l                                                                  as DomainValue,

      //Associations
      _Text
}
where
  (
    dd07l.domname  = 'ZDD_STATUS_TRADING_PROCESS'
  )
  and(
    dd07l.as4local = 'A'
  );

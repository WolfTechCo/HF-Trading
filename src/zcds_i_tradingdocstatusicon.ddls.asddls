@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Document Status with Icon'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCDS_I_TradingDocStatusIcon
  as select from ZCDS_I_TradingDocumentStatus
  association [0..1] to icon as _icon on $projection.iconID = _icon.id 
{
  key DocumentStatus,
      
      _Text[1: Language = $session.system_language ].DocumentStatusName,  
      
      @EndUserText.label: 'Icon ID'
      case DocumentStatus
      when 'N' then '@39@'
      when 'P' then '@5B@'
      when 'I' then '@5D@'
      when 'F' then '@5C@'
      when 'C' then '@06@'
      when 'D' then '@5C@'
      when 'E' then '@5C@'
      else ''
      end as iconID,
        
      /* Associations */
      _Text,
      _icon

}

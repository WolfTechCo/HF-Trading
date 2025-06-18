@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Reclassification Log'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCDS_I_TradingReclassLog
  as select from ztbfi_trdrecllog
{
  key documentuuid  as DocumentUUID,
  key datetime_l    as DateTimeL,
  key type_document as TypeDocument,
  key type_process  as TypeProcess,
  key zaehl         as Sequence,
      type          as Type,
      id            as ID,
      nro           as Nro,
      message       as Message,
      messagev1     as Messagev1,
      messagev2     as Messagev2,
      messagev3     as Messagev3,
      messagev4     as Messagev4,
      createdby     as Createdby
}

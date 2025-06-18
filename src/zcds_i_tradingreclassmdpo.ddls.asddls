@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Trading Reclass DM Doc.Contable Compras'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZCDS_I_TradingReclassMdPo
  as select from ztbfi_trdrecl_po
{
  key companycode                                           as Companycode,
      accountingdocumenttype                                as Accountingdocumenttype,
      glaccount                                             as Glaccount,
      cast( fromprofitcenter as fis_prctr preserving type ) as Fromprofitcenter,
      cast( toprofitcenter as fis_prctr preserving type )   as Toprofitcenter
}

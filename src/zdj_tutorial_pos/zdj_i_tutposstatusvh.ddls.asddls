@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Status Search Help'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
@ObjectModel.resultSet.sizeCategory: #XS
@ObjectModel.semanticKey: ['Code']
@ObjectModel.representativeKey: 'Code'
define view entity ZDJ_I_TutposStatusVH
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE(
                 p_domain_name:'ZDJ_DO_TUTPOS_STAT'
                 ) as Source
  association [0..*] to ZDJ_I_TutposStatus as _Text on  _Text.Code = $projection.Code
{
      @Search.defaultSearchElement: true
      @ObjectModel.text.association: '_Text'
  key Source.value_low      as Code,
      @Search.defaultSearchElement: true
      @Consumption.hidden: true
      _Text
}

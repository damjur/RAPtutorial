@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Status Search Help'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity ZDJ_I_TutposStatus
  as select from DDCDS_CUSTOMER_DOMAIN_VALUE(
    p_domain_name:'ZDJ_DO_TUTPOS_STAT'
  ) as Source
    inner join   DDCDS_CUSTOMER_DOMAIN_VALUE_T(
        p_domain_name:'ZDJ_DO_TUTPOS_STAT'
    ) as Text on Text.value_position = Source.value_position
    association [0..*] to I_LanguageText        as _LanguageText on $projection.Language = _LanguageText.LanguageCode
{
      @ObjectModel.text.element: ['Text']
  key Source.value_low as Code,
      @Semantics.language: true
  key Text.language                        as Language,
      @Semantics.text: true
      @Search.defaultSearchElement: true
      Text.text as Text,
      _LanguageText
}

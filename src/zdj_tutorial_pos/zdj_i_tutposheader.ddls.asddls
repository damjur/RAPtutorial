@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Receipt Header'
@ObjectModel.semanticKey: ['Id']
@ObjectModel.representativeKey: 'Id'
define root view entity ZDJ_I_TutposHeader
  as select from zdj_tut_pos_head
  composition [0..*] of ZDJ_I_TutposItem       as _Items
  association [0..1] to ZDJ_I_TutposHeaderCalc as _Calc     on $projection.Id = _Calc.Id
  association [0..*] to ZDJ_I_TutposStatus     as _Status   on $projection.Status = _Status.Code
  association [0..1] to I_Currency             as _Currency on $projection.Currency = _Currency.Currency
{
      @ObjectModel.text.element: ['Description','Customer']
  key id                                                                                                                           as Id,
      @Semantics.text: true
      description                                                                                                                  as Description,
      @ObjectModel.foreignKey.association: '_Currency'
      currency                                                                                                                     as Currency,
      @Semantics.text: true
      customer                                                                                                                     as Customer,
      @ObjectModel.text.association: '_Status'
      status                                                                                                                       as Status,

      @Semantics.user.createdBy: true
      creator                                                                                                                      as Creator,
      @Semantics.systemDateTime.createdAt: true
      created_at                                                                                                                   as CreatedAt,
      @Semantics.user.lastChangedBy: true
      modificator                                                                                                                  as Modificator,
      @Semantics.systemDateTime.lastChangedAt: true
      modified_at                                                                                                                  as ModifiedAt,
      @Semantics.imageUrl: true
      cast( 'https://www.all-for-one.pl/wp-content/themes/snp_blackout/assets/img/all_for_one_group_rgb-2.svg' as abap.char(100) ) as PictureURL,
      _Calc.OverallPrice,
      _Items,
      _Currency,
      _Status
}

@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Receipt Item'
@ObjectModel.semanticKey: ['Item','Id']
@ObjectModel.representativeKey: 'Item'

define view entity ZDJ_I_TutposItem
  as select from zdj_tut_pos_item
  association        to parent ZDJ_I_TutposHeader as _Header        on $projection.Id = _Header.Id
  association [0..1] to I_UnitOfMeasure           as _UnitOfMeasure on $projection.Unit = _UnitOfMeasure.UnitOfMeasure
{
      @ObjectModel.text.element: ['Description']
      @ObjectModel.foreignKey.association: '_Header'
  key id                                          as Id,
  key item                                        as Item,
      @Semantics.text: true
      description                                 as Description,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      quantity                                    as Quantity,
      @ObjectModel.foreignKey.association: '_UnitOfMeasure'
      unit                                        as Unit,
      _Header.Currency                            as Currency,
      @Semantics.amount.currencyCode: 'Currency'
      unit_price                                  as UnitPrice,


      @Semantics.amount.currencyCode: 'Currency'
      cast( quantity as abap.dec( 13, 2 ) )
        * cast( unit_price as abap.dec( 13, 2 ) ) as Price,

      _Header,
      _Header._Currency,
      _UnitOfMeasure

}

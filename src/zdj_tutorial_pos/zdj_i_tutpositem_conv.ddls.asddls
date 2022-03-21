@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Currency&Unit Converter for Receipt Item'
@Metadata.ignorePropagatedAnnotations: true

define view entity ZDJ_I_TUTPOSITEM_CONV
  with parameters
    p_currency : abap.cuky,
    p_unit     : abap.unit( 3 )
  as select from ZDJ_I_TutposItem

{
  key Id,
  key Item,
      Currency,
      Unit,
      @Semantics.amount.currencyCode: 'Currency'
      UnitPrice,
      @Semantics.quantity.unitOfMeasure: 'Unit'
      Quantity,
      $parameters.p_currency                        as ConvertedCurrency,
      $parameters.p_unit                            as ConvertedUnit,
      @Semantics.amount.currencyCode: 'ConvertedCurrency'
      currency_conversion(
        amount => UnitPrice,
        source_currency => Currency,
        target_currency => $parameters.p_currency,
        exchange_rate_date => $session.system_date
        ) as ConvertedUnitPrice,
      @Semantics.quantity.unitOfMeasure: 'ConvertedUnit'
      unit_conversion(
        quantity => Quantity,
        source_unit => Unit,
        target_unit => $parameters.p_unit)          as ConvertedQuantity

}
where
     Currency <> $parameters.p_currency
  or Unit     <> $parameters.p_unit

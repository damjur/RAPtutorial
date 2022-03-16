@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Receipt Header with caluculated fields'

define view entity ZDJ_I_TutposHeaderCalc
  as select from zdj_tut_pos_item as item
    inner join   zdj_tut_pos_head as header on header.id = item.id
{
  key item.id              as Id,

      header.currency        as Currency,
      @Semantics.amount.currencyCode: 'Currency'
      sum(  cast( item.quantity as abap.dec( 13, 2 ) )
        * cast( item.unit_price as abap.dec( 13, 2 ) ) ) as OverallPrice
}
group by
  item.id,
  header.currency

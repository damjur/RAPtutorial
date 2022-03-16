@EndUserText.label: 'Consumption view of receipt item'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define view entity ZDJ_C_TutorialItem
  as projection on ZDJ_I_TutposItem
{
  key Id,
  key Item,
      Description,
      Quantity,
      Unit,
      Currency,
      UnitPrice,
      Price,
      /* Associations */
      _Currency,
      _Header : redirected to parent ZDJ_C_TutorialHeader,
      _UnitOfMeasure
      
      
}

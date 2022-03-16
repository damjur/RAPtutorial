@EndUserText.label: 'Consumption view of receipt header'
@AccessControl.authorizationCheck: #CHECK
@Metadata.allowExtensions: true
define root view entity ZDJ_C_TutorialHeader
  provider contract transactional_query
  as projection on ZDJ_I_TutposHeader
{
  key     Id,
          Description,
          Currency,
          Customer,
          @ObjectModel.text.element: ['StatusText']
          Status,
          Creator,
          CreatedAt,
          Modificator,
          ModifiedAt,
          OverallPrice,
          _Status.Text       as StatusText : localized,
          @ObjectModel.virtualElementCalculatedBy:
             'ABAP:ZDJ_CL_CRITICALITY_PROVIDER'
  virtual Criticality :abap.numc(1),
           PictureURL,
          /* Associations */
          _Currency,
          _Items:redirected to composition child ZDJ_C_TutorialItem
}

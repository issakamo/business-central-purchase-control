namespace PurchaseControl.Purchasing;

permissionset 51100 "PCX Purch Risk User"
{
    Caption = 'Purchase Risk User';
    Assignable = true;

    Permissions =
        tabledata "PCX Purchase Risk Assessment" = R,
        tabledata "PCX Vendor Scorecard" = R,
        tabledata "PCX Purchase Risk Cue" = RIM,
        table "PCX Purchase Risk Assessment" = X,
        table "PCX Vendor Scorecard" = X,
        table "PCX Purchase Risk Cue" = X,
        page "PCX Purchase Risk List" = X,
        page "PCX Purchase Risk Card" = X,
        page "PCX Vendor Scorecard List" = X,
        page "PCX Purchase Risk Cue" = X;
}
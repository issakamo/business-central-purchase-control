namespace PurchaseControl.Purchasing;

permissionset 51101 "PCX Purch Risk Mgr"
{
    Caption = 'Purchase Risk Manager';
    Assignable = true;
    IncludedPermissionSets = "PCX Purch Risk User";

    Permissions =
        tabledata "PCX Purchase Risk Assessment" = IM,
        tabledata "PCX Vendor Scorecard" = IMD;
}
namespace WarehouseControl.Purchasing;

using Microsoft.Finance.RoleCenters;

pageextension 51102 "PCX Business Manager RC Ext" extends "Business Manager Role Center"
{
    layout
    {
        addfirst(RoleCenter)
        {
            part(PCXPurchaseRiskCue; "PCX Purchase Risk Cue")
            {
                ApplicationArea = All;
            }
        }
    }
}
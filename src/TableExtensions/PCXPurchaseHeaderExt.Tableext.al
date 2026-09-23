namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Document;

tableextension 51100 "PCX Purchase Header Ext" extends "Purchase Header"
{
    fields
    {
        field(51100; "PCX Current Risk Level"; Enum "PCX Risk Level")
        {
            Caption = 'Risk Level';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51101; "PCX Current Match Status"; Enum "PCX Match Status")
        {
            Caption = '3-Way Match Status';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(51102; "PCX Currently Overdue"; Boolean)
        {
            Caption = 'Currently Overdue';
            DataClassification = CustomerContent;
            Editable = false;
        }
    }
}
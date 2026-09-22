namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Vendor;

table 51101 "PCX Vendor Scorecard"
{
    Caption = 'Vendor Scorecard';
    DataClassification = CustomerContent;
    LookupPageId = "PCX Vendor Scorecard List";
    DrillDownPageId = "PCX Vendor Scorecard List";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            TableRelation = Vendor."No.";
            DataClassification = CustomerContent;
        }
        field(10; "Assessment Count"; Integer)
        {
            Editable = false;
            DataClassification = SystemMetadata;
        }
        field(20; "On-Time %"; Decimal)
        {
            DecimalPlaces = 0 : 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(21; "Quantity Accuracy %"; Decimal)
        {
            DecimalPlaces = 0 : 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(22; "Price Accuracy %"; Decimal)
        {
            DecimalPlaces = 0 : 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(30; "Overall Score"; Decimal)
        {
            DecimalPlaces = 0 : 1;
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(31; "Rating"; Enum "PCX Vendor Rating")
        {
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(40; "Last Calculated"; DateTime)
        {
            Editable = false;
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Vendor No.") { Clustered = true; }
    }
}
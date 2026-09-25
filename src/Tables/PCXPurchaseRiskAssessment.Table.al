namespace PurchaseControl.Purchasing;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

table 51100 "PCX Purchase Risk Assessment"
{
    Caption = 'Purchase Risk Assessment';
    DataClassification = CustomerContent;
    LookupPageId = "PCX Purchase Risk List";
    DrillDownPageId = "PCX Purchase Risk List";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            AutoIncrement = true;
            DataClassification = SystemMetadata;
        }
        field(10; "Document No."; Code[20])
        {
            Caption = 'PO Document No.';
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));
            DataClassification = CustomerContent;
        }
        field(11; "Vendor No."; Code[20])
        {
            TableRelation = Vendor."No.";
            DataClassification = CustomerContent;
        }
        field(20; "Assessment Date"; DateTime)
        {
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(21; "Trigger"; Enum "PCX Risk Trigger")
        {
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(30; "Risk Level"; Enum "PCX Risk Level")
        {
            DataClassification = CustomerContent;
        }
        field(31; "Match Status"; Enum "PCX Match Status")
        {
            DataClassification = CustomerContent;
        }
        field(40; "Overdue"; Boolean)
        {
            DataClassification = CustomerContent;
        }
        field(41; "Quantity Variance %"; Decimal)
        {
            DecimalPlaces = 0 : 2;
            DataClassification = CustomerContent;
        }
        field(42; "Price Variance %"; Decimal)
        {
            DecimalPlaces = 0 : 2;
            DataClassification = CustomerContent;
        }
        field(50; "Notes"; Text[250])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(DocRisk; "Document No.", "Assessment Date") { }
    }

    trigger OnInsert()
    begin
        if "Assessment Date" = 0DT then
            "Assessment Date" := CurrentDateTime;
    end;
}
namespace PurchaseControl.Purchasing;

using Microsoft.Purchases.Document;

table 51102 "PCX Purchase Risk Cue"
{
    Caption = 'Purchase Risk Cue';
    DataClassification = SystemMetadata;
    TableType = Normal;

    fields
    {
        field(1; "Primary Key"; Code[10]) { DataClassification = SystemMetadata; }
        field(10; "Critical Risk POs"; Integer)
        {
            Caption = 'Critical Risk';
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("PCX Current Risk Level" = const(Critical)));
            Editable = false;
        }
        field(11; "High Risk POs"; Integer)
        {
            Caption = 'High Risk';
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("PCX Current Risk Level" = const(High)));
            Editable = false;
        }
        field(12; "Overdue POs"; Integer)
        {
            Caption = 'Overdue';
            FieldClass = FlowField;
            CalcFormula = count("Purchase Header" where("PCX Currently Overdue" = const(true)));
            Editable = false;
        }
    }

    keys { key(PK; "Primary Key") { Clustered = true; } }
}
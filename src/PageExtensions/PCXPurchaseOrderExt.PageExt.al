namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Document;

pageextension 51100 "PCX Purchase Order Ext" extends "Purchase Order"
{
    layout
    {
        addafter("Vendor Invoice No.")
        {
            field("PCX Current Risk Level"; Rec."PCX Current Risk Level")
            {
                ApplicationArea = All;
                Caption = 'Risk Level';
                ToolTip = 'Specifies the current risk level for this purchase order.';
                StyleExpr = RiskStyle;
                Editable = false;
            }
            field("PCX Current Match Status"; Rec."PCX Current Match Status")
            {
                ApplicationArea = All;
                Caption = '3-Way Match Status';
                ToolTip = 'Specifies the current 3-way match status for this purchase order.';
                Editable = false;
            }
        }
    }

    actions
    {
        addafter(Approve)
        {
            action(PCXViewRiskHistory)
            {
                ApplicationArea = All;
                Caption = 'Risk Assessment History';
                ToolTip = 'View the risk assessment history for this purchase order.';
                Image = History;
                trigger OnAction()
                var
                    Assessment: Record "PCX Purchase Risk Assessment";
                    RiskList: Page "PCX Purchase Risk List";
                begin
                    Assessment.SetRange("Document No.", Rec."No.");
                    RiskList.SetTableView(Assessment);
                    RiskList.Run();
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetRiskStyle();
    end;

    local procedure SetRiskStyle()
    begin
        case Rec."PCX Current Risk Level" of
            Rec."PCX Current Risk Level"::Critical:
                RiskStyle := 'Unfavorable';
            Rec."PCX Current Risk Level"::High:
                RiskStyle := 'Ambiguous';
            else
                RiskStyle := 'Standard';
        end;
    end;

    var
        RiskStyle: Text;
}
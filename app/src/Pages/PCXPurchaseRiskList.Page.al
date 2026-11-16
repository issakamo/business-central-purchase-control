namespace PurchaseControl.Purchasing;

page 51100 "PCX Purchase Risk List"
{
    ApplicationArea = All;
    Caption = 'Purchase Risk Assessments';
    PageType = List;
    SourceTable = "PCX Purchase Risk Assessment";
    UsageCategory = Lists;
    CardPageId = "PCX Purchase Risk Card";
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                    Tooltip = 'The unique identifier for the risk assessment entry.';
                }
                field("Document No."; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    ToolTip = 'The purchase document number associated with this risk assessment.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                    ToolTip = 'The vendor number associated with this risk assessment.';
                }
                field("Assessment Date"; Rec."Assessment Date")
                {
                    Caption = 'Assessment Date';
                    ToolTip = 'The date when the risk assessment was performed.';
                }
                field("Trigger"; Rec."Trigger")
                {
                    Caption = 'Trigger';
                    ToolTip = 'The event or condition that triggered this risk assessment.';
                }
                field("Match Status"; Rec."Match Status")
                {
                    Caption = 'Match Status';
                    ToolTip = 'The status of the 3-way match for this risk assessment.';
                }
                field("Risk Level"; Rec."Risk Level")
                {
                    Caption = 'Risk Level';
                    StyleExpr = RiskStyle;
                    ToolTip = 'The level of risk associated with this assessment.';
                }
                field("Overdue"; Rec."Overdue")
                {
                    Caption = 'Overdue';
                    ToolTip = 'Indicates whether the purchase order is overdue.';
                }
                field("Quantity Variance %"; Rec."Quantity Variance %")
                {
                    Caption = 'Quantity Variance %';
                    ToolTip = 'The percentage variance in the quantity ordered versus received.';
                }
                field("Price Variance %"; Rec."Price Variance %")
                {
                    Caption = 'Price Variance %';
                    ToolTip = 'The percentage variance in the price ordered versus invoiced.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetRiskStyle();
    end;

    local procedure SetRiskStyle()
    begin
        case Rec."Risk Level" of
            Rec."Risk Level"::Critical:
                RiskStyle := 'Unfavorable';
            Rec."Risk Level"::High:
                RiskStyle := 'Ambiguous';
            else
                RiskStyle := 'Standard';
        end;
    end;

    var
        RiskStyle: Text;
}
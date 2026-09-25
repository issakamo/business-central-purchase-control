namespace PurchaseControl.Purchasing;

page 51101 "PCX Vendor Scorecard List"
{
    ApplicationArea = All;
    Caption = 'Vendor Scorecards';
    PageType = List;
    SourceTable = "PCX Vendor Scorecard";
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    Tooltip = 'Specifies the vendor associated with this scorecard.';
                }
                field("Assessment Count"; Rec."Assessment Count")
                {
                    Tooltip = 'Specifies the number of assessments included in the vendor scorecard.';
                }
                field("On-Time %"; Rec."On-Time %")
                {
                    Tooltip = 'Specifies the percentage of purchase order lines delivered on time.';
                }
                field("Quantity Accuracy %"; Rec."Quantity Accuracy %")
                {
                    Tooltip = 'Specifies the percentage of purchase order quantities delivered accurately.';
                }
                field("Price Accuracy %"; Rec."Price Accuracy %")
                {
                    Tooltip = 'Specifies the percentage of purchase order prices delivered accurately.';
                }
                field("Overall Score"; Rec."Overall Score")
                {
                    Tooltip = 'Specifies the overall vendor score calculated from the scorecard results.';
                    StyleExpr = ScoreStyle;
                }
                field(Rating; Rec.Rating)
                {
                    Tooltip = 'Specifies the vendor rating based on the scorecard results.';
                    StyleExpr = ScoreStyle;
                }
                field("Last Calculated"; Rec."Last Calculated")
                {
                    Tooltip = 'Specifies the date and time when the vendor scorecard was last calculated.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        SetScoreStyle();
    end;

    local procedure SetScoreStyle()
    begin
        case Rec.Rating of
            Rec.Rating::"Insufficient Data":
                ScoreStyle := 'Subordinate';
            Rec.Rating::Poor:
                ScoreStyle := 'Unfavorable';
            Rec.Rating::Fair:
                ScoreStyle := 'Ambiguous';
            else
                ScoreStyle := 'Favorable';
        end;
    end;

    var
        ScoreStyle: Text;
}
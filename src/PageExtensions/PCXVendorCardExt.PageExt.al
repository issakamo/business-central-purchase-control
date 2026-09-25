namespace PurchaseControl.Purchasing;

using Microsoft.Purchases.Vendor;

pageextension 51101 "PCX Vendor Card Ext" extends "Vendor Card"
{
    layout
    {
        addafter(General)
        {
            group(PCXScorecard)
            {
                Caption = 'Purchase Risk Scorecard';

                field("PCX Overall Score"; ScorecardOverallScore)
                {
                    ApplicationArea = All;
                    Caption = 'Overall Score';
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s overall purchase risk score.';
                    StyleExpr = ScoreStyle;
                }
                field("PCX Rating"; ScorecardRating)
                {
                    ApplicationArea = All;
                    Caption = 'Rating';
                    Editable = false;
                    ToolTip = 'Specifies the vendor''s purchase risk rating.';
                    StyleExpr = ScoreStyle;
                }
                field("PCX Assessment Count"; ScorecardAssessmentCount)
                {
                    ApplicationArea = All;
                    Caption = 'Assessments';
                    Editable = false;
                    ToolTip = 'Specifies the number of purchase risk assessments for the vendor.';

                    trigger OnDrillDown()
                    var
                        Assessment: Record "PCX Purchase Risk Assessment";
                        RiskList: Page "PCX Purchase Risk List";
                    begin
                        Assessment.SetRange("Vendor No.", Rec."No.");
                        RiskList.SetTableView(Assessment);
                        RiskList.Run();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        LoadScorecard();
    end;

    local procedure LoadScorecard()
    var
        Scorecard: Record "PCX Vendor Scorecard";
    begin
        if Scorecard.Get(Rec."No.") then begin
            ScorecardOverallScore := Scorecard."Overall Score";
            ScorecardRating := Format(Scorecard.Rating);
            ScorecardAssessmentCount := Scorecard."Assessment Count";
        end else begin
            ScorecardOverallScore := 0;
            ScorecardRating := Format(Enum::"PCX Vendor Rating"::"Insufficient Data");
            ScorecardAssessmentCount := 0;
        end;

        SetScoreStyle();
    end;

    local procedure SetScoreStyle()
    begin
        case ScorecardRating of
            Format(Enum::"PCX Vendor Rating"::Poor):
                ScoreStyle := 'Unfavorable';
            Format(Enum::"PCX Vendor Rating"::Fair):
                ScoreStyle := 'Ambiguous';
            Format(Enum::"PCX Vendor Rating"::"Insufficient Data"):
                ScoreStyle := 'Subordinate';
            else
                ScoreStyle := 'Favorable';
        end;
    end;

    var
        ScorecardOverallScore: Decimal;
        ScorecardRating: Text;
        ScorecardAssessmentCount: Integer;
        ScoreStyle: Text;
}
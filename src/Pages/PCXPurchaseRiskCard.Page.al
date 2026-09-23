namespace WarehouseControl.Purchasing;

page 51102 "PCX Purchase Risk Card"
{
    ApplicationArea = All;
    Caption = 'Purchase Risk Assessment';
    PageType = Card;
    SourceTable = "PCX Purchase Risk Assessment";
    UsageCategory = None;
    Editable = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("Document No."; Rec."Document No.")
                {
                    Caption = 'Document No.';
                    Tooltip = 'Specifies the number of the purchase document.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    Caption = 'Vendor No.';
                    Tooltip = 'Specifies the vendor number associated with this risk assessment.';
                }
                field("Assessment Date"; Rec."Assessment Date")
                {
                    Caption = 'Assessment Date';
                    Tooltip = 'Specifies the date when the risk assessment was performed.';
                }
                field("Trigger"; Rec."Trigger")
                {
                    Caption = 'Trigger';
                    Tooltip = 'Specifies the event or condition that triggered this risk assessment.';
                }
            }
            group(Result)
            {
                Caption = 'Assessment Result (as calculated)';
                field("Match Status"; Rec."Match Status")
                {
                    Caption = 'Match Status';
                    Tooltip = 'Specifies the status of the 3-way match for this risk assessment.';
                }
                field("Risk Level"; Rec."Risk Level")
                {
                    Caption = 'Risk Level';
                    Tooltip = 'Specifies the level of risk associated with this assessment.';
                }
                field("Overdue"; Rec."Overdue")
                {
                    Caption = 'Overdue';
                    Tooltip = 'Specifies whether the purchase order is overdue.';
                }
                field("Quantity Variance %"; Rec."Quantity Variance %")
                {
                    Caption = 'Quantity Variance %';
                    Tooltip = 'Specifies the percentage variance in the quantity ordered versus received.';
                }
                field("Price Variance %"; Rec."Price Variance %")
                {
                    Caption = 'Price Variance %';
                    Tooltip = 'Specifies the percentage variance in the price ordered versus invoiced.';
                }
            }
            group(AssessmentNotes)
            {
                field("Notes"; Rec."Notes")
                {
                    Editable = true;
                    Tooltip = 'Specifies additional notes for this purchase risk assessment.';
                }
            }
        }
    }
}
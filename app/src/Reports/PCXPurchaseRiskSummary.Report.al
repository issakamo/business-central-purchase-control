namespace PurchaseControl.Purchasing;

using Microsoft.Purchases.Document;

report 51100 "PCX Purchase Risk Summary"
{
    Caption = 'Purchase Risk Summary';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultLayout = Word;
    WordLayout = './src/Reports/Layouts/PurchaseRiskSummary.docx';

    dataset
    {
        dataitem(OpenRiskOrders; "Purchase Header")
        {
            DataItemTableView = where("Document Type" = const(Order));
            RequestFilterFields = "Buy-from Vendor No.";

            column(HeaderText_; HeaderText) { }
            column(No_; "No.") { }
            column(BuyFromVendorNo; "Buy-from Vendor No.") { }
            column(BuyFromVendorName; "Buy-from Vendor Name") { }
            column(RiskLevel; "PCX Current Risk Level") { }
            column(MatchStatus; "PCX Current Match Status") { }
            column(CurrentlyOverdue; "PCX Currently Overdue") { }

            trigger OnPreDataItem()
            begin
                RiskReportMgt.ApplyMinimumRiskFilter(OpenRiskOrders, MinimumRiskLevel);
            end;
        }
        dataitem(VendorScorecards; "PCX Vendor Scorecard")
        {
            column(VendorNo; "Vendor No.") { }
            column(AssessmentCount; "Assessment Count") { }
            column(OnTimePctTxt; OnTimePctTxt) { }
            column(QtyAccuracyPctTxt; QtyAccuracyPctTxt) { }
            column(PriceAccuracyPctTxt; PriceAccuracyPctTxt) { }
            column(OverallScoreTxt; OverallScoreTxt) { }
            column(Rating; Rating) { }

            trigger OnPreDataItem()
            begin
                if not IncludeInsufficientData then
                    SetFilter(Rating, '<>%1', Rating::"Insufficient Data");
            end;

            trigger OnAfterGetRecord()
            begin
                // An unrated vendor has no measured scores. Printing 0 would
                // read as a measured 0%, so these are left blank instead.
                if Rating = Rating::"Insufficient Data" then begin
                    OnTimePctTxt := '';
                    QtyAccuracyPctTxt := '';
                    PriceAccuracyPctTxt := '';
                    OverallScoreTxt := '';
                end else begin
                    OnTimePctTxt := Format("On-Time %", 0, '<Precision,0:1><Standard Format,0>');
                    QtyAccuracyPctTxt := Format("Quantity Accuracy %", 0, '<Precision,0:1><Standard Format,0>');
                    PriceAccuracyPctTxt := Format("Price Accuracy %", 0, '<Precision,0:1><Standard Format,0>');
                    OverallScoreTxt := Format("Overall Score", 0, '<Precision,0:1><Standard Format,0>');
                end;
            end;
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(MinimumRiskLevelField; MinimumRiskLevel)
                    {
                        ApplicationArea = All;
                        Caption = 'Minimum Risk Level to Include';
                        ToolTip = 'Specifies the minimum risk level for purchase orders to include in the report.';
                    }
                    field(IncludeInsufficientDataField; IncludeInsufficientData)
                    {
                        ApplicationArea = All;
                        Caption = 'Include Vendors with Insufficient Data';
                        ToolTip = 'Specifies whether to include vendors with insufficient data in the report.';
                    }
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        MinimumRiskLevel := MinimumRiskLevel::Medium;
        IncludeInsufficientData := true;
    end;

    trigger OnPreReport()
    begin
        HeaderText := StrSubstNo(HeaderTextLbl, MinimumRiskLevel);
    end;

    var
        RiskReportMgt: Codeunit "PCX Risk Report Mgt";
        MinimumRiskLevel: Enum "PCX Risk Level";
        IncludeInsufficientData: Boolean;
        HeaderText: Text;
        HeaderTextLbl: Label 'Purchase Risk Summary - Orders at %1 Risk or Higher', Comment = '%1 = minimum risk level';
        OnTimePctTxt: Text;
        QtyAccuracyPctTxt: Text;
        PriceAccuracyPctTxt: Text;
        OverallScoreTxt: Text;

}
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
            column(ExpectedReceiptDate; "Expected Receipt Date") { }
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
            column(AssessmentCount; "Assessment Count") { }
            column(OnTimePct; "On-Time %") { }
            column(QtyAccuracyPct; "Quantity Accuracy %") { }
            column(PriceAccuracyPct; "Price Accuracy %") { }
            column(OverallScore; "Overall Score") { }
            column(Rating; Rating) { }
            column(VendorNo; "Vendor No.") { }

            trigger OnPreDataItem()
            begin
                if not IncludeInsufficientData then
                    SetFilter(Rating, '<>%1', Rating::"Insufficient Data");
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
}
namespace PurchaseControl.Purchasing;

codeunit 51102 "PCX Vendor Scorecard Mgt"
{
    // A floor against single-data-point false confidence, not a claim that
    // this many assessments is statistically sufficient — a vendor rated
    // off exactly this many POs is still a thin sample, just not the
    // worst case (one lucky/unlucky PO deciding the entire rating).
    var
        MinimumAssessmentsForRating: Integer;

    procedure RecalculateScorecard(VendorNo: Code[20])
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        Scorecard: Record "PCX Vendor Scorecard";
        TotalCount: Integer;
        OnTimeCount: Integer;
        QtyVarianceSum: Decimal;
        PriceVarianceSum: Decimal;
        OnTimePct: Decimal;
        QtyAccuracyPct: Decimal;
        PriceAccuracyPct: Decimal;
        OverallScore: Decimal;
    begin
        MinimumAssessmentsForRating := 5;

        Assessment.SetRange("Vendor No.", VendorNo);
        if Assessment.FindSet() then
            repeat
                TotalCount += 1;
                if not Assessment.Overdue then
                    OnTimeCount += 1;
                QtyVarianceSum += Abs(Assessment."Quantity Variance %");
                PriceVarianceSum += Abs(Assessment."Price Variance %");
            until Assessment.Next() = 0;

        if not Scorecard.Get(VendorNo) then begin
            Scorecard.Init();
            Scorecard."Vendor No." := VendorNo;
            Scorecard.Insert();
        end;

        Scorecard."Assessment Count" := TotalCount;
        Scorecard."Last Calculated" := CurrentDateTime;

        if TotalCount < MinimumAssessmentsForRating then begin
            Scorecard.Rating := Scorecard.Rating::"Insufficient Data";
            Scorecard."On-Time %" := 0;
            Scorecard."Quantity Accuracy %" := 0;
            Scorecard."Price Accuracy %" := 0;
            Scorecard."Overall Score" := 0;
            Scorecard.Modify();
            exit;
        end;

        OnTimePct := OnTimeCount / TotalCount * 100;
        QtyAccuracyPct := 100 - (QtyVarianceSum / TotalCount);
        PriceAccuracyPct := 100 - (PriceVarianceSum / TotalCount);
        OverallScore := (OnTimePct + QtyAccuracyPct + PriceAccuracyPct) / 3;

        Scorecard."On-Time %" := OnTimePct;
        Scorecard."Quantity Accuracy %" := QtyAccuracyPct;
        Scorecard."Price Accuracy %" := PriceAccuracyPct;
        Scorecard."Overall Score" := OverallScore;
        Scorecard.Rating := DetermineRating(OverallScore);
        Scorecard.Modify();
    end;

    local procedure DetermineRating(OverallScore: Decimal): Enum "PCX Vendor Rating"
    begin
        case true of
            OverallScore >= 90:
                exit(Enum::"PCX Vendor Rating"::Excellent);
            OverallScore >= 75:
                exit(Enum::"PCX Vendor Rating"::Good);
            OverallScore >= 60:
                exit(Enum::"PCX Vendor Rating"::Fair);
            else
                exit(Enum::"PCX Vendor Rating"::Poor);
        end;
    end;
}
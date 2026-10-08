namespace PurchaseControl.Purchasing.Test;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using PurchaseControl.Purchasing;

codeunit 51122 "PCX Vendor Scorecard Test"
{
    Subtype = Test;

    [Test]
    procedure RecalculateScorecard_BelowMinimum_ReturnsInsufficientData()
    var
        Scorecard: Record "PCX Vendor Scorecard";
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        ScorecardMgt: Codeunit "PCX Vendor Scorecard Mgt";
    begin
        // [GIVEN] Only 2 assessments for this vendor (below the 5 minimum)
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 100, PurchaseHeader);
        ScorecardMgt.RecalculateScorecard(PurchaseHeader."Buy-from Vendor No.");
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 100, PurchaseHeader);

        // [WHEN]
        ScorecardMgt.RecalculateScorecard(PurchaseHeader."Buy-from Vendor No.");

        // [THEN]
        Scorecard.Get(PurchaseHeader."Buy-from Vendor No.");
        Assert.AreEqual(Scorecard.Rating::"Insufficient Data", Scorecard.Rating, 'Expected Insufficient Data below the minimum');
    end;

    [Test]
    procedure RecalculateScorecard_AllOnTimeAndAccurate_ReturnsExcellent()
    var
        Vendor: Record Vendor;
        Scorecard: Record "PCX Vendor Scorecard";
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        ScorecardMgt: Codeunit "PCX Vendor Scorecard Mgt";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        LibraryPurchase: Codeunit "Library - Purchase";
        i: Integer;
    begin
        // [GIVEN] One vendor, 5 fully-matched, on-time assessments against them
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 5 do begin
            TestLibrary.CreatePurchaseOrderWithReceiptForVendor(Vendor."No.", 100, 100, PurchaseHeader);
            RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::"Receipt Posted");
        end;

        // [WHEN]
        ScorecardMgt.RecalculateScorecard(Vendor."No.");

        // [THEN]
        Scorecard.Get(Vendor."No.");
        Assert.AreEqual(Scorecard.Rating::Excellent, Scorecard.Rating, 'Expected Excellent with perfect on-time, matched history');
        Assert.AreEqual(100, Scorecard."Overall Score", 'Expected a perfect 100 overall score');
    end;

    [Test]
    procedure RecalculateScorecard_ExtremeVariance_AccuracyFlooredAtZero()
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        Scorecard: Record "PCX Vendor Scorecard";
        Vendor: Record Vendor;
        ScorecardMgt: Codeunit "PCX Vendor Scorecard Mgt";
        LibraryPurchase: Codeunit "Library - Purchase";
        i: Integer;
    begin
        // [GIVEN] A vendor with 5 assessments, each with a 500% price variance
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 5 do begin
            Assessment.Init();
            Assessment."Document No." := 'TEST';
            Assessment."Vendor No." := Vendor."No.";
            Assessment."Price Variance %" := 500;
            Assessment.Insert(true);
        end;

        // [WHEN]
        ScorecardMgt.RecalculateScorecard(Vendor."No.");

        // [THEN] Price accuracy floors at zero, and the overall score stays non-negative
        Scorecard.Get(Vendor."No.");
        Assert.AreEqual(0, Scorecard."Price Accuracy %", 'Price accuracy should floor at zero');
        Assert.IsTrue(Scorecard."Overall Score" >= 0, 'Overall score should never be negative');
    end;

    var
        Assert: Codeunit Assert;
}
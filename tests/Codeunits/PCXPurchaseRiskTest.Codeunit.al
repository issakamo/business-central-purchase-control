namespace PurchaseControl.Purchasing.Test;

using Microsoft.Purchases.Document;
using PurchaseControl.Purchasing;
using System.TestLibraries.Utilities;

codeunit 51120 "PCX Purchase Risk Test"
{
    Subtype = Test;

    [Test]
    procedure EvaluateReceiptMatch_NoReceipt_ReturnsNotYetReceived()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 0, PurchaseHeader);

        Result := RiskMgt.EvaluateReceiptMatch(PurchaseHeader."No.", QtyVariancePct);

        Assert.AreEqual(Result::"Not Yet Received", Result, 'Expected Not Yet Received');
        Assert.AreEqual(0, QtyVariancePct, 'Variance should be 0 when nothing received');
    end;

    [Test]
    procedure EvaluateReceiptMatch_PartialReceipt_ReturnsQuantityMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 80, PurchaseHeader);

        Result := RiskMgt.EvaluateReceiptMatch(PurchaseHeader."No.", QtyVariancePct);

        Assert.AreEqual(Result::"Quantity Mismatch", Result, 'Expected Quantity Mismatch');
        Assert.AreEqual(20, QtyVariancePct, 'Expected 20% variance');
    end;

    [Test]
    procedure EvaluateReceiptMatch_FullReceipt_ReturnsMatched()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 100, PurchaseHeader);

        Result := RiskMgt.EvaluateReceiptMatch(PurchaseHeader."No.", QtyVariancePct);

        Assert.AreEqual(Result::Matched, Result, 'Expected Matched');
        Assert.AreEqual(0, QtyVariancePct, 'Expected 0% variance');
    end;

    [Test]
    procedure EvaluateInvoiceMatch_NoInvoice_ReturnsNotYetInvoiced()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";

        PriceVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 100, 0, 10, 0, PurchaseHeader);

        Result := RiskMgt.EvaluateInvoiceMatch(PurchaseHeader."No.", PriceVariancePct);

        Assert.AreEqual(Result::"Not Yet Invoiced", Result, 'Expected Not Yet Invoiced');
    end;

    [Test]
    procedure EvaluateInvoiceMatch_SamePrice_ReturnsMatched()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        PriceVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 100, 100, 10, 10, PurchaseHeader);

        Result := RiskMgt.EvaluateInvoiceMatch(PurchaseHeader."No.", PriceVariancePct);

        Assert.AreEqual(Result::Matched, Result, 'Expected Matched');
        Assert.AreEqual(0, PriceVariancePct, 'Expected 0% variance');
    end;

    [Test]
    procedure EvaluateInvoiceMatch_HigherPrice_ReturnsPriceMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        PriceVariancePct: Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 100, 100, 10, 12, PurchaseHeader);

        Result := RiskMgt.EvaluateInvoiceMatch(PurchaseHeader."No.", PriceVariancePct);

        Assert.AreEqual(Result::"Price Mismatch", Result, 'Expected Price Mismatch');
        Assert.AreEqual(20, PriceVariancePct, 'Expected 20% variance');
    end;

    [Test]
    procedure EvaluateThreeWayMatch_FullyMatched_ReturnsMatched()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 100, 100, 10, 10, PurchaseHeader);

        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        Assert.AreEqual(Result::Matched, Result, 'Expected fully Matched');
    end;

    [Test]
    procedure EvaluateThreeWayMatch_QtyOnlyMismatch_ReturnsQuantityMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 80, 80, 10, 10, PurchaseHeader);

        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        Assert.AreEqual(Result::"Quantity Mismatch", Result, 'Expected Quantity Mismatch only');
    end;

    [Test]
    procedure EvaluateThreeWayMatch_PriceOnlyMismatch_ReturnsPriceMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 100, 100, 10, 12, PurchaseHeader);

        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        Assert.AreEqual(Result::"Price Mismatch", Result, 'Expected Price Mismatch only');
    end;

    [Test]
    procedure EvaluateThreeWayMatch_BothMismatch_ReturnsQuantityAndPriceMismatch()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceiptAndInvoice(100, 80, 80, 10, 12, PurchaseHeader);

        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        Assert.AreEqual(Result::"Quantity and Price Mismatch", Result, 'Expected both mismatched');
    end;

    [Test]
    procedure EvaluateThreeWayMatch_NotReceived_ShortCircuitsBeforeInvoiceCheck()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 0, PurchaseHeader);

        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        Assert.AreEqual(Result::"Not Yet Received", Result, 'Expected Not Yet Received to take precedence');
    end;

    [Test]
    procedure DetermineRiskLevel_BothMismatchSmall_EscalatesOneTierFromLow()
    var
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        Result: Enum "PCX Risk Level";
    begin
        // [GIVEN] Both variances are small (below the 5% Medium threshold)
        // [WHEN]
        Result := RiskMgt.DetermineRiskLevel(Enum::"PCX Match Status"::"Quantity and Price Mismatch", false, 4, 4);

        // [THEN] Baseline is Low, escalated one tier to Medium — not Critical
        Assert.AreEqual(Result::Medium, Result, 'Expected Medium, not an inflated Critical from summing small variances');
    end;

    [Test]
    procedure DetermineRiskLevel_OneLargeOneSmall_BaselinesOnLarger()
    var
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        Result: Enum "PCX Risk Level";
    begin
        // [GIVEN] Quantity variance small (4%), price variance large (45%)
        // [WHEN]
        Result := RiskMgt.DetermineRiskLevel(Enum::"PCX Match Status"::"Quantity and Price Mismatch", false, 4, 45);

        // [THEN] Baseline is High (from the 45%), escalated to Critical
        Assert.AreEqual(Result::Critical, Result, 'Expected baseline from the larger variance, escalated one tier');
    end;

    [Test]
    procedure DetermineRiskLevel_OverdueOnly_NudgesLowToMediumButNeverHigher()
    var
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        CleanResult: Enum "PCX Risk Level";
        MismatchResult: Enum "PCX Risk Level";
    begin
        // [GIVEN/WHEN] A clean match, overdue
        CleanResult := RiskMgt.DetermineRiskLevel(Enum::"PCX Match Status"::Matched, true, 0, 0);
        // [GIVEN/WHEN] An already-High mismatch, also overdue
        MismatchResult := RiskMgt.DetermineRiskLevel(Enum::"PCX Match Status"::"Quantity Mismatch", true, 25, 0);

        // [THEN] Overdue nudges a clean PO to Medium, but never overrides a worse tier
        Assert.AreEqual(CleanResult::Medium, CleanResult, 'Overdue alone should nudge Low to Medium');
        Assert.AreEqual(MismatchResult::High, MismatchResult, 'Overdue should not override an already-worse tier');
    end;

    [Test]
    procedure ReleasePurchaseOrder_CreatesReleasedTriggerAssessment()
    var
        PurchaseHeader: Record "Purchase Header";
        Assessment: Record "PCX Purchase Risk Assessment";
        TestLibrary: Codeunit "PCX Purchase Test Library";
    begin
        // [GIVEN/WHEN] A purchase order is created and released
        TestLibrary.CreateAndReleasePurchaseOrder(100, PurchaseHeader);

        // [THEN] A risk assessment exists for this document, triggered by Released
        Assessment.SetRange("Document No.", PurchaseHeader."No.");
        Assessment.SetRange("Trigger", Assessment."Trigger"::Released);
        Assert.RecordIsNotEmpty(Assessment);
    end;

    [Test]
    procedure AssessPurchaseOrder_RepeatedIdenticalTrigger_DoesNotDuplicateAssessment()
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
    begin
        // [GIVEN] A PO assessed once via Release
        TestLibrary.CreateAndReleasePurchaseOrder(100, PurchaseHeader);
        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::Released);

        // [WHEN] The identical assessment is triggered again (simulating BC's
        // internal re-release during posting) with no change in state
        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::Released);

        // [THEN] Only one assessment record exists for this document
        Assessment.SetRange("Document No.", PurchaseHeader."No.");
        Assert.AreEqual(1, Assessment.Count(), 'Redundant identical assessment should not create a duplicate row');
    end;

    [Test]
    procedure AssessPurchaseOrder_OverdueChangeOnly_StillRecordsNewAssessment()
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
    begin
        // [GIVEN] A PO assessed once, not overdue (matches nothing yet)
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 0, PurchaseHeader);
        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::Manual);

        // [WHEN] Backdate the expected receipt date so the same PO is now
        // overdue, with Match Status/Risk Level otherwise unchanged
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        PurchaseHeader."Expected Receipt Date" := CalcDate('<-30D>', Today);
        PurchaseHeader.Modify();
        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::Manual);

        // [THEN] A second, distinct assessment was recorded despite unchanged
        // Match Status/Risk Level, because Overdue changed
        Assessment.SetRange("Document No.", PurchaseHeader."No.");
        Assert.AreEqual(2, Assessment.Count(), 'Overdue-only change should not be treated as redundant');

        // [AND] The header cache reflects the new overdue state
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        Assert.IsTrue(PurchaseHeader."PCX Currently Overdue", 'Header cache should reflect the updated overdue flag');
    end;


    [Test]
    procedure EvaluateThreeWayMatch_QtyMismatchNotYetInvoiced_ReportsQuantityMismatchNotMasked()
    var
        PurchaseHeader: Record "Purchase Header";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        QtyVariancePct, PriceVariancePct : Decimal;
        Result: Enum "PCX Match Status";
    begin
        // [GIVEN] Ordered 100, received 20 — a real 80% quantity variance —
        // with nothing invoiced yet
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 20, PurchaseHeader);

        // [WHEN]
        Result := RiskMgt.EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);

        // [THEN] The real mismatch is reported, not hidden behind "Not Yet
        // Invoiced" just because invoicing hasn't happened yet
        Assert.AreEqual(Result::"Quantity Mismatch", Result, 'A known quantity mismatch should not be masked by Not Yet Invoiced');
    end;


    [Test]
    procedure ApplyMinimumRiskFilter_MediumThreshold_ExcludesLowOnly()
    var
        PurchaseHeader: Record "Purchase Header";
        LowHeader: Record "Purchase Header";
        MediumHeader: Record "Purchase Header";
        RiskReportMgt: Codeunit "PCX Risk Report Mgt";
        TestLibrary: Codeunit "PCX Purchase Test Library";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
    begin
        // [GIVEN] One Low-risk PO (fully matched) and one Medium-or-worse PO
        TestLibrary.CreatePurchaseOrderWithReceipt(100, 100, LowHeader);
        RiskMgt.AssessPurchaseOrder(LowHeader, Enum::"PCX Risk Trigger"::"Receipt Posted");

        TestLibrary.CreatePurchaseOrderWithReceipt(100, 80, MediumHeader);
        RiskMgt.AssessPurchaseOrder(MediumHeader, Enum::"PCX Risk Trigger"::"Receipt Posted");

        // [WHEN]
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        RiskReportMgt.ApplyMinimumRiskFilter(PurchaseHeader, Enum::"PCX Risk Level"::Medium);

        // [THEN] The Low-risk PO is excluded, the mismatched one is included
        PurchaseHeader.SetRange("No.", LowHeader."No.");
        Assert.IsTrue(PurchaseHeader.IsEmpty(), 'Low-risk PO should be excluded at Medium threshold');

        PurchaseHeader.SetRange("No.", MediumHeader."No.");
        Assert.IsFalse(PurchaseHeader.IsEmpty(), 'Medium-or-worse PO should be included');
    end;


    var
        Assert: Codeunit "Library Assert";
}
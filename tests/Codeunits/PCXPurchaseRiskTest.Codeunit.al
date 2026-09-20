namespace WarehouseControl.Purchasing.Test;

using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;
using WarehouseControl.Purchasing;

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

    var
        Assert: Codeunit "Library Assert";
}
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

    var
        Assert: Codeunit "Library Assert";
}
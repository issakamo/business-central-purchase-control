namespace WarehouseControl.Purchasing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 51121 "PCX Purchase Test Library"
{
   procedure CreatePurchaseOrderWithReceipt(OrderedQty: Decimal; ReceivedQty: Decimal; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreateBasePurchaseOrder(PurchaseHeader, PurchaseLine, OrderedQty);
        if ReceivedQty > 0 then
            PostReceiptOnly(PurchaseHeader, PurchaseLine, ReceivedQty);
    end;

    procedure CreatePurchaseOrderWithReceiptAndInvoice(OrderedQty: Decimal; ReceivedQty: Decimal; InvoicedQty: Decimal; UnitPrice: Decimal; InvoicedUnitPrice: Decimal; var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        CreateBasePurchaseOrder(PurchaseHeader, PurchaseLine, OrderedQty);

        PurchaseLine.Validate("Direct Unit Cost", UnitPrice);
        PurchaseLine.Modify(true);

        if ReceivedQty > 0 then
            PostReceiptOnly(PurchaseHeader, PurchaseLine, ReceivedQty);

        if InvoicedQty > 0 then begin
            PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
            PurchaseLine.Validate("Qty. to Invoice", InvoicedQty);
            PurchaseLine.Validate("Direct Unit Cost", InvoicedUnitPrice);
            PurchaseLine.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);
        end;
    end;

    local procedure CreateBasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; OrderedQty: Decimal)
    var
        Vendor: Record Vendor;
        Item: Record Item;
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", OrderedQty);
    end;

    local procedure PostReceiptOnly(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ReceivedQty: Decimal)
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        PurchaseLine.Validate("Qty. to Receive", ReceivedQty);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
    end;
}
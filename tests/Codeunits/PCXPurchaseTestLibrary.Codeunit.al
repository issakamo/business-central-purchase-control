namespace WarehouseControl.Purchasing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 51121 "PCX Purchase Test Library"
{
    procedure CreatePurchaseOrderWithReceipt(OrderedQty: Decimal; ReceivedQty: Decimal; var PurchaseHeader: Record "Purchase Header")
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", OrderedQty);

        if ReceivedQty > 0 then begin
            PurchaseLine.Validate("Qty. to Receive", ReceivedQty);
            PurchaseLine.Modify(true);
            LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        end;
    end;
}
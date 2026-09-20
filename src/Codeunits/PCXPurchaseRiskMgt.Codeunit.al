namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 51100 "PCX Purchase Risk Mgt"
{
    procedure AssessPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; RiskTrigger: Enum "PCX Risk Trigger")
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        MatchStatus: Enum "PCX Match Status";
        QtyVariancePct: Decimal;
        PriceVariancePct: Decimal;
        IsOverdue: Boolean;
    begin
        MatchStatus := EvaluateReceiptMatch(PurchaseHeader."No.", QtyVariancePct);
        IsOverdue := IsOrderOverdue(PurchaseHeader);

        Assessment.Init();
        Assessment."Document No." := PurchaseHeader."No.";
        Assessment."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        Assessment."Trigger" := RiskTrigger;
        Assessment."Match Status" := MatchStatus;
        Assessment."Overdue" := IsOverdue;
        Assessment."Quantity Variance %" := QtyVariancePct;
        Assessment.Insert(true);

        PurchaseHeader."PCX Current Risk Level" := Assessment."Risk Level";
        PurchaseHeader."PCX Current Match Status" := Assessment."Match Status";
        PurchaseHeader.Modify();
    end;

    procedure EvaluateReceiptMatch(DocumentNo: Code[20]; var QtyVariancePct: Decimal): Enum "PCX Match Status"
    var
        OrderedQty: Decimal;
        ReceivedQty: Decimal;
    begin
        OrderedQty := SumOrderedQuantity(DocumentNo);
        ReceivedQty := SumReceivedQuantity(DocumentNo);

        if ReceivedQty = 0 then begin
            QtyVariancePct := 0;
            exit(Enum::"PCX Match Status"::"Not Yet Received");
        end;

        if OrderedQty = 0 then
            QtyVariancePct := 100
        else
            QtyVariancePct := Abs(OrderedQty - ReceivedQty) / OrderedQty * 100;

        if ReceivedQty = OrderedQty then
            exit(Enum::"PCX Match Status"::Matched);

        exit(Enum::"PCX Match Status"::"Quantity Mismatch");
    end;

    local procedure SumOrderedQuantity(DocumentNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.CalcSums(Quantity);
        exit(PurchaseLine.Quantity);
    end;

    local procedure SumReceivedQuantity(DocumentNo: Code[20]): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        PurchRcptLine.CalcSums(Quantity);
        exit(PurchRcptLine.Quantity);
    end;

    local procedure IsOrderOverdue(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit((PurchaseHeader."Expected Receipt Date" <> 0D)
            and (PurchaseHeader."Expected Receipt Date" < Today)
            and (SumReceivedQuantity(PurchaseHeader."No.") < SumOrderedQuantity(PurchaseHeader."No.")));
    end;
}
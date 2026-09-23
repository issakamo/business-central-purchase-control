namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;

codeunit 51100 "PCX Purchase Risk Mgt"
{
    procedure AssessPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; RiskTrigger: Enum "PCX Risk Trigger")
    var
        Assessment: Record "PCX Purchase Risk Assessment";
        ScorecardMgt: Codeunit "PCX Vendor Scorecard Mgt";
        MatchStatus: Enum "PCX Match Status";
        QtyVariancePct: Decimal;
        PriceVariancePct: Decimal;
        IsOverdue: Boolean;
        NewRiskLevel: Enum "PCX Risk Level";
    begin
        MatchStatus := EvaluateThreeWayMatch(PurchaseHeader."No.", QtyVariancePct, PriceVariancePct);
        IsOverdue := IsOrderOverdue(PurchaseHeader);
        NewRiskLevel := DetermineRiskLevel(MatchStatus, IsOverdue, QtyVariancePct, PriceVariancePct);

        if IsRedundantAssessment(PurchaseHeader."No.", MatchStatus, NewRiskLevel, IsOverdue) then
            exit;

        Assessment.Init();
        Assessment."Document No." := PurchaseHeader."No.";
        Assessment."Vendor No." := PurchaseHeader."Buy-from Vendor No.";
        Assessment."Trigger" := RiskTrigger;
        Assessment."Match Status" := MatchStatus;
        Assessment."Overdue" := IsOverdue;
        Assessment."Quantity Variance %" := QtyVariancePct;
        Assessment."Price Variance %" := PriceVariancePct;
        Assessment."Risk Level" := NewRiskLevel;
        Assessment.Insert(true);

        ScorecardMgt.RecalculateScorecard(Assessment."Vendor No.");

        // The order header itself is deleted once fully received and fully
        // invoiced (no lines remain) — the audit record above is still written
        // regardless, but the live-cache fields on the header can only be
        // updated when the header still exists to receive them.
        if PurchaseHeader.Find() then begin
            PurchaseHeader."PCX Current Risk Level" := Assessment."Risk Level";
            PurchaseHeader."PCX Current Match Status" := Assessment."Match Status";
            PurchaseHeader."PCX Currently Overdue" := Assessment.Overdue;
            PurchaseHeader.Modify();
        end;
    end;

    local procedure IsRedundantAssessment(DocumentNo: Code[20]; MatchStatus: Enum "PCX Match Status"; RiskLevel: Enum "PCX Risk Level"; Overdue: Boolean): Boolean
    var
        LastAssessment: Record "PCX Purchase Risk Assessment";
    begin
        LastAssessment.SetRange("Document No.", DocumentNo);
        LastAssessment.SetCurrentKey("Entry No.");
        LastAssessment.Ascending(false);
        if not LastAssessment.FindFirst() then
            exit(false);

        exit((LastAssessment."Match Status" = MatchStatus) and (LastAssessment."Risk Level" = RiskLevel) and (LastAssessment.Overdue = Overdue));
    end;

    procedure EvaluateThreeWayMatch(DocumentNo: Code[20]; var QtyVariancePct: Decimal; var PriceVariancePct: Decimal): Enum "PCX Match Status"
    var
        ReceiptStatus: Enum "PCX Match Status";
        InvoiceStatus: Enum "PCX Match Status";
    begin
        ReceiptStatus := EvaluateReceiptMatch(DocumentNo, QtyVariancePct);

        if ReceiptStatus = ReceiptStatus::"Not Yet Received" then begin
            PriceVariancePct := 0;
            exit(ReceiptStatus);
        end;

        InvoiceStatus := EvaluateInvoiceMatch(DocumentNo, PriceVariancePct);

        if InvoiceStatus = InvoiceStatus::"Not Yet Invoiced" then
            exit(InvoiceStatus);

        case true of
            (ReceiptStatus = ReceiptStatus::Matched) and (InvoiceStatus = InvoiceStatus::Matched):
                exit(Enum::"PCX Match Status"::Matched);
            (ReceiptStatus = ReceiptStatus::"Quantity Mismatch") and (InvoiceStatus = InvoiceStatus::Matched):
                exit(Enum::"PCX Match Status"::"Quantity Mismatch");
            (ReceiptStatus = ReceiptStatus::Matched) and (InvoiceStatus = InvoiceStatus::"Price Mismatch"):
                exit(Enum::"PCX Match Status"::"Price Mismatch");
            else
                exit(Enum::"PCX Match Status"::"Quantity and Price Mismatch");
        end;
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

    procedure EvaluateInvoiceMatch(DocumentNo: Code[20]; var PriceVariancePct: Decimal): Enum "PCX Match Status"
    var
        OrderedAmount: Decimal;
        InvoicedAmount: Decimal;
    begin
        OrderedAmount := SumOrderedAmount(DocumentNo);
        InvoicedAmount := SumInvoicedAmount(DocumentNo);

        if InvoicedAmount = 0 then begin
            PriceVariancePct := 0;
            exit(Enum::"PCX Match Status"::"Not Yet Invoiced");
        end;

        if OrderedAmount = 0 then
            PriceVariancePct := 100
        else
            PriceVariancePct := Abs(OrderedAmount - InvoicedAmount) / OrderedAmount * 100;

        if InvoicedAmount = OrderedAmount then
            exit(Enum::"PCX Match Status"::Matched);

        exit(Enum::"PCX Match Status"::"Price Mismatch");
    end;

    procedure DetermineRiskLevel(MatchStatus: Enum "PCX Match Status"; Overdue: Boolean; QtyVariancePct: Decimal; PriceVariancePct: Decimal): Enum "PCX Risk Level"
    var
        BaseLevel: Enum "PCX Risk Level";
    begin
        case MatchStatus of
            MatchStatus::Matched, MatchStatus::"Not Yet Received", MatchStatus::"Not Yet Invoiced":
                BaseLevel := BaseLevel::Low;
            MatchStatus::"Quantity Mismatch":
                BaseLevel := SeverityFromVariance(QtyVariancePct);
            MatchStatus::"Price Mismatch":
                BaseLevel := SeverityFromVariance(PriceVariancePct);
            MatchStatus::"Quantity and Price Mismatch":
                // Baseline uses the more severe of the two variances, then
                // escalates one tier for the dual-failure itself — a small
                // variance alongside a large one is indistinguishable from
                // two equally large variances. Deliberate simplification;
                // a production version might blend both magnitudes.
                BaseLevel := EscalateOneLevel(SeverityFromVariance(GreaterOf(QtyVariancePct, PriceVariancePct)));
        end;

        if Overdue and (BaseLevel = BaseLevel::Low) then
            exit(BaseLevel::Medium);

        exit(BaseLevel);
    end;

    local procedure SeverityFromVariance(VariancePct: Decimal): Enum "PCX Risk Level"
    begin
        case true of
            VariancePct >= 50:
                exit(Enum::"PCX Risk Level"::Critical);
            VariancePct >= 20:
                exit(Enum::"PCX Risk Level"::High);
            VariancePct >= 5:
                exit(Enum::"PCX Risk Level"::Medium);
            else
                exit(Enum::"PCX Risk Level"::Low);
        end;
    end;

    local procedure EscalateOneLevel(Level: Enum "PCX Risk Level"): Enum "PCX Risk Level"
    begin
        case Level of
            Level::Low:
                exit(Level::Medium);
            Level::Medium:
                exit(Level::High);
            else
                exit(Level::Critical);
        end;
    end;

    local procedure GreaterOf(A: Decimal; B: Decimal): Decimal
    begin
        if A > B then
            exit(A);
        exit(B);
    end;

    local procedure SumOrderedQuantity(DocumentNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);

        if PurchaseLine.IsEmpty() then
            // The order line no longer exists — Business Central deletes it
            // once fully received and fully invoiced. Its absence is itself
            // confirmation the order completed exactly as ordered, so ordered
            // quantity equals received quantity in this case.
            exit(SumReceivedQuantity(DocumentNo));

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

    local procedure SumOrderedAmount(DocumentNo: Code[20]): Decimal
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OrderedAmount: Decimal;
    begin
        // Purchase Order lines are deleted once fully received and invoiced,
        // so the live Purchase Line can't serve as the baseline here. The
        // posted receipt line persists regardless of later invoicing and
        // carries the agreed unit cost/discount at the time of receipt.
        //
        // Recomputed from Line Discount % rather than a stored discount
        // amount field, which does not exist on Purch. Rcpt. Line in this
        // version — mathematically equivalent, though a fraction-of-a-cent
        // rounding difference is theoretically possible versus BC's own
        // internal rounding on unusual percentage/quantity combinations.
        PurchRcptLine.SetRange("Order No.", DocumentNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
        if PurchRcptLine.FindSet() then
            repeat
                OrderedAmount += (PurchRcptLine.Quantity * PurchRcptLine."Direct Unit Cost") *
                    (1 - PurchRcptLine."Line Discount %" / 100);
            until PurchRcptLine.Next() = 0;
        exit(OrderedAmount);
    end;

    local procedure SumInvoicedAmount(DocumentNo: Code[20]): Decimal
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        PurchInvLine.SetRange("Order No.", DocumentNo);
        PurchInvLine.SetRange(Type, PurchInvLine.Type::Item);
        PurchInvLine.CalcSums(Amount);
        exit(PurchInvLine.Amount);
    end;

    local procedure IsOrderOverdue(PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        exit((PurchaseHeader."Expected Receipt Date" <> 0D)
            and (PurchaseHeader."Expected Receipt Date" < Today)
            and (SumReceivedQuantity(PurchaseHeader."No.") < SumOrderedQuantity(PurchaseHeader."No.")));
    end;
}
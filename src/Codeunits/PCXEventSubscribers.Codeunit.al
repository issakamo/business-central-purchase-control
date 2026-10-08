namespace PurchaseControl.Purchasing;

using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Posting;

codeunit 51101 "PCX Event Subscribers"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure OnAfterReleasePurchaseDoc_AssessRisk(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
    var
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
    begin
        if PreviewMode then
            exit;
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            exit;

        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::Released);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnAfterPostPurchaseDoc', '', false, false)]
    local procedure OnAfterPostPurchaseDoc_AssessRisk(var PurchaseHeader: Record "Purchase Header"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PurchRcpHdrNo: Code[20]; RetShptHdrNo: Code[20]; PurchInvHdrNo: Code[20]; PurchCrMemoHdrNo: Code[20]; CommitIsSupressed: Boolean)
    var
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
        RiskTrigger: Enum "PCX Risk Trigger";
    begin
        if PurchaseHeader."Document Type" <> PurchaseHeader."Document Type"::Order then
            exit;

        if PurchInvHdrNo <> '' then
            RiskTrigger := RiskTrigger::"Invoice Posted"
        else
            if PurchRcpHdrNo <> '' then
                RiskTrigger := RiskTrigger::"Receipt Posted"
            else
                exit;

        RiskMgt.AssessPurchaseOrder(PurchaseHeader, RiskTrigger);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterValidateEvent', 'Quantity', false, false)]
    local procedure OnAfterValidateQuantity_AssessAdministrativeClosure(var Rec: Record "Purchase Line"; var xRec: Record "Purchase Line"; CurrFieldNo: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        RiskMgt: Codeunit "PCX Purchase Risk Mgt";
    begin
        if Rec."Document Type" <> Rec."Document Type"::Order then
            exit;
        if Rec.Type <> Rec.Type::Item then
            exit;

        // A shortfall is closed administratively by reducing Quantity to
        // exactly what was received. This is checked from the line's own
        // values rather than xRec, which a code-driven Validate may not
        // populate the way a page does.
        if (Rec."Quantity Received" = 0) or (Rec.Quantity <> Rec."Quantity Received") then
            exit;

        // OnAfterValidateEvent runs before the page or caller saves the
        // line, and the risk engine reads lines from the database. Save the
        // new quantity first so the re-assessment sees it. The caller's own
        // save still runs afterwards, with the table's normal triggers.
        Rec.Modify(false);

        if not PurchaseHeader.Get(Rec."Document Type", Rec."Document No.") then
            exit;

        RiskMgt.AssessPurchaseOrder(PurchaseHeader, Enum::"PCX Risk Trigger"::"Manually Closed");
    end;

}
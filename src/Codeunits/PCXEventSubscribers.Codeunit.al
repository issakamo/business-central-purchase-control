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
}
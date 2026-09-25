namespace PurchaseControl.Purchasing;

using Microsoft.Purchases.Document;

codeunit 51103 "PCX Risk Report Mgt"
{
    procedure ApplyMinimumRiskFilter(var PurchaseHeader: Record "Purchase Header"; MinimumRiskLevel: Enum "PCX Risk Level")
    begin
        PurchaseHeader.SetFilter("PCX Current Risk Level", '>=%1', MinimumRiskLevel.AsInteger());
    end;
}
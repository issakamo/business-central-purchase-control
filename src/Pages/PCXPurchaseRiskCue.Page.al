namespace WarehouseControl.Purchasing;

using Microsoft.Purchases.Document;

page 51103 "PCX Purchase Risk Cue"
{
    PageType = CardPart;
    SourceTable = "PCX Purchase Risk Cue";
    Caption = 'Purchase Risk';

    layout
    {
        area(Content)
        {
            cuegroup(Main)
            {
                Caption = 'Purchase Order Risk';

                field("Critical Risk POs"; Rec."Critical Risk POs")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of purchase orders with a critical risk level.';
                    StyleExpr = 'Unfavorable';

                    trigger OnDrillDown()
                    begin
                        OpenFilteredPurchaseOrders(Enum::"PCX Risk Level"::Critical);
                    end;
                }
                field("High Risk POs"; Rec."High Risk POs")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of purchase orders with a high risk level.';
                    StyleExpr = 'Ambiguous';

                    trigger OnDrillDown()
                    begin
                        OpenFilteredPurchaseOrders(Enum::"PCX Risk Level"::High);
                    end;
                }
                field("Overdue POs"; Rec."Overdue POs")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of overdue purchase orders.';

                    trigger OnDrillDown()
                    begin
                        OpenFilteredOverduePurchaseOrders();
                    end;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    local procedure OpenFilteredPurchaseOrders(RiskLevel: Enum "PCX Risk Level")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: Page "Purchase Order List";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("PCX Current Risk Level", RiskLevel);
        PurchaseOrderList.SetTableView(PurchaseHeader);
        PurchaseOrderList.Run();
    end;

    local procedure OpenFilteredOverduePurchaseOrders()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderList: Page "Purchase Order List";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("PCX Currently Overdue", true);
        PurchaseOrderList.SetTableView(PurchaseHeader);
        PurchaseOrderList.Run();
    end;
}
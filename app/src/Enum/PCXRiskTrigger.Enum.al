namespace PurchaseControl.Purchasing;

enum 51102 "PCX Risk Trigger"
{
    Extensible = true;
    value(0; Manual)
    {
        Caption = 'Manual';
    }
    value(1; Released)
    {
        Caption = 'Released';
    }
    value(2; "Receipt Posted")
    {
        Caption = 'Receipt Posted';
    }
    value(3; "Invoice Posted")
    {
        Caption = 'Invoice Posted';
    }
    value(4; "Manually Closed")
    {
        Caption = 'Manually Closed';
    }
}
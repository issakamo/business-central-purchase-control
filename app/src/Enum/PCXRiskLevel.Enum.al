namespace PurchaseControl.Purchasing;

enum 51100 "PCX Risk Level"
{
    Extensible = true;
    value(0; Low)
    {
        Caption = 'Low';
    }
    value(1; Medium)
    {
        Caption = 'Medium';
    }
    value(2; High)
    {
        Caption = 'High';
    }
    value(3; Critical)
    {
        Caption = 'Critical';
    }
}
namespace PurchaseControl.Purchasing;

enum 51103 "PCX Vendor Rating"
{
    Extensible = true;
    value(0; "Insufficient Data")
    {
        Caption = 'Insufficient Data';
    }
    value(1; Poor)
    {
        Caption = 'Poor';
    }
    value(2; Fair)
    {
        Caption = 'Fair';
    }
    value(3; Good)
    {
        Caption = 'Good';
    }
    value(4; Excellent)
    {
        Caption = 'Excellent';
    }
}
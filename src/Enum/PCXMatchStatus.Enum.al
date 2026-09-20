namespace WarehouseControl.Purchasing;

enum 51101 "PCX Match Status"
{
    Extensible = true;
    value(0; "Not Yet Received")
    {
        Caption = 'Not Yet Received';
    }
    value(1; "Not Yet Invoiced")
    {
        Caption = 'Not Yet Invoiced';
    }
    value(2; Matched)
    {
        Caption = 'Matched';
    }
    value(3; "Quantity Mismatch")
    {
        Caption = 'Quantity Mismatch';
    }
    value(4; "Price Mismatch")
    {
        Caption = 'Price Mismatch';
    }
    value(5; "Quantity and Price Mismatch")
    {
        Caption = 'Quantity and Price Mismatch';
    }
}
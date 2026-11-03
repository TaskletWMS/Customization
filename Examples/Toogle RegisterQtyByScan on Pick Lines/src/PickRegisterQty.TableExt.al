tableextension 60100 "Pick Register Qty." extends "Warehouse Activity Line"
{
    fields
    {
        field(60100; "Register Qty. by Scan"; Boolean)
        {
            Caption = 'Register Qty. by Scan';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies whether mobile barcode scans register quantities for this pick line. Toggle using Register Qty. on mobile Pick lines.';
        }
    }
}
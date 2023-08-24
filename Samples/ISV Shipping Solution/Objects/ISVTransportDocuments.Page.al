page 62203 "ISV Transport Documents"
{
    ApplicationArea = All;
    Caption = 'ISV Transport Documents';
    PageType = List;
    SourceTable = "ISV Transport Header";
    UsageCategory = Lists;
    CardPageId = "ISV Transport Document";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Warehouse Shipment No."; Rec."Warehouse Shipment No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warehouse Shipment No. field.';
                }
            }
        }
    }
}

page 62201 "ISV Transport Document"
{
    Caption = 'ISV Transport Document';
    PageType = Document;
    SourceTable = "ISV Transport Header";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';

                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the No. field.';
                }
                field("Warehouse Shipment No."; Rec."Warehouse Shipment No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Warehouse Shipment No.';
                }
                field("Delivery Name"; Rec."Delivery Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Name field.';
                }
                field("Delivery Address"; Rec."Delivery Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Address field.';
                }
                field("Delivery Post Code"; Rec."Delivery Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Post Code field.';
                }
                field("Delivery City"; Rec."Delivery City")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery City field.';
                }
                field("Delivery Country/Region Code"; Rec."Delivery Country/Region Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Delivery Country/Region Code field.';
                }
                field("Transport Booked"; Rec."Transport Booked")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Transport Booked field.';
                }
            }
            part(SubPage; "ISV Transport SubPage")
            {
                ApplicationArea = all;
                SubPageLink = "Transport No." = FIELD("No.");
                UpdatePropagation = Both;
            }
        }
    }
}

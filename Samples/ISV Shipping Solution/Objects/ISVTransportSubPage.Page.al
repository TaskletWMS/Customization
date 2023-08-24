page 62202 "ISV Transport SubPage"
{
    PageType = ListPart;
    SourceTable = "ISV Transport Line";
    DelayedInsert = true;
    LinksAllowed = false;
    MultipleNewLines = true;

    Caption = 'Lines';

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Line No. field.';
                }
                field("Package Type"; Rec."Package Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Package Type field.';
                }
                field("License Plate No."; Rec."License Plate No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the License Plate No. field.';
                }
                field(Height; Rec.Height)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Height field.';
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the value of the Weight field.';
                }
            }
        }
    }
}

table 62202 "ISV Transport Line"
{
    Caption = 'ISV Transport Line';
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Transport No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Transport No.';
            TableRelation = "ISV Transport Header";
        }
        field(2; "Line No."; Integer)
        {
            DataClassification = CustomerContent;
            Caption = 'Line No.';
        }
        field(10; "Package Type"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Package Type';
            TableRelation = "ISV Package Type";
        }
        field(20; "License Plate No."; Code[50])
        {
            DataClassification = CustomerContent;
            Caption = 'License Plate No.';
        }
        field(21; Height; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Height';
        }
        field(11; Weight; Decimal)
        {
            DataClassification = CustomerContent;
            Caption = 'Weight';
        }
    }
    keys
    {
        key(PK; "Transport No.", "Line No.")
        {
            Clustered = true;
        }
    }
}
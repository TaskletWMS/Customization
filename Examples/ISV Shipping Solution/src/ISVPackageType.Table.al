table 62200 "ISV Package Type"
{
    Caption = 'ISV Package Type';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[100])
        {
            Caption = 'Code';
        }
        field(2; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(3; Height; Decimal)
        {
            Caption = 'Height';
        }
        field(6; Weight; Decimal)
        {
            Caption = 'Weight';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}

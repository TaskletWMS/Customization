tableextension 60500 "Temp LP Report Content Ext" extends "MOB Temp LP Report Content"
{
    //
    // Extension Table for License Plate Report Content
    //

    fields
    {
        // Add your custom data fields here
        field(50100; "Custom Field"; Text[50])
        {
            DataClassification = CustomerContent;
            Caption = 'Custom Field';
        }
    }
}
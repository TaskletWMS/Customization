tableextension 60500 "Temp LP Report Content" extends "MOB Temp LP Report Content"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // Step 1: Extend the report buffer table with a custom field
    // MOB Temp LP Report Content is the temporary buffer table used to build the dataset for the LP Contents Label report.
    // Add a field here for each piece of custom data you want to include in the label.
    // -----------------------------------------------------------------------------------------------------------------------

    fields
    {
        field(60500; "Custom Field"; Text[50])
        {
            Caption = 'Custom Field';
            DataClassification = CustomerContent;
        }
    }
}
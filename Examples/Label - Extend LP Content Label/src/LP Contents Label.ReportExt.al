reportextension 60500 "LP Contents Label" extends "MOB LP Contents Label"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // Step 2: Add the custom field as a dataset column and register a new layout
    // The column makes the field from Step 1 available to the report layout.
    // The layout is a modified copy of the original, exported from Report Layouts and edited in Report Builder.
    // -----------------------------------------------------------------------------------------------------------------------

    dataset
    {
        add("MOB Temp LP Report Content")
        {
            column(Custom_Field; "Custom Field")
            {
                IncludeCaption = true;
            }
        }
    }

    rendering
    {
        layout("Custom LP Content Layout")
        {
            Caption = 'Custom LP Content Layout';
            Summary = 'A custom layout for License Plate Contents Label with additional field.';
            Type = RDLC;
            LayoutFile = 'src\CustomLayout\License Plate Contents GS1 4x6 AddToDataset.rdl';
        }
    }
}
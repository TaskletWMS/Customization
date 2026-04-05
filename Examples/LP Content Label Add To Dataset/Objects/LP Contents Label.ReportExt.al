reportextension 60500 "LP Contents Label Ext" extends "MOB LP Contents Label"
{
    //
    // Add a custom field to the dataset and layout of an existing report
    //

    dataset
    {
        // Add changes to dataitems and columns here
        add("MOB Temp LP Report Content")
        {
            // Add new custom field to dataset
            // It does not get more custom than "Custom Field" for this example
            column(Custom_Field; "Custom Field")
            {
                IncludeCaption = true;
            }
        }
    }

    rendering
    {
        // Define a new layout that includes the custom field
        layout("Custom LP Content Layout")
        {
            // This example has exported the original layout and Modified it using report builder.
            Caption = 'Custom LP Content Layout';
            Summary = 'A custom layout for License Plate Contents Label with additional field.';
            Type = RDLC;
            LayoutFile = 'CustomLayout\License Plate Contents GS1 4x6 AddToDataset.rdl';
        }
    }
}
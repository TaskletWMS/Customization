pageextension 60000 "MOBEX1 MOB Setup Ext" extends "MOB Setup"
{
    layout
    {

        addafter(General)
        {
            group("JOB")
            {
                Caption = 'Job';
                Visible = true;

                field("MOBEX1 Job Jnl Template"; Rec."MOBEX1 Job Jnl Template")
                {
                    Visible = true;
                    ToolTip = 'Enter Job Journal Template';
                    ApplicationArea = All;

                }
                field("MOBEX1 Job Jnl Batch Name"; Rec."MOBEX1 Job Jnl Batch Name")
                {
                    ToolTip = 'Enter Job Batch Name';
                    Visible = true;
                    ApplicationArea = All;
                }
                field("MOBEX1 Job Line Type"; Rec."MOBEX1 Job Line Type")
                {
                    ToolTip = 'Select Line Type for Unplanned Job Consumption';
                    Visible = true;
                    ApplicationArea = All;
                }
            }
        }
    }
}
tableextension 60050 "EXMPL MOB Setup" extends "MOB Setup"
{
    fields
    {
        field(60050; "EXMPL Project Jnl Template"; Code[10])
        {
            Caption = 'Project Journal Template';
            ToolTip = 'Specifies the Project Journal Template used for unplanned project consumption on the mobile device.';
            TableRelation = "Job Journal Template".Name;
            DataClassification = CustomerContent;
        }
        field(60051; "EXMPL Project Jnl Batch Name"; Code[10])
        {
            Caption = 'Project Journal Batch Name';
            ToolTip = 'Specifies the Project Journal Batch Name used for unplanned project consumption on the mobile device.';
            TableRelation = "Job Journal Batch".Name where("Journal Template Name" = field("EXMPL Project Jnl Template"));
            DataClassification = CustomerContent;
        }
        field(60052; "EXMPL Project Line Type"; Enum "Job Line Type")
        {
            Caption = 'Project Line Type';
            ToolTip = 'Specifies the Project Line Type for unplanned project consumption on the mobile device.';
            DataClassification = CustomerContent;
        }
    }

    internal procedure CheckProjectJournalIsSetup()
    var
        JnlNotSetupErr: Label 'Project Journal Template and Batch Name must be set up to use the Project Item Posting functionality.';
    begin
        if (Rec."EXMPL Project Jnl Template" = '') or (Rec."EXMPL Project Jnl Batch Name" = '') then
            Error(JnlNotSetupErr);
    end;
}

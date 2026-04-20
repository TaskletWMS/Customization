pageextension 60050 "EXMPL MOB Setup" extends "MOB Setup"
{
    layout
    {
        addafter(PhysInvt)
        {
            group(EXMPL_ProjectJournal)
            {
                Caption = 'Project Journal';

                field("EXMPL Project Jnl Template"; Rec."EXMPL Project Jnl Template")
                {
                    ApplicationArea = All;
                }
                field("EXMPL Project Jnl Batch Name"; Rec."EXMPL Project Jnl Batch Name")
                {
                    ApplicationArea = All;
                }
                field("EXMPL Project Line Type"; Rec."EXMPL Project Line Type")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
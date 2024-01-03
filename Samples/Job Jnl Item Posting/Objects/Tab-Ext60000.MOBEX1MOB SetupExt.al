tableextension 60000 "MOBEX1 MOB Setup Ext" extends "MOB Setup"
{
    fields
    {
        field(60000; "MOBEX1 Job Jnl Template"; Code[10])
        {
            Caption = 'Job Jnl Template';
            TableRelation = "job Journal Template".Name;
            DataClassification = CustomerContent;
        }
        field(60001; "MOBEX1 Job Jnl Batch Name"; Code[10])
        {
            Caption = 'Job Jnl Batch Name';
            TableRelation = "Job Journal Batch".Name WHERE("Journal Template Name" = FIELD("MOBEX1 Job Jnl Template"));
            DataClassification = CustomerContent;
        }
        field(60002; "MOBEX1 Job Line Type"; enum "Job Line Type")
        {
            Caption = 'Job Line Type';
            DataClassification = CustomerContent;
        }

    }
}

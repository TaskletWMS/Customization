permissionset 81272 "MOB1D REPORT PACK"
{
    Access = Internal;
    Assignable = true;
    Caption = 'Tasklet Mobile WMS - Report Pack with 1D Barcodes', Locked = true;

    Permissions =
         codeunit "MOB1D Internal MOB Functions" = X,
         report "MOB1D Item Label" = X,
         report "MOB1D License Plate Label" = X,
         report "MOB1D LP Contents Label" = X;
}
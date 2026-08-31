codeunit 70033 MyLookup3_Install
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyLookup3_SetupData";
    begin
        SetupData.CreateMobileMenuOption();
        SetupData.CreateMobileMessages();
    end;
}
codeunit 70014 MyLookup1_Install
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyLookup1_SetupData";
    begin
        SetupData.CreateMobileMenuOption();
        SetupData.CreateMobileMessages();
    end;
}
codeunit 60015 "MyUnplanned1_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyUnplanned1_SetupData";
    begin
        SetupData.CreateMobileMenuOption();
        SetupData.CreateMobileMessages();
    end;
}

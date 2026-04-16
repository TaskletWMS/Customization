codeunit 60024 "MyUnplanned2_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyUnplanned2_SetupData";
    begin
        SetupData.CreateMobileMenuOption();
        SetupData.CreateMobileMessages();
    end;
}

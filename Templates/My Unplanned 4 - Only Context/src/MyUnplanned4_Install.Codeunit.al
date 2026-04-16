codeunit 60044 "MyUnplanned4_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyUnplanned4_SetupData";
    begin
        SetupData.CreateMobileMessages();
    end;
}

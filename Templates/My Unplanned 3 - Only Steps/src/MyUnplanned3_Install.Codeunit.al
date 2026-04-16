codeunit 60035 "MyUnplanned3_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyUnplanned3_SetupData";
    begin
        SetupData.CreateMobileMessages();
    end;
}

codeunit 70024 "MyLookup2_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        SetupData: Codeunit "MyLookup2_SetupData";
    begin
        SetupData.CreateMobileMessages();
    end;
}

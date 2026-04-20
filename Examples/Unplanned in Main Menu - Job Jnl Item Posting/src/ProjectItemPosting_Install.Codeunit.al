codeunit 60055 "ProjectItemPosting_Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Setup: Codeunit "ProjectItemPosting_Setup";
    begin
        Setup.CreateMenuOption();
        Setup.CreateMobileMessages();
    end;
}


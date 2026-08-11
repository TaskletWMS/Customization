codeunit 62306 MyPlannedOrders_Install
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        Setup: Codeunit "MyPlannedOrders_Setup";
    begin
        Setup.CreateDocumentTypes();
        Setup.CreateMenuOption();
        Setup.CreateMobileMessages();
    end;
}
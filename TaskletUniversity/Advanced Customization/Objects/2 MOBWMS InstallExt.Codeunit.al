codeunit 50150 "MOB Install Ext"
{
    Subtype = Install;

    procedure InstallApp()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        // Creates "Mobile Menu" entries in BC, matching the "<menuItem>" entries in Mobile Application 
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('SetWhseClassCode', 'WMS', 10);
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('LookupItems', 'WMS', 20);
    end;

    trigger OnInstallAppPerCompany() // Includes code for company-related operations. Runs once for each company in the database.
    begin
        if GetCurrentVersion() = Version.Create(0, 0, 0, 0) then
            FreshInstall()
        else
            Reinstall();
    end;

    local procedure FreshInstall();
    begin
        InstallApp(); // Runs first time this extension is  installed for this tenant
    end;

    local procedure Reinstall();
    begin
        InstallApp(); // Run when reinstalling the same version of this extension back on this tenant
    end;

    procedure GetInstallingVersion(): version
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.AppVersion());
    end;

    procedure GetCurrentVersion(): version
    var
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        exit(AppInfo.DataVersion());
    end;
}
codeunit 50000 "X02 Install"
{
    // Automatically creates "MOB Group Menu Config" & "MOB Menu Option" & "MOB Message" during install

    Subtype = Install;

    trigger OnInstallAppPerCompany() // Includes code for company-related operations. Runs once for each company in the database.
    begin

        if GetCurrentVersion() = Version.Create(0, 0, 0, 0) then
            FreshInstall()
        else
            Reinstall();
    end;

    local procedure FreshInstall();
    begin
        // Do work needed the first time this extension is ever installed for this tenant.
        // Some possible usages:
        // - Service callback/telemetry indicating that extension was install
        // - Initial data setup for use

        InitMobSetup();
    end;

    local procedure Reinstall();
    begin
        // Do work needed when reinstalling the same version of this extension back on this tenant.
        // Some possible usages:
        // - Service callback/telemetry indicating that extension was reinstalled
        // - Data 'patchup' work, for example, detecting if new 'base' records have been changed while you have been working 'offline'.
        // - Setup 'welcome back' messaging for next user access.

        InitMobSetup();
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

    procedure InitMobSetup()
    var
        MobMenuGrp: Record "MOB Group Menu Config";
        MobMenu: Record "MOB Menu Option";
    begin

        if not MobMenu.Get('PickToBinList') then begin
            MobMenu.Init();
            MobMenu."Menu Option" := 'PickToBinList';
            MobMenu.Insert();
        end;

        if not MobMenuGrp.Get('WMS', 'PickToBinList') then begin
            MobMenuGrp.Init();
            MobMenuGrp.Validate("Mobile Group", 'WMS');
            MobMenuGrp.Validate("Mobile Menu Option", 'PickToBinList');
            MobMenuGrp.Validate(Sorting, 10);
            MobMenuGrp.Insert(true);
        end;

        // Create Initial Translations and insert into Mob Message table
        CreateMobMessages();
    end;

    local procedure CreateMobMessages()
    var
        MobMessage: Record "MOB Message";
    begin
        MobMessage.Create('ENU', 'MOBPBPickToBinList', 'Pick to Bin');
        MobMessage.Create('DAN', 'MOBPBPickToBinList', 'Pluk til Placering');

        MobMessage.Create('ENU', 'MOBPBPickToBinContents', 'Bin Contents');
        MobMessage.Create('DAN', 'MOBPBPickToBinContents', 'Placeringsindhold');

        MobMessage.Create('ENU', 'MOBBPBinDescription', 'Bin Description');
        MobMessage.Create('DAN', 'MOBBPBinDescription', 'Pluk-beskrivelse');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
    end;

}


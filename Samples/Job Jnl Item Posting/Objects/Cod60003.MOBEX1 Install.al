codeunit 60003 "MOBEX1 Install"
{
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

        if not MobMenu.Get('JobJnlNegAdjustQty') then begin
            MobMenu.Init();
            MobMenu."Menu Option" := 'JobJnlNegAdjustQty';
            MobMenu.Insert();
        end;

        if not MobMenuGrp.Get('WMS', 'JobJnlNegAdjustQty') then begin
            MobMenuGrp.Init();
            MobMenuGrp.Validate("Mobile Group", 'WMS');
            MobMenuGrp.Validate("Mobile Menu Option", 'JobJnlNegAdjustQty');
            MobMenuGrp.Validate(Sorting, 10);
            MobMenuGrp.Insert(true);
        end;

        if not MobMenu.Get('JobJnlPosAdjustQty') then begin
            MobMenu.Init();
            MobMenu."Menu Option" := 'JobJnlPosAdjustQty';
            MobMenu.Insert();
        end;

        if not MobMenuGrp.Get('WMS', 'JobJnlPosAdjustQty') then begin
            MobMenuGrp.Init();
            MobMenuGrp.Validate("Mobile Group", 'WMS');
            MobMenuGrp.Validate("Mobile Menu Option", 'JobJnlPosAdjustQty');
            MobMenuGrp.Validate(Sorting, 20);
            MobMenuGrp.Insert(true);
        end;

        if not MobMenu.Get('Item2JobJnl') then begin
            MobMenu.Init();
            MobMenu."Menu Option" := 'Item2JobJnl';
            MobMenu.Insert();
        end;

        if not MobMenuGrp.Get('WMS', 'Item2JobJnl') then begin
            MobMenuGrp.Init();
            MobMenuGrp.Validate("Mobile Group", 'WMS');
            MobMenuGrp.Validate("Mobile Menu Option", 'Item2JobJnl');
            MobMenuGrp.Validate(Sorting, 30);
            MobMenuGrp.Insert(true);
        end;

        // Create Initial Translations and insert into Mob Message table
        CreateMobMessages();

    end;

    local procedure CreateMobMessages()
    var
        MobMessage: Record "MOB Message";
        MobToolBox: Codeunit "MOB Toolbox";
    begin
        MobMessage.Create('ENU', 'JOB_NO_LABEL', 'Job No.');
        MobMessage.Create('DAN', 'JOB_NO_LABEL', 'Sagsnummer');

        MobMessage.Create('ENU', 'JOB_TASK_NO_LABEL', 'Job Task No.');
        MobMessage.Create('DAN', 'JOB_TASK_NO_LABEL', 'Sagsopgavenummer');

        MobMessage.Create('ENU', 'JOB_JNL_POS', 'Job Journal Item Return');
        MobMessage.Create('DAN', 'JOB_JNL_POS', 'Sagskladde vare retur');

        MobMessage.Create('ENU', 'JOB_JNL_NEG', 'Job Journal Item Consumption');
        MobMessage.Create('DAN', 'JOB_JNL_NEG', 'Sagskladde vareforbrug');

        MobMessage.Create('ENU', 'JOB_JNL_ADD', 'Add Items to Job Jnl.');
        MobMessage.Create('DAN', 'JOB_JNL_ADD', 'Tilføj varer til sagskladde');

        MobMessage.Create('ENU', 'JOB_JNL_POSTED', 'Job Journal Line Posted!' + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + ' %1 %2 %3' + MobToolbox.CRLFSeparator() + '%4 %5');
        MobMessage.Create('DAN', 'JOB_JNL_POSTED', 'Sagskladdelinje bogført!' + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + ' %1 %2 %3' + MobToolbox.CRLFSeparator() + '%4 %5');

        MobMessage.Create('ENU', 'JOB_JNL_POST_WARNING', 'Item %1 is already registred on this Job' + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + 'Do you want to continue?');
        MobMessage.Create('DAN', 'JOB_JNL_POST_WARNING', 'Vare %1 er allerede registreret på denne sag' + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator() + 'Ønsker du at fortsætte?');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure CompanyInitialize()
    begin
    end;
}


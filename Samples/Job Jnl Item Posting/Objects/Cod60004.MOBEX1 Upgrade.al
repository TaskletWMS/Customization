codeunit 60004 "MOBEX1 Upgrade"
{
    Subtype = Upgrade;

    var
        Install: Codeunit "MOBEX1 Install";

    trigger OnUpgradePerCompany()
    // Perform Upgrade
    begin
        Install.InitMobSetup();
    end;
}

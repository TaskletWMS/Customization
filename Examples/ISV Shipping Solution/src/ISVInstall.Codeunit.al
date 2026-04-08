codeunit 62200 "ISV Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        FreshInstall();
    end;

    local procedure FreshInstall();
    begin
        CreateISVTransportHelperData();
        CreateISVPackageSetup();
    end;

    local procedure CreateISVTransportHelperData()
    var
        ISV_PackageType: Record "ISV Package Type";
    begin
        ISV_PackageType.Init();
        ISV_PackageType.Code := 'RED BOX';
        ISV_PackageType.Description := 'ISV Red Box';
        ISV_PackageType.Height := 10;
        ISV_PackageType.Weight := 5;
        if ISV_PackageType.Insert() then;

        ISV_PackageType.Init();
        ISV_PackageType.Code := 'BLUE BAG';
        ISV_PackageType.Description := 'ISV Blue Bag';
        ISV_PackageType.Height := 5;
        ISV_PackageType.Weight := 1;
        if ISV_PackageType.Insert() then;

        ISV_PackageType.Init();
        ISV_PackageType.Code := 'GREEN PALLET';
        ISV_PackageType.Description := 'ISV Green Pallet';
        ISV_PackageType.Height := 100;
        ISV_PackageType.Weight := 25;
        if ISV_PackageType.Insert() then;
    end;

    local procedure CreateISVPackageSetup()
    var
        MobPackageType: Record "MOB Package Type";
        MobMobileWMSPackageSetup: Record "MOB Mobile WMS Package Setup";
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        MobPackAPI.SynchronizePackageTypes(MobPackageType);

        MobPackageType.Reset();
        MobPackageType.SetFilter("Shipping Provider Id", 'ISV');
        if MobPackageType.FindSet() then
            repeat
                MobMobileWMSPackageSetup.Init();
                MobMobileWMSPackageSetup.Validate("Shipping Agent", 'DHL');
                MobMobileWMSPackageSetup.Validate("Package Type", MobPackageType.Code);
                MobMobileWMSPackageSetup.Validate("Register Weight", true);
                MobMobileWMSPackageSetup.Validate("Register Height", true);
                if MobMobileWMSPackageSetup.Insert() then;
            until MobPackageType.Next() = 0;
    end;
}
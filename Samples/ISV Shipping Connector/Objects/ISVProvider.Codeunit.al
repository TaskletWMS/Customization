codeunit 62300 "ISV Shipping Provider"
{

    /// <summary>
    /// Interface implementation: Register shipping provider in base Pack and Ship app
    /// </summary>  
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnDiscoverShippingProvider', '', true, true)]
    local procedure OnDiscoverShippingProvider()
    var
        MobPackAPI: Codeunit "MOB Pack API";
    begin
        MobPackAPI.SetupShippingProvider(GetShippingProviderId(), 'ISV'); //TODO Change to your own unique Name
    end;

    /// <summary>
    /// Interface implementation: Unique Shipping Provider Id for this class (implementation)
    /// </summary>
    local procedure GetShippingProviderId(): Code[20]
    begin
        exit('ISV');  //TODO Change to your own unique Name
    end;

    /// <summary>
    /// Interface implementation: Is the package type handled by the current Shipping Provider Id
    /// </summary>   
    local procedure IsShippingProvider(_PackageType: Code[50]): Boolean
    var
        MobPackageType: Record "MOB Package Type";
    begin
        exit(MobPackageType.Get(_PackageType) and (MobPackageType."Shipping Provider Id" = GetShippingProviderId()));
    end;

    /// <summary>
    /// Interface implementation: Synchronize package types from external solution to our own internal table
    /// </summary>   
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnSynchronizePackageTypes', '', true, true)]
    local procedure OnSynchronizePackageTypes(var _PackageType: Record "MOB Package Type")
    begin
        SynchronizePackageTypes(_PackageType);
    end;

    internal procedure SynchronizePackageTypes(var _MobPackageType: Record "MOB Package Type")
    var
        ISVPackageType: Record "ISV Package Type";
    begin
        _MobPackageType.SetRange("Shipping Provider Id", GetShippingProviderId());
        _MobPackageType.DeleteAll();
        _MobPackageType.SetRange("Shipping Provider Id");

        ISVPackageType.Reset();
        if ISVPackageType.FindSet() then
            repeat
                _MobPackageType.Init();
                _MobPackageType.Validate(Code, '');  // OnInsert Code will auto-assign value
                _MobPackageType.Validate("Shipping Provider Id", GetShippingProviderId());
                _MobPackageType.Validate("Shipping Provider Package Type", ISVPackageType.Code);
                _MobPackageType.Validate(Description, CopyStr(ISVPackageType.Description, 1, MaxStrLen(_MobPackageType.Description)));
                _MobPackageType.Validate(Height, ISVPackageType.Height);
                _MobPackageType.Validate(Weight, ISVPackageType.Weight);
                _MobPackageType.Insert(true);
            until ISVPackageType.Next() = 0;
    end;

    /// <summary>
    /// Interface implementation: "Early" validation before posting (only to be executed if we are the shipping provider for a license plate)
    /// </summary> 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnPostPackingOnCheckUntransferredLicensePlate', '', true, true)]
    local procedure OnPostPackingOnCheckUntransferredLicensePlate(_LicensePlate: Record "MOB License Plate")
    var

        ISVPackageType: Record "ISV Package Type";
        MobPackageType: Record "MOB Package Type";
    begin
        if not IsShippingProvider(_LicensePlate."Package Type") then
            exit;

        // Check PackageType exists and will not error out during validation        
        MobPackageType.Get(_LicensePlate."Package Type");
        ISVPackageType.Get(MobPackageType."Shipping Provider Package Type");
    end;

    /// <summary>
    /// Interface implementation: Create new Transport Document prior to posting if needed (prior to initial commit)
    /// </summary>
    /// <remarks>
    /// Redirected from standard event OnAfterCheckWhseShptLine to new local event for more accessible "interface" (all neccessary events in MOB Pack Register CU)
    /// </remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnPostPackingOnBeforePostWarehouseShipment', '', false, false)]
    local procedure OnPostPackingOnBeforePostWarehouseShipment(var WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        MobPackRegister: Codeunit "MOB WMS Pack Adhoc Reg-PostPck";
    begin

        if HasQuantityToShip(WhseShptLine) and MobPackRegister.HasUntransferredLicensePlatesForWarehouseShipment(WhseShptHeader."No.") then
            CreateTransportDocumentAndPackages(WhseShptHeader);  // May append to existing consignment
    end;

    /// <summary>
    /// Interface implementation: Book and Print if needed (following the final commit in standard code)
    /// </summary>
    /// <remarks>
    /// Redirected from standard event OnAfterPostWhseShipment to new local event for more accessible "interface" (all neccessary events in MOB Pack Register CU)
    /// </remarks>
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnPostPackingOnAfterPostWarehouseShipment', '', false, false)]
    local procedure OnPostPackingOnAfterPostWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        BookAndPrint(WarehouseShipmentHeader);
    end;

    /// <summary>
    /// Is there anything to ship for the filtered warehouse shipment lines
    /// </summary>
    local procedure HasQuantityToShip(var _WarehouseShipmentLine: Record "Warehouse Shipment Line"): Boolean
    var
        WarehouseShipmentLine2: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine2.Copy(_WarehouseShipmentLine);
        WarehouseShipmentLine2.SetFilter("Qty. to Ship", '>0');
        exit(not WarehouseShipmentLine2.IsEmpty());
    end;

    /// <summary>
    /// Create a new Transport Document for the warehouse shipment
    /// </summary>
    local procedure CreateTransportDocumentAndPackages(var _WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        ISVTransportHeader: Record "ISV Transport Header";
    begin
        // Create Transport Document from Warehouse Shipment Header
        ISVTransportHeader := ISVTransportHeader.CreateTransportDocument(_WarehouseShipmentHeader);

        // Insert all packages for the entire shipment
        InsertPackagesFromWarehouseShipment(_WarehouseShipmentHeader."No.", ISVTransportHeader);
    end;

    /// <summary>
    /// Insert all untransferred packages from a warehouse shipment
    /// </summary>   
    local procedure InsertPackagesFromWarehouseShipment(_FromWhseShipmentNo: Code[20]; _ISVTransportHeader: Record "ISV Transport Header") _PackagesInserted: Integer
    var
        ISVTransportLine: Record "ISV Transport Line";
        MobUntransferredLicensePlate: Record "MOB License Plate";
        MobUntransferredLicensePlate2: Record "MOB License Plate";
        MobPackageType: Record "MOB Package Type";
        MobPackRegister: Codeunit "MOB WMS Pack Adhoc Reg-PostPck";
        NextLineNo: Integer;
    begin
        Clear(_PackagesInserted);
        MobPackRegister.FilterUntransferredLicensePlatesForWarehouseShipment(_FromWhseShipmentNo, MobUntransferredLicensePlate);
        if MobUntransferredLicensePlate.FindSet() then
            repeat
                if IsShippingProvider(MobUntransferredLicensePlate."Package Type") then begin
                    NextLineNo += 10000;
                    MobPackageType.Get(MobUntransferredLicensePlate."Package Type");

                    ISVTransportLine.Init();
                    ISVTransportLine.Validate("Transport No.", _ISVTransportHeader."No.");

                    ISVTransportLine.Validate("Line No.", NextLineNo);
                    ISVTransportLine.Validate("Package Type", MobPackageType."Shipping Provider Package Type");
                    ISVTransportLine.Validate("License Plate No.", MobUntransferredLicensePlate."No.");

                    if MobUntransferredLicensePlate.Weight <> 0 then
                        ISVTransportLine.Validate(Weight, MobUntransferredLicensePlate.Weight);
                    if MobUntransferredLicensePlate.Height <> 0 then
                        ISVTransportLine.Validate(Height, MobUntransferredLicensePlate.Height);

                    ISVTransportLine.Insert(true);

                    _PackagesInserted := _PackagesInserted + 1;

                    MobUntransferredLicensePlate2 := MobUntransferredLicensePlate;
                    MobUntransferredLicensePlate2.Validate("Transferred to Shipping", true);    // Will mark all child license plates as transferred as well
                    MobUntransferredLicensePlate2.Modify();  // Do not modify the record used for iteration, due to next cursorplacement 
                end;
            until MobUntransferredLicensePlate.Next() = 0;

        exit(_PackagesInserted);
    end;

    /// <summary>
    /// Book and Print thee Transport Document
    /// </summary>
    local procedure BookAndPrint(var _WhseShipmentHeader: Record "Warehouse Shipment Header")
    var
        ISVTransportHeader: Record "ISV Transport Header";
        MOBPackingStation: Record "MOB Packing Station";
    begin

        // Packing Station Code could be relevant if you need to direct label print in your customization
        if _WhseShipmentHeader."MOB Packing Station Code" <> '' then
            MOBPackingStation.Get(_WhseShipmentHeader."MOB Packing Station Code");

        ISVTransportHeader.SetRange("Warehouse Shipment No.", _WhseShipmentHeader."No.");
        if ISVTransportHeader.FindSet() then
            repeat

                // Activate Book & Print
                ISVTransportHeader.BookAndPrint();

            until ISVTransportHeader.Next() = 0;
    end;

    /*        
    /// <summary>
    /// Intentionally commented out - Optional implementation to link Packing Stations to external print service features
    /// Example: Interface implementation: Synchronize Print Queue setup to Packing Stations
    /// </summary>
    
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Pack API", 'OnSynchronizePackingStations', '', true, true)]
    local procedure OnSynchronizePackingStations(var _PackingStation: Record "MOB Packing Station")
    var
        ISVPrintQueue: Record "ISV Print Queue";
    begin
        _PackingStation.Reset();
        if ISVPrintQueue.FindSet() then
            repeat
                _PackingStation.SetRange("ISV Print Queue", ISVPrintQueue.Code);
                if _PackingStation.IsEmpty() then begin
                    _PackingStation.Init();
                    _PackingStation.Code := '';  // OnInsert Code will auto-assign value
                    _PackingStation.Description := ISVPrintQueue.Description;
                    _PackingStation."ISV Print Queue" := ISVPrintQueue.Code;
                    _PackingStation.Insert(true);
                end;
                _PackingStation.SetRange("ISV Print Queue");
            until ISVPrintQueue.Next() = 0;
    end;    
    */
}
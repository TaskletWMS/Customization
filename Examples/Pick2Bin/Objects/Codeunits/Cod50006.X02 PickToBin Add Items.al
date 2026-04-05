codeunit 50006 "X02 PickToBin Add Items"
{
    // Enables the user to add items to the bin

    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinAddItemsHeader');

        // Add the header lines
        _HeaderFields.Create_ListField_Location(10);

        _HeaderFields.Create_TextField_ItemNumber(20);
        _HeaderFields.Set_name('PickToBinItemNumber'); // Prevent inheritance from Parent request
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure MyOnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        DummyRegisterExpirationDate: Boolean;
    begin
        // Handle only your own Header name
        if _RegistrationType <> 'PickToBinAddItems' then
            exit;

        MobSetup.Get();

        // Read the headerFields
        Evaluate(LocationCode, _HeaderFieldValues.Get_Location(true));
        Evaluate(NewLocationCode, _HeaderFieldValues.GetContextValue('NewLocation', true));
        ItemNumber := MobItemReferenceMgt.SearchItemReference(MobToolbox.ReadEAN(_HeaderFieldValues.GetValue('PickToBinItemNumber', true)), VariantCode, UoMCode);
        Item.Get(ItemNumber);

        // If move is within the same Location, Item Tracking should only be collected if Warehouse Tracking is enabled
        Clear(MobTrackingSetup);
        if LocationCode = NewLocationCode then
            MobTrackingSetup.DetermineWhseTrackingRequired(Item."No.", DummyRegisterExpirationDate)
        else
            MobTrackingSetup.DetermineTransferTrackingRequired(Item."No.", DummyRegisterExpirationDate);

        // Add From Bin
        _Steps.Create_TextStep_Bin(10, LocationCode, Item."No.", VariantCode);

        // Step: Variant
        if VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", Item."No.");
            if not ItemVariant.IsEmpty() then begin
                _Steps.Create_ListStep_Variant(30, Item."No.");
                _Steps.Set_name('NewVariant'); // Prevent inheritance from parent
            end;

        end;

        // Step: UoM
        if (not MobSetup."Use Base Unit of Measure") and (UoMCode = '') then begin
            _Steps.Create_ListStep_UoM(40, Item."No.");
            _Steps.Set_name('NewOuM'); // Prevent inheritance from parent
            _Steps.Set_defaultValue(Item."Base Unit of Measure");
            if not MobWmsToolbox.GetItemHasMultipleUoM(Item."No.") then begin
                UoMCode := Item."Base Unit of Measure";
                _Steps.Set_visible(false);
            end;
        end;

        // Steps: LotNumber, SerialNumber, PackageNumber and custom tracking dimensions
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 50, Item."No.");

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(200, Item."No.");
            _Steps.Set_name('NewQuantity'); // Prevent inheritance from parent
            _Steps.Set_defaultValue(1);
            _Steps.Set_minValue(0.0000000001);

            // Show UoM in Quantity help
            if MobSetup."Use Base Unit of Measure" then
                _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + Item."Base Unit of Measure")
            else
                if UoMCode <> '' then
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + UoMCode);
        end;

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobPbPostUnplannedMoveReg: Codeunit "X02 Post Unplanned Move Reg.";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        FromBin: Code[20];
        ToBin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
    begin
        if _RegistrationType <> 'PickToBinAddItems' then
            exit;

        if _IsHandled then
            exit;

        // Read _RequestValues
        Evaluate(LocationCode, _RequestValues.Get_Location(true));
        Evaluate(NewLocationCode, _RequestValues.GetContextValue('NewLocation', true));
        Evaluate(FromBin, _RequestValues.Get_Bin());
        Evaluate(ToBin, _RequestValues.GetContextValue('ToBin', true));
        ScannedBarcode := _RequestValues.GetValue('PickToBinItemNumber', true);
        Quantity := _RequestValues.GetValueAsDecimal('NewQuantity', true);

        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('NewUoM') then
            UoMCode := _RequestValues.GetValue('NewUoM');
        if _RequestValues.HasValue('NewVariant') then
            VariantCode := _RequestValues.GetValue('NewVariant');

        // Post move
        MobPbPostUnplannedMoveReg.PostUnplannedMoveRegistration(ItemNumber, VariantCode, UoMCode, LocationCode, FromBin, NewLocationCode, ToBin, Quantity, MobTrackingSetup);

        _SuccessMessage := StrSubstNo('Added item %1 from %2 - %3', ItemNumber, LocationCode, FromBin);
        _RegistrationTypeTracking := StrSubstNo('Item %1 moved from %2 - %3 to %4 - %5', ItemNumber, LocationCode, FromBin, NewLocationCode, ToBin);

        _IsHandled := true;
    end;
}
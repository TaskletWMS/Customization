codeunit 50003 "X02 Lookup PickToBin List"
{
    // Shows a list of Bins that can easily be picked to

    var
        MobPbToolbox: Codeunit "X02 Toolbox";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    var
        Location: Record Location;
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinListHeader');

        // Add headerConfiguration elements here                
        _HeaderFields.Create_ListField_NewLocation(10);
        Location.Get('BASKETS'); // TODO: Add logic to find appropiate Location
        _HeaderFields.Set_defaultValue(Location.Code);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _LookupType <> 'PickToBinList' then
            exit;

        LookupPickToBinList(_LookupType, _RequestValues, _LookupResponseElement);
        _IsHandled := true;
    end;

    local procedure LookupPickToBinList(var _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        NewLocationCode: Code[10];
        BinQuantity: Decimal;
    begin
        // Read Request        
        Evaluate(NewLocationCode, _RequestValues.GetValue('NewLocation'));

        Bin.SetRange("Location Code", NewLocationCode);
        if not Bin.FindSet() then
            Error('No bins found for location %1.', NewLocationCode);

        repeat
            // Find BinQuantity
            BinQuantity := 0;
            BinContent.SetCurrentKey("Location Code", "Bin Code");
            BinContent.SetRange("Location Code", Bin."Location Code");
            BinContent.SetRange("Bin Code", Bin.Code);
            BinContent.SetFilter(Quantity, '<>0');
            BinContent.SetAutoCalcFields(Quantity);
            if BinContent.FindSet() then
                repeat
                    BinQuantity := BinQuantity + BinContent.Quantity;
                until BinContent.Next() = 0;

            // Create new Response Element
            _LookupResponseElement.Create();
            _LookupResponseElement.Set_Barcode(Bin.Code);
            _LookupResponseElement.Set_DisplayLine1(Bin.Code);
            _LookupResponseElement.Set_DisplayLine2('No. of items: ' + MobPbToolbox.Decimal2TextAsDisplayFormat(BinQuantity));
            _LookupResponseElement.Set_DisplayLine3(Bin.Description);

            _LookupResponseElement.SetValue('NewLocation', Bin."Location Code");
            _LookupResponseElement.SetValue('ToBin', Bin.Code);
            _LookupResponseElement.Save();
        until Bin.Next() = 0;
    end;
}
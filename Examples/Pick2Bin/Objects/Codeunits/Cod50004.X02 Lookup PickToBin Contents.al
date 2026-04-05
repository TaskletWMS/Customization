codeunit 50004 "X02 Lookup PickToBin Contents"
{
    // Shows the contents of the selected bin

    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobPbToolbox: Codeunit "X02 Toolbox";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinContentsHeader');

        // Add the header lines
        _HeaderFields.Create_ListField_NewLocation(10);
        _HeaderFields.Create_TextField_ToBin(20);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _LookupType <> 'PickToBinContents' then
            exit;

        LookupPickToBinContents(_LookupType, _RequestValues, _LookupResponseElement);
        _IsHandled := true;
    end;

    local procedure LookupPickToBinContents(var _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        NewLocationCode: Code[10];
        ToBin: Code[20];
        TotalQty: Decimal;
        NoOfItems: Integer;
    begin
        // Read Request        
        Evaluate(ToBin, _RequestValues.GetValue('ToBin', true));
        Evaluate(NewLocationCode, _RequestValues.GetValue('NewLocation', true));
        Bin.Get(NewLocationCode, ToBin);

        // Lookup the content of the bin
        BinContent.SetCurrentKey("Location Code", "Bin Code");
        BinContent.SetRange("Location Code", NewLocationCode);
        BinContent.SetRange("Bin Code", ToBin);
        BinContent.SetFilter(Quantity, '<>0');
        BinContent.SetAutoCalcFields(Quantity);
        if BinContent.FindSet() then
            repeat
                // Insert Response
                _LookupResponseElement.Create();
                SetFromLookupBinContent(BinContent, _LookupResponseElement);

                // Count number of Units and Items
                TotalQty := TotalQty + BinContent.Quantity;
                NoOfItems := NoOfItems + 1;
            until BinContent.Next() = 0;

        // Create a footer Response Element
        _LookupResponseElement.Create();
        _LookupResponseElement.SetValue('NewLocation', NewLocationCode);
        _LookupResponseElement.SetValue('ToBin', ToBin);
        _LookupResponseElement.Set_DisplayLine1('- TOTAL QUANTITY -');
        _LookupResponseElement.Set_Quantity(MobPbToolbox.Decimal2TextAsDisplayFormat(TotalQty));
        _LookupResponseElement.Set_DisplayLine2(StrSubstNo('Number of lines: %1', NoOfItems));
        if Bin.Description <> '' then
            _LookupResponseElement.Set_DisplayLine3(StrSubstNo('Description: %1', Bin.Description));
        _LookupResponseElement.Save();
    end;

    local procedure SetFromLookupBinContent(_BinContent: Record "Bin Content"; var _LookupResponse: Record "MOB NS WhseInquery Element")
    var
        MobWmsMedia: Codeunit "MOB WMS Media";
    begin
        _LookupResponse.Init();

        _LookupResponse.SetValue('NewLocation', _BinContent."Location Code");
        _LookupResponse.SetValue('ToBin', _BinContent."Bin Code");

        _LookupResponse.Set_ItemNumber(_BinContent."Item No.");
        _LookupResponse.Set_Variant(_BinContent."Variant Code");
        _LookupResponse.Set_UoM(_BinContent."Unit of Measure Code");
        _LookupResponse.Set_Quantity(MobPbToolbox.Decimal2TextAsDisplayFormat(_BinContent.Quantity));

        _LookupResponse.Set_DisplayLine1(_BinContent."Item No.");
        _LookupResponse.Set_DisplayLine2(MobPbToolbox.GetItemDescriptions(_BinContent."Item No.", _BinContent."Variant Code"));
        _LookupResponse.Set_DisplayLine3(_BinContent."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _BinContent."Variant Code", '');
        _LookupResponse.Set_DisplayLine4(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _BinContent."Unit of Measure Code");
        _LookupResponse.Set_DisplayLine5('');

        _LookupResponse.Set_ItemImageID(MobWmsMedia.GetItemImageID(_LookupResponse.Get_ItemNumber()));
        _LookupResponse.Set_ReferenceID(_BinContent);
    end;
}
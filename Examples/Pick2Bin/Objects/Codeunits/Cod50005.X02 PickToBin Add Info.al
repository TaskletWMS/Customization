codeunit 50005 "X02 PickToBin Add Info"
{
    // Asks user for additional information and stores the information on the Bin records

    var
        MobWmsLanguage: Codeunit "MOB WMS Language";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinAddInfoHeader');

        // Add the header lines
        _HeaderFields.Create_ListField_NewLocation(10);
        _HeaderFields.Create_TextField_ToBin(20);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure MyOnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Bin: Record Bin;
        NewLocationCode: Code[10];
        ToBin: Code[20];
    begin
        // Handle only your own Header name
        if _RegistrationType <> 'PickToBinAddInfo' then
            exit;

        // Read the headerFields
        Evaluate(NewLocationCode, _HeaderFieldValues.GetValue('NewLocation'));
        Evaluate(ToBin, _HeaderFieldValues.GetValue('ToBin'));
        Bin.Get(NewLocationCode, ToBin);

        // Add To Steps
        _Steps.Create_TextStep(10, 'BinDescription');
        _Steps.Set_label(MobWmsLanguage.GetMessage('MOBBPBinDescription') + ':');
        _Steps.Set_defaultValue(Bin.Description);
        _Steps.Set_primaryInputMethod('Control');
        _Steps.Set_optional(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        Bin: Record Bin;
        NewLocationCode: Code[10];
        ToBin: Code[20];
        BinDescription: Text[100];
    begin
        if _RegistrationType <> 'PickToBinAddInfo' then
            exit;

        if _IsHandled then
            exit;

        // Read Request        
        Evaluate(NewLocationCode, _RequestValues.GetValue('NewLocation', true));
        Evaluate(ToBin, _RequestValues.GetValue('ToBin', true));
        Evaluate(BinDescription, _RequestValues.GetValue('BinDescription', true));

        // Update Bin Description
        Bin.Get(NewLocationCode, ToBin);
        if BinDescription <> Bin.Description then begin
            Bin.Validate(Description, BinDescription);
            Bin.Modify(true);
        end;

        _RegistrationTypeTracking := StrSubstNo('Bin %1 is now called %2', ToBin, BinDescription);

        _IsHandled := true;
    end;
}
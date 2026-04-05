codeunit 50008 "X02 PickToBin Process Bin"
{
    // Enables the user to start a processing function in the backend
    // TODO: Here you can add creation and shipment posting of a Sales Order or exporting to a POS or ... (Remember the contents of the bin stays in the bin, until they are removed by a posting function)

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinProcessBinHeader');

        // Add the header lines
        _HeaderFields.Create_ListField_NewLocation(10);
        _HeaderFields.Create_TextField_ToBin(20);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure MyOnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        NewLocationCode: Code[10];
        ToBin: Code[20];
    begin
        // Handle only your own Header name
        if _RegistrationType <> 'PickToBinProcessBin' then
            exit;

        // Read the headerFields
        Evaluate(NewLocationCode, _HeaderFieldValues.GetValue('NewLocation', true));
        Evaluate(ToBin, _HeaderFieldValues.GetValue('ToBin', true));

        // Add Steps TODO: Here you can add more steps to collect whatever information you need from the warehouse worker - customer information perhaps?
        _Steps.Create_TextStep(10, 'CustomText', StrSubstNo('Enter custom text (%1 - %2)', NewLocationCode, ToBin));
        _Steps.Set_helpLabel('Enter Custom Text');
        _Steps.Set_primaryInputMethod('Control');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        Bin: Record Bin;
        NewLocationCode: Code[10];
        ToBin: Code[20];
        CustomText: Text;
    begin
        if _RegistrationType <> 'PickToBinProcessBin' then
            exit;

        if _IsHandled then
            exit;

        // Read _RequestValues
        Evaluate(NewLocationCode, _RequestValues.GetValue('NewLocation', true));
        Evaluate(ToBin, _RequestValues.GetValue('ToBin', true));
        Evaluate(CustomText, _RequestValues.GetValue('CustomText', true));

        // TODO: Add processing - inspired by the RemoveItem function to get full tracking of BinContents

        // Clearing description and making it available for the next pick
        Bin.Get(NewLocationCode, Tobin);
        Bin.Validate(Description, '');
        Bin.Modify(true);

        // Message the user
        _SuccessMessage := 'Processed the bin';
        _RegistrationTypeTracking := StrSubstNo('Processed bin %1 - %2', NewLocationCode, ToBin);

        _IsHandled := true;
    end;
}
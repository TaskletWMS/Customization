codeunit 60000 "Unable to Pick Example"
{
    // Example: Add an "Unable To Pick" action to Pick Lines.
    // When triggered from the mobile device, it collects the quantity the user was unable to pick
    // and transfers the Order Line context values (Location, Bin, Item) as locked header fields.

    // -----------------------------------------------------------------------------------------------------------------------
    // Step 1: Distribute the configuration tweak to the Mobile App
    // This event is fired during GetReferenceData and GetApplicationConfiguration, both triggered on mobile login,
    // so the tweak is available as soon as the user logs in.
    // Requires: Android App 1.8.0+ and Mobile WMS 5.55+
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", OnGetApplicationConfiguration_OnAddTweaks, '', true, true)]
    local procedure AddUnableToPickTweak_OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    var
        Tweak: Text;
    begin
        Tweak := NavApp.GetResourceAsText('UnableToPickTweak.xml'); // Load the tweak XML from resources - resource folder specified in app.json
        _MobTweakContainer.Add(60000, 'UnableToPick: Add Unable To Pick action to Pick Lines', Tweak);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // Step 2: Define Header and header fields
    // Subscribe to this event to tell Tasklet Mobile WMS which header fields your unplanned function should display when it opens.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', true, true)]
    local procedure AddUnableToPickHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('UnableToPick'); // IMPORTANT: _Key must match the configurationKey attribute in your Tweak.xml

        // 'Location' is provided by the Pick Line context — locked so the user cannot change it
        _HeaderFields.Create_ListField_Location(10);
        _HeaderFields.Set_locked(true);

        // 'FromBin' is provided by the Pick Line context — locked so the user cannot change it
        _HeaderFields.Create_TextField_FromBin(20);
        _HeaderFields.Set_locked(true);

        // 'ItemNumber' is provided by the Pick Line context — locked so the user cannot change it
        _HeaderFields.Create_TextField_ItemNumber(30);
        _HeaderFields.Set_locked(true);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // Step 3: Return Steps to collect
    // When the header is accepted, the mobile device will ask the backend which steps to present to the user.
    // Subscribe to this event to return the steps for your unplanned function.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', true, true)]
    local procedure AddUnableToPickSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        UnableToPickQuantity: Decimal;
    begin
        if _RegistrationType <> 'UnableToPick' then // IMPORTANT: _RegistrationType must match the type attribute on <unplannedItemRegistrationConfiguration> in your Tweak.xml
            exit;

        // Calculate the suggested quantity
        UnableToPickQuantity :=
            _HeaderFieldValues.GetContextValueAsDecimal('Quantity') -
            _HeaderFieldValues.GetContextValueAsDecimal('RegisteredQuantity');

        // Create a decimal step so the user can confirm / adjust the quantity
        _Steps.Create_DecimalStep(10, 'UnableToPickQuantity', false);
        _Steps.Set_header('Unable to pick');
        _Steps.Set_label('Quantity:');
        _Steps.Set_helpLabel('Please input the quantity you were unable to pick');
        _Steps.Set_defaultValue(UnableToPickQuantity);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // Step 4: Handle registration
    // When the user accepts all steps, the mobile device sends a PostAdhocRegistration request with the collected values to the backend.
    // Subscribe to this event to read the values collected from the mobile device and perform the required business logic.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', true, true)]
    local procedure HandleUnableToPickRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _RegistrationType <> 'UnableToPick' then // IMPORTANT: _RegistrationType must match the type attribute on <unplannedItemRegistrationConfiguration> in your Tweak.xml
            exit;
        if _IsHandled then
            exit;

        // << Perform your own business logic here >>
        // For example: create a journal line, update a planning record, send a notification, etc.

        // To illustrate that all values are available, this example shows them in the success message
        _SuccessMessage := StrSubstNo(
            'Unable to pick %1 for document %2 line %3',
            _RequestValues.GetValueAsDecimal('UnableToPickQuantity'),  // The quantity collected from the step created in Step 3
            _RequestValues.GetValueOrContextValue('OrderBackendId'),   // The order number from the Pick Line context
            _RequestValues.GetValueOrContextValue('LineNumber'));        // The line number from the Pick Line context

        // Set tracking info shown in the Mobile Document Queue (optional)
        _RegistrationTypeTracking := StrSubstNo('Unable to pick: %1', _RequestValues.GetValueAsDecimal('UnableToPickQuantity'));

        _IsHandled := true;
    end;

    // -----------------------------------------------------------------------
    // Step 5: Define values for title placeholders used in the Tweak.xml
    // Create Mobile Messages for each language you want to support, with keys matching the placeholders used in your Tweak.xml (without the @{}).
    // These messages are sent to the device on Reference Data load and resolve the @{} placeholders in the application.cfg.
    //
    // Mobile Messages can be created manually in the BC client, or via code as shown below.
    // This example uses the OnAddMessages event, which is triggered when:
    //   - "Create Document Types" action is run manually from Mobile WMS Setup page
    //   - "Create Messages" is run manually from the Mobile Language page
    //   - Tasklet Mobile WMS is upgraded to a new version (Upgrade codeunit)
    //
    // If you want the messages to be created automatically without manually running page actions or waiting for an upgrade of Tasklet Mobile WMS,
    // you can create the messages in an Install or Upgrade codeunit for your extension.
    // -----------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", OnAddMessages, '', true, true)]
    local procedure AddUnableToPickMessages_OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
        CreateLabelMessages(_LanguageCode, _Messages);
        // Alternatively, hardcode values per language without xlf translations:
        // CreateHardcodedMessages(_LanguageCode, _Messages);
    end;

    local procedure CreateLabelMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    var
        Language: Codeunit Language;
        InputLanguageId: Integer;
        SessionLanguageId: Integer;
        KeyLbl: Label 'UNABLE_TO_PICK_TITLE', Locked = true; // Message key matching the placeholder used in the Tweak.xml (without the @{})
        ValueLbl: Label 'Unable To Pick'; // Translate this value for each language you want to support in xlf files
    begin
        InputLanguageId := Language.GetLanguageId(_LanguageCode);
        SessionLanguageId := GlobalLanguage();
        if (InputLanguageId = 0) or (SessionLanguageId = 0) then
            exit;

        if InputLanguageId <> SessionLanguageId then
            GlobalLanguage(InputLanguageId); // Change the session language to the input language so that labels are resolved in the correct language

        _Messages.Create(_LanguageCode, KeyLbl, ValueLbl); // Create a message record for the label placeholder used in the Tweak.xml

        if SessionLanguageId <> GlobalLanguage() then
            GlobalLanguage(SessionLanguageId); // Change the session language back to the original language
    end;

    local procedure CreateHardcodedMessages(var _LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    var
        KeyLbl: Label 'UNABLE_TO_PICK_TITLE', Locked = true; // Message key matching the placeholder used in the Tweak.xml (without the @{})
    begin
        case _LanguageCode of
            'ENU':
                _Messages.Create(_LanguageCode, KeyLbl, 'Unable To Pick');
            'DAN':
                _Messages.Create(_LanguageCode, KeyLbl, 'Kan ikke plukkes');
        // Add more languages here
        end;
    end;
}
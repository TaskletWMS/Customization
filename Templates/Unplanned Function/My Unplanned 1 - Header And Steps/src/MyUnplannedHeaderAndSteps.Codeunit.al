codeunit 60010 "MyUnplanned Header And Steps"
{
    // Template: Unplanned function with Header fields AND Steps, added to the Main Menu.
    //
    // Flow: User selects the menu item → fills in header fields → accepts header → fills in steps → business logic runs.
    //
    // Implements:
    //   Distribute Tweak     — sends the tweak XML to the mobile device on login
    //   Define Header Fields — defines the fields the user fills in before accepting
    //   Define Steps         — defines the steps collected after the header is accepted
    //   Handle Registration  — business logic runs when the user accepts all steps
    //   Handle Icon          — serves the icon image to the device on request
    //   Create Setup Data    — creates the menu option and Mobile Messages (menu label and page title)

    // -----------------------------------------------------------------------------------------------------------------------
    // DISTRIBUTE TWEAK
    //
    // This event fires on mobile login (GetApplicationConfiguration and GetReferenceData), so the tweak is distributed to the mobile device at that time.
    // Requires: Android App 1.8.0+ and Mobile WMS 5.55+
    //
    // The first parameter of Add() is a unique integer ID for the tweak. Each tweak registered across all extensions must have a different ID.
    // Tweaks are applied in ascending ID order, so if your tweak depends on another (e.g. adding an action to a page defined by a different tweak),
    // give it a higher ID so it is applied after the page it references exists.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", OnGetApplicationConfiguration_OnAddTweaks, '', false, false)]
    local procedure AddTweak_OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    begin
        _MobTweakContainer.Add(60010, 'My Unplanned Header And Steps Tweak', NavApp.GetResourceAsText('MyUnplannedHeaderAndStepsTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Defines the header fields shown to the user for input when the page opens.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', false, false)]
    local procedure AddHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyUnplannedHeaderAndSteps'); // IMPORTANT: must match configurationKey in the Tweak.xml

        Samples.CreateSampleHeaderFields(_HeaderFields);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header is accepted, the device requests which steps to present to the user.
    // Add your steps here using _Steps.Create_*Field() methods. Replace the sample call with the fields your registration requires.
    // Header field values are available via _HeaderFieldValues.GetValue() — use them to drive step logic or set default values.
    // Requires useRegistrationCollector="true" in the Tweak.xml (already set).
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', false, false)]
    local procedure AddSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MyDate: Date;
        MyText: Text;
        MyDecimal: Decimal;
    begin
        if _RegistrationType <> 'MyUnplannedHeaderAndSteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        Samples.ReadSampleHeaderValues(_HeaderFieldValues, MyDate, MyText, MyDecimal);

        Samples.CreateSampleSteps(_Steps, MyDate, MyText, MyDecimal);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called when the user accepts all steps. Implement your business logic here.
    // Both header field values and step values are available via _RequestValues.
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MyDateStep: Date;
        MyTextStep: Text;
        MyDecimalStep: Decimal;
        SuccessMsg: Label 'Registration completed for MyUnplannedHeaderAndSteps: %1, %2, %3'; // Message for the mobile user. Provide translations as needed.
    begin
        if _IsHandled then
            exit;
        if _RegistrationType <> 'MyUnplannedHeaderAndSteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        Samples.ReadSampleStepValues(_RequestValues, MyDateStep, MyTextStep, MyDecimalStep);

        // << Perform your business logic here >>

        _SuccessMessage := StrSubstNo(SuccessMsg, MyDateStep, MyTextStep, MyDecimalStep); // Create a success message to show to the mobile user.
        _RegistrationTypeTracking := StrSubstNo('%1 %2 %3', MyDateStep, MyTextStep, MyDecimalStep); // Set a tracking value for the Mobile Document Queue, that can be used for filtering or just for information (optional)
        _IsHandled := true;
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE ICON
    //
    // When the mobile device does not have an image cached for the media id defined in the tweak, it requests the image from the backend via a GetMedia call.
    // Use this event to return the icon image as a Base64 string when the expected media id is requested.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnGetMedia_OnBeforeAddImageToMedia, '', false, false)]
    local procedure HandleMyIcon_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; var _Base64Media: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;
        if _MediaID <> 'myicon' then // must match the icon attribute in the Tweak.xml
            exit;

        _Base64Media := Samples.GetIconAsBase64('myicon.png');
        _IsHandled := true;
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // CREATE SETUP DATA
    //
    // Setup data is created via event subscribers that run when manually triggering actions in the BC client or during a Mobile WMS upgrade.
    //
    // The event OnAfterCreateDefaultMenuOptions is triggered by the action "Create Document Types" on the Mobile WMS Setup page.
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be run for each language you want to support.
    // Both are also triggered during upgrade of the Tasklet Mobile WMS app.
    //
    // To create the setup data automatically when your extension is installed or upgraded, implement the code in an Install/Upgrade codeunit also.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", OnAfterCreateDefaultMenuOptions, '', false, false)]
    local procedure CreateMenu_OnAfterCreateDefaultMenuOptions()
    begin
        // Create menu option and add to group to make it show up in the mobile app. Adjust as needed.
        // The MenuOption must match the menuItem/page id used in the Tweak.xml
        // The group code must match an existing group in the Mobile Group table.
        Samples.CreateSampleMenuOption('MyUnplannedHeaderAndSteps', 'WMS');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", OnAddMessages, '', false, false)]
    local procedure AddMessages_OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
        // Create the Mobile Messages that resolve the placeholders used in the Tweak.xml.
        // See the sample code for details about how this is done.
        Samples.CreateSampleMessages(_LanguageCode, _Messages);
        // Alternatively, hardcode values per language without xlf translations:
        // Samples.CreateSampleMessagesHardcoded(_LanguageCode, _Messages);
    end;

    var
        Samples: Codeunit "MyUnplanned Samples";
}

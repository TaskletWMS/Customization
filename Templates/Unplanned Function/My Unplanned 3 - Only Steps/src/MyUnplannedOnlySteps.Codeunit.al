codeunit 60030 "MyUnplanned Only Steps"
{
    // Template: Unplanned function with Steps ONLY, no user-fillable header fields. Added as an action on an existing page.
    //
    // Flow: Action triggered from a parent page → header shows a context field and auto-accepts immediately →
    //       user fills in steps → business logic runs.
    //
    // Implements:
    //   Distribute Tweak     — sends the tweak XML to the mobile device on login
    //   Define Header Fields — defines the locked context display field in the header (auto-accepted on open)
    //   Define Steps         — defines the steps collected after the header auto-accepts
    //   Handle Registration  — business logic runs when the user accepts all steps
    //   Handle Icon          — serves the icon image to the device on request
    //   Create Setup Data    — creates Mobile Messages (action label and page title)

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
        _MobTweakContainer.Add(60030, 'My Unplanned Only Steps Tweak', NavApp.GetResourceAsText('MyUnplannedOnlyStepsTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Defines one locked BackendID field. The framework automatically populates this reserved field with the BackendID context value
    // from the calling page, so the user can see their context on open.
    // The header takes no user input and will auto-accept on open via automaticAcceptOnOpen="true" in the Tweak.xml — no user interaction required.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', false, false)]
    local procedure AddHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyUnplannedOnlySteps'); // IMPORTANT: must match configurationKey in the Tweak.xml

        _HeaderFields.Create_TextField_BackendID(10); // Locked — shows the BackendID context value from the calling page; the user cannot edit it.
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header auto-accepts, the device requests which steps to present to the user.
    // Add your steps here using _Steps.Create_*Field() methods. Replace the sample call with the fields your registration requires.
    // Context values from the calling page are available via _HeaderFieldValues.GetContextValue() — use them to drive step logic or set default values.
    // Requires useRegistrationCollector="true" in the Tweak.xml (already set).
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', false, false)]
    local procedure AddSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        DisplayLine1: Text;
        Location: Text;
    begin
        if _RegistrationType <> 'MyUnplannedOnlySteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        Samples.ReadSampleContextValues(_HeaderFieldValues, DisplayLine1, Location); // Sample of reading context values from the calling page, to use in step logic or default values. Replace with reads for the context fields relevant to your target page.

        Samples.CreateSampleSteps(_Steps, 0D, DisplayLine1, 0);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called when the user accepts all steps. Implement your business logic here.
    // Step values are available via _RequestValues. Context values from the calling page are also available via _RequestValues.GetContextValue().
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MyDateStep: Date;
        MyTextStep: Text;
        MyDecimalStep: Decimal;
        SuccessMsg: Label 'Registration completed for MyUnplannedOnlySteps: %1, %2, %3'; // Message for the mobile user. Provide translations as needed.
    begin
        if _IsHandled then
            exit;
        if _RegistrationType <> 'MyUnplannedOnlySteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
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
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be manually run for each language you want to support.
    // It is also triggered during upgrade of the Tasklet Mobile WMS app.
    //
    // To create the setup data automatically when your extension is installed or upgraded, implement the code in an Install/Upgrade codeunit also.
    // -----------------------------------------------------------------------------------------------------------------------
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

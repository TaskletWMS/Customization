codeunit 70020 "MyLookup From Context"
{
    // Template: Lookup function — shown as an action on an existing page (e.g., Receive Lines list).
    //
    // Flow: User selects a receive line → taps the action → lookup page opens → result is displayed.
    //
    // Implements:
    //   Distribute Tweak     — sends the tweak XML to the mobile device on login
    //   Define Header Fields — defines OrderBackendID as the header field (auto-transferred from context, auto-accepted silently)
    //   Handle Lookup        — returns the lookup result to the device
    //   Handle Icon          — serves the icon image to the device on request
    //   Create Setup Data    — creates the Mobile Messages for the page title and action label

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
        _MobTweakContainer.Add(70020, 'My Lookup From Context Tweak', NavApp.GetResourceAsText('MyLookupFromContextTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // The header contains a single field, automatically filled from the context value of the same name on the calling page.
    // The field name must match a context value available on the source page — this is what triggers the automatic value transfer.
    // Because automaticAcceptOnOpen="true" is set in the Tweak.xml, the user never sees the header — it is accepted silently.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', false, false)]
    local procedure AddHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyLookupFromContext'); // IMPORTANT: must match configurationKey in the Tweak.xml

        _HeaderFields.Create_TextField_OrderBackendID(10); // Locked — shows the OrderBackendID context value from the calling page; the user cannot edit it.
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE LOOKUP
    //
    // Called when the device requests the lookup data after the header is accepted.
    // Read context values from _RequestValues (e.g. OrderBackendID transferred via the header, plus any other context values
    // from the source page), resolve the relevant record, and populate _LookupResponseElement with what to display.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", OnLookupOnCustomLookupType, '', false, false)]
    local procedure HandleLookup_OnLookupOnCustomLookupType(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _IsHandled: Boolean)
    var
        LineNumber: Text;
    begin
        if _LookupType <> 'MyLookupFromContext' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        Samples.ReadSampleContextValues(_RequestValues, LineNumber); // Sample of reading context values from ReceiveLines, to use in the lookup logic. Replace with reads for the context fields relevant to your scenario.
        Samples.CreateSampleLookupResponse(_LookupResponseElement, LineNumber); // Sample of creating a lookup response using the context value. Replace with your own logic to build the desired lookup result.

        _IsHandled := true;
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE ICON
    //
    // When the mobile device does not have an image cached for the media id defined in the tweak, it requests the image from the backend via a GetMedia call.
    // Use this event to return the icon image as a Base64 string when the expected media id is requested.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnGetMedia_OnBeforeAddImageToMedia, '', false, false)]
    local procedure HandleIcon_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; var _Base64Media: Text; var _IsHandled: Boolean)
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
        Samples: Codeunit "MyLookup Samples";
}

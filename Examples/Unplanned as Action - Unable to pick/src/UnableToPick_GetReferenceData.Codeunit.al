codeunit 60001 "UnableToPick_RefData"
{
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", OnGetApplicationConfiguration_OnAddTweaks, '', true, true)]
    local procedure AddUnableToPickTweak_OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    var
        Tweak: Text;
    begin
        Tweak := NavApp.GetResourceAsText('UnableToPickTweak.xml'); // Load the tweak XML from resources - resource folder specified in app.json
        _MobTweakContainer.Add(60000, 'UnableToPick: Add Unable To Pick action to Pick Lines', Tweak);
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Defines three locked fields. The framework automatically populates these fields with the context values from the calling page.
    // The header takes no user input and will auto-accept on open via automaticAcceptOnOpen="true" in the Tweak.xml — no user interaction required.
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
}
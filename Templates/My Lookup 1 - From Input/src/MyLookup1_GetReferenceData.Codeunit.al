codeunit 70011 MyLookup1_RefData
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", OnGetApplicationConfiguration_OnAddTweaks, '', false, false)]
    local procedure AddTweak_OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    begin
        _MobTweakContainer.Add(70010, 'My Lookup From Input Tweak', NavApp.GetResourceAsText('MyLookupFromInputTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Defines the fields the user fills in to filter the list. The user sees and accepts these before the list is loaded.
    // Replace the sample fields with whatever search criteria your lookup requires.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', false, false)]
    local procedure AddHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyLookupFromInput'); // IMPORTANT: must match configurationKey in the Tweak.xml

        CreateSampleHeaderFields(_HeaderFields);
    end;

    /// <summary>
    /// This sample creates a search text field for the header configuration.
    /// The field name must match the name read in ReadSampleHeaderValue.
    /// Replace this with the search fields your lookup requires.
    /// </summary>
    /// <param name="HeaderFields">The header field element record passed by the event subscriber.</param>
    local procedure CreateSampleHeaderFields(var HeaderFields: Record "MOB HeaderField Element")
    var
        SearchFieldLbl: Label 'Search';
    begin
        HeaderFields.Create_TextField(10, 'MySearchField', SearchFieldLbl); // e.g. Item No., Bin Code, Location Code
        HeaderFields.Set_optional(true); // Set optional if a blank value should return all results
    end;
}
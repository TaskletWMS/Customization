codeunit 60020 "MyUnplanned2_RefData"
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
        _MobTweakContainer.Add(60001, 'My Unplanned Only Header Tweak', NavApp.GetResourceAsText('MyUnplannedOnlyHeaderTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Defines the header fields shown to the user for input when the page opens.
    // Because useRegistrationCollector="false", registration fires immediately when the header is accepted.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', false, false)]
    local procedure AddHeader_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyUnplannedOnlyHeader'); // IMPORTANT: must match configurationKey in the Tweak.xml

        CreateSampleHeaderFields(_HeaderFields);
    end;

    /// <summary>
    /// This sample creates three fields for the header configuration: a required Date field, an optional Text field, and a required Decimal field.
    /// Replace this sample code with your own header field definitions.
    /// </summary>
    /// <param name="HeaderFields">The header field element record passed by the event subscriber.</param>
    local procedure CreateSampleHeaderFields(var HeaderFields: Record "MOB HeaderField Element")
    var
        DateFieldLbl: Label 'Select date';
        TextFieldLbl: Label 'Enter text';
        DecimalFieldLbl: Label 'Enter decimal';
    begin
        HeaderFields.Create_DateField(10, 'MyDate', DateFieldLbl);

        HeaderFields.Create_TextField(20, 'MyText', TextFieldLbl);
        HeaderFields.Set_optional(true); // Optional — the user is not required to fill this in

        HeaderFields.Create_DecimalField(30, 'MyDecimal', DecimalFieldLbl);
    end;
}

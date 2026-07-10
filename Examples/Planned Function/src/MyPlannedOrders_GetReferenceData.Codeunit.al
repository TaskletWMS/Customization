codeunit 62301 MyPlannedOrders_RefData
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
    local procedure AddTweak_OnGetApplicationConfiguration_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    begin
        _MobTweakContainer.Add(62300, 'My Planned Orders', NavApp.GetResourceAsText('MyPlannedOrdersTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Define which fields should be included in the header of the Order List page.
    // These are typically used as filter fields, and the values are handled in the "GetSalesOrders" function in the service codeunit.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddHeaderConfigurations, '', true, true)]
    local procedure AddHeaders_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        CreateMyPlannedOrderListHeader(_HeaderFields);
    end;

    local procedure CreateMyPlannedOrderListHeader(var HeaderFields: Record "MOB HeaderField Element")
    begin
        HeaderFields.InitConfigurationKey('MyPlannedOrders'); // Matches the ConfigurationKey defined in the tweak xml: <filter configurationKey="MyPlannedOrders"/>

        // Predefined filter like "Location" is often used
        HeaderFields.Create_ListField_FilterLocationAsLocation(10);

        // You can add additional filter fields using "Create_.." functions, for example a text filter:
        HeaderFields.Create_TextField(20, 'MyField', 'My field');
        HeaderFields.Set_optional(true);
    end;
}
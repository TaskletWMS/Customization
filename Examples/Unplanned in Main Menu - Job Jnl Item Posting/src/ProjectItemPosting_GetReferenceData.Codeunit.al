codeunit 60050 "ProjectItemPosting_RefData"
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
        _MobTweakContainer.Add(60050, 'Project Item Posting functionality', NavApp.GetResourceAsText('ProjectItemPostingTweak.xml'));
    end;

    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE HEADER FIELDS
    //
    // Define which fields should be included in the header of the three new pages added by the tweak, and how they should behave.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure AddHeaders_OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        CreateLookupHeader(_HeaderFields, 'ProjectItemPosting');
        CreateUnplannedItemRegistrationHeader(_HeaderFields, 'ProjectItemConsumption');
        CreateUnplannedItemRegistrationHeader(_HeaderFields, 'ProjectItemReturn');
    end;

    local procedure CreateLookupHeader(var _HeaderFields: Record "MOB HeaderField Element"; _ConfigurationKey: Text)
    var
        ProjectSearchLbl: Label 'Project Search', Comment = 'Field label';
    begin
        _HeaderFields.InitConfigurationKey(_ConfigurationKey); // IMPORTANT: _Key must match the configurationKey attribute in the Tweak.xml

        _HeaderFields.Create_TextField(10, 'ProjectSearchTxt');
        _HeaderFields.Set_label(ProjectSearchLbl);
        _HeaderFields.Set_optional(true);
    end;

    local procedure CreateUnplannedItemRegistrationHeader(var _HeaderFields: Record "MOB HeaderField Element"; _ConfigurationKey: Text)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        ProjectNoLbl: Label 'Project No.:', Comment = 'Field label';
        ProjectTaskNoLbl: Label 'Project Task No.:', Comment = 'Field label';
    begin
        _HeaderFields.InitConfigurationKey(_ConfigurationKey); // IMPORTANT: _Key must match the configurationKey attribute in the Tweak.xml

        // Project No.
        _HeaderFields.Create_TextField(10, 'ProjectNo');
        _HeaderFields.Set_label(ProjectNoLbl);
        _HeaderFields.Set_clearOnClear(false);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_length(20);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_eanAi('92');

        // Project Task. No.
        _HeaderFields.Create_TextField(20, 'ProjectTaskNo');
        _HeaderFields.Set_label(ProjectTaskNoLbl);
        _HeaderFields.Set_optional(true); // If value is not provided in the header, a Project Task No step will be created so the value can be collected
        _HeaderFields.Set_clearOnClear(false);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_length(20);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_eanAi('93');

        // Location
        _HeaderFields.Create_ListField_Location(30);
        _HeaderFields.Set_clearOnClear(false);

        // ItemNumber
        _HeaderFields.Create_TextField_ItemNumber(40);
        _HeaderFields.Set_clearOnClear(true);
        _HeaderFields.Set_acceptBarcode(true);
    end;
}

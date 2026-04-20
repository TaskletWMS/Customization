
codeunit 60052 "ProjectItemPosting_RegCfg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header is accepted, the device requests which steps to present to the user (if useRegistrationCollector="true" in the Tweak.xml).
    // Subscribe to this event to define which steps (input fields) the user sees on the UnplannedItemRegistration pages.
    // The registration type must match the type attribute of the unplannedItemRegistrationConfiguration in the Tweak.xml.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure DefineRegistrationSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    begin
        if not (_RegistrationType in ['ProjectItemConsumption', 'ProjectItemReturn']) then
            exit;

        DefineRegistrationSteps(_RegistrationType, _HeaderFieldValues, _Steps, _RegistrationTypeTracking);
    end;

    local procedure DefineRegistrationSteps(RegistrationType: Text; var HeaderFieldValues: Record "MOB NS Request Element"; var Steps: Record "MOB Steps Element"; var RegistrationTypeTracking: Text)
    var
        Item: Record Item;
        Location: Record Location;
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        UoMCode: Code[10];
        VariantCode: Code[10];
        ProjectNo: Code[20];
        ProjectTaskNo: Code[20];
        RegisterExpirationDate: Boolean;
        UseBaseUoM: Boolean;
    begin
        MobSetup.Get();
        MobSetup.CheckProjectJournalIsSetup();

        ReadAndValidateRequest(HeaderFieldValues, ProjectNo, ProjectTaskNo, VariantCode, UoMCode, Location, Item);

        DetermineItemTracking(RegistrationType, Item."No.", MobTrackingSetup, RegisterExpirationDate);
        UseBaseUoM := MobSetup."Use Base Unit of Measure";

        CreateProjectTaskStep(Steps, ProjectNo, ProjectTaskNo);
        CreateVariantStep(Steps, Item."No.", VariantCode);
        CreateBinStep(Steps, Location, Item."No.", VariantCode);
        CreateUoMStep(Steps, Item."No.", UoMCode, UseBaseUoM);
        CreateQuantityStep(Steps, Item, MobTrackingSetup);
        CreateTrackingSteps(Steps, Item."No.", MobTrackingSetup, RegisterExpirationDate);

        RegistrationTypeTracking := StrSubstNo('%1 - %2 - %3', Location.Code, Item."No.", VariantCode);
    end;

    local procedure ReadAndValidateRequest(var HeaderFieldValues: Record "MOB NS Request Element"; var ProjectNo: Code[20]; var ProjectTaskNo: Code[20]; var VariantCode: Code[10]; var UoMCode: Code[10]; var Location: Record Location; var Item: Record Item)
    var
        MobSetup: Record "MOB Setup";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        ScannedItemBarcode: Code[20];
        LocationCode: Code[10];
        ItemNo: Code[20];
    begin
        MobSetup.Get();

        ProjectNo := CopyStr(HeaderFieldValues.GetValue('ProjectNo'), 1, MaxStrLen(ProjectNo));
        ProjectTaskNo := CopyStr(HeaderFieldValues.GetValue('ProjectTaskNo'), 1, MaxStrLen(ProjectTaskNo));

        LocationCode := CopyStr(HeaderFieldValues.GetValue('Location'), 1, MaxStrLen(LocationCode));
        Location.Get(LocationCode);
        Location.TestField("Directed Put-away and Pick", false); // "Directed Put-away and Pick" not supported in Project Journal Standard Code

        ScannedItemBarcode := CopyStr(HeaderFieldValues.GetValue('ItemNumber'), 1, MaxStrLen(ScannedItemBarcode));

        // Resolve ItemNo, VariantCode and UoMCode based on the scanned barcode
        if MobSetup."Use Base Unit of Measure" then
            ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedItemBarcode, VariantCode)
        else
            ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedItemBarcode, VariantCode, UoMCode);

        if not Item.Get(ItemNo) then
            Error(MobWmsLanguage.GetMessage('ITEM_NOT_FOUND'), ItemNo); // Message provided by Tasklet Mobile WMS
    end;

    local procedure DetermineItemTracking(RegistrationType: Text; ItemNo: Code[20]; var MobTrackingSetup: Record "MOB Tracking Setup"; var RegisterExpirationDate: Boolean)
    begin
        case RegistrationType of
            'ProjectItemConsumption':
                MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, true, 2, RegisterExpirationDate); // 2 = positive adjustment
            'ProjectItemReturn':
                MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, false, 3, RegisterExpirationDate); // 3 = negative adjustment
        end;
    end;

    local procedure CreateProjectTaskStep(var Steps: Record "MOB Steps Element"; ProjectNo: Code[20]; ProjectTaskNo: Code[20])
    var
        JobTask: Record "Job Task";
        ProjectTaskList: Text;
        ProjectNoLbl: Label 'Project %1', Comment = 'Header for Project Task No. step.';
        ProjectTaskNoLbl: Label 'Project Task No.', Comment = 'Label for Project Task No. step.';
    begin
        if ProjectTaskNo <> '' then // If value is provided in the header, no need to create a step to collect it.
            exit;

        JobTask.SetRange("Job No.", ProjectNo);
        JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
        if JobTask.FindSet() then
            repeat
                ProjectTaskList += ';' + JobTask."Job Task No." + ' - ' + JobTask.Description;
            until JobTask.Next() = 0;

        Steps.Create_ListStep(5, 'ProjectTaskNoStep', false);
        Steps.Set_header(StrSubstNo(ProjectNoLbl, ProjectNo));
        Steps.Set_label(ProjectTaskNoLbl);
        Steps.Set_listValues(ProjectTaskList);
        Steps.Set_optional(false); // Optional to support blank value. Otherwise 1st element is selected on a list step.
        Steps.Save();
    end;

    local procedure CreateVariantStep(var Steps: Record "MOB Steps Element"; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        if VariantCode <> '' then // If value resolved from the scanned barcode, no need to create a step to collect it.
            exit;

        ItemVariant.SetRange("Item No.", ItemNo);
        if not ItemVariant.IsEmpty() then
            Steps.Create_ListStep_Variant(10, ItemNo);
    end;

    local procedure CreateBinStep(var Steps: Record "MOB Steps Element"; Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        if Location."Bin Mandatory" then
            Steps.Create_TextStep_Bin(20, Location.Code, ItemNo, VariantCode);
    end;

    local procedure CreateUoMStep(var Steps: Record "MOB Steps Element"; ItemNo: Code[20]; UoMCode: Code[10]; UseBaseUoM: Boolean)
    var
        WmsMgt: Codeunit "WMS Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        if UseBaseUoM or (UoMCode <> '') then // If UoM is provided from the scanned barcode or setup to use base UoM, no need to create a step to collect it.
            exit;

        Steps.Create_ListStep_UoM(30, ItemNo);
        Steps.Set_visible(MobWmsToolbox.GetItemHasMultipleUoM(ItemNo));
        Steps.Set_defaultValue(WmsMgt.GetBaseUOM(ItemNo));
    end;

    local procedure CreateQuantityStep(var Steps: Record "MOB Steps Element"; Item: Record Item; MobTrackingSetup: Record "MOB Tracking Setup")
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
    begin
        if MobTrackingSetup."Serial No. Required" then // If Serial Number is required, quantity is always 1, so no need to create a step to collect it.
            exit;

        Steps.Create_DecimalStep_Quantity(40, Item."No.");
        Steps.Set_defaultValue(1);
        if not MobWmsToolbox.GetItemHasMultipleUoM(Item."No.") then
            Steps.Set_helpLabel(Item."Base Unit of Measure");
    end;

    local procedure CreateTrackingSteps(var Steps: Record "MOB Steps Element"; ItemNo: Code[20]; MobTrackingSetup: Record "MOB Tracking Setup"; RegisterExpirationDate: Boolean)
    begin
        if MobTrackingSetup."Serial No. Required" then // If Serial Number is required, we need to create a step to collect it.
            Steps.Create_TextStep_SerialNumber(50, ItemNo);

        if MobTrackingSetup."Lot No. Required" then // If Lot Number is required, we need to create a step to collect it.
            Steps.Create_TextStep_LotNumber(60, ItemNo);

        if MobTrackingSetup."Package No. Required" then // If Package Number is required, we need to create a step to collect it.
            Steps.Create_TextStep_PackageNumber(70, ItemNo);

        if RegisterExpirationDate then // If Expiration Date needs to be registered based on the entry type, we need to create a step to collect it.
            Steps.Create_DateStep_ExpirationDate(80, ItemNo);
    end;
}

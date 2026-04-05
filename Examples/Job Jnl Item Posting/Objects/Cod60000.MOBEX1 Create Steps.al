
codeunit 60000 "MOBEX1 CreateSteps"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        JobTask: Record "Job Task";
        WmsMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        LocationCode: Code[10];
        UoMCode: Code[10];
        ScannedItemBarcode: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        JobNo: Code[20];
        JobTaskNo: Code[20];
        RegisterExpirationDate: Boolean;
        JobTaskList: Text;
    begin
        if _RegistrationType IN ['JobJnlPosAdjustQty', 'JobJnlNegAdjustQty'] then begin

            MobSetup.Get();

            // Get values from request
            JobNo := CopyStr(_HeaderFieldValues.GetValue('JobNo'), 1, MaxStrLen(JobNo));
            JobTaskNo := CopyStr(_HeaderFieldValues.GetValue('JobTaskNo'), 1, MaxStrLen(JobTaskNo));

            LocationCode := CopyStr(_HeaderFieldValues.GetValue('Location'), 1, MaxStrLen(LocationCode));
            if LocationCode <> '' then
                Location.Get(LocationCode);

            // "Directed Put-away and Pick" not supported in Job Journal Standard Code
            Location.TestField("Directed Put-away and Pick", false);

            // ...extract ItemNo and VariantCode from scanned barcode
            ScannedItemBarcode := CopyStr(_HeaderFieldValues.GetValue('ItemNumber'), 1, MaxStrLen(ScannedItemBarcode));

            // Obsolete function
            // If scanned value is Cross Reference, then get Variant and UoM from that            
            //ItemNo := MobWMSToolbox.CheckCrossRef(ScannedItemBarcode, VariantCode)

            // Use after BC17            
            // If scanned value is Cross Reference, then get Variant and UoM from that            
            if MobSetup."Use Base Unit of Measure" then
                ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedItemBarcode, VariantCode)
            else
                ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedItemBarcode, VariantCode, UoMCode);

            // Validate values from request                      
            if not Item.Get(ItemNo) then
                Error(MobWmsLanguage.GetMessage('ITEM_NOT_FOUND'), ItemNo);

            // Determine if item tracking is needed        
            Case _RegistrationType of
                'JobJnlPosAdjustQty':
                    MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, true, 2, RegisterExpirationDate);
                'JobJnlNegAdjustQty':
                    MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, false, 3, RegisterExpirationDate);
            end;

            // Create the steps

            // STEP: "Job Task"
            if JobTaskNo = '' then begin
                JobTask.SetRange("Job No.", JobNo);
                JobTask.SetRange("Job Task Type", JobTask."Job Task Type"::Posting);
                if JobTask.FindSet() then
                    repeat
                        JobTaskList += ';' + JobTask."Job Task No." + ' - ' + JobTask.Description;
                    until JobTask.Next() = 0;

                _Steps.Create_ListStep(5, 'JobTaskNoStep', false);
                _Steps.Set_header(MobWmsLanguage.GetMessage('JOB') + ' ' + JobNo);
                _Steps.Set_label(MobWmsLanguage.GetMessage('JOB_TASK_NO_LABEL') + ':');
                //_Steps.Set_helpLabel(MobWmsLanguage.GetMessage('ENTER_JOB_TASK_NO_HELP'));
                _Steps.Set_listValues(JobTaskList);
                _Steps.Set_optional(false); // Optional to support blank value. Otherwise 1st element is selected on a list step.
                _Steps.Save();
            end;

            // STEP: "Item Variant"
            if VariantCode = '' then begin
                ItemVariant.Reset();
                ItemVariant.SetRange("Item No.", ItemNo);
                if not ItemVariant.IsEmpty() then
                    _Steps.Create_ListStep_Variant(10, ItemNo);
            end;

            // STEP: Bin
            if Location."Bin Mandatory" then
                _Steps.Create_TextStep_Bin(20, Location.Code, ItemNo, VariantCode);

            // STEP: "Unit of Measure" - Only show if more than one UoM avaliable
            if not MobSetup."Use Base Unit of Measure" and (UoMCode = '') then begin
                _Steps.Create_ListStep_UoM(30, ItemNo);
                _Steps.Set_visible(MobWmsToolbox.GetItemHasMultipleUoM(ItemNo));
                _Steps.Set_defaultValue(WmsMgt.GetBaseUOM(ItemNo));
            end;

            // STEP: "Quantity"
            if not MobTrackingSetup."Serial No. Required" then begin
                _Steps.Create_DecimalStep_Quantity(40, ItemNo);
                _Steps.Set_minValue(-1000);  // Allow both negative and positive numbers to be used
                _Steps.Set_defaultValue(1);

                if not MobWmsToolbox.GetItemHasMultipleUoM(ItemNo) then
                    _Steps.Set_helpLabel(Item."Base Unit of Measure");
            end;

            // STEP: "Serial number" (should only be added if the item is serial tracked)
            if MobTrackingSetup."Serial No. Required" then
                _Steps.Create_TextStep_SerialNumber(50, ItemNo);

            // STEP: "Lot number" (should only be added if the item is lot tracked)
            if MobTrackingSetup."Lot No. Required" then
                _Steps.Create_TextStep_LotNumber(60, ItemNo);

            // STEP: "Exp. Date" (should only be added if the item is lot tracked and require Exp. Date)
            if RegisterExpirationDate then
                _Steps.Create_DateStep_ExpirationDate(70, ItemNo);

            // Information to display at the Mobile Document Queue
            _RegistrationTypeTracking := StrSubstNo('%1 - %2 - %3', LocationCode, ItemNo, VariantCode);
        end;
    end;

}

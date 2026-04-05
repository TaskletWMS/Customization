codeunit 50007 "X02 PickToBin Remove Item"
{
    // Enables the user to remove an item from the bin and replace it on a different bin

    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey
        _HeaderFields.InitConfigurationKey('PickToBinRemoveItemHeader');

        // Add the header lines
        _HeaderFields.Create_ListField_Location(10);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure MyOnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MobSetup: Record "MOB Setup";
        Item: Record Item;
        LocationCode: Code[10];
        ItemNumber: Code[20];
        VariantCode: Code[10];
    begin
        // Handle only your own Header name
        if _RegistrationType <> 'PickToBinRemoveItem' then
            exit;

        MobSetup.Get();

        // Read the headerFields
        Evaluate(LocationCode, _HeaderFieldValues.Get_Location(true));
        ItemNumber := _HeaderFieldValues.GetContextValue('ItemNumber');

        // Check if user tries to delete the footer element with totals
        if ItemNumber = '' then
            Error('You cannot remove the line with totals. Please remove items one by one.');

        Item.Get(ItemNumber);
        VariantCode := _HeaderFieldValues.GetValue('Variant');

        // Add To Bin
        _Steps.Create_TextStep_Bin(10, LocationCode, Item."No.", VariantCode);
        _Steps.Set_helpLabel(StrSubstNo('Where do you place item %1?', ItemNumber));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure MyOnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        TempEntrySummary: Record "Entry Summary" temporary;
        MobTrackingSetup: Record "MOB Tracking Setup";
        Location: Record Location;
        BinContent: Record "Bin Content";
        ItemLedgEntry: Record "Item Ledger Entry";
        MobPbPostUnplannedMoveReg: Codeunit "X02 Post Unplanned Move Reg.";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        FromBin: Code[20];
        ToBin: Code[20];
        ItemNumber: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        QtyInBin: Decimal;
        SpecificRegisterExpirationDate: Boolean;
        EntrySummaryFound: Boolean;
        TrackingRequired: Boolean;
    begin
        if _RegistrationType <> 'PickToBinRemoveItem' then
            exit;

        if _IsHandled then
            exit;

        // Read primary _RequestValue
        ItemNumber := _RequestValues.GetContextValue('ItemNumber', true);

        // Read _RequestValues
        VariantCode := _RequestValues.GetContextValue('Variant');
        UoMCode := _RequestValues.GetContextValue('UoM', true);
        Quantity := _RequestValues.GetContextValueAsDecimal('Quantity', true);

        // Opposite normal, as removing item from Bin
        Evaluate(NewLocationCode, _RequestValues.Get_Location(true));
        Evaluate(LocationCode, _RequestValues.GetContextValue('NewLocation', true));
        Evaluate(ToBin, _RequestValues.Get_Bin());
        Evaluate(FromBin, _RequestValues.GetContextValue('ToBin', true));
        Location.Get(LocationCode);

        // Get user to confirm Item needs to be removed
        MobToolbox.ErrorIfNotConfirm(_RequestValues, StrSubstNo('Are you sure you wish to remove item %1 from the bin and place them on %2?', ItemNumber, ToBin));

        // Lookup the content of the bin
        MobTrackingSetup.DetermineWhseTrackingRequiredWithExpirationDate(ItemNumber, SpecificRegisterExpirationDate);
        // MobTrackingSetup.Tracking: Copy later in TempEntrySummary loop or fallback to no summary

        EntrySummaryFound := false;
        TrackingRequired := MobTrackingSetup.TrackingRequired();
        if TrackingRequired then begin
            // Item is tracked, get a summary to Look Up in Bin Content
            MobWmsToolbox.GetTrackedSummary(TempEntrySummary, Location, FromBin, ItemNumber, VariantCode, UoMCode, SpecificRegisterExpirationDate);

            if TempEntrySummary.FindSet() then begin
                EntrySummaryFound := true;

                // Set filters equal for all EntrySummary records
                if Location."Bin Mandatory" then begin
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", LocationCode);
                    BinContent.SetRange("Bin Code", FromBin);
                    BinContent.SetRange("Item No.", ItemNumber);
                    BinContent.SetRange("Variant Code", VariantCode);
                    BinContent.SetRange("Unit of Measure Code", UoMCode);
                end else begin
                    ItemLedgEntry.Reset();
                    ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code", "Location Code", "Item Tracking", "Lot No.", "Serial No.");
                    ItemLedgEntry.SetRange("Item No.", ItemNumber);
                    ItemLedgEntry.SetRange(Open, TRUE);
                    ItemLedgEntry.SetRange("Variant Code", VariantCode);
                    ItemLedgEntry.SetRange("Location Code", LocationCode);
                    ItemLedgEntry.SetRange("Unit of Measure Code", UoMCode);
                end;

                repeat
                    // Calculate Qty. in Bin per Serial No. / Lot No.
                    QtyInBin := 0;
                    if Location."Bin Mandatory" then begin
                        BinContent.MobSetTrackingFilterFromEntrySummaryIfNotBlank(TempEntrySummary);
                        BinContent.SetAutoCalcFields(Quantity);
                        if BinContent.FindFirst() then
                            QtyInBin := BinContent.Quantity;
                    end else begin
                        ItemLedgEntry.MobSetTrackingFilterFromEntrySummaryIfNotBlank(TempEntrySummary);
                        ItemLedgEntry.CalcSums("Remaining Quantity");
                        QtyInBin := ItemLedgEntry."Remaining Quantity";
                    end;

                    // Post move away from bin
                    MobTrackingSetup.CopyTrackingFromEntrySummary(TempEntrySummary);
                    MobPbPostUnplannedMoveReg.PostUnplannedMoveRegistration(ItemNumber, VariantCode, UoMCode, LocationCode, FromBin, NewLocationCode, ToBin, QtyInBin, MobTrackingSetup);

                until TempEntrySummary.Next() = 0;
            end;
        end;

        if not (TrackingRequired and EntrySummaryFound) then begin
            // Fallback for no tracking and tracked items with no inventory on hand
            Clear(TempEntrySummary);
            Clear(MobTrackingSetup);

            // Post move away from bin
            MobPbPostUnplannedMoveReg.PostUnplannedMoveRegistration(ItemNumber, VariantCode, UoMCode, LocationCode, FromBin, NewLocationCode, ToBin, Quantity, MobTrackingSetup);
        end;

        _SuccessMessage := StrSubstNo('Removed item %1 from %2 - %3 to %4 - %5', ItemNumber, LocationCode, FromBin, NewLocationCode, ToBin);
        _RegistrationTypeTracking := StrSubstNo('Item %1 moved from %2 - %3 to %4 - %5', ItemNumber, LocationCode, FromBin, NewLocationCode, ToBin);

        _IsHandled := true;
    end;
}
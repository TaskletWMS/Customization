codeunit 60053 "ProjectItemPosting_PostReg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Subscribe to this event to post the collected step values via a Job Journal Line.
    // The registration type must match the type attribute of the unplannedItemRegistrationConfiguration in the Tweak.xml.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure RunPosting_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _RegistrationTypeTracking: Text; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;
        if not (_RegistrationType in ['ProjectItemConsumption', 'ProjectItemReturn']) then
            exit;

        _SuccessMessage := RunPosting(_RegistrationType, _RequestValues, _RegistrationTypeTracking);
        _IsHandled := true;
    end;

    var
        MobSetup: Record "MOB Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";

    local procedure RunPosting(RegistrationType: Text; var RequestValues: Record "MOB NS Request Element"; var RegistrationTypeTracking: Text): Text
    var
        Location: Record Location;
        Item: Record Item;
        JobJnlLine: Record "Job Journal Line";
        MobTrackingSetup: Record "MOB Tracking Setup";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        ProjectNo: Code[20];
        ProjectTaskNo: Code[20];
        BinCode: Code[10];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        ExpDate: Date;
        IsConsumption: Boolean;
    begin
        MobSetup.Get();
        MobSetup.CheckProjectJournalIsSetup();

        ReadAndValidateRequest(RequestValues, ProjectNo, ProjectTaskNo, VariantCode, BinCode, UoMCode, Quantity, ExpDate, Location, Item, MobTrackingSetup);

        if RegistrationType = 'ProjectItemConsumption' then
            IsConsumption := true;

        if IsConsumption then begin
            ValidateBinContent(Location.Code, BinCode, Item."No.", VariantCode, UoMCode, Quantity);
            if HasRecentEntries(ProjectNo, Item."No.") then // Show Confirm Dialog on Device before consumption if recent entries exist
                MobToolbox.ErrorIfNotConfirm(RequestValues, GetConsumptionConfirmMsg(Item));
        end;

        if not IsConsumption then
            Quantity := Quantity * -1;

        BuildJobJnlLine(JobJnlLine, ProjectNo, ProjectTaskNo, Location.Code, BinCode, Item."No.", UoMCode, Quantity);
        CreateItemTracking(JobJnlLine, MobTrackingSetup, Location, IsConsumption, ExpDate);

        JobJnlPostLine.Run(JobJnlLine);

        if UoMCode = '' then
            UoMCode := Item."Base Unit of Measure";

        RegistrationTypeTracking := StrSubstNo('%1 %2 %3 %4 %5', ProjectNo, ProjectTaskNo, Item."No.", Quantity, UoMCode);

        exit(GetSuccessMsg(ProjectNo, ProjectTaskNo, Item, UoMCode, Quantity));
    end;

    local procedure ReadAndValidateRequest(var RequestValues: Record "MOB NS Request Element"; var ProjectNo: Code[20]; var ProjectTaskNo: Code[20]; var VariantCode: Code[10]; var BinCode: Code[10]; var UoMCode: Code[10]; var Quantity: Decimal; var ExpDate: Date; var Location: Record Location; var Item: Record Item; var MobTrackingSetup: Record "MOB Tracking Setup")
    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        ProjectTaskNoStepText: Text;
        LocationCode: Code[10];
        ScannedItemBarcode: Code[20];
        ItemNo: Code[20];
    begin
        ProjectNo := CopyStr(RequestValues.GetValue('ProjectNo'), 1, MaxStrLen(ProjectNo));
        ProjectTaskNo := CopyStr(RequestValues.GetValue('ProjectTaskNo'), 1, MaxStrLen(ProjectTaskNo));
        if ProjectTaskNo = '' then begin
            // ProjectTaskNo was collected via a step — extract the code from "CODE - Description" format
            ProjectTaskNoStepText := RequestValues.GetValue('ProjectTaskNoStep');
            ProjectTaskNo := CopyStr(CopyStr(ProjectTaskNoStepText, 1, StrPos(ProjectTaskNoStepText, ' - ') - 1), 1, MaxStrLen(ProjectTaskNo));
        end;
        LocationCode := CopyStr(RequestValues.GetValue('Location'), 1, MaxStrLen(LocationCode));
        BinCode := CopyStr(RequestValues.GetValue('Bin'), 1, MaxStrLen(BinCode));
        Quantity := RequestValues.GetValueAsDecimal('Quantity');
        ExpDate := RequestValues.GetValueAsDate('ExpirationDate');
        MobTrackingSetup.CopyTrackingFromRequestValues(RequestValues);

        Location.Get(LocationCode);
        Location.TestField("Directed Put-away and Pick", false);

        // Resolve ItemNo, VariantCode and UoMCode based on the scanned barcode
        ItemNo := MobItemReferenceMgt.SearchItemReference(CopyStr(RequestValues.GetValue('ItemNumber'), 1, MaxStrLen(ItemNo)), VariantCode, UoMCode);
        Item.Get(ItemNo);

        if UoMCode = '' then
            UoMCode := CopyStr(RequestValues.GetValue('UoM'), 1, MaxStrLen(UoMCode));

        if MobSetup."Use Base Unit of Measure" then
            UoMCode := ''; // When using Base UoM, the UoMCode is stored as empty and will be defaulted to the item's Base UoM during posting
        if MobTrackingSetup."Serial No." <> '' then begin // When using Serial Number, quantity is always 1 and UoM is always Base UoM
            UoMCode := '';
            Quantity := 1;
        end;
    end;

    local procedure ValidateBinContent(LocationCode: Code[10]; BinCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UoMCode: Code[10]; Quantity: Decimal)
    var
        BinContent: Record "Bin Content";
        WMSMgt: Codeunit "WMS Management";
        QtyBase: Decimal;
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        if BinCode = '' then
            exit;

        if UoMCode <> '' then begin
            ItemUnitofMeasure.Get(ItemNo, UoMCode);
            ItemUnitofMeasure.TestField("Qty. per Unit of Measure");
            QtyBase := Quantity * ItemUnitofMeasure."Qty. per Unit of Measure";
        end else
            QtyBase := Quantity;

        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetRange("Unit of Measure Code", WMSMgt.GetBaseUOM(ItemNo)); // Non-directed is always Base UoM
        if BinContent.IsEmpty() then
            Error(MobWmsLanguage.GetMessage('NO_QTY_ON_BIN'), BinCode); // Message provided by Tasklet Mobile WMS

        BinContent.FindFirst();
        BinContent.CalcFields("Quantity (Base)");
        if BinContent."Quantity (Base)" < QtyBase then
            Error(MobWmsLanguage.GetMessage('INSUFFICIENT_STOCK_QTY'), BinContent.Quantity, BinContent."Unit of Measure Code"); // Message provided by Tasklet Mobile WMS
    end;

    local procedure BuildJobJnlLine(var JobJnlLine: Record "Job Journal Line"; ProjectNo: Code[20]; ProjectTaskNo: Code[20]; LocationCode: Code[10]; BinCode: Code[10]; ItemNo: Code[20]; UoMCode: Code[10]; Quantity: Decimal)
    begin
        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := MobSetup."EXMPL Project Jnl Template";
        JobJnlLine."Journal Batch Name" := MobSetup."EXMPL Project Jnl Batch Name";
        JobJnlLine.Validate("Line Type", MobSetup."EXMPL Project Line Type");
        JobJnlLine.Validate("Posting Date", WorkDate());
        JobJnlLine."Document No." := MobWmsLanguage.GetMessage('HANDHELD'); // Message provided by Tasklet Mobile WMS
        JobJnlLine.Validate("Job No.", ProjectNo);
        JobJnlLine.Validate("Job Task No.", ProjectTaskNo);
        JobJnlLine.Validate("Location Code", LocationCode);
        JobJnlLine.Validate(Type, JobJnlLine.Type::Item);
        JobJnlLine.Validate("No.", ItemNo);
        JobJnlLine.Validate("Unit of Measure Code", UoMCode);
        JobJnlLine.Validate(Quantity, Quantity);
        if BinCode <> '' then
            JobJnlLine.Validate("Bin Code", BinCode);
    end;

    local procedure CreateItemTracking(var JobJnlLine: Record "Job Journal Line"; var MobTrackingSetup: Record "MOB Tracking Setup"; Location: Record Location; IsConsumption: Boolean; ExpDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
        MobItemTrackingMgt: Codeunit "MOB Item Tracking Management";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        RegisterExpirationDate: Boolean;
        ExistingExpDate: Date;
        EntriesExist: Boolean;
    begin
        if IsConsumption then
            MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(JobJnlLine."No.", false, 3, RegisterExpirationDate) // 3 = negative adjustment
        else
            MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(JobJnlLine."No.", true, 2, RegisterExpirationDate); // 2 = positive adjustment

        if not MobTrackingSetup.TrackingRequired() then
            exit;

        if IsConsumption then
            MobTrackingSetup.CheckTrackingOnInventoryIfRequired(JobJnlLine."No.", JobJnlLine."Variant Code");

        // The function expects quantity in base UoM
        MobTrackingSetup.CreateReservEntryFor(
            CreateReservationEntry,
            Database::"Job Journal Line",
            MobToolbox.AsInteger(JobJnlLine."Entry Type"),
            JobJnlLine."Journal Template Name",
            JobJnlLine."Journal Batch Name",
            0,              // ForProdOrderLine
            JobJnlLine."Line No.",
            JobJnlLine."Qty. per Unit of Measure",
            JobJnlLine.Quantity,
            JobJnlLine."Quantity (Base)");

        EntriesExist := MobItemTrackingMgt.GetWhseExpirationDate(JobJnlLine."No.", JobJnlLine."Variant Code", Location, MobTrackingSetup, ExistingExpDate);

        if EntriesExist then begin
            CreateReservationEntry.SetDates(0D, ExistingExpDate);
            CreateReservationEntry.SetNewExpirationDate(ExistingExpDate);
        end;

        // For item returns, apply the expiration date from the scan
        if not IsConsumption and (ExpDate <> 0D) then begin
            CreateReservationEntry.SetDates(0D, ExpDate);
            CreateReservationEntry.SetNewExpirationDate(ExpDate);
        end;

        CreateReservationEntry.CreateEntry(
            JobJnlLine."No.",
            JobJnlLine."Variant Code",
            JobJnlLine."Location Code",
            '',         // Description
            0D,
            WorkDate(),
            0,          // Transferred from entry no.
            ReservationEntry."Reservation Status"::Prospect);
    end;

    /// <summary>
    /// Check if any Job Ledger Entries have been posted for this item within the last 5 minutes.
    /// Used to warn the user before posting a consumption that may be a duplicate.
    /// </summary>
    local procedure HasRecentEntries(ProjectNo: Code[20]; ItemNo: Code[20]): Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        DateTime5MinAgo: DateTime;
    begin
        JobLedgerEntry.SetRange("Job No.", ProjectNo);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", ItemNo);
        JobLedgerEntry.SetRange("Posting Date", Today());
        DateTime5MinAgo := CurrentDateTime() - 300000;  // 5 min * 60 sec * 1000 ms
        JobLedgerEntry.SetRange(SystemCreatedAt, DateTime5MinAgo, CurrentDateTime());
        exit(not JobLedgerEntry.IsEmpty());
    end;

    local procedure GetConsumptionConfirmMsg(var Item: Record Item) ReturnText: Text
    var
        InfoLine1Lbl: Label 'Item %1 has been registered on this Project in the last 5 minutes.';
        InfoLine2Lbl: Label 'This might be a duplicate registration.';
        ConfirmLbl: Label 'Do you want to continue?';
    begin
        ReturnText :=
            StrSubstNo(InfoLine1Lbl, Item."No.") + MobToolbox.CRLFSeparator()
            + StrSubstNo(InfoLine2Lbl, Item."No.") + MobToolbox.CRLFSeparator()
            + StrSubstNo(ConfirmLbl, Item."No.");
    end;

    local procedure GetSuccessMsg(ProjectNo: Text; ProjectTaskNo: Text; Item: Record Item; UoMCode: Code[10]; Quantity: Decimal) ReturnText: Text
    var
        SuccessLbl: Label 'Posting to project %1 task %2 succeeded!', Comment = 'Success message shown on the mobile device after posting the line';
    begin
        ReturnText :=
            StrSubstNo(SuccessLbl, ProjectNo, ProjectTaskNo) + MobToolbox.CRLFSeparator() + MobToolbox.CRLFSeparator()
            + StrSubstNo('%1 %2', Item."No.", Item.Description) + MobToolbox.CRLFSeparator()
            + StrSubstNo('%1 %2', Quantity, UoMCode);
    end;
}

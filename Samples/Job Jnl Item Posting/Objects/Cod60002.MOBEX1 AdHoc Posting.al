codeunit 60002 "MOBEX1 AdHoc Posting"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin

        if _IsHandled = false then
            Case _RegistrationType of
                // Handle Returning of Item in Job Journal
                'JobJnlPosAdjustQty':
                    begin
                        _SuccessMessage := JobJnlPostAdjustQty(_RegistrationType, _RequestValues, false);
                        _IsHandled := true;
                    end;

                // Handle Consumption of Item in Job Journal
                'JobJnlNegAdjustQty':
                    begin
                        _SuccessMessage := JobJnlPostAdjustQty(_RegistrationType, _RequestValues, true);
                        _IsHandled := true;
                    end;
            end;
    end;

    local procedure JobJnlPostAdjustQty(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; _consumption: Boolean): Text
    var
        MobSetup: Record "MOB Setup";
        Location: Record Location;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        JobJnlLine: Record "Job Journal Line";
        BinContent: Record "Bin Content";
        ReservationEntry: Record "Reservation Entry";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        JobJnlPostLine: Codeunit "Job Jnl.-Post Line";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        WMSMgt: Codeunit "WMS Management";
        JobNo: Code[20];
        JobTaskNo: Code[20];
        JobTaskNoStepText: Text;
        LocationCode: Code[10];
        BinCode: Code[10];
        ItemNo: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        RegisterExpirationDate: Boolean;
        ExistingExpDate: Date;
        ExpDate: Date;
        QtyBase: Decimal;
        EntriesExist: Boolean;

    begin
        JobNo := CopyStr(_RequestValues.GetValue('JobNo'), 1, MaxStrLen(JobNo));
        JobTaskNo := CopyStr(_RequestValues.GetValue('JobTaskNo'), 1, MaxStrLen(JobTaskNo));
        if JobTaskNo = '' then begin
            JobTaskNoStepText := _RequestValues.GetValue('JobTaskNoStep');
            JobTaskNo := CopyStr(CopyStr(JobTaskNoStepText, 1, StrPos(JobTaskNoStepText, ' - ') - 1), 1, MaxStrLen(JobTaskNo));
        end;
        LocationCode := CopyStr(_RequestValues.GetValue('Location'), 1, MaxStrLen(LocationCode));
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues);
        ExpDate := _RequestValues.GetValueAsDate('ExpirationDate');
        LocationCode := CopyStr(_RequestValues.GetValue('Location'), 1, MaxStrLen(LocationCode));
        BinCode := CopyStr(_RequestValues.GetValue('Bin'), 1, MaxStrLen(BinCode));
        ItemNo := CopyStr(_RequestValues.GetValue('ItemNumber'), 1, MaxStrLen(ItemNo));
        UoMCode := CopyStr(_RequestValues.GetValue('UoM'), 1, MaxStrLen(UoMCode));
        Quantity := _RequestValues.GetValueAsDecimal('Quantity');

        // Show Confirm Dialog on Device
        if (_RegistrationType = 'JobJnlNegAdjustQty') and JobLedgerEntriesExist(JobNo, ItemNo) then
            MobToolbox.ErrorIfNotConfirm(_RequestValues, StrSubstNo(MobWmsLanguage.GetMessage('JOB_JNL_POST_WARNING'), ItemNo));

        MobSetup.Get();
        MobSetup.TestField("MOBEX1 Job Jnl Batch Name");
        MobSetup.TestField("MOBEX1 Job Jnl Template");

        if LocationCode <> '' then
            Location.Get(LocationCode);

        // "Directed Put-away and Pick" not supported in Job Journal Standard Code
        Location.TestField("Directed Put-away and Pick", false);

        // If scanned value is Cross Reference, then get Variant and UoM from that
        if MobSetup."Use Base Unit of Measure" or (UoMCode <> '') then
            ItemNo := MobItemReferenceMgt.SearchItemReference(ItemNo, VariantCode)
        else
            ItemNo := MobItemReferenceMgt.SearchItemReference(ItemNo, VariantCode, UoMCode);

        if UoMCode <> '' then begin
            ItemUnitofMeasure.Get(ItemNo, UoMCode);
            ItemUnitofMeasure.TestField("Qty. per Unit of Measure");
            QtyBase := Quantity * ItemUnitofMeasure."Qty. per Unit of Measure";
        end else
            QtyBase := Quantity;

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        // Determine Consumption or Returning and reverse sign if needed
        if not _consumption then
            Quantity := Quantity * -1;

        // Create Job Journal
        JobJnlLine.Init();
        JobJnlLine."Journal Template Name" := MobSetup."MOBEX1 Job Jnl Template";
        JobJnlLine."Journal Batch Name" := MobSetup."MOBEX1 Job Jnl Batch Name";
        JobJnlLine.Validate("Line Type", MobSetup."MOBEX1 Job Line Type");
        JobJnlLine.Validate("Posting Date", WorkDate());
        JobJnlLine."Document No." := MobWmsLanguage.GetMessage('HANDHELD');
        JobJnlLine.Validate("Job No.", JobNo);
        JobJnlLine.Validate("Job Task No.", JobTaskNo);
        JobJnlLine.Validate("Location Code", LocationCode);
        JobJnlLine.Validate(Type, JobJnlLine.Type::Item);
        JobJnlLine.Validate("No.", ItemNo);
        JobJnlLine.Validate("Unit of Measure Code", UoMCode);
        JobJnlLine.Validate(Quantity, Quantity);

        // Find BinContent to check if it is possible to remove quantity
        if BinCode <> '' then
            if _consumption then begin
                BinContent.SetRange("Location Code", LocationCode);
                BinContent.SetRange("Bin Code", BinCode);
                BinContent.SetRange("Item No.", ItemNo);
                BinContent.SetRange("Variant Code", VariantCode);
                BinContent.SetRange("Unit of Measure Code", WMSMgt.GetBaseUOM(JobJnlLine."No.")); // Non directed is always Base UoM
                if BinContent.FIND('-') then begin
                    BinContent.CalcFields(Quantity, "Quantity (Base)");
                    if BinContent."Quantity (Base)" < QtyBase then  // Compare base with base
                        Error(MobWmsLanguage.GetMessage('INSUFFICIENT_STOCK_QTY'), BinContent.Quantity, BinContent."Unit of Measure Code")
                    else
                        JobJnlLine.Validate("Bin Code", BinCode);
                end else
                    Error(MobWmsLanguage.GetMessage('NO_QTY_ON_BIN'), BinCode);
            end else
                JobJnlLine.Validate("Bin Code", BinCode);

        // Determine if item tracking is needed        
        Case _RegistrationType of
            'JobJnlPosAdjustQty':
                MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, true, 2, RegisterExpirationDate);
            'JobJnlNegAdjustQty':
                MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(ItemNo, false, 3, RegisterExpirationDate);
        end;

        //if RegisterSerialNumber or RegisterLotNumber then begin
        if MobTrackingSetup.TrackingRequired() then begin

            if _consumption then
                MobTrackingSetup.CheckTrackingOnInventoryIfRequired(JobJnlLine."No.",
                                                                    JobJnlLine."Variant Code");

            // The function expects the quantity to be in the base UoM
            MobTrackingSetup.CreateReservEntryFor(
                CreateReservationEntry,
                Database::"Job Journal Line",
                MobToolbox.AsInteger(JobJnlLine."Entry Type"),
                JobJnlLine."Journal Template Name",
                JobJnlLine."Journal Batch Name", // ForBatchName
                0,  // ForProdOrderLine
                JobJnlLine."Line No.", // 0,  // SourceLineNo
                JobJnlLine."Qty. per Unit of Measure",
                JobJnlLine.Quantity,
                JobJnlLine."Quantity (Base)");

            // If the ExpirationDate is registered it must be set on the reservation entry
            EntriesExist :=
                MobCommonMgt.GetWhseExpirationDate(
                    JobJnlLine."No.",
                    JobJnlLine."Variant Code",
                    Location,
                    MobTrackingSetup,
                    ExistingExpDate);

            if EntriesExist then begin
                CreateReservationEntry.SetDates(0D, ExistingExpDate);
                CreateReservationEntry.SetNewExpirationDate(ExistingExpDate);
            end;

            // If Item return then apply ExpirationDate from Scan
            if not _consumption and (ExpDate <> 0D) then begin
                CreateReservationEntry.SetDates(0D, ExpDate);
                CreateReservationEntry.SetNewExpirationDate(ExpDate);
            end;

            CreateReservationEntry.CreateEntry(JobJnlLine."No.",
                                               JobJnlLine."Variant Code",
                                               JobJnlLine."Location Code",
                                               '',   //Description
                                               0D,
                                               WorkDate(),
                                               0,  // Tranferred from entry no.
                                               ReservationEntry."Reservation Status"::Prospect);
        end;

        // Post Job Journal
        JobJnlPostLine.Run(JobJnlLine);

        Item.Get(ItemNo);
        exit(StrSubstNo(MobWmsLanguage.GetMessage('JOB_JNL_POSTED'), ItemNo, VariantCode, Item.Description, Quantity, UoMCode));
    end;

    /// <summary>
    /// Check if any Entries has been posted within the last 5 minutes
    /// </summary>    
    local procedure JobLedgerEntriesExist(_JobNo: Code[20]; _ItemNo: Code[20]): Boolean
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        DateTime5MinAgo: DateTime;
    begin
        JobLedgerEntry.SetRange("Job No.", _JobNo);
        JobLedgerEntry.SetRange(Type, JobLedgerEntry.Type::Item);
        JobLedgerEntry.SetRange("No.", _ItemNo);
        JobLedgerEntry.SetRange("Posting Date", Today());
        DateTime5MinAgo := CurrentDateTime() - 300000;  // substract 5 min from Current DateTime (5 Min * 60 Sec * 1000 MilSec)
        JobLedgerEntry.Setrange(SystemCreatedAt, DateTime5MinAgo, CurrentDateTime());
        if JobLedgerEntry.IsEmpty then
            exit(false)
        else
            exit(true);
    end;

}
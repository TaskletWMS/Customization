codeunit 50100 "MyMobile Adhoc Ext"
{

    // [WMS Adhoc] [Pos. Adjustment Ext]

    // Step 7/12

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Location: Record Location;
        Item: Record Item;
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        LocationCode: Code[10];
        BinCode: Code[10];
        ScannedItemBarcode: Code[50];
        ItemNo: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
    begin
        if _RegistrationType = 'PosAdjustQuantity' then begin

            // Get headerfield values from request
            LocationCode := _HeaderFieldValues.GetValue('Location', true);  // true = Location tag must exist in request Xml
            BinCode := _HeaderFieldValues.GetValue('Bin', true);
            ScannedItemBarcode := _HeaderFieldValues.GetValue('ItemNumber', true);

            // Verify headerfield values from request
            Location.Get(LocationCode);
            if Location."Bin Mandatory" and (BinCode = '') then
                Error(MobWmsLanguage.GetMessage('BIN_IS_MANDATORY_ON_LOCATION'), LocationCode);

            ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedItemBarcode, VariantCode, UoMCode, true);    // extract ItemNo/VariantCode/UoMCode from scanned barcode; true = ErrorIfNotExists to ensure ScannedBarcode could be converted to a valid ItemNo
            Item.Get(ItemNo);

            // Create the steps
            CreatePosAdjustQuantitySteps(_Steps, Location, BinCode, Item, VariantCode, UoMCode);

            // Information to display at the Mobile Document Queue
            _RegistrationTypeTracking := StrSubstNo('%1 - %2', LocationCode, ItemNo);
        end;
    end;

    local procedure CreatePosAdjustQuantitySteps(var _Steps: Record "MOB Steps Element"; _Location: Record "Location"; _BinCode: Code[10]; _Item: Record Item; _VariantCode: Code[10]; _UoMCode: Code[10])
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        ReasonCode: Record "Reason Code";
        ItemVariant: Record "Item Variant";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        DummyRegisterExpirationDate: Boolean;
        UseBaseUoM: Boolean;
    begin
        MobSetup.Get();

        Clear(MobTrackingSetup);
        MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(_Item."No.", true, 2, DummyRegisterExpirationDate); // 2 = Positive Adjustment
        // MobTrackingSetup.Tracking: Tracking values are unused in this scope

        // Step: Variant  (only created when needed = if not already defined from the ScannedBarcode)
        if _VariantCode = '' then begin
            ItemVariant.Reset();
            ItemVariant.SetRange("Item No.", _Item."No.");
            if not ItemVariant.IsEmpty() then
                _Steps.Create_ListStep_Variant(10, _Item."No.");
        end;

        // Step: UoM  (only created when needed = if not already defined from the ScannedBarcode / or when not posting in Base Unit of Measure and multiple UoM to select exists)
        if _UoMCode = '' then begin
            UseBaseUoM := (MobSetup."Use Base Unit of Measure" and (not _Location."Directed Put-away and Pick")) or (not MobWmsToolbox.GetItemHasMultipleUoM(_Item."No."));
            if not UseBaseUoM then begin
                _Steps.Create_ListStep_UoM(20, _Item."No.");
                _Steps.Set_defaultValue(_Item."Base Unit of Measure");
            end;
        end;

        // Steps: SerialNumber, LotNumber, PackageNumber and custom tracking dimensions
        _Steps.Create_TrackingStepsIfRequired(MobTrackingSetup, 30, _Item."No.");

        // Step: ExpirationDate
        // Collecting ExpirationDate not supported in this example (can only make positive adjustment on Tracking that previously has existed on inventory)

        // Step: Quantity
        if not MobTrackingSetup."Serial No. Required" then begin
            _Steps.Create_DecimalStep_Quantity(100, _Item."No.");
            _Steps.Set_Header('Enter Quantity to add'); // Hardcoded text
            _Steps.Set_minValue(0.0000000001);

            // Show UoM in Quantity help
            case true of
                _UoMCode <> '':
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _UoMCode);
                UseBaseUoM:
                    _Steps.Set_helpLabel(MobWmsLanguage.GetMessage('UOM_LABEL') + ': ' + _Item."Base Unit of Measure");
            end;
        end;

        // Step: ReasonCode
        ReasonCode.Reset();
        if not ReasonCode.IsEmpty() then
            _Steps.Create_ListStep_ReasonCode(110, _Item."No.");

    end;


    // Step 8/12

    // [Example] 
    // OnPostAdhoc-event -- but subscribing only to some parameters
    // See https://docs.taskletfactory.com/display/TFSK/OnPostAdhocRegistrationOnCustomRegistrationType for full parameter list
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _RegistrationTypeTracking: Text; var _SuccessMessage: Text; var _IsHandled: Boolean)
    begin
        if (_RegistrationType = 'PosAdjustQuantity') and (not _IsHandled) then begin
            PostPosAdjustQuantityRegistration(_RequestValues, _SuccessMessage, _RegistrationTypeTracking);
            _IsHandled := true;
        end;
    end;

    // <remarks>
    // Based on MobWmsAdhocRegistr.PostAdjustQuantityRegistration()
    // </remarks>
    local procedure PostPosAdjustQuantityRegistration(var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text)
    var
        SourceCode: Record "Source Code";
        Item: Record Item;
        Bin: Record Bin;
        Location: Record Location;
        BinContent: Record "Bin Content";
        ItemJnlLine: Record "Item Journal Line";
        ItemJnlLine2: Record "Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpec: Record "Tracking Specification" temporary;
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsAdhocRegistr: Codeunit "MOB WMS Adhoc Registr.";
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        CreateReservationEntry: Codeunit "Create Reserv. Entry";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        WMSMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        ReasonCode: Code[10];
        BinCode: Code[20];
        ScannedBarcode: Code[50];
        ItemNo: Code[20];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        RegisterExpirationDate: Boolean;
        ExpirationDate: Date;
    begin
        MobSetup.Get();

        // The values are added to the relevant journal if they have been registered on the mobile device

        LocationCode := _RequestValues.GetValue('Location', true);
        BinCode := MobToolbox.ReadBin(_RequestValues.GetValue('Bin'));
        ScannedBarcode := _RequestValues.GetValue('ItemNumber', true);
        Quantity := _RequestValues.GetValueAsDecimal('Quantity');
        ReasonCode := _RequestValues.GetValue('ReasonCode');

        // Set Item, UoM and Variant from Barcode
        ItemNo := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _RequestValues.HasValue('UoM') then
            UoMCode := _RequestValues.GetValue('UoM');
        if _RequestValues.HasValue('Variant') then
            VariantCode := _RequestValues.GetValue('Variant');

        // Set the tracking value displayed in the document queue
        _RegistrationTypeTracking :=
            ItemJnlLine.FieldCaption("Location Code") + ' ' +
            LocationCode + ' ' +
            Item.TableCaption() + ' ' +
            ItemNo + ' ' +
            ItemJnlLine.FieldCaption(Quantity) + ' ' +
            Format(Quantity);

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        // Initialize MobTrackingSetup (TrackingRequired and Tracking fields)
        Item.Get(ItemNo);
        MobTrackingSetup.DetermineItemTrackingRequiredByEntryType(Item."No.", true, 2, RegisterExpirationDate); // 2 = Positive Adjustment
        MobTrackingSetup.CopyTrackingFromRequestValues(_RequestValues); // LotNumber, SerialNumber, PackageNumber

        // Make sure that the MOBADJQTY source code exist (for tracking purposes)
        if not SourceCode.Get('MOBADJQTY') then begin
            SourceCode.Code := 'MOBADJQTY';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_ADJUST_QUANTITY'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;

        Location.Get(LocationCode);
        if (MobSetup."Skip Whse Unpl Count IJ Post") and Location."Directed Put-away and Pick" then begin

            // Create and post warehouse journal.
            // The posting will generate bin entries to/from the adjustment bin.
            // Periodically G/L must be updated by executing "Calculate Whse. Adjustment" in an item journal.

            //Check necessary configuration for this tutorial - other configurations may require posting code below to be refactored
            MobSetup.TestField("Whse Inventory Jnl Template");
            Location.TestField("Adjustment Bin Code");
            // Create Warehouse Journal
            TempWhseJnlLine.Init();
            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
            TempWhseJnlLine."Location Code" := LocationCode;
            TempWhseJnlLine.Validate("Registering Date", WorkDate());
            TempWhseJnlLine.Validate("Source Code", SourceCode.Code);
            TempWhseJnlLine.Validate("Whse. Document Type", TempWhseJnlLine."Whse. Document Type"::"Whse. Phys. Inventory");
            TempWhseJnlLine."Whse. Document No." := MobWmsLanguage.GetMessage('HANDHELD');
            TempWhseJnlLine."User ID" := UserId();
            TempWhseJnlLine.Validate("Entry Type", TempWhseJnlLine."Entry Type"::"Positive Adjmt.");
            TempWhseJnlLine.Validate("Item No.", Item."No.");
            TempWhseJnlLine.Validate("Variant Code", VariantCode);
            TempWhseJnlLine.Validate("Reason Code", ReasonCode);
            if UoMCode = '' then // When no step was created for UoMCode, use the Base Unit of Meaure (the item has only one UoM or MobSetup."Use Base Unit of Measure" is enabled)
                TempWhseJnlLine.Validate("Unit of Measure Code", MobWmsAdhocRegistr.DetermineItemUOM(Item."No."))
            else
                TempWhseJnlLine.Validate("Unit of Measure Code", UoMCode);

            // MobTrackingSetup.TrackingRequired: Determined before (during parse of RequestValues)
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues) 

            MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(TempWhseJnlLine);

            if RegisterExpirationDate then begin

                // In this example ExpirationDate is always blank in current example as we do not collect ExpirationDate step 
                // Therefore only it can only be supported when the Lot/Serial Number was previously on inventory
                // Consider creating an optional step for Expiration Date using the OnPostAdhocRegistration_OnAddSteps event
                MobCommonMgt.GetWhseExpirationDate(TempWhseJnlLine."Item No.", TempWhseJnlLine."Variant Code", Location, MobTrackingSetup, ExpirationDate);

                TempWhseJnlLine.Validate("Expiration Date", ExpirationDate);    // Will throw error on posting if blank (not previously on inventory)
                TempWhseJnlLine.Validate("New Expiration Date", ExpirationDate);
            end;

            // Set the adjustment bin
            Bin.Get(Location.Code, Location."Adjustment Bin Code");
            TempWhseJnlLine."From Bin Code" := Bin.Code;
            TempWhseJnlLine."From Zone Code" := Bin."Zone Code";
            TempWhseJnlLine."From Bin Type Code" := Bin."Bin Type Code";
            // Set the bin
            Bin.Get(Location.Code, BinCode);
            TempWhseJnlLine.Validate("To Bin Code", Bin.Code);
            TempWhseJnlLine.Validate("To Zone Code", Bin."Zone Code");
            TempWhseJnlLine.Validate("Zone Code", Bin."Zone Code");
            TempWhseJnlLine.Validate("Bin Code", Bin.Code);
            // Allow entry of quantities
            TempWhseJnlLine."Phys. Inventory" := true;
            // Calculate the quantity on bin
            BinContent.SetRange("Location Code", LocationCode);
            BinContent.SetRange("Bin Code", BinCode);
            BinContent.SetRange("Item No.", Item."No.");
            BinContent.SetRange("Variant Code", VariantCode);
            MobTrackingSetup.SetTrackingFilterForBinContent(BinContent);
            BinContent.SetRange("Unit of Measure Code", TempWhseJnlLine."Unit of Measure Code");
            BinContent.SetAutoCalcFields(Quantity, "Quantity (Base)");
            if BinContent.FindFirst() then begin
                TempWhseJnlLine."Qty. (Calculated)" := BinContent.Quantity;
                TempWhseJnlLine."Qty. (Calculated) (Base)" := BinContent."Quantity (Base)";
            end;
            TempWhseJnlLine.Validate("Qty. (Phys. Inventory)", BinContent.Quantity + Quantity);
            // Post the warehouse journal            
            MobWmsAdhocRegistr.RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
        end else begin

            // Perform the posting
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
            ItemJnlLine."Document No." := MobWmsLanguage.GetMessage('HANDHELD');
            ItemJnlLine.Validate("Item No.", Item."No.");
            ItemJnlLine.Validate("Variant Code", VariantCode);
            ItemJnlLine.Validate("Posting Date", WorkDate());
            ItemJnlLine."Source Code" := SourceCode.Code;
            ItemJnlLine.Validate("Location Code", LocationCode);
            if UoMCode = '' then // When no step was created for UoMCode, use the Base Unit of Meaure (the item has only one UoM or MobSetup."Use Base Unit of Measure" is enabled)
                ItemJnlLine.Validate("Unit of Measure Code", MobWmsAdhocRegistr.DetermineItemUOM(Item."No."))
            else
                ItemJnlLine.Validate("Unit of Measure Code", UoMCode);

            ItemJnlLine.Validate(Quantity, Quantity);
            ItemJnlLine.Validate("Reason Code", ReasonCode);

            if BinCode <> '' then begin
                Bin.Get(ItemJnlLine."Location Code", BinCode);
                ItemJnlLine.Validate("Bin Code", BinCode);
            end;

            // Determine if item tracking is needed
            // No -> just post
            // Yes -> create reservation entries for the line

            // MobTrackingSetup.TrackingRequired: Determined before (during parse of RequestValues)
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues) 

            if MobTrackingSetup.TrackingRequired() then begin

                TempTrackingSpec.InitFromItemJnlLine(ItemJnlLine);
                MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);

                // In this example ExpirationDate is always blank in current example as we do not collect ExpirationDate step 
                // Therefore only it can only be supported when the Lot/Serial Number was previously on inventory
                // Consider creating an optional step for Expiration Date using the OnPostAdhocRegistration_OnAddSteps event
                TempTrackingSpec."Expiration Date" := 0D;   // Will throw error on posting if not previously on inventory

                if TempTrackingSpec.TrackingExists() then begin
                    MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
                    MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
                    MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
                end;

            end;

            // Take copy and Post Item Jnl Line
            MobWmsAdhocRegistr.PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            if ItemJnlLine."Location Code" <> '' then begin
                Location.Get(ItemJnlLine."Location Code");
                if Location."Bin Mandatory" then begin
                    MobTrackingSetup.CopyTrackingToItemJnlLine(ItemJnlLine2);
                    ItemJnlLine2.Validate("Item Expiration Date", ReservationEntry."Expiration Date");
                    // When using Directed Put-away and Pick, Zone Code and Bin Code is set to Adjustment bin from Location Card. This must be
                    // overwritten to post on the correct Zone and Bin.
                    if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, 1, TempWhseJnlLine, false) then begin
                        if Location."Directed Put-away and Pick" then begin
                            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
                            if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Positive Adjmt." then begin
                                TempWhseJnlLine.Validate("To Zone Code", Bin."Zone Code");
                                TempWhseJnlLine.Validate("To Bin Code", Bin."Code");
                                // Validation deliberately not performed to avoid posting to adjustment bin
                                TempWhseJnlLine."From Zone Code" := '';
                                TempWhseJnlLine."From Bin Type Code" := '';
                                TempWhseJnlLine."From Bin Code" := '';
                            end else
                                if TempWhseJnlLine."Entry Type" = TempWhseJnlLine."Entry Type"::"Negative Adjmt." then begin
                                    TempWhseJnlLine.Validate("From Zone Code", Bin."Zone Code");
                                    TempWhseJnlLine.Validate("From Bin Code", Bin."Code");
                                    // Validation deliberately not performed to avoid posting to adjustment bin
                                    TempWhseJnlLine."To Zone Code" := '';
                                    TempWhseJnlLine."To Bin Code" := '';
                                end;
                        end;
                        MobWmsAdhocRegistr.RegisterWhseJnlLine(TempWhseJnlLine, 4, false);
                    end;
                end;
            end;
        end;

        _SuccessMessage := StrSubstNo(MobWmsLanguage.GetMessage('ADJUST_QTY_COMPLETED'), Item."No.");
    end;
}
codeunit 50009 "X02 Post Unplanned Move Reg."
{
    // Code copied from codeunit 6181380 "MOB WMS Adhoc Registr.".PostUnplannedMoveRegistration() - MOB5.40
    // Only the parameters and Initialization section has been adjusted to use parameter values. (and Publisher Events has been skipped)

    var
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
        MobWmsAdhocReg: Codeunit "MOB WMS Adhoc Registr.";
        MobWMSToolbox: Codeunit "MOB WMS Toolbox";

    internal procedure PostUnplannedMoveRegistration(_ItemNo: Code[20]; _VariantCode: Code[10]; _UoM: Code[10]; _Location: Code[10]; _FromBin: Code[20]; _NewLocation: Code[10]; _ToBin: Code[20]; _Quantity: Decimal; _MobTrackingSetup: Record "MOB Tracking Setup");
    var
        MobSetup: Record "MOB Setup";
        MobTrackingSetup: Record "MOB Tracking Setup";
        SourceCode: Record "Source Code";
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
        WarehouseJnlLine: Record "Warehouse Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        TempTrackingSpec: Record "Tracking Specification" temporary;
        ReservationEntry: Record "Reservation Entry";
        ItemJnlLine2: Record "Item Journal Line";
        MobCommonMgt: Codeunit "MOB Common Mgt.";
        MobTrackingSpecReserve: Codeunit "MOB Tracking Spec-Reserve";
        WMSMgt: Codeunit "WMS Management";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        LocationCode: Code[10];
        NewLocationCode: Code[10];
        FromBin: Code[20];
        ToBin: Code[20];
        ScannedBarcode: Code[50];
        ItemNumber: Code[50];
        VariantCode: Code[10];
        UoMCode: Code[10];
        Quantity: Decimal;
        DummyRegisterExpirationDate: Boolean;
        ExpirationDate: Date;
        EntriesExist: Boolean;
    begin
        Clear(MobTrackingSetup);
        MobSetup.Get();

        // *** Initialize - Start ***
        LocationCode := _Location;
        NewLocationCode := _NewLocation;
        FromBin := _FromBin;
        ToBin := _ToBin;
        ScannedBarcode := _ItemNo;
        Quantity := _Quantity;
        // MobTrackingSetup.TrackingRequired: Determine later when populating the WhseJnLine after a valid WhseJnlLine."Item No." has been found
        MobTrackingSetup := _MobTrackingSetup;

        // Set Item, UoM and Variant from Barcode
        ItemNumber := MobItemReferenceMgt.SearchItemReference(ScannedBarcode, VariantCode, UoMCode);
        // Collected values have priority
        if _UoM <> '' then
            UoMCode := _UoM;
        if _VariantCode <> '' then
            VariantCode := _VariantCode;

        // *** Initialize - End ***

        // Make sure that the MOBUNPMOVE source code exist (for tracking purposes)
        if not SourceCode.Get('MOBUNPMOVE') then begin
            SourceCode.Code := 'MOBUNPMOVE';
            SourceCode.Description := CopyStr(MobWmsLanguage.GetMessage('HANDHELD_UNPLANNED_MOVE'), 1, MaxStrLen(SourceCode.Description));
            SourceCode.Insert();
        end;

        // When using Serial Number Quantity is always = 1
        if MobTrackingSetup."Serial No." <> '' then
            Quantity := 1;

        // Get the location and determine if it uses directed pick/put-away or not
        // When moving between different locations, both Item Journal and Warehouse Journal Posting is necessarry.
        Location.Get(LocationCode);
        if Location."Directed Put-away and Pick" and (LocationCode = NewLocationCode) then begin

            // Perform the posting using the Warehouse Item Journal
            // Set the template
            MobSetup.TestField("Move Whse. Jnl Template");
            WarehouseJnlLine."Journal Template Name" := MobSetup."Move Whse. Jnl Template";

            // Set the batch name
            MobSetup.TestField("Unplanned Move Batch Name");
            WarehouseJnlLine."Journal Batch Name" := MobSetup."Unplanned Move Batch Name";

            // Set the location code
            WarehouseJnlLine."Location Code" := LocationCode;

            // Initialize the new line (based on the values set above)
            //WarehouseJnlLine.SetUpNewLine(WarehouseJnlLineOld);

            // Set the fixed values
            WarehouseJnlLine.Validate("Registering Date", WorkDate());
            WarehouseJnlLine.Validate("Source Code", SourceCode.Code);
            WarehouseJnlLine.Validate("Whse. Document Type", WarehouseJnlLine."Whse. Document Type"::"Whse. Journal");
            WarehouseJnlLine.Validate("Whse. Document No.", MobWmsLanguage.GetMessage('HANDHELD'));
            WarehouseJnlLine.Validate("Entry Type", WarehouseJnlLine."Entry Type"::Movement);
            WarehouseJnlLine."User ID" := UserId();

            // Set the values from the mobile device
            WarehouseJnlLine.Validate("Item No.", ItemNumber);
            WarehouseJnlLine.Validate("Variant Code", VariantCode);
            WarehouseJnlLine.Validate("From Bin Code", FromBin);
            WarehouseJnlLine.Validate("To Bin Code", ToBin);
            if MobSetup."Use Base Unit of Measure" then
                WarehouseJnlLine.Validate("Qty. (Base)", Quantity)
            else begin
                WarehouseJnlLine.Validate("Unit of Measure Code", UoMCode);
                WarehouseJnlLine.Validate(Quantity, Quantity);
            end;

            // Wrapped in condition (LocationCode = NewLocationCode) meaning this part of code will always be WhseTracking and never TransferTracking
            MobTrackingSetup.DetermineWhseTrackingRequired(WarehouseJnlLine."Item No.", DummyRegisterExpirationDate);
            // MobTrackingSetup.Tracking: Copied before (during parse of RequestValues)

            // Validate LotNumber, SerialNumber, PackageNumber and custom tracking dimensions
            MobTrackingSetup.ValidateTrackingToWhseJnlLineIfRequired(WarehouseJnlLine);

            // If expiration date is used for either the serial or lot number then the new expiration date must match the old exp date            
            // Determine ExpDate from Whse. Entries to account for new entries that has not yet been posted to ItemLedgEntry from adj. bin
            EntriesExist :=
              MobCommonMgt.GetWhseExpirationDate(
                WarehouseJnlLine."Item No.",
                WarehouseJnlLine."Variant Code",
                Location,
                MobTrackingSetup,
                ExpirationDate);

            if EntriesExist then begin
                WarehouseJnlLine.Validate("Expiration Date", ExpirationDate);
                WarehouseJnlLine.Validate("New Expiration Date", ExpirationDate);
            end;

            //OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateWhseJnlLine(_RequestValues, WarehouseJnlLine);

            // Post Warehouse Journal Line
            MobWmsAdhocReg.RegisterWhseJnlLine(WarehouseJnlLine, 4, false);

        end else begin

            // Perform the posting using the standard journal
            ItemJnlLine.Init();
            ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::Transfer;
            ItemJnlLine."Document No." := MobWmsLanguage.GetMessage('HANDHELD');
            ItemJnlLine.Validate("Item No.", ItemNumber);
            ItemJnlLine.Validate("Variant Code", VariantCode);
            ItemJnlLine.Validate("Posting Date", WorkDate());
            ItemJnlLine."Source Code" := SourceCode.Code;
            ItemJnlLine.Validate("Location Code", LocationCode);
            if MobWmsAdhocReg.TestBinMandatory(LocationCode) then
                ItemJnlLine.Validate("Bin Code", FromBin);
            ItemJnlLine.Validate("New Location Code", NewLocationCode);
            if MobWmsAdhocReg.TestBinMandatory(NewLocationCode) then
                ItemJnlLine.Validate("New Bin Code", ToBin);
            if MobSetup."Use Base Unit of Measure" then
                ItemJnlLine.Validate(Quantity, Quantity)
            else begin
                ItemJnlLine.Validate("Unit of Measure Code", UoMCode);
                ItemJnlLine.Validate(Quantity, Quantity);
            end;

            TempTrackingSpec.InitFromItemJnlLine(ItemJnlLine);

            Clear(ReservationEntry);
            if MobTrackingSetup.TrackingExists() then begin
                MobTrackingSetup.CopyTrackingToTrackingSpec(TempTrackingSpec);
                TempTrackingSpec."Expiration Date" := 0D;

                MobTrackingSpecReserve.CreateReservation(TempTrackingSpec);
                MobTrackingSpecReserve.GetLastEntry(ReservationEntry);
                MobTrackingSetup.CopyTrackingFromReservEntry(ReservationEntry);
            end;

            // Take copy and Post Item Jnl Line
            //OnPostAdhocRegistrationOnUnplannedMove_OnAfterCreateItemJnlLine(_RequestValues, ReservationEntry, ItemJnlLine);
            MobWmsAdhocReg.PostItemJnlLine(ItemJnlLine, ItemJnlLine2);

            if ItemJnlLine."Location Code" <> '' then begin
                Location.Get(ItemJnlLine."Location Code");
                if Location."Bin Mandatory" then begin
                    MobTrackingSetup.CopyTrackingToItemJnlLine(ItemJnlLine2);
                    ItemJnlLine2."Item Expiration Date" := ReservationEntry."Expiration Date";

                    // Post Warehouse "Transfer From" 
                    if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, 1, TempWhseJnlLine, false) then begin
                        if Location."Directed Put-away and Pick" then begin
                            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
                            TempWhseJnlLine.Validate("From Zone Code", MobWmsToolbox.GetZoneFromBin(ItemJnlLine2."Location Code", ItemJnlLine2."Bin Code"));
                            TempWhseJnlLine.Validate("From Bin Code", ItemJnlLine2."Bin Code");
                            // Validation deliberately not performed to avoid posting to adjustment bin
                            TempWhseJnlLine."To Zone Code" := '';
                            TempWhseJnlLine."To Bin Code" := '';
                        end;
                        MobWmsAdhocReg.RegisterWhseJnlLine(TempWhseJnlLine, 1, false);
                    end;
                end;
            end;

            if ItemJnlLine."New Location Code" <> '' then begin
                Location.Get(ItemJnlLine."New Location Code");
                if Location."Bin Mandatory" then begin
                    MobTrackingSetup.CopyTrackingToItemJnlLine(ItemJnlLine2);
                    ItemJnlLine2."Item Expiration Date" := ReservationEntry."Expiration Date";

                    // Post Warehouse "Transfer To"
                    if WMSMgt.CreateWhseJnlLine(ItemJnlLine2, 1, TempWhseJnlLine, true) then begin
                        if Location."Directed Put-away and Pick" then begin
                            TempWhseJnlLine."Journal Template Name" := MobSetup."Whse Inventory Jnl Template";
                            TempWhseJnlLine.Validate("To Zone Code", MobWMSToolbox.GetZoneFromBin(ItemJnlLine2."New Location Code", ItemJnlLine2."New Bin Code"));
                            TempWhseJnlLine.Validate("To Bin Code", ItemJnlLine2."New Bin Code");
                            // Validation deliberately not performed to avoid posting to adjustment bin
                            TempWhseJnlLine."From Zone Code" := '';
                            TempWhseJnlLine."From Bin Type Code" := '';
                            TempWhseJnlLine."From Bin Code" := '';
                        end;
                        MobWmsAdhocReg.RegisterWhseJnlLine(TempWhseJnlLine, 1, true);
                    end;
                end;
            end;
        end;
    end;
}

// This example can register "Qty. To Ship" on basic Sales Order Picking.
// The example is kept very basic.
// Please seek inspiration from our source code e.g. Codeunit "MOB WMS Receive" and "MOB WMS Pick".

// IMPORTANT: Do NOT use both examples at the same time.
// IMPORTANT: After publishing, you MUST run the action "Create Document Types" in "Mobile WMS Setup" - this triggers the creation of Mobile Messages and Mobile Documents Types


// Tips:
// Troubleshooting is easier if you call  "MobSessionData.SetPreservedLastErrorCallStack()" preserves the LastErrorCallStack in document queue on error.

// Tip:
// Storing a value in field "MOB Posting MessageId" on the base document, allows other events to pull the Mobile Document Queue, that are currently posting the document, the
// value is also stored in  "MOB MessageId" on the posted document. 

// Tip:
// If posting fails, Reservation Entries might need to be rolled back. See 
// "MobSyncItemTracking.Run" and "MobSyncItemTracking.RevertToOriginalReservationEntriesFor.."


codeunit 62301 MobPlannedFunction
{
    TableNo = "MOB Document Queue"; // Each call from mobile becomes a "Mobile Doc. Queue" record, which holds both the Request and Reponse

    var
        MobDocQueue: Record "MOB Document Queue";
        MobWmsLanguage: Codeunit "MOB WMS Language";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseDoc: XmlDocument;

    // --------------------------------- Install/Setup ---------------------------------

    // Mobile Document Type needs to know what Codeunit will handle the three requests a planned function uses. Get Orders/Lines and Posting.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultDocumentTypes', '', true, true)]
    local procedure OnAfterCreateDefaultDocumentTypes()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateDocumentType('GetMyOrders', '', Codeunit::MobPlannedFunction);
        MobWmsSetupDocTypes.CreateDocumentType('GetMyOrderLines', '', Codeunit::MobPlannedFunction);
        MobWmsSetupDocTypes.CreateDocumentType('PostMyOrder', '', Codeunit::MobPlannedFunction);
    end;

    // ---------------------------- Mobile Document Types ----------------------------
    // Handle the 3 document types a planned function needs: Orders, Lines and Posting

    trigger OnRun();
    var
        XmlRequestDoc: XmlDocument;
    begin
        MobDocQueue := Rec;
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);// Load the request from the queue

        case Rec."Document Type" of
            'GetMyOrders': // Respond with Orders
                GetOrders(XmlRequestDoc);
            'GetMyOrderLines': // Respond with Order lines
                GetOrderLines(XmlRequestDoc);
            'PostMyOrder': // Handle Posting
                PostOrder(XmlRequestDoc);
        end;
        MobToolbox.UpdateResult(Rec, XmlResponseDoc); // Store the result in the queue and update the status
    end;

    // The header fields on the header of the Orders-page
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        _HeaderFields.InitConfigurationKey('MyHeader');
        _HeaderFields.Create_ListField_FilterLocationAsLocation(10); // Predefined filter like "Location" is often used
        _HeaderFields.Create_TextField(20, 'MyField', 'My field'); // ToDo: You can add additional filter fields using "Create_.."
        _HeaderFields.Set_optional(true);

        // ToDo: Important. These field values are handled in "GetSalesOrders" function
    end;

    // ----------------------------------- Orders -----------------------------------

    local procedure GetOrders(var _XmlRequestDoc: XmlDocument)
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlResponseData: XmlNode;
    begin
        // Initialize response
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XMLResponseData);
        // Add orders to buffer
        GetSalesOrders(_XmlRequestDoc, MobDocQueue, TempBaseOrderElement);
        // Use buffer to create <Orders> response
        MobXmlMgt.AddNsBaseDataModelBaseOrderElements(XMLResponseData, TempBaseOrderElement);
    end;

    // Find Orders
    local procedure GetSalesOrders(var _XmlRequestDoc: XmlDocument; var _MobDocQueue: Record "MOB Document Queue"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    var
        TempOrders: Record "Sales Header" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        ScannedValue: Text;
    begin
        // Save filter data into Temporary table
        MobRequestMgt.SaveHeaderFilters(_XmlRequestDoc, TempHeaderFilter);

        // Sales Order filter
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);

        // ToDo: Handle each field in "MyHeader"
        if TempHeaderFilter.FindSet() then
            repeat
                case TempHeaderFilter."Name" of
                    'Location':
                        if TempHeaderFilter."Value" = 'All' then
                            SalesHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(_MobDocQueue."Mobile User ID")) // All locations for this user
                        else
                            SalesHeader.SetRange("Location Code", TempHeaderFilter."Value");
                    'MyField': // Todo: You must handle your header filter fields
                        ;
                    'ScannedValue': // Note: ScannedValue is not a header field. This value comes from the user scanning directly on the Orders page
                        ScannedValue := TempHeaderFilter."Value";  // Used in search for Document No. or Item/Variant later
                end;
            until TempHeaderFilter.Next() = 0;

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForSalesDoc(SalesHeader, SalesLine, ScannedValue);

        // Respect filters find valid orders. Insert them to temporary record
        CopyValidOrdersToTempRecord(SalesHeader, SalesLine, TempHeaderFilter, TempOrders);

        // Respond with resulting orders
        CreateBaseOrderElements(TempOrders, _BaseOrderElement);
    end;

    // Find valid orders
    // Orders must have lines with valid items
    local procedure CopyValidOrdersToTempRecord(var _SalesHeaderView: Record "Sales Header"; var _SalesLineView: Record "Sales Line"; var _HeaderFilters: Record "MOB NS Request Element"; var _TempOrders: Record "Sales Header")
    var
        IncludeInOrderList: Boolean;
    begin
        if _SalesHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;

                // Include only valid lines
                _SalesLineView.SetRange("Document Type", _SalesHeaderView."Document Type");
                _SalesLineView.SetRange("Document No.", _SalesHeaderView."No.");
                // ToDo: Add filters here
                if _SalesLineView.FindSet() then
                    repeat
                        IncludeInOrderList := _SalesLineView.IsInventoriableItem();
                    until (_SalesLineView.Next() = 0) or IncludeInOrderList;

                if IncludeInOrderList then begin
                    _TempOrders.Copy(_SalesHeaderView);
                    _TempOrders.Insert();
                end;

            until _SalesHeaderView.Next() = 0;
    end;

    // Create a "Base Order Elements" from the temporary order record
    local procedure CreateBaseOrderElements(var _SalesHeader: Record "Sales Header"; var _BaseOrderElement: Record "MOB NS BaseDataModel Element")
    begin
        // Create a base order element for each order
        if _SalesHeader.FindSet() then
            repeat
                _BaseOrderElement.Create();
                SetFromOrderHeader(_SalesHeader, _BaseOrderElement); // Populate the base order element with the properties we want the user to see on Order List
                _BaseOrderElement.Save();
            until _SalesHeader.Next() = 0;
    end;

    // Populate the base order element with the properties we want the user to see on Order List
    local procedure SetFromOrderHeader(_SalesHeader: Record "Sales Header"; var _BaseOrder: Record "MOB Ns BaseDataModel Element")
    begin
        _BaseOrder.Init();
        _BaseOrder.Set_BackendID(_SalesHeader."No."); // Important: "BackendID" is the unique key, mobile use to handle orders

        _BaseOrder.Set_DisplayLine1(_SalesHeader."No."); // DisplayLines 1..4 are shown on each order
        _BaseOrder.Set_DisplayLine2(format(_SalesHeader."Document Type"));
        _BaseOrder.Set_DisplayLine3(_SalesHeader."Sell-to Customer Name");
        _BaseOrder.Set_DisplayLine4(_SalesHeader."Sell-to Country/Region Code");

        _BaseOrder.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER')); // HeaderLines 1..2 are shown on the top of the Order Lines-page
        _BaseOrder.Set_HeaderLabel2(MobWmsLanguage.GetMessage('TYPE'));
        _BaseOrder.Set_HeaderValue1(_SalesHeader."No.");
        _BaseOrder.Set_HeaderValue2(format(_SalesHeader."Document Type"));

        _BaseOrder.Set_ReferenceID(_SalesHeader);
        _BaseOrder.Set_Status(); // Set Locked/Has Attachment symbol (1=Unlocked, 2=Locked, 3=Attachment)
    end;


    // ----------------------------------- Lines -----------------------------------

    local procedure GetOrderLines(var _XmlRequestDoc: XmlDocument)
    var
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        TempRequestValues: Record "MOB NS Request Element" temporary;
        XmlResponseData: XmlNode;
    begin
        // Load XML request into "Request Element" for easy processing
        MobRequestMgt.SaveAdhocRequestValues(_XmlRequestDoc, TempRequestValues);
        // Initialize response 
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);
        // Add lines buffer
        GetSalesOrderLines(TempRequestValues.Get_BackendID(true), TempBaseOrderLineElement);
        // Use buffer to create <Lines> response
        MobXmlMgt.AddNsBaseDataModelBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement);
    end;

    /// Find Order Lines
    local procedure GetSalesOrderLines(_BackendID: Text; var _TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", _BackendID);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                _TempBaseOrderLineElement.Create();
                SetFromOrderLine(SalesLine, _TempBaseOrderLineElement, _BackendID); // Set the elements that we want the user to see on Order Lines
                _TempBaseOrderLineElement.Save();
            until SalesLine.Next() = 0;
    end;

    // Add the elements that we want the user to see on Order Lines
    local procedure SetFromOrderLine(_SalesLine: Record "Sales Line"; var _BaseOrderLine: Record "MOB Ns BaseDataModel Element"; _BackendID: Text)
    var
        // MobTrackingSetup: Record "MOB Tracking Setup";
        // TempSteps: Record "MOB Steps Element" temporary; // Use this to add line steps
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
    begin
        _BaseOrderLine.Init();
        _BaseOrderLine.Set_OrderBackendID(_BackendID); // "BackendID" is the unique key, mobile use to handle orders. It must also be on line elements
        _BaseOrderLine.Set_LineNumber(_SalesLine."Line No."); // "LineNumber" must also be unique in line elements

        // What to display
        _BaseOrderLine.Set_Description(_SalesLine.Description);
        if _SalesLine."Bin Code" <> '' then
            _BaseOrderLine.Set_DisplayLine1(_SalesLine."Bin Code")
        else
            _BaseOrderLine.Set_DisplayLine1(_SalesLine.Description);
        _BaseOrderLine.Set_DisplayLine2(_SalesLine."No.");
        _BaseOrderLine.Set_DisplayLine3(_SalesLine.Description);
        // _BaseOrderLine.Set_DisplayLine4(MobTrackingSetup.FormatTracking());
        // _BaseOrderLine.Set_DisplayLine5(_SalesLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + _SalesLine."Variant Code", '');

        // Warehouse and Bins
        _BaseOrderLine.Set_Location(_SalesLine."Location Code");
        _BaseOrderLine.Set_FromBin(_SalesLine."Bin Code");
        _BaseOrderLine.Set_ToBin('');
        _BaseOrderLine.Set_AllowBinChange(false);

        // Quantity to register
        _BaseOrderLine.Set_Quantity(_SalesLine."Qty. to Ship (Base)");
        _BaseOrderLine.Set_UnitOfMeasure(_SalesLine."Unit of Measure Code");
        _BaseOrderLine.Set_RegisteredQuantity('0');
        // _BaseOrderLine.Set_UnderDeliveryValidation("MOB ValidationWarningType"::None);
        // _BaseOrderLine.Set_OverDeliveryValidation("MOB ValidationWarningType"::None);

        // Item
        _BaseOrderLine.Set_ItemNumber(_SalesLine."No.");
        _BaseOrderLine.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(_SalesLine."No.", _SalesLine."Variant Code", _SalesLine."Unit of Measure Code")); // Item References becomes Barcodes for scanning
        _BaseOrderLine.Set_RegisterQuantityByScan(false);  // if true then mobile device can use values in <BarcodeQuantity>

        // Item Tracking
        // MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_SalesLine."No.", ExpDateRequired);
        // MobTrackingSetup.CopyTrackingFromPhysInvtRecordLine(_SalesLine);
        // _BaseOrderLine.SetTracking(MobTrackingSetup);
        // _BaseOrderLine.SetRegisterTracking(MobTrackingSetup);
        // _BaseOrderLine.Set_RegisterExpirationDate(false);

        // Misc. system
        _BaseOrderLine.Set_ReferenceID(_SalesLine);
        _BaseOrderLine.Set_Status('0');
        _BaseOrderLine.Set_Attachment();
        _BaseOrderLine.Set_ItemImageID();

        // Use this to add line steps. For example:
        // TempSteps.Create_TextStep(200,'MyTextStep');
        // if not TempSteps.IsEmpty() then
        //  _BaseOrderLine.Set_Workflow(TempSteps, "MOB TweakType"::Append);
    end;


    // ----------------------------------- Posting -----------------------------------

    local procedure PostOrder(var _XmlRequestDoc: XmlDocument);
    var
        Location: Record Location;
        MobSetup: Record "MOB Setup";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        TempSteps: Record "MOB Steps Element" temporary;
        TempOrderValues: Record "MOB Common Element" temporary;
        MobTrackingSetup: Record "MOB Tracking Setup";
        TempReservationEntry: Record "Reservation Entry" temporary;
        MobWmsRegistration: Record "MOB WMS Registration";
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        SalesPost: Codeunit "Sales-Post";
        MobSessionData: Codeunit "MOB SessionData";
        UoMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        MobItemTrackingManagement: Codeunit "MOB Item Tracking Management";
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        OrderID: Code[20];
        ResultMessage: Text;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        LotExists: Boolean;
        SerialExists: Boolean;
        EntriesExist: Boolean;
        PostingRunSuccessful: Boolean;
        RegisterExpirationDate: Boolean;
        ExistingExpirationDate: Date;
    begin
        LockTimeout(false);// Disable the locktimeout to prevent timeout messages on the mobile device 
        SalesHeader.Locktable();
        SalesLine.Locktable();
        MobWmsRegistration.Locktable();
        MobDocQueue.Consistent(false); // Turn on commit protection to prevent unintentional committing data

        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        // Save the registrations from the XML in the Mobile WMS Registration table
        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), _XmlRequestDoc, MobWmsRegistration.Type::"My Function");

        // Update the sales header
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderID);
        SalesHeader."MOB Posting MessageId" := MobDocQueue.MessageIDAsGuid();

        // ToDo: If you want to collect additional steps, once per posting.  Use this to return steps on posting. 
        // if not TempSteps.IsEmpty() then begin
        //     MobSessionData.SetRegistrationTypeTracking('OnAddStepsTo');
        //     MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
        //     MobToolbox.CreateResponseWithSteps(XmlResponseDoc, TempSteps);
        //     MobDocQueue.Consistent(true);
        //     exit;
        // end;

        SalesHeader.Modify();

        // Filter the sales lines
        SalesLine.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document No.", OrderID);

        if SalesLine.FindSet() then
            repeat
                // Try to find the registrations
                MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid());
                MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"My Function");
                MobWmsRegistration.SetRange("Order No.", OrderID);
                MobWmsRegistration.SetRange("Line No.", SalesLine."Line No.");
                MobWmsRegistration.SetRange(Handled, false);

                // Line splitting is not supported for sales orders
                // Before the registrations are processed we need to determine if the user has received to multiple bins
                MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration);

                // If the registration is found -> set the quantity to handle
                // Else set the quantity to handle to zero (to avoid posting lines with the qty to handle set to something)
                if MobWmsRegistration.FindSet() then begin

                    if not Location.Get(SalesLine."Location Code") then
                        Clear(Location);

                    // Transfer-To Bin Code must be validated when Location."Bin Mandatory"
                    if Location."Bin Mandatory" and SalesLine.IsInventoriableItem() then
                        SalesLine.Validate("Bin Code", MobWmsRegistration.ToBin);

                    SalesLine.TestField("Qty. per Unit of Measure");

                    // Scenarios:
                    // The line requires item tracking (maybe more than one registration, create reservation entries for each registration)
                    // No item tracking (there must only be one registration with the quantity)
                    // Determine if item tracking is needed
                    MobTrackingSetup.DetermineItemTrackingRequiredBySalesLine(SalesLine, RegisterExpirationDate);
                    // MobTrackingSetup.Tracking: Copy later in MobWmsRegistration loop

                    // Initialize the quantity counter
                    TotalQty := 0;
                    TotalQtyBase := 0;

                    repeat
                        // MobTrackingSetup.TrackingRequired: Determined before (outside inner MobWmsRegistration loop)
                        MobTrackingSetup.CopyTrackingFromRegistration(MobWmsRegistration);

                        // Calculate registered quantity and base quantity
                        if MobSetup."Use Base Unit of Measure" then begin
                            Qty := 0; // To ensure best possible rounding the TotalQty will be calculated after the loop
                            QtyBase := MobWmsRegistration.Quantity;
                        end else begin
                            MobWmsRegistration.TestField(UnitOfMeasure, SalesLine."Unit of Measure Code");
                            Qty := MobWmsRegistration.Quantity;
                            QtyBase := UoMMgt.CalcBaseQty(MobWmsRegistration.Quantity, SalesLine."Qty. per Unit of Measure");
                        end;

                        TotalQty := TotalQty + Qty;
                        TotalQtyBase := TotalQtyBase + QtyBase;

                        if SalesLine.IsInventoriableItem() then begin
                            if MobTrackingSetup.TrackingRequired() and RegisterExpirationDate then
                                MobWmsRegistration.TestField("Expiration Date");

                            // Make sure that the serial number does not exist already
                            // SerialNumber contains only the serial number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Serial No. Required" then begin
                                SerialExists := ItemTrackingMgt.FindInInventory(SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration.SerialNumber);
                                if SerialExists then
                                    Error(MobWmsLanguage.GetMessage('RECV_KNOWN_SERIAL'), MobWmsRegistration.SerialNumber);
                            end;

                            // Handle lot numbers and expiration dates
                            // Make sure LotNumber has same Expiration Date if already on inventory
                            // LotNumber contains only the lot number (unlike earlier version where expiration date was included in same field)
                            if MobTrackingSetup."Lot No. Required" then begin
                                LotExists := MobWmsToolbox.InventoryExistsByLotNo(SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration.LotNumber);
                                if LotExists then begin
                                    ExistingExpirationDate := MobItemTrackingManagement.ExistingExpirationDate(SalesLine."No.",
                                                                                                        SalesLine."Variant Code",
                                                                                                        MobTrackingSetup,
                                                                                                        false,
                                                                                                        EntriesExist);

                                    if MobWmsRegistration."Expiration Date" <> ExistingExpirationDate then
                                        Error(MobWmsLanguage.GetMessage('WRONG_EXPIRATION_DATE'), MobWmsToolbox.Date2TextAsDisplayFormat(ExistingExpirationDate), MobWmsRegistration.LotNumber);
                                end;
                            end;
                        end;

                        // Synchronize Item Tracking to Source Document
                        MobSyncItemTracking.CreateTempReservEntryForSalesLine(SalesLine, MobWmsRegistration, TempReservationEntry, QtyBase);
                        MobWmsToolbox.SaveRegistrationDataFromSource(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration);

                        // Remember that the registration was handled
                        MobWmsRegistration.Validate(Handled, true);
                        MobWmsRegistration.Modify();

                    until MobWmsRegistration.Next() = 0;

                    // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
                    if MobSetup."Use Base Unit of Measure" then
                        TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, SalesLine."Qty. per Unit of Measure");

                    SalesLine.Validate("Qty. to Ship", TotalQty);
                end else  // endif MobWmsRegistration.FindSet()
                    SalesLine.Validate("Qty. to Ship", 0);

                SalesLine.Modify();

            until SalesLine.Next() = 0;

        // Find the sales header
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("No.", SalesLine."Document No.");
        if SalesHeader.FindFirst() then begin
            SalesHeader.Ship := true;
            SalesHeader.Invoice := false;
            SalesHeader.Modify();
        end;

        // Turn off the commit protection. From this point on we explicitely clean up committed data if an error occurs
        MobDocQueue.Consistent(true);

        Commit();

        // Post
        // if not MobSyncItemTracking.Run(TempReservationEntry) then begin
        //     ResultMessage := GetLastErrorText();
        //     MobSessionData.SetPreservedLastErrorCallStack();
        //     MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
        //     Commit();
        //     UpdateIncomingSalesReturnOrder(SalesHeader);
        //     MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
        //     Commit();   // Separate commit to prevent error in UpdateIncomingPurchase from preventing Reservation Entries being rollback
        //     Error(ResultMessage);
        // end;

        // SuppressCommit do not fully work for SalesReturnOrder, but is still included to at least improve the 
        // change of good rollbacks if customer creates eventsubscriptions to standard posting events.
        SalesPost.SetSuppressCommit(true);

        // ToDo: Trigger posting
        PostingRunSuccessful := SalesPost.Run(SalesHeader);


        if PostingRunSuccessful then
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingRunSuccessful)
        else begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog); // If the posting fails for some reason we need to clean up the created reservation entries and MobWmsRegistrations
            Commit();
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();
            Error(ResultMessage);
        end;

        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;
}
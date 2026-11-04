codeunit 62304 MyPlannedOrders_PostOrder
{
    var
        TempReservationEntry: Record "Reservation Entry" temporary;
        TempReservationEntryLog: Record "Reservation Entry" temporary;
        MobSyncItemTracking: Codeunit "MOB Sync. Item Tracking";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        DocQueue: Record "MOB Document Queue";

    internal procedure HandleRequest(var MobDocQueue: Record "MOB Document Queue"; var XmlResponseDoc: XmlDocument)
    var
        TempOrderValues: Record "MOB Common Element" temporary;
        DocType: Option SalesOrder; // We only handle sales orders in this example, but this could be extended to handle different document types as well
        DocNo: Code[20];
        ResultMessage: Text;
    begin
        PrepareForProcessing(MobDocQueue);

        ReadRequest(TempOrderValues, DocType, DocNo);

        PostOrder(DocType, DocNo, ResultMessage);

        BuildResponseDoc(ResultMessage, XmlResponseDoc);
    end;

    local procedure PrepareForProcessing(var MobDocQueue: Record "MOB Document Queue")
    begin
        LockTimeout(false);// Disable the locktimeout to prevent timeout messages on the mobile device

        DocQueue := MobDocQueue; // Store the document queue record in a global variable to allow other functions to access it without needing to pass it as a parameter
        DocQueue.Consistent(false); // Turn on commit protection to prevent unintentional committing data, we will turn it off right before posting the document
    end;

    /// <summary>
    /// Reads request XML from document queue and saves values into TempOrderValues.
    /// Determines the document type and document number based on the values stored in TempOrderValues from the GetOrders request.
    /// Also saves the registrations from the XML in the Mobile WMS Registration table.
    /// </summary>
    local procedure ReadRequest(var TempOrderValues: Record "MOB Common Element" temporary; var DocType: Option SalesOrder; var DocNo: Code[20])
    var
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsRegistration: Record "MOB WMS Registration";
        XmlRequestDoc: XmlDocument;
        BackendID: Code[30];
        RecId: RecordId;
    begin
        DocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.InitCommonFromXmlOrderNode(XmlRequestDoc, TempOrderValues);

        // In GetOrders we set the BackendID to SalesHeader."No." and ReferenceID to the RecordID of the Sales Header.
        // Here we can use those values to determine the document type and document number.
        // This is very useful if your implementation needs to handle multiple document types that are stored in different tables, e.g. sales orders, transfer orders, production orders, etc.    
        Evaluate(RecId, TempOrderValues.GetValue('referenceID', true));
        if RecId.TableNo = Database::"Sales Header" then begin
            DocType := DocType::SalesOrder;
            Evaluate(DocNo, TempOrderValues.GetValue('backendID', true));
        end;

        // Save the registrations from the XML in the Mobile WMS Registration table
        MobWmsRegistration.ReadIsolation := IsolationLevel::UpdLock; // Acquire an update lock on rows read by the next database read (replaces the legacy LockTable())
        MobWmsToolbox.SaveRegistrationData(DocQueue.MessageIDAsGuid(), XmlRequestDoc, MobWmsRegistration.Type::"My Planned Order");
    end;

    local procedure PostOrder(DocType: Option SalesOrder; DocNo: Code[20]; var ResultMessage: Text)
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        XmlRequestDoc: XmlDocument;
    begin
        case DocType of
            DocType::SalesOrder:
                PostSalesOrder(DocNo, ResultMessage);
        end;
    end;

    local procedure PostSalesOrder(DocNo: Code[20]; var ResultMessage: Text)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.ReadIsolation := IsolationLevel::UpdLock; // Acquire an update lock on rows read by the next database read (replaces the legacy LockTable())
        SalesLine.ReadIsolation := IsolationLevel::UpdLock;

        PrepareSalesHeader(DocNo, SalesHeader);
        PrepareSalesLines(SalesHeader);

        DocQueue.Consistent(true); // Turn off the commit protection. From this point on we explicitely clean up committed data if an error occurs
        Commit();

        RunSyncItemTracking(SalesHeader, SalesLine, ResultMessage);
        RunSalesPosting(SalesHeader, SalesLine, ResultMessage);
    end;

    local procedure PrepareSalesHeader(OrderID: Code[20]; var SalesHeader: Record "Sales Header")
    var
        SalesRelease: Codeunit "Release Sales Document";
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, OrderID);

        if SalesHeader."Posting Date" <> WorkDate() then begin
            SalesRelease.Reopen(SalesHeader);
            SalesRelease.SetSkipCheckReleaseRestrictions();
            SalesHeader.SetHideValidationDialog(true);
            SalesHeader.Validate("Posting Date", WorkDate());
            SalesRelease.Run(SalesHeader);
        end;

        SalesHeader."MOB Posting MessageId" := DocQueue.MessageIDAsGuid();
        SalesHeader.Modify();
    end;

    local procedure PrepareSalesLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");

        MobSyncItemTracking.SaveOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog); // Save original reservation entries before we create new ones, this allows us to revert back to the original state if posting fails

        if SalesLine.FindSet() then
            repeat
                UpdateLineAndRegistrations(SalesLine);
            until SalesLine.Next() = 0;
    end;

    local procedure UpdateLineAndRegistrations(SalesLine: Record "Sales Line"): Decimal
    var
        MobSetup: Record "MOB Setup";
        MobWmsRegistration: Record "MOB WMS Registration";
        Location: Record Location;
        MobTrackingSetup: Record "MOB Tracking Setup";

        UoMMgt: Codeunit "Unit of Measure Management";
        RegisterExpirationDate: Boolean;
        Qty: Decimal;
        QtyBase: Decimal;
        TotalQty: Decimal;
        TotalQtyBase: Decimal;
        BinCode: Code[20];
    begin
        MobWmsRegistration.SetRange("Posting MessageId", DocQueue.MessageIDAsGuid());
        MobWmsRegistration.SetRange(Type, MobWmsRegistration.Type::"My Planned Order");
        MobWmsRegistration.SetRange("Order No.", SalesLine."Document No.");
        MobWmsRegistration.SetRange("Line No.", SalesLine."Line No.");
        MobWmsRegistration.SetRange(Handled, false);

        if MobWmsRegistration.IsEmpty() then begin // Nothing to post for this line
            SalesLine.Validate("Qty. to Ship", 0);
            SalesLine.Modify();
            exit;
        end;

        MobSetup.Get();
        SalesLine.TestField("Qty. per Unit of Measure");
        MobWmsToolbox.ValidateSingleRegistrationBin(MobWmsRegistration); // Multiple bins on the same line is not allowed

        TotalQty := 0;
        TotalQtyBase := 0;
        if MobWmsRegistration.FindSet() then
            repeat
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
                BinCode := MobWmsRegistration.ToBin; // Is validated to be the same for all registrations on the same line

                // Create reservation entries based on the registration (if the registration includes item tracking data)
                MobSyncItemTracking.CreateTempReservEntryForSalesLine(SalesLine, MobWmsRegistration, TempReservationEntry, QtyBase);

                // Update the registration
                MobWmsToolbox.SaveRegistrationDataFromSource(SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code", MobWmsRegistration);
                MobWmsRegistration.Validate(Handled, true);
                MobWmsRegistration.Modify(true);

            until MobWmsRegistration.Next() = 0;

        if Location.Get(SalesLine."Location Code") and Location."Bin Mandatory" and SalesLine.IsInventoriableItem() then
            SalesLine.Validate("Bin Code", BinCode);

        if MobSetup."Use Base Unit of Measure" then // To ensure best possible rounding the TotalQty is calculated and rounded only once when MobSetup."Use Base Unit of Measure" is enabled (i.e. 3 * 1/3 = 1)
            TotalQty := UoMMgt.CalcQtyFromBase(TotalQtyBase, SalesLine."Qty. per Unit of Measure");

        SalesLine.Validate("Qty. to Ship", TotalQty);
        SalesLine.Modify();
    end;

    local procedure RunSyncItemTracking(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var ResultMessage: Text)
    begin
        if not MobSyncItemTracking.Run(TempReservationEntry) then
            RollBackAndStop(SalesHeader, SalesLine, ResultMessage);
    end;

    local procedure RunSalesPosting(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var ResultMessage: Text)
    var
        SalesPost: Codeunit "Sales-Post";
        PostingSuccess: Boolean;
    begin
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Ship := true;
        SalesHeader.Invoice := false;
        SalesHeader.Modify(false);

        SalesPost.SetSuppressCommit(true);
        PostingSuccess := SalesPost.Run(SalesHeader);

        if not PostingSuccess then
            PostingSuccess := SalesShipmentHeaderExists(SalesHeader); // If Posted Sales Shipment exists posting has succeeded but something else failed. ie. code in OnAfterPost events

        if PostingSuccess then
            ResultMessage := MobToolbox.GetPostSuccessMessage(PostingSuccess)
        else
            RollBackAndStop(SalesHeader, SalesLine, ResultMessage);
    end;

    /// <summary>
    /// Rolls back the changes and stops the process.
    /// This includes reverting reservation entries to their original state, clearing the MessageId on the sales header to allow reprocessing, and deleting the Mobile WMS Registrations that were created for this posting.
    /// The ResultMessage parameter should be set to the error message that should be returned to the mobile device.
    /// </summary>
    /// <param name="SalesHeader">The sales header record for which the rollback is being performed.</param>
    /// <param name="SalesLine">The set of sales line records for which the rollback is being performed.</param>
    /// <param name="ResultMessage">The error message that should be returned to the mobile device.</param>
    local procedure RollBackAndStop(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; var ResultMessage: Text)
    var
        MobSessionData: Codeunit "MOB SessionData";
    begin
        ResultMessage := GetLastErrorText();
        MobSessionData.SetPreservedLastErrorCallStack();
        MobSyncItemTracking.RevertToOriginalReservationEntriesForSalesLines(SalesLine, TempReservationEntryLog);
        Commit();
        ClearMessageIdOnSalesHeader(SalesHeader);
        MobWmsToolbox.DeleteRegistrationData(DocQueue.MessageIDAsGuid());
        Commit();
        Error(ResultMessage);
    end;

    local procedure ClearMessageIdOnSalesHeader(var SalesHeader: Record "Sales Header")
    begin
        if not SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.") then
            exit;

        Clear(SalesHeader."MOB Posting MessageId");
        SalesHeader.Modify(false);
    end;

    local procedure BuildResponseDoc(ResultMessage: Text; var XmlResponseDoc: XmlDocument)
    begin
        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;

    local procedure SalesShipmentHeaderExists(SalesHeader: Record "Sales Header"): Boolean
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.SetRange("MOB MessageId", SalesHeader."MOB Posting MessageId");
        exit(not SalesShipmentHeader.IsEmpty());
    end;
}
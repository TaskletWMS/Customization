codeunit 62303 MyPlannedOrders_GetOrderLines
{
    internal procedure HandleRequest(var MobDocQueue: Record "MOB Document Queue"; var XmlResponseDoc: XmlDocument)
    var
        TempRequestValues: Record "MOB NS Request Element" temporary;
        TempOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
    begin
        ReadRequest(MobDocQueue, TempRequestValues);

        LoadOrderLines(TempRequestValues, TempOrderLineElement);

        BuildResponseDoc(TempOrderLineElement, XmlResponseDoc);
    end;

    /// <summary>
    /// Reads request XML from document queue and saves request data into TempRequestValues.
    /// </summary>
    local procedure ReadRequest(var MobDocQueue: Record "MOB Document Queue"; var TempRequestValues: Record "MOB NS Request Element" temporary)
    var
        XmlRequestDoc: XmlDocument;
        MobRequestMgt: Codeunit "MOB NS Request Management";
    begin
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.SaveAdhocRequestValues(XmlRequestDoc, TempRequestValues);
    end;

    /// <summary>
    /// Loads order lines into the temporary base order line element buffer based on request values.
    /// </summary>
    local procedure LoadOrderLines(var TempRequestValues: Record "MOB NS Request Element" temporary; var TempOrderLineElement: Record "MOB NS BaseDataModel Element" temporary)
    begin
        // If the order list page includes orders from multiple sources, the BackendID or the ReferenceID can be used to determine which source to pull the lines from.
        // In this example, we only have one source (Sales Orders), so we can directly call LoadSalesOrderLines, but in a real implementation there would likely be some logic to determine which source lines to load based on the request values.
        LoadSalesOrderLines(TempRequestValues.Get_BackendID(true), TempOrderLineElement);
    end;

    /// <summary>
    /// Builds the XML response document and appends the buffered base order line elements.
    /// </summary>
    local procedure BuildResponseDoc(var TempOrderLineElement: Record "MOB NS BaseDataModel Element" temporary; var XmlResponseDoc: XmlDocument)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseData: XmlNode;
    begin
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData);
        MobXmlMgt.AddNsBaseDataModelBaseOrderLineElements(XmlResponseData, TempOrderLineElement);
    end;

    /// <summary>
    /// Finds order lines for a given backend ID (Document No.) and builds the order line element buffer.
    /// </summary>
    local procedure LoadSalesOrderLines(BackendID: Text; var TempOrderLineElement: Record "MOB NS BaseDataModel Element" temporary)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", BackendID);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                CreateOrderLineElement(BackendID, SalesLine, TempOrderLineElement);
            until SalesLine.Next() = 0;
    end;

    /// <summary>
    /// Creates an OrderLineElement for the given sales line and adds it to the TempOrderLineElement buffer.
    /// Populates the fields based on what information you want to show on the mobile device, and what information you need for processing on the device.
    /// </summary>
    local procedure CreateOrderLineElement(BackendID: Text; SalesLine: Record "Sales Line"; var TempOrderLineElement: Record "MOB Ns BaseDataModel Element" temporary)
    var
        // MobTrackingSetup: Record "MOB Tracking Setup";
        // TempSteps: Record "MOB Steps Element" temporary; // Use this to add line steps
        MobItemReferenceMgt: Codeunit "MOB Item Reference Mgt.";
    begin
        TempOrderLineElement.Create();

        // Set key information for the order line element
        TempOrderLineElement.Set_OrderBackendID(BackendID); // "OrderBackendID" is the BackendID from the header element, and is used to link the line to the header in the mobile app
        TempOrderLineElement.Set_LineNumber(SalesLine."Line No."); // "LineNumber" must also be unique in line elements
        TempOrderLineElement.Set_ReferenceID(SalesLine);
        TempOrderLineElement.Set_Status('0'); //  0 = Blank symbol - that is the default status for lines
        TempOrderLineElement.Set_Attachment(); // Updates the status if the line has an attached image 
        TempOrderLineElement.Set_ItemImageID();

        // Set display information for the order line element
        TempOrderLineElement.Set_Description(SalesLine.Description);
        if SalesLine."Bin Code" <> '' then
            TempOrderLineElement.Set_DisplayLine1(SalesLine."Bin Code")
        else
            TempOrderLineElement.Set_DisplayLine1(SalesLine.Description);
        TempOrderLineElement.Set_DisplayLine2(SalesLine."No.");
        TempOrderLineElement.Set_DisplayLine3(SalesLine.Description);
        // TempOrderLineElement.Set_DisplayLine4(MobTrackingSetup.FormatTracking());
        // TempOrderLineElement.Set_DisplayLine5(SalesLine."Variant Code" <> '', MobWmsLanguage.GetMessage('VARIANT_LABEL') + ': ' + SalesLine."Variant Code", '');

        // Warehouse and Bins
        TempOrderLineElement.Set_Location(SalesLine."Location Code");
        TempOrderLineElement.Set_FromBin(SalesLine."Bin Code");
        TempOrderLineElement.Set_ToBin('');
        TempOrderLineElement.Set_AllowBinChange(false);

        // Quantity to register
        TempOrderLineElement.Set_Quantity(SalesLine."Qty. to Ship (Base)");
        TempOrderLineElement.Set_UnitOfMeasure(SalesLine."Unit of Measure Code");
        TempOrderLineElement.Set_RegisteredQuantity('0');
        // TempOrderLineElement.Set_UnderDeliveryValidation("MOB ValidationWarningType"::None);
        // TempOrderLineElement.Set_OverDeliveryValidation("MOB ValidationWarningType"::None);

        // Item
        TempOrderLineElement.Set_ItemNumber(SalesLine."No.");
        TempOrderLineElement.Set_ItemBarcode(MobItemReferenceMgt.GetBarcodeList(SalesLine."No.", SalesLine."Variant Code", SalesLine."Unit of Measure Code")); // Item References becomes Barcodes for scanning
        TempOrderLineElement.Set_RegisterQuantityByScan(false);  // if true then mobile device can use values in <BarcodeQuantity>

        // Item Tracking
        // MobTrackingSetup.DetermineSpecificTrackingRequiredFromItemNo(_SalesLine."No.", ExpDateRequired);
        // MobTrackingSetup.CopyTrackingFromPhysInvtRecordLine(_SalesLine);
        // TempOrderLineElement.SetTracking(MobTrackingSetup);
        // TempOrderLineElement.SetRegisterTracking(MobTrackingSetup);
        // TempOrderLineElement.Set_RegisterExpirationDate(false);


        // Use this to add line steps. For example:
        // TempSteps.Create_TextStep(200,'MyTextStep');
        // if not TempSteps.IsEmpty() then
        //  TempOrderLineElement.Set_Workflow(TempSteps, "MOB TweakType"::Append);

        TempOrderLineElement.Save();
    end;

}
codeunit 62302 MyPlannedOrders_GetOrders
{
    /// <summary>
    /// Handles the GetOrders request by reading filters from the request, finding relevant orders and creating the response document.
    /// </summary>
    internal procedure HandleRequest(var MobDocQueue: Record "MOB Document Queue"; var XmlResponseDoc: XmlDocument)
    var
        TempOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        TempHeaderFilter: Record "MOB NS Request Element" temporary;
    begin
        ReadRequest(MobDocQueue, TempHeaderFilter);

        LoadOrders(MobDocQueue, TempHeaderFilter, TempOrderElement);

        BuildResponseDoc(TempOrderElement, XmlResponseDoc);
    end;

    /// <summary>
    /// Reads request XML from document queue and saves filter data into TempHeaderFilter.
    /// The filter fields are defined in the header configuration (see MyPlannedOrders_GetReferenceData.Codeunit).
    /// </summary>
    local procedure ReadRequest(var MobDocQueue: Record "MOB Document Queue"; var TempHeaderFilter: Record "MOB NS Request Element" temporary)
    var
        XmlRequestDoc: XmlDocument;
        MobRequestMgt: Codeunit "MOB NS Request Management";
    begin
        MobDocQueue.LoadXMLRequestDoc(XmlRequestDoc);
        MobRequestMgt.SaveHeaderFilters(XmlRequestDoc, TempHeaderFilter);
    end;

    /// <summary>
    /// Loads orders into the order element buffer based on request filters.
    /// This is the aggregation point where orders from multiple sources can be added.
    /// </summary>
    local procedure LoadOrders(var MobDocQueue: Record "MOB Document Queue"; var TempHeaderFilter: Record "MOB NS Request Element" temporary; var TempOrderElement: Record "MOB NS BaseDataModel Element" temporary)
    begin
        LoadSalesOrders(MobDocQueue, TempHeaderFilter, TempOrderElement);
        // Here orders from others sources could be added to the buffer as well.
    end;

    /// <summary>
    /// Builds the XML response document and appends the buffered base order elements.
    /// </summary>
    local procedure BuildResponseDoc(var TempOrderElement: Record "MOB NS BaseDataModel Element" temporary; var XmlResponseDoc: XmlDocument)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseData: XmlNode;
    begin
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XmlResponseData);
        MobXmlMgt.AddNsBaseDataModelBaseOrderElements(XmlResponseData, TempOrderElement);
    end;

    /// <summary>
    /// This code is an example that demonstrates how to find records from filters and populate the BaseOrderElement buffer.
    /// </summary>
    local procedure LoadSalesOrders(var MobDocQueue: Record "MOB Document Queue"; var TempHeaderFilter: Record "MOB NS Request Element" temporary; var TempOrderElement: Record "MOB NS BaseDataModel Element" temporary)
    var
        TempSalesHeader: Record "Sales Header" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        FilterSalesHeaderAndLine(MobDocQueue, TempHeaderFilter, SalesHeader, SalesLine);

        CopyValidOrdersToTempRecord(SalesHeader, SalesLine, TempSalesHeader);

        BuildOrderElements(TempSalesHeader, TempOrderElement);
    end;

    /// <summary>
    /// Filters sales header and line records based on mandatory criteria for the order to be included in the list, as well as filters sent from the mobile device.
    /// </summary>
    local procedure FilterSalesHeaderAndLine(var MobDocQueue: Record "MOB Document Queue"; var TempHeaderFilter: Record "MOB NS Request Element" temporary; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        MobScannedValueMgt: Codeunit "MOB ScannedValue Mgt.";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        ScannedValue: Text;
    begin
        // Apply mandatory header filters that matches your function - for example, only released sales orders that are not completely shipped should be included in the order list.
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange(Status, SalesHeader.Status::Released);
        SalesHeader.SetRange("Completely Shipped", false);

        // Apply mandatory line filters that matches your function - for example, only include lines that are not fully shipped, and are inventory items (no services, etc.)
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');

        // Apply filters from the request that is loaded into TempHeaderFilter.
        if TempHeaderFilter.FindSet() then
            repeat
                case TempHeaderFilter."Name" of
                    'Location':
                        if TempHeaderFilter."Value" = 'All' then
                            SalesHeader.SetFilter("Location Code", MobWmsToolbox.GetLocationFilter(MobDocQueue."Mobile User ID")) // All locations for this user
                        else
                            SalesHeader.SetRange("Location Code", TempHeaderFilter."Value");
                    'MyField': // Handle custom filter fields as needed.
                        ;
                    'ScannedValue': // Note: ScannedValue is not a header field. This value comes from the user scanning directly on the Order List page
                        ScannedValue := TempHeaderFilter."Value";
                end;
            until TempHeaderFilter.Next() = 0;

        // Filter: DocumentNo or Item/Variant (match for scanned document no. at location takes precedence over other filters)
        if ScannedValue <> '' then
            MobScannedValueMgt.SetFilterForSalesDoc(SalesHeader, SalesLine, ScannedValue);
    end;

    /// <summary>
    /// Copies valid orders from the sales header and line views to a temporary sales header record.
    /// Only the orders that should be included in the list are copied to the temporary record, which is then used to create the Base Order Elements.
    /// </summary>
    local procedure CopyValidOrdersToTempRecord(var SalesHeaderView: Record "Sales Header"; var SalesLineView: Record "Sales Line"; var TempSalesHeader: Record "Sales Header" temporary)
    var
        IncludeInOrderList: Boolean;
    begin
        if SalesHeaderView.FindSet() then
            repeat
                IncludeInOrderList := false;

                // For each header, check if there are lines that match the criteria for the order to be included in the list.
                SalesLineView.SetRange("Document Type", SalesHeaderView."Document Type");
                SalesLineView.SetRange("Document No.", SalesHeaderView."No.");
                // Additional line filters could be applied here as well, for example to only include lines with certain items or status, etc.
                if SalesLineView.FindSet() then
                    repeat
                        IncludeInOrderList := SalesLineView.IsInventoriableItem(); // Example: only include orders with inventoriable items. Adjust logic as needed.
                    until (SalesLineView.Next() = 0) or IncludeInOrderList;

                if IncludeInOrderList then begin
                    TempSalesHeader.Copy(SalesHeaderView);
                    TempSalesHeader.Insert();
                end;

            until SalesHeaderView.Next() = 0;
    end;

    local procedure BuildOrderElements(var TempSalesHeader: Record "Sales Header" temporary; var TempOrderElement: Record "MOB NS BaseDataModel Element" temporary)
    begin
        if TempSalesHeader.FindSet() then
            repeat
                CreateOrderElement(TempSalesHeader, TempOrderElement);
            until TempSalesHeader.Next() = 0;
    end;

    /// <summary>
    /// Creates an OrderElement for the given sales header and adds it to the TempOrderElement buffer.
    /// Populates the fields that should be displayed on the mobile device, as well as BackendID and ReferenceID that links the order header to the order lines.
    /// </summary>
    local procedure CreateOrderElement(var TempSalesHeader: Record "Sales Header" temporary; var TempOrderElement: Record "MOB NS BaseDataModel Element" temporary)
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        TempOrderElement.Create();

        // Set key information for the order element.
        TempOrderElement.Set_BackendID(TempSalesHeader."No."); // Important: "BackendID" is the unique key the mobile app uses to identify the order, and to link the header to the lines, so it must be set to a value that uniquely identifies the order.
        TempOrderElement.Set_ReferenceID(TempSalesHeader);
        TempOrderElement.Set_Status(); // Sets the mobile "Status" symbol which is determined from BackendId and ReferenceID. 

        // Set display lines for the order. DisplayLine1-4 are displayed for each order in the order list on the mobile device.
        TempOrderElement.Set_DisplayLine1(TempSalesHeader."No.");
        TempOrderElement.Set_DisplayLine2(format(TempSalesHeader."Document Type"));
        TempOrderElement.Set_DisplayLine3(TempSalesHeader."Sell-to Customer Name");
        TempOrderElement.Set_DisplayLine4(TempSalesHeader."Sell-to Country/Region Code");

        // Set header labels and values that are displayed on the order lines page when an order is selected on the mobile device.
        TempOrderElement.Set_HeaderLabel1(MobWmsLanguage.GetMessage('ORDER_NUMBER'));
        TempOrderElement.Set_HeaderLabel2(MobWmsLanguage.GetMessage('TYPE'));
        TempOrderElement.Set_HeaderValue1(TempSalesHeader."No.");
        TempOrderElement.Set_HeaderValue2(format(TempSalesHeader."Document Type"));

        TempOrderElement.Save();
    end;
}

// This example is extremely barebones. This is only to illustrate the mobile logic, but without any improvements at all.
// You should consider using the regular example and seek inspiration from our source code e.g. Codeunit "MOB WMS Receive" and "MOB WMS Pick".

// IMPORTANT: Do NOT use both examples at the same time.
// IMPORTANT: After publishing, you MUST run the action "Create Document Types" in "Mobile WMS Setup" - this triggers the creation of Mobile Messages and Mobile Documents Types

codeunit 62303 MobPlannedFunctionBarebone
{
    TableNo = "MOB Document Queue"; // Each call from mobile becomes a "Mobile Doc. Queue" record, which holds both the Request and Reponse
    EventSubscriberInstance = Manual;

    var
        MobDocQueue: Record "MOB Document Queue";
        MobRequestMgt: Codeunit "MOB NS Request Management";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseDoc: XmlDocument;


    // --------------------------------- Install/Setup ---------------------------------

    /// Mobile Document Type needs to know what Codeunit will handle the three requests a planned function uses. Get Orders/Lines and Posting.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", 'OnAfterCreateDefaultDocumentTypes', '', true, true)]
    local procedure OnAfterCreateDefaultDocumentTypes()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateDocumentType('GetMyOrders', '', Codeunit::MobPlannedFunctionBarebone);
        MobWmsSetupDocTypes.CreateDocumentType('GetMyOrderLines', '', Codeunit::MobPlannedFunctionBarebone);
        MobWmsSetupDocTypes.CreateDocumentType('PostMyOrder', '', Codeunit::MobPlannedFunctionBarebone);
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
    end;

    // ----------------------------------- Orders -----------------------------------

    local procedure GetOrders(var _XmlRequestDoc: XmlDocument)
    var
        TempBaseOrderElement: Record "MOB NS BaseDataModel Element" temporary;
        XmlResponseData: XmlNode;
    begin
        MobToolbox.InitializeResponseDoc(XmlResponseDoc, XMLResponseData);

        TempBaseOrderElement.Create();
        TempBaseOrderElement.Set_BackendID('DummyOrder A'); // Important: "BackendID" is the unique key, mobile use to handle orders
        TempBaseOrderElement.Set_DisplayLine1('Ordre A'); // DisplayLines 1..4 are shown on each order

        TempBaseOrderElement.Create();
        TempBaseOrderElement.Set_BackendID('DummyOrder B');
        TempBaseOrderElement.Set_DisplayLine1('Ordre B');

        MobXmlMgt.AddNsBaseDataModelBaseOrderElements(XMLResponseData, TempBaseOrderElement); // Use buffer to create <Orders> response
    end;

    // ----------------------------------- Lines -----------------------------------

    local procedure GetOrderLines(var _XmlRequestDoc: XmlDocument)
    var
        TempBaseOrderLineElement: Record "MOB NS BaseDataModel Element" temporary;
        TempRequestValues: Record "MOB NS Request Element" temporary;
        XmlResponseData: XmlNode;
    begin
        MobRequestMgt.SaveAdhocRequestValues(_XmlRequestDoc, TempRequestValues); // Load XML request into "Request Element" for easy processing
        MobToolbox.InitializeOrderLineDataRespDoc(XmlResponseDoc, XmlResponseData); // Initialize response 

        // Add dummy line
        TempBaseOrderLineElement.Create();
        TempBaseOrderLineElement.Set_LineNumber(10000); // "LineNumber" must also be unique in line elements
        TempBaseOrderLineElement.Set_OrderBackendID(TempRequestValues.Get_BackendID()); // "BackendID" is the unique key, mobile use to handle orders. It must also be on line elements
        TempBaseOrderLineElement.Set_DisplayLine1('Line Description');
        TempBaseOrderLineElement.Set_Quantity(1);

        TempBaseOrderLineElement.Create();
        TempBaseOrderLineElement.Set_LineNumber(20000); // "LineNumber" must also be unique in line elements
        TempBaseOrderLineElement.Set_OrderBackendID(TempRequestValues.Get_BackendID()); // "BackendID" is the unique key, mobile use to handle orders. It must also be on line elements
        TempBaseOrderLineElement.Set_DisplayLine1('Line Description');
        TempBaseOrderLineElement.Set_Quantity(1);

        MobXmlMgt.AddNsBaseDataModelBaseOrderLineElements(XmlResponseData, TempBaseOrderLineElement); // Add linens to response
    end;

    // ----------------------------------- Posting -----------------------------------

    local procedure PostOrder(var _XmlRequestDoc: XmlDocument);
    var
        TempOrderValues: Record "MOB Common Element" temporary;
        MobWmsRegistration: Record "MOB WMS Registration";
        MobSessionData: Codeunit "MOB SessionData";
        OrderID: Code[20];
        ResultMessage: Text;
        PostingRunSuccessful: Boolean;
    begin
        MobWmsRegistration.Locktable();
        MobRequestMgt.InitCommonFromXmlOrderNode(_XmlRequestDoc, TempOrderValues);

        OrderID := MobWmsToolbox.SaveRegistrationData(MobDocQueue.MessageIDAsGuid(), _XmlRequestDoc, MobWmsRegistration.Type::"My Function");

        MobWmsRegistration.SetRange("Posting MessageId", MobDocQueue.MessageIDAsGuid()); // Try to find the registrations
        MobWmsRegistration.SetRange("Order No.", OrderID);
        MobWmsRegistration.SetRange(Handled, false);
        if MobWmsRegistration.FindSet() then
            repeat
                ResultMessage += StrSubstNo('Line %1 Quantity %2 ', MobWmsRegistration."Line No.", MobWmsRegistration.Quantity);

                MobWmsRegistration.Validate(Handled, true);
                MobWmsRegistration.Modify();
            until MobWmsRegistration.Next() = 0;

        PostingRunSuccessful := true;

        if not PostingRunSuccessful then begin
            ResultMessage := GetLastErrorText();
            MobSessionData.SetPreservedLastErrorCallStack();
            MobWmsToolbox.DeleteRegistrationData(MobDocQueue.MessageIDAsGuid());
            Commit();
            Error(ResultMessage);
        end;

        MobToolbox.CreateSimpleResponse(XmlResponseDoc, ResultMessage);
    end;
}
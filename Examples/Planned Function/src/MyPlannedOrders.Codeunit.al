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


codeunit 62300 MyPlannedOrders
{
    // -----------------------------------------------------------------------------------------------------------------------
    // DOCUMENT PROCESSING 
    //
    // This codeunit handles the processing of the document types related to My Planned Orders.
    // The document types GetMyOrders, GetMyOrderLines, and PostMyOrder are created as setup data, and each document type is linked
    // to a specific function (GetOrders, GetOrderLines, PostOrder) that is triggered when the mobile device sends a request with that document type.
    //
    // When a request is received a MOB Document Queue record is created, and the XML request is stored in that record.
    // The processing function reads the XML request from the queue, processes it, and then stores the XML response
    // back in the queue before the response is sent back to the mobile device.
    // -----------------------------------------------------------------------------------------------------------------------

    TableNo = "MOB Document Queue"; // This codeunit is linked to the MOB Document Queue table, which is the entry point for processing mobile requests.

    trigger OnRun();
    var
        GetOrders: Codeunit MyPlannedOrders_GetOrders;
        GetOrderLines: Codeunit MyPlannedOrders_GetOrderLines;
        PostOrder: Codeunit MyPlannedOrders_PostOrder;
        MobToolbox: Codeunit "MOB Toolbox";
        XmlResponseDoc: XmlDocument;
    begin
        case Rec."Document Type" of
            'GetMyOrders':
                GetOrders.HandleRequest(Rec, XmlResponseDoc);
            'GetMyOrderLines':
                GetOrderLines.HandleRequest(Rec, XmlResponseDoc);
            'PostMyOrder':
                PostOrder.HandleRequest(Rec, XmlResponseDoc);
        end;
        MobToolbox.UpdateResult(Rec, XmlResponseDoc); // Store the result in the queue and update the status
    end;
}
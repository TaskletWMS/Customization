//=========================================== EXAMPLE ===========================================
//
// EX-0008: Add an ImageCapture Header Step to Pick
//
// Demonstrates how to add an ImageCapture Header Step to the Pick posting flow.
//
// This same pattern applies to other planned flows — for example, Receive, Put-away, Count, and Move.
// The event names will be different, but the pattern is the same.
//
// Full documentation: https://github.com/TaskletWMS/Customization/blob/main/Examples/Adding%20and%20modifying%20steps/docs/Add%20ImageCapture%20step%20to%20Pick.md

codeunit 75000 Pick_ImageCaptureStep
{
    //============================================ STEP 1 ===========================================
    // Create a header step that interrupts the posting.
    //
    // Adding a step halts posting and returns the step to the mobile client. Once the user completes it, the client resends
    // the request carrying the collected value — that is why we guard with HasValue below, to avoid re-adding the step in a loop.
    //
    // Here we add a new ImageCapture step to the Pick flow, which prompts the user to take a picture of the item before posting.
    //
    // This example uses the generic OnAddStepsToAnyHeader event, which fires for all Pick document types (Warehouse Pick, Inventory Pick, Sales Order, Transfer Order, Purchase Return).
    // To target only one document type, use the typed variant instead, e.g. OnAddStepsToWarehouseActivityHeader.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", OnPostPickOrder_OnAddStepsToAnyHeader, '', false, false)]
    local procedure AddImageCaptureStep_OnPostPickOrder_OnAddStepsToAnyHeader(var _OrderValues: Record "MOB Common Element"; var _StepsElement: Record "MOB Steps Element")
    var
        // Display texts for the mobile app are added as labels to support translation.
        // As this is a Per-request configuration, the labels will be translated run-time to the mobile users language, if a translation is available.
        HelpLabel: Label 'Take a picture of the item';
    begin
        if _OrderValues.HasValue('ImageCapture') then //Element already exists (step already added) — exit to avoid re-adding it
            exit;

        _StepsElement.Create_ImageCaptureStep(50, 'ImageCapture');
        _StepsElement.Set_helpLabel(HelpLabel);
    end;

    //============================================ STEP 2 ===========================================
    // Handle the collected value from the step.
    //
    // Here we register that one or more images were collected in the ImageCapture step (a "MOB Media Queue" entry is created for each image).
    // The image data arrives to BC in separate PostMedia requests, which are processed automatically when the image has been registered in the Media Queue.
    //
    // This example uses the generic OnBeforePostAnyOrder and checks RecordRef.Number to identify the document type before extracting the typed record with SetTable.
    // To target only one document type, use the typed variant instead, e.g. OnPostPickOrder_OnBeforePostWarehouseActivityOrder.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", OnPostPickOrder_OnBeforePostAnyOrder, '', false, false)]
    local procedure HandleCollectedValue_OnPostPickOrder_OnBeforePostAnyOrder(var _OrderValues: Record "MOB Common Element"; var _RecRef: RecordRef)
    var
        MobMedia: Codeunit "MOB WMS Media";
        WhseActivityHeader: Record "Warehouse Activity Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        PurchaseHeader: Record "Purchase Header";
        ImageCaptureValue: Text;
    begin
        ImageCaptureValue := _OrderValues.GetValue('ImageCapture');
        if ImageCaptureValue = '' then
            exit;

        case _RecRef.Number of
            Database::"Warehouse Activity Header":
                begin
                    _RecRef.SetTable(WhseActivityHeader);
                    MobMedia.RegisterImageCaptureInMediaQueue(WhseActivityHeader, ImageCaptureValue);
                end;
            Database::"Sales Header":
                begin
                    _RecRef.SetTable(SalesHeader);
                    MobMedia.RegisterImageCaptureInMediaQueue(SalesHeader, ImageCaptureValue);
                end;
            Database::"Transfer Header":
                begin
                    _RecRef.SetTable(TransferHeader);
                    MobMedia.RegisterImageCaptureInMediaQueue(TransferHeader, ImageCaptureValue);
                end;
            Database::"Purchase Header":
                begin
                    _RecRef.SetTable(PurchaseHeader);
                    MobMedia.RegisterImageCaptureInMediaQueue(PurchaseHeader, ImageCaptureValue);
                end;
        end;

        // The reference record passed above is stored as the source (Record ID) on the Media Queue entry, and the target (Target Record ID) is derived from that
        // source during this registration. The first parameter accepts a Record, RecordId, or RecordRef (or a reference ID as text).
        // The image data arrives later in separate PostMedia requests and is attached to the already-derived target — the supported source-to-target
        // mappings are listed here: https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78949021/Attach+Image
        // Some record types have no attachment support in BC (for example Transfer Header).
        // To provide your own attachment logic for those, subscribe to:
        // - OnRegisterImageCapture_OnBeforeMediaQueueInsert https://taskletfactory.atlassian.net/wiki/x/BwB8hQ
        // - OnPostMedia_OnBeforeHandleMedia https://taskletfactory.atlassian.net/wiki/x/EgCAhQ
    end;
}
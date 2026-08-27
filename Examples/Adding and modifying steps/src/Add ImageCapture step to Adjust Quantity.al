//=========================================== EXAMPLE ===========================================
//
// EX-0009: Add an ImageCapture Step to Adjust Quantity
//
// This example demonstrates how to add an ImageCapture registration step to the Adjust Quantity unplanned function.
// The user is prompted to take a picture during the registration, before it is posted.
// The collected image is saved in the Mob WMS Media Queue.
//
// Requirements: Android App 1.8.1.1 or later
//
// The same pattern applies to other unplanned functions — change the registration type filter
// to target a different function. Use MobWmsToolbox constants to avoid hardcoded strings.
//
// Full documentation: https://github.com/TaskletWMS/Customization/blob/main/Examples/Adding%20and%20modifying%20steps/docs/Add%20ImageCapture%20step%20to%20Adjust%20Quantity.md

codeunit 75001 AdjustQty_ImageCaptureStep
{
    //============================================ STEP 1 ===========================================
    // Add the ImageCapture step to the registration configuration.
    //
    // OnGetRegistrationConfiguration_OnAddSteps fires when the device sends a GetRegistrationConfiguration request — right after the user
    // accepts the header and before the registration is posted. The step is returned to the mobile client and shown as part of the registration.
    //
    // This event fires for all unplanned functions, so we filter by registration type to target Adjust Quantity only.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', false, false)]
    local procedure AddImageCaptureStep_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _Steps: Record "MOB Steps Element")
    var
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        // Display texts for the mobile app are added as labels to support translation.
        // As this is a Per-request configuration, the labels will be translated run-time to the mobile users language, if a translation is available.
        HelpLabel: Label 'Take a picture of the item';
    begin
        if _RegistrationType <> MobWmsToolbox."CONST::AdjustQuantity"() then
            exit;

        _Steps.Create_ImageCaptureStep(10000, 'ImageCapture');
        _Steps.Set_helpLabel(HelpLabel);
    end;

    //============================================ STEP 2 ===========================================
    // Handle the collected value after posting.
    //
    // OnPostAdhocRegistration_OnAfterPost fires after BC has processed the registration.
    // The image reference is read from the request values and registered in the Mob WMS Media Queue.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistration_OnAfterPost, '', false, false)]
    local procedure HandleCollectedValue_OnPostAdhocRegistration_OnAfterPost(_MessageId: Guid; _RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element")
    var
        MobMedia: Codeunit "MOB WMS Media";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        ImageCaptureValue: Text;
    begin
        if _RegistrationType <> MobWmsToolbox."CONST::AdjustQuantity"() then
            exit;

        ImageCaptureValue := _RequestValues.GetValue('ImageCapture');
        if ImageCaptureValue = '' then
            exit;

        // Register the captured images in the Mob WMS Media Queue.
        MobMedia.RegisterImageCaptureInMediaQueue('', ImageCaptureValue);

        // We pass a blank reference above, so no source record is recorded and no target is derived — the images stay only in the Media Queue.
        // The first parameter accepts a Record, RecordId, or RecordRef (or a reference ID as text) to use as the source (Record ID);
        // the target (Target Record ID) is then derived from that source during this registration.
        // The image data arrives later in separate PostMedia requests and is attached to the derived target.
        //
        // For example, you could pass the Item Ledger Entry created by this posting. Standard code has no attachment support for an Item Ledger Entry,
        // so you would implement the storage logic yourself (for instance, your own image attachment for the entry) by subscribing to
        // OnRegisterImageCapture_OnBeforeMediaQueueInsert and OnPostMedia_OnBeforeHandleMedia.
        //
        // For the supported source-to-target mappings and links to these events, see the full documentation linked at the top of this file.
    end;
}

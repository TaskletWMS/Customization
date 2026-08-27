//=========================================== EXAMPLE ===========================================
//
// EX-0007: Add Line Steps to Warehouse Receipts to Collect Item Weights
//
// This example demonstrates how to add decimal line steps to the Receive flow to collect
// Net Weight and Gross Weight per line registration, and use the captured values during posting.
//
// Requirements: Extension version MOB5.23 or later
//
// This same pattern applies to other planned flows — for example, Pick, Put-away, Count, and Move.
// The event names will be different, but the pattern is the same.
//
// Full documentation: https://github.com/TaskletWMS/Customization/blob/main/Examples/Adding%20and%20modifying%20steps/docs/Add%20line%20steps%20to%20capture%20weight%20in%20Receive.md

codeunit 75010 Receive_LineStepsItemWeights
{
    //============================================ STEP 1 ===========================================
    // Define the step configuration in Reference Data.
    //
    // Here we create a RegistrationCollectorConfiguration with key "CustomWeightSteps" with two decimal steps for Net Weight and Gross Weight.
    // Reference Data steps are defined once and can be reused across multiple flows and document types.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", OnGetReferenceData_OnAddRegistrationCollectorConfigurations, '', false, false)]
    local procedure DefineSteps_OnGetReferenceData_OnAddRegistrationCollectorConfigurations(var _Steps: Record "MOB Steps Element")
    var
        // Display texts for the mobile app are added as labels to support translation.
        // As this is a Login-time request configuration, the labels will be translated run-time to the mobile users language, if a translation is available.
        NetWeightLbl: label 'Net Weight (Grams)';
        NetWeightHelpLbl: label 'Net Weight in grams per base unit of measure';
        GrossWeightLbl: label 'Gross Weight (Grams)';
        GrossWeightHelpLbl: label 'Gross Weight in grams per base unit of measure';
    begin
        _Steps.InitConfigurationKey('CustomWeightSteps');

        _Steps.Create_DecimalStep(10000, 'NetWeightGrams');
        _Steps.Set_header(NetWeightLbl);
        _Steps.Set_label(NetWeightLbl + ':');
        _Steps.Set_helpLabel(NetWeightHelpLbl);
        _Steps.Set_minValue(0);
        _Steps.Set_maxValue(100000);
        _Steps.Set_performCalculation(true); // Allows the user to perform calculations directly in the step

        _Steps.Create_DecimalStep(20000, 'GrossWeightGrams');
        _Steps.Set_header(GrossWeightLbl);
        _Steps.Set_label(GrossWeightLbl + ':');
        _Steps.Set_helpLabel(GrossWeightHelpLbl);
        _Steps.Set_minValue(0);
        _Steps.Set_maxValue(100000);
        _Steps.Set_performCalculation(true); // Allows the user to perform calculations directly in the step
    end;

    //============================================ STEP 2 ===========================================
    // Include the steps on Warehouse Receipt lines.
    //
    // Here we attach the step configuration key to Warehouse Receipt lines only.
    // OnGetReceiveOrderLines_OnAddStepsToAnyLine fires for all Receive document types, so we guard with RecordRef.Number to skip other types.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", OnGetReceiveOrderLines_OnAddStepsToAnyLine, '', false, false)]
    local procedure AddStepsToLine_OnGetReceiveOrderLines_OnAddStepsToAnyLine(_RecRef: RecordRef; var _BaseOrderLineElement: Record "MOB Ns BaseDataModel Element")
    begin
        if _RecRef.Number <> Database::"Warehouse Receipt Line" then
            exit;

        _BaseOrderLineElement.Create_StepsByReferenceDataKey('CustomWeightSteps');
    end;

    //============================================ STEP 3 ===========================================
    // Handle the collected values, storing them on the Warehouse Receipt Line before posting.
    //
    // Here we read the collected step values and save them to custom fields on the Warehouse Receipt Line, making them available for the posting step below.
    // The custom fields are defined in the Supporting Objects (table extensions) at the bottom of this file.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", OnPostReceiveOrder_OnHandleRegistrationForWarehouseReceiptLine, '', false, false)]
    local procedure HandleCollectedValues_OnPostReceiveOrder_OnHandleRegistrationForWarehouseReceiptLine(var _Registration: Record "MOB WMS Registration"; var _WhseReceiptLine: Record "Warehouse Receipt Line")
    begin
        _WhseReceiptLine."EXMPL Captured Net Weight" := _Registration.GetValueAsDecimal('NetWeightGrams', true);
        _WhseReceiptLine."EXMPL Captured Gross Weight" := _Registration.GetValueAsDecimal('GrossWeightGrams', true);
    end;

    //============================================ STEP 4 ===========================================
    // Use the captured values during posting — fires once per receipt line.
    //
    // Here we explicitly copy the custom fields to the Posted Whse. Receipt Line before it is inserted,
    // and update the Item Card as a demonstration of what can be done with the captured values.
    // Note: Overwriting Item Card weights on every receipt is not a realistic use case — replace this with whatever makes sense for your scenario.

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Receipt", OnBeforeCreatePostedRcptLine, '', false, false)]
    local procedure UseCapturedValues_OnBeforeCreatePostedRcptLine(var WhseRcptLine: Record "Warehouse Receipt Line"; var PostedWhseRcptHeader: Record "Posted Whse. Receipt Header"; var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var TempHandlingSpecification: Record "Tracking Specification"; var IsHandled: Boolean)
    var
        Item: Record Item;
        ConversionFactor: Decimal;
    begin
        if (WhseRcptLine."EXMPL Captured Net Weight" = 0) and (WhseRcptLine."EXMPL Captured Gross Weight" = 0) then
            exit;

        // Explicitly copy to the posted line (alternative to relying on TransferFields)
        PostedWhseRcptLine."EXMPL Captured Net Weight" := WhseRcptLine."EXMPL Captured Net Weight";
        PostedWhseRcptLine."EXMPL Captured Gross Weight" := WhseRcptLine."EXMPL Captured Gross Weight";

        // Demo: update Item Card weights — replace with your actual business logic
        Item.Get(WhseRcptLine."Item No.");
        ConversionFactor := 1000; // grams to kg
        if WhseRcptLine."EXMPL Captured Net Weight" > 0 then
            Item."Net Weight" := WhseRcptLine."EXMPL Captured Net Weight" / ConversionFactor;
        if WhseRcptLine."EXMPL Captured Gross Weight" > 0 then
            Item."Gross Weight" := WhseRcptLine."EXMPL Captured Gross Weight" / ConversionFactor;
        Item.Modify();
    end;
}

//======================================= SUPPORTING OBJECTS =====================================
// Table extensions to hold captured values between registration and posting.
// The Posted Whse. Receipt Line extension receives the values explicitly in Step 4.
tableextension 75010 "EXMPL Warehouse Receipt Line" extends "Warehouse Receipt Line"
{
    fields
    {
        field(75010; "EXMPL Captured Net Weight"; Decimal)
        {
            Caption = 'Captured Net Weight';
            DataClassification = CustomerContent;
        }
        field(75011; "EXMPL Captured Gross Weight"; Decimal)
        {
            Caption = 'Captured Gross Weight';
            DataClassification = CustomerContent;
        }
    }
}

tableextension 75011 "EXMPL Posted Whse. Rcpt. Line" extends "Posted Whse. Receipt Line"
{
    fields
    {
        field(75010; "EXMPL Captured Net Weight"; Decimal)
        {
            Caption = 'Captured Net Weight';
            DataClassification = CustomerContent;
        }
        field(75011; "EXMPL Captured Gross Weight"; Decimal)
        {
            Caption = 'Captured Gross Weight';
            DataClassification = CustomerContent;
        }
    }
}

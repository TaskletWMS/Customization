codeunit 70035 MyLookup3_PostReg
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called when the user submits after completing the steps. Implement your business logic here.
    // Both header field values and step values are available via _RequestValues.
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        SimulatedStorage: Codeunit "MyLookup3_SimulatedStorage";
        SelectedReferenceID: Text;
        SelectedRowNo: Integer;
        MyDateStep: Date;
        MyTextStep: Text;
        MyDecimalStep: Decimal;
        SuccessMsg: Label 'Registration completed for MyLookupSelectAndRegister: %1, %2, %3'; // Message for the mobile user. Provide translations as needed.
    begin
        if _IsHandled then
            exit;
        if _RegistrationType <> 'MyLookupSelectAndRegister' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        SelectedReferenceID := _RequestValues.Get_ReferenceID(); // The ReferenceID set on the selected lookup row
        ReadSampleStepValues(_RequestValues, MyDateStep, MyTextStep, MyDecimalStep);

        // << Perform your business logic here — use SelectedReferenceID and step values to complete the registration >>

        // SIMULATION (template only): accumulate the registered quantity for the selected row so it shows on the lookup list
        // after the refresh. In a real implementation, replace this with an update to your own table/ledger.
        if Evaluate(SelectedRowNo, SelectedReferenceID) then
            SimulatedStorage.AddRegisteredQty(SelectedRowNo, MyDecimalStep);

        _SuccessMessage := StrSubstNo(SuccessMsg, MyDateStep, MyTextStep, MyDecimalStep); // Create a success message to show to the mobile user.
        _RegistrationTypeTracking := SelectedReferenceID; // Optional — shown in the Mobile Document Queue for filtering/info
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads three step values from the completed registration: MyDateStep, MyTextStep, and MyDecimalStep.
    /// Replace this with reads for the steps you defined in CreateSampleSteps.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <param name="MyDateStep">Receives the value of the MyDateStep step.</param>
    /// <param name="MyTextStep">Receives the value of the MyTextStep step.</param>
    /// <param name="MyDecimalStep">Receives the value of the MyDecimalStep step.</param>
    internal procedure ReadSampleStepValues(var RequestValues: Record "MOB NS Request Element"; var MyDateStep: Date; var MyTextStep: Text; var MyDecimalStep: Decimal)
    begin
        MyDateStep := RequestValues.GetValueAsDate('MyDateStep');
        MyTextStep := RequestValues.GetValue('MyTextStep');
        MyDecimalStep := RequestValues.GetValueAsDecimal('MyDecimalStep');
    end;
}
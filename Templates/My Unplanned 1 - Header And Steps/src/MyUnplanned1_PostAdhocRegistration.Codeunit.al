codeunit 60012 "MyUnplanned1_PostReg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called when the user accepts all steps. Implement your business logic here.
    // Both header field values and step values are available via _RequestValues.
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MyDateStep: Date;
        MyTextStep: Text;
        MyDecimalStep: Decimal;
        SuccessMsg: Label 'Registration completed for MyUnplannedHeaderAndSteps: %1, %2, %3'; // Message for the mobile user. Provide translations as needed.
    begin
        if _IsHandled then
            exit;
        if _RegistrationType <> 'MyUnplannedHeaderAndSteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        ReadSampleStepValues(_RequestValues, MyDateStep, MyTextStep, MyDecimalStep);

        // << Perform your business logic here >>

        _SuccessMessage := StrSubstNo(SuccessMsg, MyDateStep, MyTextStep, MyDecimalStep); // Create a success message to show to the mobile user.
        _RegistrationTypeTracking := StrSubstNo('%1 %2 %3', MyDateStep, MyTextStep, MyDecimalStep); // Set a tracking value for the Mobile Document Queue, that can be used for filtering or just for information (optional)
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads three step values from the completed registration: MyDateStep, MyTextStep, and MyDecimalStep.
    /// Replace this sample code with reads for the steps you defined in your step configuration.
    /// </summary>
    /// <param name="_RequestValues">The request values record passed by the event subscriber.</param>
    /// <param name="MyDateStep">Receives the value of the MyDateStep step.</param>
    /// <param name="MyTextStep">Receives the value of the MyTextStep step.</param>
    /// <param name="MyDecimalStep">Receives the value of the MyDecimalStep step.</param>
    local procedure ReadSampleStepValues(var _RequestValues: Record "MOB NS Request Element"; var MyDateStep: Date; var MyTextStep: Text; var MyDecimalStep: Decimal)
    begin
        MyDateStep := _RequestValues.GetValueAsDate('MyDateStep');
        MyTextStep := _RequestValues.GetValue('MyTextStep');
        MyDecimalStep := _RequestValues.GetValueAsDecimal('MyDecimalStep');
    end;
}

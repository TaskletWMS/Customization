codeunit 60021 "MyUnplanned2_PostReg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called immediately when the user accepts the header (no steps are collected). Implement your business logic here.
    // Only header field values are available via _RequestValues.
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MyDate: Date;
        MyText: Text;
        MyDecimal: Decimal;
        SuccessMsg: Label 'Registration completed for MyUnplannedOnlyHeader: %1, %2, %3'; // Message for the mobile user. Provide translations as needed.
    begin
        if _IsHandled then
            exit;
        if _RegistrationType <> 'MyUnplannedOnlyHeader' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        ReadSampleHeaderValues(_RequestValues, MyDate, MyText, MyDecimal);

        // << Perform your business logic here >>

        _SuccessMessage := StrSubstNo(SuccessMsg, MyDate, MyText, MyDecimal); // Create a success message to show to the mobile user.
        _RegistrationTypeTracking := StrSubstNo('%1 %2 %3', MyDate, MyText, MyDecimal); // Set a tracking value for the Mobile Document Queue, that can be used for filtering or just for information (optional)
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads three header field values from the accepted header: MyDate, MyText, and MyDecimal.
    /// Replace this sample code with reads for the header fields you defined in your header configuration.
    /// </summary>
    /// <param name="HeaderFieldValues">The header field values record passed by the event subscriber.</param>
    /// <param name="MyDate">Receives the value of the MyDate header field.</param>
    /// <param name="MyText">Receives the value of the MyText header field.</param>
    /// <param name="MyDecimal">Receives the value of the MyDecimal header field.</param>
    local procedure ReadSampleHeaderValues(var HeaderFieldValues: Record "MOB NS Request Element"; var MyDate: Date; var MyText: Text; var MyDecimal: Decimal)
    begin
        MyDate := HeaderFieldValues.GetValueAsDate('MyDate');
        MyText := HeaderFieldValues.GetValue('MyText');
        MyDecimal := HeaderFieldValues.GetValueAsDecimal('MyDecimal');
    end;
}

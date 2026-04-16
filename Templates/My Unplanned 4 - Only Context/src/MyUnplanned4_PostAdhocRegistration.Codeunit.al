codeunit 60041 "MyUnplanned4_PostReg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // Called immediately when the header auto-accepts (no steps are collected). Implement your business logic here.
    // No header or step values are collected from the user — all input comes from context values passed from the calling page.
    //
    // Context values contain the data of the currently selected row on the parent page (e.g. document header, document line, lookup result).
    // Context values are read with GetContextValue() or GetValueOrContextValue().
    // This does not have to post to a ledger — it can update any record, trigger any process, or simply log.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', false, false)]
    local procedure HandleRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        DisplayLine1: Text;
        Location: Text;
        SuccessMsg: Label 'Registration completed for MyUnplannedOnlyContext: %1, %2'; // Message for the mobile user. Provide translations as needed.
    begin
        if _RegistrationType <> 'MyUnplannedOnlyContext' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;
        if _IsHandled then
            exit;

        ReadSampleContextValues(_RequestValues, DisplayLine1, Location);

        // << Perform your business logic here >>

        _SuccessMessage := StrSubstNo(SuccessMsg, DisplayLine1, Location); // Create a success message to show to the mobile user.
        _RegistrationTypeTracking := StrSubstNo('%1 %2', DisplayLine1, Location); // Set a tracking value for the Mobile Document Queue, that can be used for filtering or just for information (optional)
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads context values from the calling page (here Receive).
    /// The available fields depend on which page the action is placed on.
    /// Replace this sample code with reads for the context fields available on your target page.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <param name="DisplayLine1">Receives the value of the DisplayLine1 context field.</param>
    /// <param name="Location">Receives the value of the Location context field.</param>
    local procedure ReadSampleContextValues(var RequestValues: Record "MOB NS Request Element"; var DisplayLine1: Text; var Location: Text)
    begin
        DisplayLine1 := RequestValues.GetContextValue('DisplayLine1');
        Location := RequestValues.GetContextValue('Location');
    end;
}

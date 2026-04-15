codeunit 60003 "UnableToPick_PostReg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE REGISTRATION
    //
    // When the user accepts all steps, the mobile device sends a PostAdhocRegistration request with the collected values to the backend.
    // Collected step values are available via _RequestValues.GetValueAs*() methods,
    // and context values from the calling page are available via _RequestValues.GetContextValue() or _RequestValues.GetValueOrContextValue().
    // Subscribe to this event to read the values collected from the mobile device and perform the required business logic.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnPostAdhocRegistrationOnCustomRegistrationType, '', true, true)]
    local procedure HandleUnableToPickRegistration_OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _CurrentRegistrations: Record "MOB WMS Registration"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _RegistrationType <> 'UnableToPick' then // IMPORTANT: _RegistrationType must match the type attribute on <unplannedItemRegistrationConfiguration> in your Tweak.xml
            exit;
        if _IsHandled then
            exit;

        // << Perform your own business logic here >>
        // For example: create a journal line, update a planning record, send a notification, etc.

        // To illustrate that all values are available, this example shows them in the success message
        _SuccessMessage := StrSubstNo(
            'Unable to pick %1 for document %2 line %3',
            _RequestValues.GetValueAsDecimal('UnableToPickQuantity'),  // The quantity collected from the step created in Step 3
            _RequestValues.GetValueOrContextValue('OrderBackendId'),   // The order number from the Pick Line context
            _RequestValues.GetValueOrContextValue('LineNumber'));        // The line number from the Pick Line context

        // Set tracking info shown in the Mobile Document Queue (optional)
        _RegistrationTypeTracking := StrSubstNo('Unable to pick: %1', _RequestValues.GetValueAsDecimal('UnableToPickQuantity'));

        _IsHandled := true;
    end;
}
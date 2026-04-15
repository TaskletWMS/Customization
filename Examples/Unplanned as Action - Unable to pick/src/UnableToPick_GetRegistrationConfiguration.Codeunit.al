codeunit 60002 "UnableToPick_RegCfg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header auto-accepts, the device requests which steps to present to the user.
    // Subscribe to the OnGetRegistrationConfiguration_OnAddSteps event to define the steps to be shown to the user, such as input fields, dropdowns, etc.
    // Requires useRegistrationCollector="true" in the Tweak.xml (already set).
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', true, true)]
    local procedure AddUnableToPickSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        UnableToPickQuantity: Decimal;
    begin
        if _RegistrationType <> 'UnableToPick' then // IMPORTANT: _RegistrationType must match the type attribute on <unplannedItemRegistrationConfiguration> in your Tweak.xml
            exit;

        // Calculate the suggested quantity
        UnableToPickQuantity :=
            _HeaderFieldValues.GetContextValueAsDecimal('Quantity') -
            _HeaderFieldValues.GetContextValueAsDecimal('RegisteredQuantity');

        // Create a decimal step so the user can confirm / adjust the quantity
        _Steps.Create_DecimalStep(10, 'UnableToPickQuantity', false);
        _Steps.Set_header('Unable to pick');
        _Steps.Set_label('Quantity:');
        _Steps.Set_helpLabel('Please input the quantity you were unable to pick');
        _Steps.Set_defaultValue(UnableToPickQuantity);
    end;
}
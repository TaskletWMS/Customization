codeunit 60031 "MyUnplanned3_RegCfg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header auto-accepts, the device requests which steps to present to the user.
    // Add your steps here using _Steps.Create_*Field() methods. Replace the sample call with the fields your registration requires.
    // Context values from the calling page are available via _HeaderFieldValues.GetContextValue() — use them to drive step logic or set default values.
    // Requires useRegistrationCollector="true" in the Tweak.xml (already set).
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', false, false)]
    local procedure AddSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        DisplayLine1: Text;
        Location: Text;
    begin
        if _RegistrationType <> 'MyUnplannedOnlySteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        ReadSampleContextValues(_HeaderFieldValues, DisplayLine1, Location); // Sample of reading context values from the calling page, to use in step logic or default values. Replace with reads for the context fields relevant to your target page.

        CreateSampleSteps(_Steps, 0D, DisplayLine1, 0);
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

    /// <summary>
    /// This sample creates three steps to collect from the user: a Date step, a Text step, and a Decimal step.
    /// It passes default values from the parameters.
    /// Replace this sample code with your own step definitions.
    /// </summary>
    /// <param name="Steps">The steps element record passed by the event subscriber.</param>
    /// <param name="MyDate">Default value for MyDateStep, or 0D for no default.</param>
    /// <param name="MyText">Default value for MyTextStep, or '' for no default.</param>
    /// <param name="MyDecimal">Default value for MyDecimalStep, or 0 for no default.</param>
    local procedure CreateSampleSteps(var Steps: Record "MOB Steps Element"; MyDate: Date; MyText: Text; MyDecimal: Decimal)
    var
        DateStepLbl: Label 'Select date';
        TextStepLbl: Label 'Enter text';
        DecimalStepLbl: Label 'Enter decimal';
    begin
        Steps.Create_DateStep(10, 'MyDateStep', DateStepLbl);
        if MyDate <> 0D then
            Steps.Set_defaultValue(MyDate);

        Steps.Create_TextStep(20, 'MyTextStep', TextStepLbl);
        if MyText <> '' then
            Steps.Set_defaultValue(MyText);

        Steps.Create_DecimalStep(30, 'MyDecimalStep', DecimalStepLbl);
        if MyDecimal <> 0 then
            Steps.Set_defaultValue(MyDecimal);
    end;
}

codeunit 60011 "MyUnplanned1_RegCfg"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // DEFINE STEPS
    //
    // When the header is accepted, the device requests which steps to present to the user.
    // Add your steps here using _Steps.Create_*Field() methods. Replace the sample call with the fields your registration requires.
    // Header field values are available via _HeaderFieldValues.GetValue() — use them to drive step logic or set default values.
    // Requires useRegistrationCollector="true" in the Tweak.xml (already set).
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", OnGetRegistrationConfiguration_OnAddSteps, '', false, false)]
    local procedure AddSteps_OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        MyDate: Date;
        MyText: Text;
        MyDecimal: Decimal;
    begin
        if _RegistrationType <> 'MyUnplannedHeaderAndSteps' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        ReadSampleHeaderValues(_HeaderFieldValues, MyDate, MyText, MyDecimal);

        CreateSampleSteps(_Steps, MyDate, MyText, MyDecimal);
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

    /// <summary>
    /// This sample creates three steps to collect from the user: a Date step, a Text step, and a Decimal step.
    /// It passes default values from the parameters (possibly read from the header fields).
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

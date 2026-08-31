codeunit 70032 MyLookup3_Lookup
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE LOOKUP
    //
    // This event is called when the device requests the lookup list after the header is accepted.
    // Read header values from _RequestValues, query your data, and loop to create one response element per row.
    // Also add the steps to collect from the user after row selection.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", OnLookupOnCustomLookupType, '', false, false)]
    local procedure HandleLookup_OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        TempSteps: Record "MOB Steps Element" temporary;
        MyHeaderField: Text;
    begin
        if _LookupType <> 'MyLookupSelectAndRegister' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        MyHeaderField := ReadSampleHeaderValue(_RequestValues);
        CreateSampleSteps(TempSteps, MyHeaderField);
        AddSampleLookupRows(_LookupResponseElement, MyHeaderField, TempSteps);
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads the header field value from the accepted header.
    /// The field name must match the name defined in CreateSampleHeaderFields.
    /// Replace this with reads for the header fields you defined.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <returns>The value entered by the user in the header field.</returns>
    local procedure ReadSampleHeaderValue(var RequestValues: Record "MOB NS Request Element"): Text
    begin
        exit(RequestValues.GetValue('MyHeaderField'));
    end;

    /// <summary>
    /// This sample creates five hardcoded lookup rows to demonstrate the response structure.
    /// Each row shows the accumulated registered quantity read from the simulated data store (see the SIMULATED DATA STORE section).
    /// Replace this with your own data query and loop — filter your table and call Create() per record.
    /// </summary>
    /// <param name="LookupResponseElement">The lookup response element record passed by the event subscriber.</param>
    /// <param name="HeaderFieldValue">The header field value entered by the user in the header.</param>
    /// <param name="TempSteps">The steps to attach to each lookup row via SetRegistrationCollector.</param>
    local procedure AddSampleLookupRows(var LookupResponseElement: Record "MOB NS WhseInquery Element"; HeaderFieldValue: Text; var TempSteps: Record "MOB Steps Element" temporary)
    var
        SimulatedStorage: Codeunit "MyLookup3_SimulatedStorage";
        i: Integer;
        Quantity: Decimal;
        RowLbl: Label 'Row %1', Comment = '%1 = row number';
        DescLbl: Label 'This is some information for row number %1', Comment = '%1 = row number';
    begin
        for i := 1 to 5 do begin
            // Move the steps creation to here if you want the steps to be conditional on the row selected by the user. The steps can be different for each row.
            LookupResponseElement.Create();
            LookupResponseElement.Set_ReferenceID(Format(i));
            LookupResponseElement.Set_DisplayLine1(StrSubstNo(RowLbl, i));
            LookupResponseElement.Set_DisplayLine2(StrSubstNo(DescLbl, i));

            Quantity := SimulatedStorage.GetRegisteredQty(i);
            LookupResponseElement.Set_Quantity(Quantity);

            // Add the configured steps to the row.
            LookupResponseElement.SetRegistrationCollector(TempSteps);
        end;

        // Replace the loop above with your own data query. Example pattern — iterate a filtered table and create a row per record:
        //
        //   var
        //       MyRecord: Record "My Table";
        //   begin
        //       MyRecord.SetFilter("My Field", '@*%1*', HeaderFieldValue);
        //       if MyRecord.FindSet() then
        //           repeat
        //               // Move the steps creation to here if you want the steps to be conditional on the row selected by the user. The steps can be different for each row.
        //               LookupResponseElement.Create();
        //               LookupResponseElement.Set_ReferenceID(MyRecord.RecordId());
        //               LookupResponseElement.Set_DisplayLine1(MyRecord."My Field");
        //               LookupResponseElement.Set_DisplayLine2(MyRecord."My Description");
        //               LookupResponseElement.Set_Quantity(MyRecord."My Quantity");
        //               // Add the configured steps to the row.
        //               LookupResponseElement.SetRegistrationCollector(TempSteps);
        //           until MyRecord.Next() = 0;
        //   end;
    end;

    /// <summary>
    /// This sample always creates a Text step and a Decimal step, and additionally creates a Date step only when the header field value is '1'.
    /// This demonstrates a fixed set of steps plus a single header-dependent step.
    /// The steps you create can differ depending on the header input entered by the user, or on the specific lookup row that was selected.
    /// Replace this sample code with your own step definitions.
    /// </summary>
    /// <param name="TempSteps">The steps element record passed by the event subscriber.</param>
    /// <param name="MyHeaderField">The header field value entered by the user in the header, used to decide which conditional step to create.</param>
    local procedure CreateSampleSteps(var TempSteps: Record "MOB Steps Element" temporary; MyHeaderField: Text)
    var
        DateStepLbl: Label 'Select date';
        TextStepLbl: Label 'Enter text';
        DecimalStepLbl: Label 'Enter decimal';
    begin
        // These steps are always created, regardless of the header input.
        TempSteps.Create_TextStep(10, 'MyTextStep', TextStepLbl);
        TempSteps.Create_DecimalStep(20, 'MyDecimalStep', DecimalStepLbl);

        // Only this step is conditional on the header field value.
        if MyHeaderField = '1' then
            TempSteps.Create_DateStep(30, 'MyDateStep', DateStepLbl);
    end;
}
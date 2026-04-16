codeunit 70012 "MyLookup1_Lookup"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE LOOKUP
    //
    // This event is called when the device requests the lookup list after the header is accepted.
    // Read header values from _RequestValues, query your data, and loop to create one response element per row.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", OnLookupOnCustomLookupType, '', false, false)]
    local procedure HandleLookup_OnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        MySearchField: Text;
    begin
        if _LookupType <> 'MyLookupFromInput' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        MySearchField := ReadSampleHeaderValue(_RequestValues);
        AddSampleLookupRows(_LookupResponseElement, MySearchField);
        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads the search field value from the accepted header.
    /// The field name must match the name defined in CreateSampleHeaderFields.
    /// Replace this with reads for the header fields you defined.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <returns>The value entered by the user in the search field.</returns>
    internal procedure ReadSampleHeaderValue(var RequestValues: Record "MOB NS Request Element"): Text
    begin
        exit(RequestValues.GetValue('MySearchField'));
    end;

    /// <summary>
    /// This sample creates five hardcoded lookup rows to demonstrate the response structure.
    /// Replace this with your own data query and loop — filter your table and call Create() per record.
    /// </summary>
    /// <param name="LookupResponseElement">The lookup response element record passed by the event subscriber.</param>
    /// <param name="SearchValue">The search value entered by the user in the header.</param>
    internal procedure AddSampleLookupRows(var LookupResponseElement: Record "MOB NS WhseInquery Element"; SearchValue: Text)
    var
        i: Integer;
        RowLbl: Label 'Row %1', Comment = '%1 = row number';
        DescLbl: Label 'This is some information for row number %1', Comment = '%1 = row number';
    begin
        for i := 1 to 5 do begin
            LookupResponseElement.Create();
            LookupResponseElement.Set_DisplayLine1(StrSubstNo(RowLbl, i));
            LookupResponseElement.Set_DisplayLine2(StrSubstNo(DescLbl, i));
        end;

        // Replace the loop above with your own data query. Example pattern — iterate a filtered table and create a row per record:
        //
        //   var
        //       MyRecord: Record "My Table";
        //   begin
        //       MyRecord.SetFilter("My Field", '@*%1*', SearchValue);
        //       if MyRecord.FindSet() then
        //           repeat
        //               LookupResponseElement.Create();
        //               LookupResponseElement.Set_DisplayLine1(MyRecord."My Field");
        //               LookupResponseElement.Set_DisplayLine2(MyRecord."My Description");
        //           until MyRecord.Next() = 0;
        //   end;
    end;
}

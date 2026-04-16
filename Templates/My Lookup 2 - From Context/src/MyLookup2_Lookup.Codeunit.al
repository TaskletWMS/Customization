codeunit 70021 "MyLookup2_Lookup"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE LOOKUP
    //
    // Called when the device requests the lookup data after the header is accepted.
    // Read context values from _RequestValues (e.g. OrderBackendID transferred via the header, plus any other context values
    // from the source page), resolve the relevant record, and populate _LookupResponseElement with what to display.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", OnLookupOnCustomLookupType, '', false, false)]
    local procedure HandleLookup_OnLookupOnCustomLookupType(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _IsHandled: Boolean)
    var
        LineNumber: Text;
    begin
        if _LookupType <> 'MyLookupFromContext' then // IMPORTANT: must match the type attribute in the Tweak.xml
            exit;

        ReadSampleContextValues(_RequestValues, LineNumber); // Sample of reading context values from ReceiveLines, to use in the lookup logic. Replace with reads for the context fields relevant to your scenario.
        CreateSampleLookupResponse(_LookupResponseElement, LineNumber); // Sample of creating a lookup response using the context value. Replace with your own logic to build the desired lookup result.

        _IsHandled := true;
    end;

    /// <summary>
    /// This sample reads context values from ReceiveLines.
    /// The available fields depend on which page the action is placed on.
    /// Replace this sample code with reads for the context fields available on your target page.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <param name="LineNumber">Receives the value of the LineNumber context field.</param>
    local procedure ReadSampleContextValues(var RequestValues: Record "MOB NS Request Element"; var LineNumber: Text)
    begin
        LineNumber := RequestValues.GetContextValue('LineNumber');
    end;

    /// <summary>
    /// This sample creates a lookup response using a context value read from the calling page.
    /// Replace this with your own logic to resolve the relevant context values and return the desired lookup result.
    /// </summary>
    /// <param name="_LookupResponseElement">The lookup response record to populate.</param>
    /// <param name="LineNumber">The context value read from the calling page (e.g. LineNumber from ReceiveLines).</param>
    local procedure CreateSampleLookupResponse(var _LookupResponseElement: Record "MOB NS WhseInquery Element"; LineNumber: Text)
    var
        LineNumberLbl: Label 'Line number is %1';
    begin
        _LookupResponseElement.Create();
        _LookupResponseElement.SetValue('LineNumber', LineNumber);
        _LookupResponseElement.Set_DisplayLine1(StrSubstNo(LineNumberLbl, LineNumber));
    end;
}

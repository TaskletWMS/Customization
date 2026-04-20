codeunit 60051 "ProjectItemPosting_Lookup"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE LOOKUP
    //
    // Subscribe to this event to return the list of projects shown when the user opens the lookup page.
    // The lookup type must match the type attribute of the lookupConfiguration in the tweak XML.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure HandleLookup_OnLookupOnCustomLookupType(_LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _IsHandled: Boolean)
    begin
        if _LookupType <> 'ProjectItemPosting' then
            exit;

        CreateLookupResponse(_LookupType, _RequestValues, _LookupResponseElement);
        _IsHandled := true;
    end;

    local procedure CreateLookupResponse(var _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element" temporary)
    var
        Job: Record Job;
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB XML Management";
        XmlResponseData: XmlNode;
        SearchTxt: Text;
    begin
        // Read Request        
        SearchTxt := _RequestValues.GetValueOrContextValue('ProjectSearchTxt'); // Field name defined in the header configuration

        if SearchTxt <> '' then begin
            Job.FilterGroup(-1); // cross-column search
            Job.SetFilter("No.", '@*' + SearchTxt + '*');
            Job.SetFilter(Description, '@*' + SearchTxt + '*');
            Job.FilterGroup(0);
        end;

        Job.SetRange(Blocked, Job.Blocked::" ");
        Job.SetFilter(Status, '<>%1', Job.Status::Completed);
        if Job.FindSet() then
            repeat
                // Create new Response Element
                _LookupResponseElement.Create();
                _LookupResponseElement.SetValue('ProjectNo', Job."No.");
                _LookupResponseElement.Set_DisplayLine1(Job."No.");
                _LookupResponseElement.Set_DisplayLine2(Job.Description);
                _LookupResponseElement.Set_DisplayLine3(Job."Bill-to Name");
                _LookupResponseElement.Save();
            until Job.Next() = 0;
    end;
}

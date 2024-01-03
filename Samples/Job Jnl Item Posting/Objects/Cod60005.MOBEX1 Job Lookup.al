codeunit 60005 "MOBEX1 Job Lookup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey - replace by your own key name
        _HeaderFields.InitConfigurationKey('Item2JobJnlHeader');

        // Add headerConfiguration elements here                
        _HeaderFields.Create_TextField(10, 'JobSearchTxt');
        _HeaderFields.Set_Label('Job Search Text:');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure MyOnLookupOnCustomLookupType(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        if _LookupType <> 'Item2JobJnl' then
            exit;

        Item2JobJnlLookup(_LookupType, _RequestValues, _XmlResultDoc);
        _IsHandled := true;
    end;

    local procedure Item2JobJnlLookup(var _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _XmlResultDoc: XmlDocument)
    var
        TempLookupResponseElement: Record "MOB NS WhseInquery Element" temporary;
        Job: Record Job;
        MobWmsLookup: Codeunit "MOB WMS Lookup";
        MobToolbox: Codeunit "MOB Toolbox";
        MobXmlMgt: Codeunit "MOB Xml Management";
        XmlResponseData: XmlNode;
        SearchTxt: Text;
    begin
        // Read Request        
        SearchTxt := _RequestValues.GetValueOrContextValue('JobSearchTxt');

        // Initialize the response xml
        MobToolbox.InitializeResponseDocWithNS(_XmlResultDoc, XmlResponseData, CopyStr(MobXmlMgt.NS_WHSEMODEL(), 1, 1024));

        Job.FilterGroup(-1); // cross-column search
        Job.SetFilter("No.", '@*' + SearchTxt + '*');
        Job.SetFilter("Description", '@*' + SearchTxt + '*');
        Job.FilterGroup(0);
        if Job.FindSet() then
            repeat
                // Create new Response Element
                TempLookupResponseElement.Create();
                TempLookupResponseElement.Set_DisplayLine1(Job."No.");
                TempLookupResponseElement.Set_DisplayLine2(Job.Description);
                TempLookupResponseElement.Set_DisplayLine3(Job."Bill-to Name");
                TempLookupResponseElement.SetValue('JobNo', Job."No.");
                TempLookupResponseElement.Save();
            until Job.Next() = 0;

        MobWmsLookup.AddLookupResponseElements(_LookupType, XmlResponseData, TempLookupResponseElement);
    end;
}

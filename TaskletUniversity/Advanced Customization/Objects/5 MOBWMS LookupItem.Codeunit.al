codeunit 50170 "MOB WMS Item Lookup Ext"
{
    // Add "LookupItems" header fields
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure AddHeader(var _HeaderFields: Record "MOB HeaderField Element")
    begin
        // Identifier for new ConfigurationKey - replace by your own key name
        _HeaderFields.InitConfigurationKey('LookupItems');

        // Create the field
        _HeaderFields.Create_TextField_ItemNumber(10);
        // Set properties on the field
        _HeaderFields.Set_optional(true);

        // ...you can add multiple fields one after another

        // Other examples of helper functions
        // _HeaderFields.Create_TextField_LotNumber(20);
        // _HeaderFields.Create_DateField_ExpirationDate(30);        
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Lookup", 'OnLookupOnCustomLookupType', '', true, true)]
    local procedure HandleOnLookup(_MessageId: Guid; _LookupType: Text; var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element"; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    begin
        // Handle only your own Lookup
        if _LookupType = 'LookupItems' then begin
            if _IsHandled then
                exit;

            LookupItems(_RequestValues, _LookupResponseElement);

            _IsHandled := true;
        end;
    end;

    local procedure LookupItems(var _RequestValues: Record "MOB NS Request Element"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    var
        Item: Record "Item";
        MobWmsToolbox: Codeunit "MOB WMS Toolbox";
        ItemNo: Code[20];
    begin
        // Read Request
        ItemNo := MobWmsToolbox.GetItemNumber(_RequestValues.Get_ItemNumber(true)); // Get exact ItemNumber, and if not exists, search fallback options including Item References. Will throw error if no match is found.

        // Set Item filter, else get all
        if ItemNo <> '' then
            Item.SetRange("No.", ItemNo);

        if Item.FindSet() then
            repeat
                // Create response element for each item
                _LookupResponseElement.Create();
                SetFromLookupItem(Item, _LookupResponseElement);
            until Item.Next() = 0;
    end;

    // Create a LookupResponse-element for one item
    local procedure SetFromLookupItem(_Item: Record "Item"; var _LookupResponseElement: Record "MOB NS WhseInquery Element")
    begin
        _Item.Get(_Item."No.");

        _LookupResponseElement.Init();
        _LookupResponseElement.Set_Location('WHITE');
        _LookupResponseElement.Set_ItemNumber(_Item."No.");

        _Item.CalcFields(Inventory);
        _LookupResponseElement.Set_Quantity(_Item.Inventory);
        _LookupResponseElement.SetValue('MyCustomValue', 'My Custom Value'); // You can Set and Get Custom values by using the Generic SetValue and GetValue procedures

        _LookupResponseElement.Set_DisplayLine1(_Item."No.");
        _LookupResponseElement.Set_DisplayLine2(_Item.Description);
        _LookupResponseElement.Set_DisplayLine3(_Item."Description 2");

        if _Item."Warehouse Class Code" <> '' then
            _LookupResponseElement.Set_DisplayLine4(_Item.FieldCaption("Warehouse Class Code") + ': ' + _Item."Warehouse Class Code");
    end;
}
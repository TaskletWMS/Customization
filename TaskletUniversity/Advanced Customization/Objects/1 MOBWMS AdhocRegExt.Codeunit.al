codeunit 50169 "MOB WMS Adhoc Reg Ext"
{
    // Add "SetWhseClassCode" header fields
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure AddHeader(var _HeaderFields: Record "MOB HeaderField Element")
    var
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        // Identifier for new ConfigurationKey - replace by your own key name
        _HeaderFields.InitConfigurationKey('SetWhseClassCode');

        // Create the field
        _HeaderFields.Create_TextField(10, 'ItemNumber');
        // Set properties on the field
        _HeaderFields.Set_label(MobWmsLanguage.GetMessage('ITEM') + ':');
        _HeaderFields.Set_clearOnClear(true);
        _HeaderFields.Set_length(50);   // 50=length of Item Reference when accepting barcode
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_eanAi('01,02,91'); // GS1 barcode AIs this field automatically reads
        _HeaderFields.Set_searchType('ItemSearch');

        // ...you can add multiple fields one after another

        // Tip: All of the above comes from a helper "Create_TextField_ItemNumber()"
        // Other examples of helper functions
        // _HeaderFields.Create_TextField_LotNumber(20);
        // _HeaderFields.Create_DateField_ExpirationDate(30);        
    end;

    // Read the header field values and return step(s)
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnGetRegistrationConfiguration_OnAddSteps', '', true, true)]
    local procedure OnGetRegistrationConfiguration_OnAddSteps(_RegistrationType: Text; var _HeaderFieldValues: Record "MOB NS Request Element"; var _Steps: Record "MOB Steps Element"; var _RegistrationTypeTracking: Text)
    var
        Item: Record Item;
        MobWMSToolbox: Codeunit "MOB WMS Toolbox";
        ItemNo: Code[20];
    begin
        // Handle only your own Header name
        if _RegistrationType <> 'SetWhseClassCode' then
            exit;

        // Read the request
        // Get exact ItemNumber, and if not exists, search fallback options including Item References. Will throw error if no match is found.
        ItemNo := MobWMSToolbox.GetItemNumber(_HeaderFieldValues.Get_ItemNumber());
        Item.Get(ItemNo);

        _HeaderFieldValues.get


        // Return step to collect Whse. Class Code for this exact Item
        _Steps.Create_ListStep(1, 'WhseClassCode');
        _Steps.Set_helpLabel('Enter Warehouse Class Code');
        _Steps.Set_label(Item.FieldCaption("Warehouse Class Code") + ':');
        _Steps.Set_optional(true);
        _Steps.Set_listValues(GetWhseClassCodeList(Item));

        // Set the Registration Type value displayed in the document queue
        _RegistrationTypeTracking := StrSubstNo('SetWhseClassCode: %1', ItemNo);
    end;

    // Returns a list of Whse. Class Codes
    // Show the current items Class Code as first element
    procedure GetWhseClassCodeList(_Item: Record Item) ReturnWhseClassList: Text;
    var
        WhseClass: Record "Warehouse Class";
    begin
        if _Item."Warehouse Class Code" <> '' then begin
            ReturnWhseClassList := _Item."Warehouse Class Code";
            WhseClass.SetFilter(Code, '<>%1', _Item."Warehouse Class Code");
        end;

        if WhseClass.FindSet() then
            repeat
                if ReturnWhseClassList = '' then
                    ReturnWhseClassList := WhseClass.Code
                else
                    ReturnWhseClassList += ';' + WhseClass.Code;
            until WhseClass.Next() = 0;

        if ReturnWhseClassList = '' then
            ReturnWhseClassList := ' '
        else
            if _Item."Warehouse Class Code" <> '' then
                ReturnWhseClassList += ';' + ' '
            else
                ReturnWhseClassList := ' ;' + ReturnWhseClassList;
    end;

    // Posting "SetWhseClassCode", using the collected Step values
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', true, true)]
    local procedure OnPostAdhocRegistrationOnCustomRegistrationType(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _RegistrationTypeTracking: Text; var _IsHandled: Boolean)
    var
        Item: Record Item;
        MobWMSToolbox: Codeunit "MOB WMS Toolbox";
        ItemNo: Code[20];
        WhseClassCode: Code[10];
    begin
        if _RegistrationType = 'SetWhseClassCode' then begin
            if _IsHandled then
                exit;

            // Read the request and the collected steps
            ItemNo := MobWMSToolbox.GetItemNumber(_RequestValues.Get_ItemNumber()); // Get exact ItemNumber, and if not exists, search fallback options including Item References. Will throw error if no match is found.
            WhseClassCode := CopyStr(_RequestValues.GetValue('WhseClassCode'), 1, MaxStrLen(WhseClassCode));

            // Validate item no. by getting item
            if not Item.Get(ItemNo) then
                Error('Item %1 does not exist.', ItemNo);

            // Modify Whse. Class on item
            if WhseClassCode <> Item."Warehouse Class Code" then begin
                Item.Validate("Warehouse Class Code", WhseClassCode);
                Item.Modify(true);
            end;

            _SuccessMessage := StrSubstNo('Warehouse Class Code set for %1', ItemNo);
            _RegistrationTypeTracking := 'SetWhseClassCode: ' + Item.TableCaption() + ' ' + ItemNo + ' ' + Item.FieldCaption("Warehouse Class Code") + ' ' + WhseClassCode;

            _IsHandled := true;
        end;
    end;
}
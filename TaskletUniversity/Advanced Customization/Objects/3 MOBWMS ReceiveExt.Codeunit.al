codeunit 50167 "MOB WMS Receive Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine', '', true, true)]
    local procedure OnGetReceiveOrderLines_OnAfterSetFromWarehouseReceiptLine(_WhseReceiptLine: Record "Warehouse Receipt Line"; var _BaseOrderLineElement: Record "MOB Ns BaseDataModel Element")
    var
        Item: Record Item;
        Bin: Record Bin;
    begin
        // Get Item no.
        Item.Get(_BaseOrderLineElement.Get_ItemNumber());

        // Set DisplayLine4 
        if Item."Warehouse Class Code" <> '' then
            _BaseOrderLineElement.Set_DisplayLine4('Whse. Class Code: ' + Item."Warehouse Class Code");


        // To be able to change Bin on Receive lines, I need to change the behaviour of the Receive Workflow steps. 
        // I can inspect "GetReceiveOrderLines" Response in Mob. Document Queue
        _BaseOrderLineElement.Set_ValidateToBin(true); // "ValidateToBin" sounds like the setting I need to change

        // That helped, but I really should set the ToBin to validate against, so let me find a Bin with a matching Warehouse Class Code
        if Item."Warehouse Class Code" <> '' then begin
            Bin.SetRange("Bin Type Code", 'RECEIVE');
            Bin.SetRange("Warehouse Class Code", Item."Warehouse Class Code");
            if Bin.FindFirst() then
                _BaseOrderLineElement.Set_ToBin(Bin.Code); // Found a Bin for this Whse. Class Code, use it as ToBin
        end else
            _BaseOrderLineElement.Set_ToBin(_WhseReceiptLine."Bin Code"); // No bin found, use default Bin

        // Show ToBin, by reading the ToBin we just set above
        _BaseOrderLineElement.Set_DisplayLine2('To Bin: ' + _BaseOrderLineElement.Get_ToBin());


        // W-08-0016 is Cold Storage in Receiving area
        // W-03-0001->3 is Cold Storage in PutPick area

        // Now that we have the flowfield on the Warehouse Receipt Line, we can set DisplayLine4 from this instead
        _WhseReceiptLine.CalcFields("Warehouse Class Code");
        if _WhseReceiptLine."Warehouse Class Code" <> '' then
            _BaseOrderLineElement.Set_DisplayLine4('Warehouse Class Code: ' + _WhseReceiptLine."Warehouse Class Code");

        _BaseOrderLineElement.SetValue('Weight', format(_WhseReceiptLine.Weight)); // You can Set and Get Custom values by using the Generic SetValue and GetValue procedures
    end;

    // Add "Whse. Class Code" field to Receive header
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin

        // Add a field to an existing ConfigurationKey
        _HeaderFields.InitConfigurationKey('ReceiveOrderFilters');

        // Create list-field with Warehouse class codes
        _HeaderFields.Create_ListField(50, 'WhseClassCode');
        _HeaderFields.Set_label('Warehouse Class Code');
        // Fill the values with semicolon separated list COLD;DRY;FROZEN;HEATED;NONSTATIC;
        _HeaderFields.Set_listValues(GetWhseClassCodeList());
        _HeaderFields.Set_listSeparator(';'); // Default is ';' you can set your own if needed with this function
        _HeaderFields.Set_optional(true);
    end;

    // Handle the "WhseClassCode" header field 
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterWarehouseReceipt', '', true, true)]
    local procedure OnGetReceiveOrders_OnSetFilterWarehouseReceipt(_HeaderFilter: Record "MOB NS Request Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _IsHandled: Boolean)
    begin
        if _HeaderFilter.Name = 'WhseClassCode' then begin
            _WhseReceiptLine.SetFilter("Warehouse Class Code", _HeaderFilter.Value);
            _IsHandled := true;
        end;
    end;

    procedure GetWhseClassCodeList() ReturnWhseClassList: Text;
    var
        WhseClass: Record "Warehouse Class";
    begin
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
            ReturnWhseClassList := ' ;' + ReturnWhseClassList;
    end;
}
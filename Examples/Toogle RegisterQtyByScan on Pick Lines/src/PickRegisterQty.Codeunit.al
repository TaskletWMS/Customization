codeunit 60100 "Pick Register Qty."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", 'OnGetApplicationConfiguration_OnAddTweaks', '', false, false)]
    local procedure PickLinesRegisterQty_OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    begin
        _MobTweakContainer.Add(60100, 'PickLines: Toggle Register Qty. By Scan', NavApp.GetResourceAsText('PickRegisterQtyByScan.xml'));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Adhoc Registr.", 'OnPostAdhocRegistrationOnCustomRegistrationType', '', false, false)]
    local procedure TogglePickRegisterQtyByScan(_RegistrationType: Text; var _RequestValues: Record "MOB NS Request Element"; var _SuccessMessage: Text; var _IsHandled: Boolean)
    var
        WhseActivityLine: Record "Warehouse Activity Line";
        LineNo: Integer;
        InvalidLineErr: Label 'Select a warehouse pick Take line before using Register Qty.';
        EnabledMsg: Label 'Register Qty. By Scan is on for the selected line.';
        DisabledMsg: Label 'Register Qty. By Scan is off for the selected line.';
    begin
        if (_RegistrationType <> 'TogglePickRegisterQtyByScan') or _IsHandled then
            exit;

        if not Evaluate(LineNo, _RequestValues.Get_LineNumber()) then
            Error(InvalidLineErr);

        WhseActivityLine.LockTable();
        if not WhseActivityLine.Get(WhseActivityLine."Activity Type"::Pick, _RequestValues.Get_BackendID(true), LineNo) then
            if not WhseActivityLine.Get(WhseActivityLine."Activity Type"::"Invt. Pick", _RequestValues.Get_BackendID(true), LineNo) then
                Error(InvalidLineErr);
        if WhseActivityLine."Action Type" <> WhseActivityLine."Action Type"::Take then
            Error(InvalidLineErr);

        WhseActivityLine."Register Qty. by Scan" := not WhseActivityLine."Register Qty. by Scan";
        WhseActivityLine.Modify();

        if WhseActivityLine."Register Qty. by Scan" then
            _SuccessMessage := EnabledMsg
        else
            _SuccessMessage := DisabledMsg;
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Pick", 'OnGetPickOrderLines_OnAfterSetFromWarehouseActivityLine', '', false, false)]
    local procedure PickLinesRegisterQty_OnAfterSetFromWarehouseActivityLine(_WhseActLineTake: Record "Warehouse Activity Line"; var _BaseOrderLineElement: Record "MOB NS BaseDataModel Element")
    begin
        if _WhseActLineTake."Register Qty. by Scan" then
            _BaseOrderLineElement.Set_RegisterQuantityByScanAndBarcodeQuantity(_WhseActLineTake."Item No.", _WhseActLineTake."Variant Code", _WhseActLineTake."Unit of Measure Code")
        else
            _BaseOrderLineElement.Set_RegisterQuantityByScan(false);
    end;
}
codeunit 50130 "Customization #1 - Modify DisplayLines"
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnAfterSetFromWarehouseReceiptHeader', '', true, true)]
    local procedure MyOnGetReceiveOrders_OnAfterSetFromWarehouseReceiptHeader(_WhseReceiptHeader: Record "Warehouse Receipt Header"; var _BaseOrderElement: Record "MOB Ns BaseDataModel Element")
    begin
        _BaseOrderElement.Set_DisplayLine2(_BaseOrderElement.Get_DisplayLine2 + ' ' + Format(_WhseReceiptHeader."Document Status"));
    end;

}
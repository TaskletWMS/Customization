codeunit 50131 "Customization #2 - Modify Order Filter"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Receive", 'OnGetReceiveOrders_OnSetFilterWarehouseReceipt', '', true, true)]
    procedure Example02_Overrule_ExptRecptDate_Filter(_HeaderFilter: Record "MOB NS Request Element"; var _WhseReceiptHeader: Record "Warehouse Receipt Header"; var _WhseReceiptLine: Record "Warehouse Receipt Line"; var _IsHandled: Boolean)
    begin
        // [Scenario]
        // Receipt lines are default filtered for "Due Date" using the formula <=%1 where %1 is "Expected Receipt Date"
        // Overrule the filter to always search one year from the current workdate
        // Filter on LINES will also affect which ORDERS that are included

        if _HeaderFilter.Name = 'Date' then begin
            _WhseReceiptLine.SetFilter("Due Date", '..%1', CalcDate('<CY+1Y>', WorkDate()));  // One year from the current workdate
            _IsHandled := true;
        end;
    end;
}
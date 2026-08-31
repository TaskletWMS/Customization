codeunit 70036 MyLookup3_SimulatedStorage
{
    // -----------------------------------------------------------------------------------------------------------------------
    // SIMULATED DATA STORAGE (TEMPLATE ONLY — DELETE IN A REAL IMPLEMENTATION)
    //
    // This template has no business table, so on its own it cannot show how a registered value would appear back on the lookup row.
    // To make that visible, this codeunit persists an accumulated "quantity" per row in Isolated Storage, keyed by a unique reference to the row.
    // The Post handler adds to this value, and the lookup handler reads it and shows it on the row.
    // Because it is persisted, the value shows on EVERY lookup — the first request and the refresh alike — refresh runs after every 
    // PostAdhocRegistration because of the refreshOnSuccess="true" attribute in the Tweak.xml. If that attribute were false (or not present),
    // the row would disappear from the device screen after the Post.
    //
    // In a real implementation you would NOT use this codeunit. Instead:
    //   - The Post handler updates your own table (ledger entry, document, quantity field, etc.).
    //   - The lookup query reads the current value from that table, so each row naturally reflects it on every load.
    // Delete this whole codeunit and the calls to it when you replace the sample data with your own query.
    // -----------------------------------------------------------------------------------------------------------------------

    /// <summary>
    /// SIMULATION ONLY: adds the registered quantity to the accumulated value stored for the given row.
    /// </summary>
    /// <param name="RowNo">The number of the registered row.</param>
    /// <param name="Qty">The quantity to add to the row's accumulated total.</param>
    procedure AddRegisteredQty(RowNo: Integer; Qty: Decimal)
    var
        NewQty: Decimal;
    begin
        NewQty := GetRegisteredQty(RowNo) + Qty;
        IsolatedStorage.Set(StorageKey(RowNo), Format(NewQty, 0, 9), DataScope::Company);
    end;

    /// <summary>
    /// SIMULATION ONLY: reads the accumulated registered quantity stored for the given row.
    /// </summary>
    /// <param name="RowNo">The number of the row.</param>
    /// <returns>The accumulated registered quantity, or 0 if none is stored.</returns>
    procedure GetRegisteredQty(RowNo: Integer): Decimal
    var
        StoredValue: Text;
        Qty: Decimal;
    begin
        if not IsolatedStorage.Contains(StorageKey(RowNo), DataScope::Company) then
            exit(0);
        if not IsolatedStorage.Get(StorageKey(RowNo), DataScope::Company, StoredValue) then
            exit(0);
        if Evaluate(Qty, StoredValue, 9) then
            exit(Qty);
        exit(0);
    end;

    local procedure StorageKey(RowNo: Integer): Text
    begin
        exit('MyLookup3_SimRegisteredQty_' + Format(RowNo));
    end;
}

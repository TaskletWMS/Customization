codeunit 60001 "MOBEX1 Create ConfKeys"
{


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Reference Data", 'OnGetReferenceData_OnAddHeaderConfigurations', '', true, true)]
    local procedure OnGetReferenceData_OnAddHeaderConfigurations(var _HeaderFields: Record "MOB HeaderField Element")
    begin

        CreateConfigurationKey(_HeaderFields, 'JobJnlNegAdjustQtyHeader');
        CreateConfigurationKey(_HeaderFields, 'JobJnlposAdjustQtyHeader');
    end;

    local procedure CreateConfigurationKey(var _HeaderFields: Record "MOB HeaderField Element"; _ConfigurationKey: Text)
    var
        MobToolbox: Codeunit "MOB Toolbox";
        MobWmsLanguage: Codeunit "MOB WMS Language";
    begin
        _HeaderFields.InitConfigurationKey(_ConfigurationKey);

        // Add headerConfiguration elements here

        // Job No.
        _HeaderFields.Create_TextField(10, 'JobNo');
        _HeaderFields.Set_label(MobWmsLanguage.GetMessage('JOB_NO_LABEL') + ':');
        _HeaderFields.Set_clearOnClear(false);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_length(20);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_eanAi('92');

        // Job Task. No.
        _HeaderFields.Create_TextField(20, 'JobTaskNo');
        _HeaderFields.Set_label(MobWmsLanguage.GetMessage('JOB_TASK_NO_LABEL') + ':');
        _HeaderFields.Set_clearOnClear(false);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_length(20);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_eanAi('93');
        _HeaderFields.Set_optional(true); // Collected using a Step if not provided in the Header

        // Location
        _HeaderFields.Create_ListField_Location(30);
        _HeaderFields.Set_clearOnClear(false);

        // ItemNumber
        _HeaderFields.Create_TextField(40, 'ItemNumber');
        _HeaderFields.Set_label(MobWmsLanguage.GetMessage('ITEM') + ':');
        _HeaderFields.Set_clearOnClear(true);
        _HeaderFields.Set_acceptBarcode(true);
        _HeaderFields.Set_length(20);
        _HeaderFields.Set_searchType('ItemSearch');
        _HeaderFields.Set_eanAi(MobToolbox.GetItemNoGS1Ai());
    end;

}

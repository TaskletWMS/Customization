codeunit 60500 "LP Contents Label Subscriber"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // Step 3: Populate the custom field before the dataset row is inserted
    // This event fires once per LP content line, just before the row is inserted into the report buffer.
    // Find and write data to the custom field in _Dataset.
    // Replace the placeholder logic below with your own business logic.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Report, Report::"MOB LP Contents Label", 'OnLicensePlateContent2Dataset_OnBeforeInsertDataset', '', false, false)]
    local procedure OnLicensePlateContent2Dataset_OnBeforeInsertDataset(_LicensePlateContent: Record "MOB License Plate Content"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _Dataset: Record "MOB Temp LP Report Content")
    begin
        _Dataset."Custom Field" := 'CUSTOM VALUE: ' + _LicensePlateContent."License Plate No.";
    end;
}
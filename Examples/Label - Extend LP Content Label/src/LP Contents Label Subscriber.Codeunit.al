codeunit 60500 "LP Contents Label Subscriber"
{
    //
    // Event Subscriber Codeunit for License Plate Content Label Report
    //

    [EventSubscriber(ObjectType::Report, Report::"MOB LP Contents Label", 'OnLicensePlateContent2Dataset_OnBeforeInsertDataset', '', false, false)]
    local procedure OnLicensePlateContent2Dataset_OnBeforeInsertDataset(_LicensePlateContent: Record "MOB License Plate Content"; var _MobTrackingSetup: Record "MOB Tracking Setup"; var _Dataset: Record "MOB Temp LP Report Content")
    begin
        // Custom code to be executed before inserting dataset record
        // Populate the custom field with some data. This example adds 'CUSTOM VALUE: ' prefix to the License Plate No.
        _Dataset."Custom Field" := 'CUSTOM VALUE: ' + _LicensePlateContent."License Plate No.";
    end;
}
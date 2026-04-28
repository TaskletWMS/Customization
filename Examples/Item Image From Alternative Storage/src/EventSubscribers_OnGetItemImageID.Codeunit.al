codeunit 60800 OnGetItemImageID
{
    //=================================================================================================
    // This codeunit demonstrates how to use event handlers to customize the process of retrieving item images in Business Central. 
    // It includes examples of handling both the 'OnBeforeGetItemImageID' and 'OnAfterGetItemImageID' events, 
    // as well as an example of providing a custom image in base64 format when the 'OnGetMedia_OnBeforeAddImageToMedia' event is triggered.

    // The event subscribers are for a very simple case, where the one variant ('YELLOW') will have its image ID set in the 'OnBeforeGetItemImageID' event,
    // and another variant ('ORANGE') will have its image ID set in the 'OnAfterGetItemImageID' event.
    // This will not be for a specific item, and will apply to all cases where the variant is 'YELLOW' or 'ORANGE', regardless of the item number.
    //=================================================================================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnBeforeGetItemImageID', '', false, false)]
    local procedure TEST_OnBeforeGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text; var _IsHandled: Boolean)
    begin
        if _VariantCode = 'YELLOW' then begin
            _ItemImageID := 'TestMediaID';
            _IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnAfterGetItemImageID', '', false, false)]
    local procedure TEST_OnAfterGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text)
    begin
        if _VariantCode = 'ORANGE' then
            _ItemImageID := 'TestMediaID';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnGetMedia_OnBeforeAddImageToMedia', '', false, false)]
    local procedure TEST_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; _ScreenHeight: Integer; _ScreenWidth: Integer; var _Base64Media: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;
        if _MediaID <> 'TestMediaID' then
            exit;

        _Base64Media := GetImageAsBase64('https://raw.githubusercontent.com/TaskletWMS/Customization/main/Templates/My%20Unplanned%201%20-%20Header%20And%20Steps/resources/myicon.png');
        if _Base64Media = '' then
            exit;
        _IsHandled := true;
    end;

    local procedure GetImageAsBase64(_ImageUrl: Text): Text
    var
        MobBase64Convert: Codeunit "MOB Base64 Convert";
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        ResponseContent: HttpContent;
        ImageInStream: InStream;
    begin
        if not HttpClient.Get(_ImageUrl, HttpResponseMessage) then
            exit('');
        if not HttpResponseMessage.IsSuccessStatusCode() then
            exit('');
        ResponseContent := HttpResponseMessage.Content();
        if not ResponseContent.ReadAs(ImageInStream) then
            exit('');

        exit(MobBase64Convert.ToBase64(ImageInStream));
    end;
}
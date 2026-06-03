codeunit 60800 OnGetItemImageID
{
    //=================================================================================================
    // This codeunit demonstrates how to use event handlers to customize the process of retrieving item images in Business Central. 
    // It includes examples of handling both the 'OnBeforeGetItemImageID' and 'OnAfterGetItemImageID' events, 
    // as well as an example of providing a custom image in base64 format when the 'OnGetMedia_OnBeforeAddImageToMedia' event is triggered.

    // The event subscribers are for item 'SPACESHIP', where the 'GREEN' variant will have its image ID set in the 'OnBeforeGetItemImageID' event,
    // and the 'ORANGE' variant will have its image ID set in the 'OnAfterGetItemImageID' event.
    // The images are fetched from an external URL (e.g. a GitHub raw file) and returned as Base64 via the 'OnGetMedia_OnBeforeAddImageToMedia' event.
    //=================================================================================================

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnBeforeGetItemImageID', '', false, false)]
    local procedure Example_OnBeforeGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text; var _IsHandled: Boolean)
    begin
        if _ItemNo <> 'SPACESHIP' then
            exit;
        if _VariantCode <> 'GREEN' then
            exit;
        _ItemImageID := 'GreenSpaceshipMediaID';
        _IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnAfterGetItemImageID', '', false, false)]
    local procedure Example_OnAfterGetItemImageID(var _ItemNo: Code[20]; var _VariantCode: Code[10]; var _ItemImageID: Text)
    begin
        if _ItemNo <> 'SPACESHIP' then
            exit;
        if _VariantCode <> 'ORANGE' then
            exit;
        _ItemImageID := 'OrangeSpaceshipMediaID';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", 'OnGetMedia_OnBeforeAddImageToMedia', '', false, false)]
    local procedure Example_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; _ScreenHeight: Integer; _ScreenWidth: Integer; var _Base64Media: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;

        if _MediaID = 'GreenSpaceshipMediaID' then
            _Base64Media := GetImageAsBase64('https://raw.githubusercontent.com/TaskletWMS/Customization/main/Examples/Item%20Image%20From%20Alternative%20Storage/media/Green%20Spaceship.png');

        if _MediaID = 'OrangeSpaceshipMediaID' then
            _Base64Media := GetImageAsBase64('https://raw.githubusercontent.com/TaskletWMS/Customization/main/Examples/Item%20Image%20From%20Alternative%20Storage/media/Orange%20Spaceship.png');

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
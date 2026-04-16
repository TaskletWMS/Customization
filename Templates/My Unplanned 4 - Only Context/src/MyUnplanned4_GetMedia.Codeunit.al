codeunit 60042 "MyUnplanned4_GetMedia"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // HANDLE ICON
    //
    // When the mobile device does not have an image cached for the media id defined in the tweak, it requests the image from the backend via a GetMedia call.
    // Use this event to return the icon image as a Base64 string when the expected media id is requested.
    // -----------------------------------------------------------------------------------------------------------------------
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Media", OnGetMedia_OnBeforeAddImageToMedia, '', false, false)]
    local procedure HandleIcon_OnGetMedia_OnBeforeAddImageToMedia(_MediaID: Text; var _Base64Media: Text; var _IsHandled: Boolean)
    begin
        if _IsHandled then
            exit;
        if _MediaID <> 'myicon' then // must match the icon attribute in the Tweak.xml
            exit;

        _Base64Media := GetIconAsBase64('myicon.png');
        _IsHandled := true;
    end;

    /// <summary>
    /// Loads an image resource from the app package and returns it as a Base64-encoded string.
    /// Make sure the image file is included in the resource folder specified in app.json and referenced with the correct filename.
    /// </summary>
    /// <param name="ResourceName">The filename of the image resource (e.g. 'myicon.png').</param>
    /// <returns>The Base64-encoded image string to assign to _Base64Media.</returns>
    local procedure GetIconAsBase64(ResourceName: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageStream: InStream;
    begin
        NavApp.GetResource(ResourceName, ImageStream);
        exit(Base64Convert.ToBase64(ImageStream));
    end;
}

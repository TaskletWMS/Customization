codeunit 60041 "MyUnplanned Samples"
{
    // This codeunit contains sample implementations shared across all MyUnplanned template variants.
    // Each procedure illustrates one piece of the registration flow: reading context values, defining header fields, creating steps, handling messages, and serving the icon.
    // Use these procedures as inspiration — copy the patterns you need into your own code and adapt the field names, labels, and logic to your customization.

    /// <summary>
    /// This sample reads context values from the calling page (here Receive).
    /// The available fields depend on which page the action is placed on.
    /// Replace this sample code with reads for the context fields available on your target page.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <param name="DisplayLine1">Receives the value of the DisplayLine1 context field.</param>
    /// <param name="Location">Receives the value of the Location context field.</param>
    internal procedure ReadSampleContextValues(var RequestValues: Record "MOB NS Request Element"; var DisplayLine1: Text; var Location: Text)
    begin
        DisplayLine1 := RequestValues.GetContextValue('DisplayLine1');
        Location := RequestValues.GetContextValue('Location');
    end;

    /// <summary>
    /// This sample creates two Mobile Messages — a page title and a shorter menu/action label — each matching a placeholder in the Tweak.xml.
    /// The sample uses labels for the message values, enabling translation via xlf files. Provide translations for the labels in each language you want to support.
    /// Replace the keys and values to match your customization.
    /// </summary>
    /// <param name="LanguageCode">The language code passed by the OnAddMessages event subscriber.</param>
    /// <param name="Message">The Mobile Message record passed by the OnAddMessages event subscriber.</param>
    internal procedure CreateSampleMessages(LanguageCode: Code[10]; var Message: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        MyActionLbl: Label 'My Unplanned Four', Comment = 'Action label';
        MyTitleLbl: Label 'My Unplanned (Only Context)', Comment = 'Page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_UNPLANNED_4_ACTION', MyActionLbl);
        Message.Create(LanguageCode, 'MY_UNPLANNED_4_TITLE', MyTitleLbl);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    /// <summary>
    /// This sample creates two Mobile Messages — a page title and a shorter menu/action label — each matching a placeholder in the Tweak.xml.
    /// This alternative to CreateSampleMessages uses hardcoded text values instead of labels, so it does not require xlf translation files.
    /// Replace the keys and values to match your customization.
    /// </summary>
    /// <param name="LanguageCode">The language code passed by the OnAddMessages event subscriber.</param>
    /// <param name="Message">The Mobile Message record passed by the OnAddMessages event subscriber.</param>
    internal procedure CreateSampleMessagesHardcoded(LanguageCode: Code[10]; var Message: Record "MOB Message")
    begin
        case LanguageCode of
            'ENU':
                begin
                    // The second parameter of Create() is the message key — it must match the @{} placeholder used in the Tweak.xml file.
                    Message.Create(LanguageCode, 'MY_UNPLANNED_4_ACTION', 'My Unplanned Four');
                    Message.Create(LanguageCode, 'MY_UNPLANNED_4_TITLE', 'My Unplanned (Only Context)');
                end;
        // Add more languages here and hardcode the corresponding translations for each message key.
        end;
    end;

    /// <summary>
    /// Loads an image resource from the app package and returns it as a Base64-encoded string.
    /// Make sure the image file is included in the resource folder specified in app.json and referenced with the correct filename.
    /// </summary>
    /// <param name="ResourceName">The filename of the image resource (e.g. 'myicon.png').</param>
    /// <returns>The Base64-encoded image string to assign to _Base64Media.</returns>
    internal procedure GetIconAsBase64(ResourceName: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        ImageStream: InStream;
    begin
        NavApp.GetResource(ResourceName, ImageStream);
        exit(Base64Convert.ToBase64(ImageStream));
    end;
}

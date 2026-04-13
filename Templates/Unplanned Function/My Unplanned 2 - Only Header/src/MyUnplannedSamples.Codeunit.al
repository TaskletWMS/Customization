codeunit 60021 "MyUnplanned Samples"
{
    // This codeunit contains sample implementations used in the MyUnplanned template.
    // Use these procedures as inspiration — adapt the field names, labels, and logic to your customization.

    /// <summary>
    /// This sample creates three fields for the header configuration: a required Date field, an optional Text field, and a required Decimal field.
    /// Replace this sample code with your own header field definitions.
    /// </summary>
    /// <param name="HeaderFields">The header field element record passed by the event subscriber.</param>
    internal procedure CreateSampleHeaderFields(var HeaderFields: Record "MOB HeaderField Element")
    var
        DateFieldLbl: Label 'Select date';
        TextFieldLbl: Label 'Enter text';
        DecimalFieldLbl: Label 'Enter decimal';
    begin
        HeaderFields.Create_DateField(10, 'MyDate', DateFieldLbl);

        HeaderFields.Create_TextField(20, 'MyText', TextFieldLbl);
        HeaderFields.Set_optional(true); // Optional — the user is not required to fill this in

        HeaderFields.Create_DecimalField(30, 'MyDecimal', DecimalFieldLbl);
    end;

    /// <summary>
    /// This sample reads three header field values from the accepted header: MyDate, MyText, and MyDecimal.
    /// Replace this sample code with reads for the header fields you defined in your header configuration.
    /// </summary>
    /// <param name="HeaderFieldValues">The header field values record passed by the event subscriber.</param>
    /// <param name="MyDate">Receives the value of the MyDate header field.</param>
    /// <param name="MyText">Receives the value of the MyText header field.</param>
    /// <param name="MyDecimal">Receives the value of the MyDecimal header field.</param>
    internal procedure ReadSampleHeaderValues(var HeaderFieldValues: Record "MOB NS Request Element"; var MyDate: Date; var MyText: Text; var MyDecimal: Decimal)
    begin
        MyDate := HeaderFieldValues.GetValueAsDate('MyDate');
        MyText := HeaderFieldValues.GetValue('MyText');
        MyDecimal := HeaderFieldValues.GetValueAsDecimal('MyDecimal');
    end;

    /// <summary>
    /// This sample creates a Mobile WMS menu option, optionally adding it to a group.
    /// Replace this sample code with your own menu option creation logic.
    /// </summary>
    /// <param name="MenuOption">The menu option to register.</param>
    /// <param name="GroupCode">The group code to add the menu option to, or '' to create a standalone menu option.</param>
    internal procedure CreateSampleMenuOption(MenuOption: Text; GroupCode: Text)
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        if GroupCode = '' then
            MobWmsSetupDocTypes.CreateMobileMenuOption(MenuOption) // Only created as menu option
        else
            MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup(MenuOption, GroupCode, 0); // Also added to group. Sorting = 0 adds to the beginning — adjust as needed.
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
        MyMenuLbl: Label 'My Unplanned Two', Comment = 'Menu label';
        MyTitleLbl: Label 'My Unplanned (Only Header)', Comment = 'Page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_UNPLANNED_2_MENU', MyMenuLbl);
        Message.Create(LanguageCode, 'MY_UNPLANNED_2_TITLE', MyTitleLbl);

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
                    Message.Create(LanguageCode, 'MY_UNPLANNED_2_MENU', 'My Unplanned');
                    Message.Create(LanguageCode, 'MY_UNPLANNED_2_TITLE', 'My Unplanned (Only Header)');
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

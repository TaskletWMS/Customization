codeunit 70011 "MyLookup Samples"
{
    // This codeunit contains sample implementations used in the MyLookupFromInput template.
    // Use these procedures as inspiration — adapt the field names, labels, and logic to your customization.

    /// <summary>
    /// This sample creates a search text field for the header configuration.
    /// The field name must match the name read in ReadSampleHeaderValue.
    /// Replace this with the search fields your lookup requires.
    /// </summary>
    /// <param name="HeaderFields">The header field element record passed by the event subscriber.</param>
    internal procedure CreateSampleHeaderFields(var HeaderFields: Record "MOB HeaderField Element")
    var
        SearchFieldLbl: Label 'Search';
    begin
        HeaderFields.Create_TextField(10, 'MySearchField', SearchFieldLbl); // e.g. Item No., Bin Code, Location Code
        HeaderFields.Set_optional(true); // Set optional if a blank value should return all results
    end;

    /// <summary>
    /// This sample reads the search field value from the accepted header.
    /// The field name must match the name defined in CreateSampleHeaderFields.
    /// Replace this with reads for the header fields you defined.
    /// </summary>
    /// <param name="RequestValues">The request values record passed by the event subscriber.</param>
    /// <returns>The value entered by the user in the search field.</returns>
    internal procedure ReadSampleHeaderValue(var RequestValues: Record "MOB NS Request Element"): Text
    begin
        exit(RequestValues.GetValue('MySearchField'));
    end;

    /// <summary>
    /// This sample creates five hardcoded lookup rows to demonstrate the response structure.
    /// Replace this with your own data query and loop — filter your table and call Create() per record.
    /// </summary>
    /// <param name="LookupResponseElement">The lookup response element record passed by the event subscriber.</param>
    /// <param name="SearchValue">The search value entered by the user in the header.</param>
    internal procedure AddSampleLookupRows(var LookupResponseElement: Record "MOB NS WhseInquery Element"; SearchValue: Text)
    var
        i: Integer;
        RowLbl: Label 'Row %1', Comment = '%1 = row number';
        DescLbl: Label 'This is some information for row number %1', Comment = '%1 = row number';
    begin
        for i := 1 to 5 do begin
            LookupResponseElement.Create();
            LookupResponseElement.Set_DisplayLine1(StrSubstNo(RowLbl, i));
            LookupResponseElement.Set_DisplayLine2(StrSubstNo(DescLbl, i));
        end;

        // Replace the loop above with your own data query. Example pattern — iterate a filtered table and create a row per record:
        //
        //   var
        //       MyRecord: Record "My Table";
        //   begin
        //       MyRecord.SetFilter("My Field", '@*%1*', SearchValue);
        //       if MyRecord.FindSet() then
        //           repeat
        //               LookupResponseElement.Create();
        //               LookupResponseElement.Set_DisplayLine1(MyRecord."My Field");
        //               LookupResponseElement.Set_DisplayLine2(MyRecord."My Description");
        //           until MyRecord.Next() = 0;
        //   end;
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
    /// The sample uses labels for the message values, enabling translation via xlf files.
    /// Replace the keys and values to match your customization.
    /// </summary>
    /// <param name="LanguageCode">The language code passed by the OnAddMessages event subscriber.</param>
    /// <param name="Message">The Mobile Message record passed by the OnAddMessages event subscriber.</param>
    internal procedure CreateSampleMessages(LanguageCode: Code[10]; var Message: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        MyMenuLbl: Label 'My Lookup One', Comment = 'Main Menu item label';
        MyTitleLbl: Label 'My Lookup (From Input)', Comment = 'Lookup page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_LOOKUP_1_MENU', MyMenuLbl);
        Message.Create(LanguageCode, 'MY_LOOKUP_1_TITLE', MyTitleLbl);

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
                    Message.Create(LanguageCode, 'MY_LOOKUP_1_MENU', 'My Lookup One');
                    Message.Create(LanguageCode, 'MY_LOOKUP_1_TITLE', 'My Lookup (From Input)');
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

codeunit 70030 MyLookup3_SetupData
{
    // -----------------------------------------------------------------------------------------------------------------------
    // CREATE SETUP DATA
    //
    // To make this customization work, you need provide setup data such as menu options and messages.
    // This codeunit includes event subscribers that create the necessary setup data when manually triggering actions in the BC client or during a Mobile WMS upgrade.
    // The procedures are also called during the installation of the extension, so the setup data is created automatically when the extension is installed.
    // If you want to run this code when the extension is upgraded to a new version, you can implement it in an Upgrade codeunit as well.
    //
    // The event OnAfterCreateDefaultMenuOptions is triggered by the action "Create Document Types" on the Mobile WMS Setup page.
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be run for each language you want to support.
    // Both are also triggered during upgrade of the Tasklet Mobile WMS app.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", OnAfterCreateDefaultMenuOptions, '', false, false)]
    local procedure CreateSetupData_OnAfterCreateDefaultMenuOptions()
    begin
        CreateMobileMenuOption();
        CreateMobileMessages();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", OnAddMessages, '', false, false)]
    local procedure AddMessages_OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
        CreateSampleMessages(_LanguageCode, _Messages);
        // Alternatively, hardcode values per language without xlf translations:
        // CreateSampleMessagesHardcoded(_LanguageCode, _Messages);
    end;

    /// <summary>
    /// Creates a menu option and adds it to a group to make it show up in the mobile app.
    /// The menu option must match the menuItem/page id used in the Tweak.xml
    /// The group code must match an existing group in the Mobile Group table.
    /// </summary>
    internal procedure CreateMobileMenuOption()
    begin
        CreateSampleMenuOption('MyLookupSelectAndRegister', 'WMS');
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml for a list of language codes.
    /// Add the language codes you want to support to the LanguageCodes list, and provide translations for each message either in xlf files or hardcoded in the code.
    /// </summary>
    internal procedure CreateMobileMessages()
    var
        MobMessage: Record "MOB Message";
        TranslationHelper: Codeunit "Translation Helper";
        LanguageCodes: List of [Code[10]];
        LanguageCode: Code[10];
    begin
        LanguageCodes.Add('ENU');
        // Add more languages here

        foreach LanguageCode in LanguageCodes do begin
            TranslationHelper.SetGlobalLanguageByCode(LanguageCode);
            CreateSampleMessages(LanguageCode, MobMessage);
            TranslationHelper.RestoreGlobalLanguage();
        end;

        // Alternatively, hardcode values per language without xlf translations:
        // foreach LanguageCode in LanguageCodes do
        //     CreateSampleMessagesHardcoded(LanguageCode, MobMessage);
    end;

    /// <summary>
    /// Creates a Mobile Menu Option, optionally adding it to a group.
    /// </summary>
    /// <param name="MenuOption">The menu option to register.</param>
    /// <param name="GroupCode">The group code to add the menu option to, or '' to create a standalone menu option.</param>
    local procedure CreateSampleMenuOption(MenuOption: Text; GroupCode: Text)
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
        MyMenuLbl: Label 'My Lookup Three', Comment = 'Main Menu item label';
        MyTitleLbl: Label 'My Lookup (Select and Register)', Comment = 'Lookup page title';
    begin
        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_LOOKUP_3_MENU', MyMenuLbl);
        Message.Create(LanguageCode, 'MY_LOOKUP_3_TITLE', MyTitleLbl);
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
                    Message.Create(LanguageCode, 'MY_LOOKUP_3_MENU', 'My Lookup Three');
                    Message.Create(LanguageCode, 'MY_LOOKUP_3_TITLE', 'My Lookup (Select and Register)');
                end;
        // Add more languages here and hardcode the corresponding translations for each message key.
        end;
    end;
}
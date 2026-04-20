codeunit 60054 "ProjectItemPosting_Setup"
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
    local procedure CreateMenu_OnAfterCreateDefaultMenuOptions()
    begin
        CreateMenuOption();
        CreateMobileMessages();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", OnAddMessages, '', false, false)]
    local procedure AddMessages_OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
        CreateMessages(_LanguageCode, _Messages);

        // Alternatively, hardcode values per language without xlf translations:
        // CreateMessagesHardcoded(_LanguageCode, _Messages);
    end;

    /// <summary>
    /// Creates a menu option and adds it to a group to make it show up in the mobile app.
    /// The menu option must match the menuItem/page id used in the Tweak.xml
    /// The group code must match an existing group in the Mobile Group table.
    /// The sorting determines the order in which the menu option appears in the mobile app, with lower numbers appearing first.
    /// </summary>
    internal procedure CreateMenuOption()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
    begin
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('ProjectItemPosting', 'WMS', 30);
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml for a list of language codes.
    /// Add the language codes you want to support to the LanguageCodes list, and provide translations for each message either in xlf files or hardcoded in the code.
    /// </summary>
    internal procedure CreateMobileMessages()
    var
        MobMessage: Record "MOB Message";
        LanguageCodes: List of [Code[10]];
        LanguageCode: Code[10];
    begin
        LanguageCodes.Add('ENU');
        // Add more languages here

        foreach LanguageCode in LanguageCodes do
            CreateMessages(LanguageCode, MobMessage);

        // Alternatively, hardcode values per language without xlf translations:
        // foreach LanguageCode in LanguageCodes do
        //     CreateMessagesHardcoded(LanguageCode, MobMessage);
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml, using labels to allow translations to be provided in xlf files.
    /// </summary>
    /// <param name="LanguageCode">The Language code to create messages for.</param>
    /// <param name="Message">The Mobile Message record to create messages on.</param>
    local procedure CreateMessages(LanguageCode: Code[10]; var Message: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        ProjectLookupTitleLbl: Label 'Projects', Comment = 'Menu and page title';
        ProjectConsumeActionLbl: Label 'Consume', Comment = 'Action label';
        ProjectConsumeTitleLbl: Label 'Project Item Consumption', Comment = 'Page title';
        ProjectReturnActionLbl: Label 'Return', Comment = 'Action label';
        ProjectReturnTitleLbl: Label 'Project Item Return', Comment = 'Page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'PROJECT_LOOKUP_TITLE', ProjectLookupTitleLbl);
        Message.Create(LanguageCode, 'PROJECT_CONSUME_ACTION', ProjectConsumeActionLbl);
        Message.Create(LanguageCode, 'PROJECT_CONSUME_TITLE', ProjectConsumeTitleLbl);
        Message.Create(LanguageCode, 'PROJECT_RETURN_ACTION', ProjectReturnActionLbl);
        Message.Create(LanguageCode, 'PROJECT_RETURN_TITLE', ProjectReturnTitleLbl);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml, using hardcoded values instead of labels.
    /// </summary>
    /// <param name="LanguageCode">The Language code to create messages for.</param>
    /// <param name="Message">The Mobile Message record to create messages on.</param>
    local procedure CreateMessagesHardcoded(LanguageCode: Code[10]; var Message: Record "MOB Message")
    begin
        case LanguageCode of
            'ENU':
                begin
                    // The second parameter of Create() is the message key — it must match the @{} placeholder used in the Tweak.xml file.
                    Message.Create(LanguageCode, 'PROJECT_LOOKUP_TITLE', 'Projects');
                    Message.Create(LanguageCode, 'PROJECT_CONSUME_ACTION', 'Consume');
                    Message.Create(LanguageCode, 'PROJECT_CONSUME_TITLE', 'Project Item Consumption');
                    Message.Create(LanguageCode, 'PROJECT_RETURN_ACTION', 'Return');
                    Message.Create(LanguageCode, 'PROJECT_RETURN_TITLE', 'Project Item Return');
                end;
        // Add more languages here and hardcode the corresponding translations for each message key.
        end;
    end;
}

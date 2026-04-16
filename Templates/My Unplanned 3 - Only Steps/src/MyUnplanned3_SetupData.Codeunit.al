codeunit 60034 "MyUnplanned3_SetupData"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // CREATE SETUP DATA
    //
    // To make this customization work, you need to provide Mobile Messages for the placeholders used in the Tweak.xml.
    // This codeunit includes event subscribers that create the messages when manually triggering the "Create Messages" action
    // on the Mobile Messages page, or during a Mobile WMS upgrade.
    // The procedure is also called during the installation of the extension, so the setup data is created automatically when the extension is installed.
    // If you want to run this code when the extension is upgraded to a new version, you can implement it in an Upgrade codeunit as well.
    //
    // The event OnAfterCreateDefaultMenuOptions is triggered by the action "Create Document Types" on the Mobile WMS Setup page.
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be run for each language you want to support.
    // Both are also triggered during upgrade of the Tasklet Mobile WMS app.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Setup Doc. Types", OnAfterCreateDefaultMenuOptions, '', false, false)]
    local procedure CreateSetupData_OnAfterCreateDefaultMenuOptions()
    begin
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
            CreateSampleMessages(LanguageCode, MobMessage);

        // Alternatively, hardcode values per language without xlf translations:
        // foreach LanguageCode in LanguageCodes do
        //     CreateSampleMessagesHardcoded(LanguageCode, MobMessage);
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml, using labels to allow translations to be provided in xlf files.
    /// </summary>
    /// <param name="LanguageCode">The Language code to create messages for.</param>
    /// <param name="Message">The Mobile Message record to create messages on.</param>
    local procedure CreateSampleMessages(LanguageCode: Code[10]; var Message: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        MyActionLbl: Label 'My Unplanned Three', Comment = 'Action label';
        MyTitleLbl: Label 'My Unplanned (Only Steps)', Comment = 'Page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_UNPLANNED_3_ACTION', MyActionLbl);
        Message.Create(LanguageCode, 'MY_UNPLANNED_3_TITLE', MyTitleLbl);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    /// <summary>
    /// Creates the Mobile Messages that resolve the placeholders used in the Tweak.xml, using hardcoded values instead of labels.
    /// </summary>
    /// <param name="LanguageCode">The Language code to create messages for.</param>
    /// <param name="Message">The Mobile Message record to create messages on.</param>
    local procedure CreateSampleMessagesHardcoded(LanguageCode: Code[10]; var Message: Record "MOB Message")
    begin
        case LanguageCode of
            'ENU':
                begin
                    // The second parameter of Create() is the message key — it must match the @{} placeholder used in the Tweak.xml file.
                    Message.Create(LanguageCode, 'MY_UNPLANNED_3_ACTION', 'My Unplanned Three');
                    Message.Create(LanguageCode, 'MY_UNPLANNED_3_TITLE', 'My Unplanned (Only Steps)');
                end;
            // Add more languages here and hardcode the corresponding translations for each message key.
        end;
    end;
}

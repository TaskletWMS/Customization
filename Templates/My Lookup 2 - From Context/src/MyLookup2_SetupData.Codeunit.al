codeunit 70023 "MyLookup2_SetupData"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // CREATE SETUP DATA
    //
    // To make this customization work, you need to provide Mobile Messages for the placeholders used in the Tweak.xml.
    // This codeunit includes an event subscriber that creates the messages when manually triggering the "Create Messages" action
    // on the Mobile Messages page, or during a Mobile WMS upgrade.
    // The procedure is also called during the installation of the extension, so the setup data is created automatically when the extension is installed.
    // If you want to run this code when the extension is upgraded to a new version, you can implement it in an Upgrade codeunit as well.
    //
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be run for each language you want to support.
    // It is also triggered during upgrade of the Tasklet Mobile WMS app.
    // -----------------------------------------------------------------------------------------------------------------------

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
    /// This sample creates two Mobile Messages — a page title and a shorter action label — each matching a placeholder in the Tweak.xml.
    /// The sample uses labels for the message values, enabling translation via xlf files.
    /// Replace the keys and values to match your customization.
    /// </summary>
    /// <param name="LanguageCode">The language code passed by the OnAddMessages event subscriber.</param>
    /// <param name="Message">The Mobile Message record passed by the OnAddMessages event subscriber.</param>
    local procedure CreateSampleMessages(LanguageCode: Code[10]; var Message: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        MyActionLbl: Label 'My Lookup Two', Comment = 'Action label on the source page';
        MyTitleLbl: Label 'My Lookup (From Context)', Comment = 'Lookup page title';
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        // The second parameter of Create() is the message code — it must match the @{} placeholder used in the Tweak.xml file.
        Message.Create(LanguageCode, 'MY_LOOKUP_2_ACTION', MyActionLbl);
        Message.Create(LanguageCode, 'MY_LOOKUP_2_TITLE', MyTitleLbl);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    /// <summary>
    /// This sample creates two Mobile Messages — a page title and a shorter action label — each matching a placeholder in the Tweak.xml.
    /// This alternative to CreateSampleMessages uses hardcoded text values instead of labels, so it does not require xlf translation files.
    /// Replace the keys and values to match your customization.
    /// </summary>
    /// <param name="LanguageCode">The language code passed by the OnAddMessages event subscriber.</param>
    /// <param name="Message">The Mobile Message record passed by the OnAddMessages event subscriber.</param>
    local procedure CreateSampleMessagesHardcoded(LanguageCode: Code[10]; var Message: Record "MOB Message")
    begin
        case LanguageCode of
            'ENU':
                begin
                    // The second parameter of Create() is the message key — it must match the @{} placeholder used in the Tweak.xml file.
                    Message.Create(LanguageCode, 'MY_LOOKUP_2_ACTION', 'My Lookup Two');
                    Message.Create(LanguageCode, 'MY_LOOKUP_2_TITLE', 'My Lookup (From Context)');
                end;
            // Add more languages here and hardcode the corresponding translations for each message key.
        end;
    end;
}

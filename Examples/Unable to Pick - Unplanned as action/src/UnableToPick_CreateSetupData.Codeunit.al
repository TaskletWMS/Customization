codeunit 60000 "UnableToPick_SetupData"
{
    // -----------------------------------------------------------------------------------------------------------------------
    // CREATE SETUP DATA
    //
    // Create Mobile Messages for each language you want to support, with keys matching the placeholders used in your Tweak.xml (without the @{}).
    // These messages are sent to the device on Reference Data load and resolve the @{} placeholders in the application.cfg.
    //
    // The event OnAddMessages is triggered by the action "Create Messages" on the Mobile Messages page, that must be manually run for each language you want to support.
    // It is also triggered during upgrade of the Tasklet Mobile WMS app.
    //
    // To create the setup data automatically when your extension is installed or upgraded, implement the code in an Install/Upgrade codeunit also.
    // -----------------------------------------------------------------------------------------------------------------------

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB WMS Language", OnAddMessages, '', true, true)]
    local procedure AddUnableToPickMessages_OnAddMessages(_LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    begin
        CreateLabelMessages(_LanguageCode, _Messages);
        // Alternatively, hardcode values per language without xlf translations:
        // CreateHardcodedMessages(_LanguageCode, _Messages);
    end;

    internal procedure CreateLabelMessages(LanguageCode: Code[10]; var Messages: Record "MOB Message")
    var
        TranslationHelper: Codeunit "Translation Helper";
        KeyLbl: Label 'UNABLE_TO_PICK_TITLE', Locked = true; // Message key matching the placeholder used in the Tweak.xml (without the @{})
        ValueLbl: Label 'Unable To Pick'; // Translate this value for each language you want to support in xlf files
    begin
        TranslationHelper.SetGlobalLanguageToDefault(); // Because if LanguageCode does not match a supported language, we want to fall back to en-US.
        TranslationHelper.SetGlobalLanguageByCode(LanguageCode);

        Messages.Create(LanguageCode, KeyLbl, ValueLbl); // Create a message record for the label placeholder used in the Tweak.xml

        TranslationHelper.RestoreGlobalLanguage();
    end;

    local procedure CreateHardcodedMessages(var _LanguageCode: Code[10]; var _Messages: Record "MOB Message")
    var
        KeyLbl: Label 'UNABLE_TO_PICK_TITLE', Locked = true; // Message key matching the placeholder used in the Tweak.xml (without the @{})
    begin
        case _LanguageCode of
            'ENU':
                _Messages.Create(_LanguageCode, KeyLbl, 'Unable To Pick');
        // Add more languages here
        end;
    end;
}
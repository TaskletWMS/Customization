enumextension 62300 "MobPlannedFunction" extends "MOB WMS Registration Type"
{
    value(62300; "My Function")
    {
        Caption = 'My Function';
    }
}

codeunit 62300 MobPlannedFunctionTweak
{
    // Applicaton.cfg changes / Tweaks 
    // See more https://taskletfactory.atlassian.net/wiki/x/UQCOC
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MOB Application Configuration", 'OnGetApplicationConfiguration_OnAddTweaks', '', true, true)]
    local procedure OnAddTweaks(var _MobTweakContainer: Codeunit "MOB Tweak Container")
    var
        Tweak: Text;
        FileManagement: Codeunit "File Management";
        InStream: InStream;
        Content: Text;
    begin
        NavApp.GetResource('MyFunctionTweak.xml', InStream);
        InStream.Read(Tweak);
        _MobTweakContainer.Add(62000, 'MyFunctionTweak', Tweak);
    end;
}
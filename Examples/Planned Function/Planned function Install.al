codeunit 62304 MobPlannedFunctionInstall
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    var
        MobWmsSetupDocTypes: Codeunit "MOB WMS Setup Doc. Types";
        MobMessage: Record "MOB Message";
    begin
        // Create a main-menu entry and what "Mobile Group" to add it 
        MobWmsSetupDocTypes.CreateMobileMenuOptionAndAddToMobileGroup('MyFunction', // Add MyFunction to a mobile group
        'WMS', // "WMS" is the default group name
         333);  // Sorting, 333 places our item near the top of the main menu

        // Create translations used in application.cfg. See "MyFunctionTweak.xml"
        MobMessage.Create('ENU', 'MainMenuMyFunction', 'My Function');
        MobMessage.Create('ENU', 'MainMenuMyFunction2', 'My Function2');
        MobMessage.Create('ENU', 'PageMyOrderListTitle', 'Orders');
        MobMessage.Create('ENU', 'PageMyOrderLinesTitle', 'Lines');
    end;
}
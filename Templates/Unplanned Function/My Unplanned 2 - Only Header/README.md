# Template: Unplanned — Header Only

An unplanned registration function with a header but no steps, added to the Main Menu.
Business logic runs immediately when the header is accepted.

## User flow

Select menu item → fill in header fields → accept → success message

## Technical flow

1. User selects menu item, fills in header fields, and accepts
2. Device sends `PostAdhocRegistration` with header values → **Handle Registration** runs business logic → success message returned to device

## Files

| File | Purpose |
|------|---------|
| `src/MyUnplannedOnlyHeader.Codeunit.al` | Main codeunit — header fields and business logic |
| `src/MyUnplannedSamples.Codeunit.al` | Sample helper — replace or remove when implementing |
| `resources/MyUnplannedOnlyHeaderTweak.xml` | Tweak — registers the page and the Main Menu item on the device |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyUnplannedOnlyHeader` — your function identifier (used in page id, type, and configurationKey)
   - `MY_UNPLANNED_2_TITLE` — your page title message key
   - `MY_UNPLANNED_2_MENU` — your menu label message key
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyUnplannedOnlyHeader` in the configurationKey, and define the header fields your registration requires.

5. In **Handle Registration**, replace `MyUnplannedOnlyHeader` in the type check, and implement your business logic.

6. In **Handle Icon**, replace `myicon` with your icon id and provide your own Base64 image.

7. In **Create Setup Data**, replace `MyUnplannedOnlyHeader` in the menu option, `MY_UNPLANNED_2_TITLE` and `MY_UNPLANNED_2_MENU` with your own message keys, and set their actual values (and translation).

8. **Optional:** To switch the entry point to an action on an existing page, use one of the action-based templates as a reference. Switching requires changes in both the code and the XML.

## When changes take effect
The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — menu configuration and Mobile Messages (returned in the language of the mobile user)

**Handle Registration** is invoked dynamically per registration and does not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

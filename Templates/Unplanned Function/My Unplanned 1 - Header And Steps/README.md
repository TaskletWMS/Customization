# Template: Unplanned — Header And Steps

An unplanned registration function with a header and steps, added to the Main Menu.

## User flow

Main Menu → fill in header fields → accept → fill in steps → run business logic → success message

## Files

| File | Purpose |
|------|---------|
| `src/MyUnplannedHeaderAndSteps.Codeunit.al` | Main codeunit — header fields, steps, and business logic |
| `src/MyUnplannedSamples.Codeunit.al` | Sample helper — replace or remove when implementing |
| `resources/MyUnplannedHeaderAndStepsTweak.xml` | Tweak — registers the page and the Main Menu item on the device |

## How to use

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyUnplannedHeaderAndSteps` — your function identifier (used in page id, type, and configurationKey)
   - `MY_UNPLANNED_1_TITLE` — your page title message key
   - `MY_UNPLANNED_1_MENU` — your menu label message key
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyUnplannedHeaderAndSteps` in the configurationKey, and define the header fields your registration requires.

5. In **Define Steps**, replace `MyUnplannedHeaderAndSteps` in the type check, and define the steps to collect after the header is accepted.

6. In **Handle Registration**, replace `MyUnplannedHeaderAndSteps` in the type check, and implement your business logic.

7. In **Handle Icon**, replace `myicon` with your icon id and provide your own Base64 image.

8. In **Create Setup Data**, replace `MyUnplannedHeaderAndSteps` in the menu option, `MY_UNPLANNED_1_TITLE` and `MY_UNPLANNED_1_MENU` with your own message keys, and set their actual values (and translation).

## When changes take effect
The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — menu configuration and Mobile Messages (returned in the language of the mobile user)

**Define Steps** and **Handle Registration** are invoked dynamically per registration and do not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

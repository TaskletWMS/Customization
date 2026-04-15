# Template: Unplanned — Steps Only

An unplanned registration function with steps but no user-fillable header, added as an action on an existing page.
The header auto-accepts on open, passing context from the parent page directly into the steps.

## User flow

Select action on parent page → fill in steps → accept → success message

## Technical flow

1. User selects action on parent page → header auto-accepts with context values from the calling page
2. Device sends `GetRegistrationConfiguration` with context values → **Define Steps** returns step definitions
3. User fills in steps and confirms
4. Device sends `PostAdhocRegistration` with context + step values → **Handle Registration** runs business logic → success message returned to device

## Files

| File | Purpose |
|------|---------|
| `src/MyUnplannedOnlySteps.Codeunit.al` | Main codeunit — header context field, steps, and business logic |
| `src/MyUnplannedSamples.Codeunit.al` | Sample helper — replace or remove when implementing |
| `resources/MyUnplannedOnlyStepsTweak.xml` | Tweak — registers the page and the action on an existing page |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyUnplannedOnlySteps` — your function identifier (used in page id, type, and configurationKey)
   - `MY_UNPLANNED_3_TITLE` — your page title message key
   - `MY_UNPLANNED_3_ACTION` — your action label message key
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyUnplannedOnlySteps` in the configurationKey, and define the context field displayed in the (auto-accepted) header.

5. In **Define Steps**, replace `MyUnplannedOnlySteps` in the type check, and define the steps to collect after the header auto-accepts.

6. In **Handle Registration**, replace `MyUnplannedOnlySteps` in the type check, and implement your business logic.

7. In **Handle Icon**, replace `myicon` with your icon id and provide your own Base64 image.

8. In **Create Setup Data**, replace `MY_UNPLANNED_3_TITLE` and `MY_UNPLANNED_3_ACTION` with your own message keys, and set their actual values (and translation).

9. **Optional:** To switch the entry point to a Main Menu item, use one of the Main Menu-based templates as a reference. Switching requires changes in both the code and the XML.

## When changes take effect
The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — Mobile Messages (returned in the language of the mobile user)

**Define Steps** and **Handle Registration** are invoked dynamically per registration and do not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

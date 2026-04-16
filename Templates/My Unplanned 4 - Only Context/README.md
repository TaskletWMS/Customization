# Template: Unplanned — Context Only

An unplanned registration function with no user-fillable header fields and no steps, added as an action on an existing page.
The header shows a locked context field (BackendID from the calling page) and auto-accepts immediately — no user input is collected.
This template can only be surfaced as an action. Context values are passed from the calling page, and a Main Menu item has no calling page to provide them.

## User flow

Select action on parent page → success message

## Technical flow

1. User selects action on parent page → header auto-accepts with context values from the calling page
2. Device sends `PostAdhocRegistration` with context values → **Handle Registration** runs business logic → success message returned to device

## Files

| File | Purpose |
|------|---------|
| `src/MyUnplannedOnlyContext.Codeunit.al` | Main codeunit — event subscribers wiring up the template |
| `src/MyUnplannedSamples.Codeunit.al` | Sample implementations — replace with your own logic when implementing |
| `resources/MyUnplannedOnlyContextTweak.xml` | Tweak — registers the page and the action on an existing page |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyUnplannedOnlyContext` — your function identifier (used in page id, type, and configurationKey)
   - `MY_UNPLANNED_4_TITLE` — your page title message key
   - `MY_UNPLANNED_4_ACTION` — your action label message key
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyUnplannedOnlyContext` in the configurationKey, and define the context field(s) to display in the auto-accepted header.

5. In **Handle Registration**, replace `MyUnplannedOnlyContext` in the type check, and implement your business logic. All input comes from context values passed from the calling page — no header or step values are collected from the user.

6. In **Handle Icon**, replace `myicon` with your icon id and provide your own Base64 image.

7. In **Create Setup Data**, replace `MY_UNPLANNED_4_TITLE` and `MY_UNPLANNED_4_ACTION` with your own message keys, and set their actual values (and translation).

## When changes take effect
The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — Mobile Messages (returned in the language of the mobile user)

**Handle Registration** is invoked dynamically per registration and does not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

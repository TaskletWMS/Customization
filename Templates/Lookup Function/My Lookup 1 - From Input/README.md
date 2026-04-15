# Template: Lookup 1 - From Input

A lookup function where the user fills in search criteria in the header, and the device fetches a filtered list of results. Added as a Main Menu item. Can alternatively be placed as an action on an existing page — see the tweak XML.

## User flow

Open the page → fill in search fields → accept → filtered list is displayed → (optionally) select a result

## Technical flow

1. User opens the page from the Main Menu and fills in the header search fields
2. User accepts the header
3. Device sends `Lookup` request → **Handle Lookup** queries BC data and returns matching rows
4. Filtered list is shown on the device

## Files

| File | Purpose |
|------|---------|
| `src/MyLookupFromInput.Codeunit.al` | Main codeunit — event subscribers wiring up the template |
| `src/MyLookupSamples.Codeunit.al` | Sample implementations — replace with your own logic when implementing |
| `resources/MyLookupFromInputTweak.xml` | Tweak — registers the lookup page and the Main Menu item |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the file and renumber the object to fit your customization.

2. In the tweak XML, replace:
   - `MyLookupFromInput` — your lookup identifier (page id, type, menu item id, and header configuration key)
   - `MY_LOOKUP_1_TITLE` — your message key for the page title
   - `MY_LOOKUP_1_MENU` — your message key for the Main Menu item label
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyLookupFromInput` in `InitConfigurationKey`, and define the search fields the user fills in. Replace `MySearchField` with your own field name(s).

5. In **Handle Lookup**, replace `MyLookupFromInput` in the type check, and implement `AddSampleLookupRows` to query your data using the header field values and create a response row per result.

6. In **Handle Icon**, replace `myicon` with your icon id and provide your own image (`myicon.png` in `resources/`).

7. In **Create Messages**, replace `MY_LOOKUP_1_TITLE` and `MY_LOOKUP_1_MENU` with your message keys and update the label texts.

## Notes

- If you want a purely read-only list with no row selection, remove `<onResultSelected>` from the tweak XML.
- If the header has a single mandatory field, the user must fill it in and tap Accept before the list loads. Set `Set_optional(true)` on header fields where a blank value should return all results.

## When changes take effect

The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — menu configuration and Mobile Messages (returned in the language of the mobile user)

**Handle Lookup** is invoked dynamically per request and does not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

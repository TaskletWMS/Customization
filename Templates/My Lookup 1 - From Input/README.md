# Template: My Lookup 1 - From Input

A lookup function where the user fills in input values in the header, and the device fetches a list of results. Added as a Main Menu item.

## User flow

Open the page → fill in header fields → accept → list is displayed → (optionally) select a result

## Technical flow

1. User opens the page from the Main Menu and fills in the header fields
2. User accepts the header
3. Device sends `Lookup` request → **Handle Lookup** queries BC data and returns matching rows
4. List of results is shown on the device

## Files

| File | Purpose |
|------|---------|
| `src/MyLookup1_GetReferenceData.Codeunit.al` | **Distribute Tweak** + **Define Header Fields** |
| `src/MyLookup1_Lookup.Codeunit.al` | **Handle Lookup** |
| `src/MyLookup1_GetMedia.Codeunit.al` | **Handle Icon** |
| `src/MyLookup1_SetupData.Codeunit.al` | **Create Setup Data** |
| `src/MyLookup1_Install.Codeunit.al` | Install codeunit |
| `resources/MyLookupFromInputTweak.xml` | Tweak XML |
| `resources/myicon.png` | Icon image |

## How to use

The codeunits contain `CreateSample*` procedures as starting points — use them as inspiration and adapt the logic, labels, and identifiers to your customization.

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyLookupFromInput` — your lookup identifier (page id, type, menu item id, and header configuration key)
   - `MY_LOOKUP_1_TITLE` — your message key for the page title
   - `MY_LOOKUP_1_MENU` — your message key for the Main Menu item label
   - `myicon` — your icon id

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyLookupFromInput` in `InitConfigurationKey`, and define the input fields the user fills in. Replace `MyHeaderField` with your own field name(s).

5. In **Handle Lookup**, replace `MyLookupFromInput` in the type check. Update `ReadSampleHeaderValue` to read the field name(s) you defined in step 4, and implement `AddSampleLookupRows` to query your data using those values and create a response row per result.

6. In **Handle Icon**, replace `myicon` with your icon id and replace `resources/myicon.png` with your own icon image (named to match your icon id).

7. In **Create Setup Data**, replace `MY_LOOKUP_1_TITLE` and `MY_LOOKUP_1_MENU` with your message keys and update the label texts.

8. **Optional:** To switch the entry point to an action on an existing page, use one of the action-based templates as a reference. Switching requires changes in both the code and the XML.

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

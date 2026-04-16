# Template: Lookup - From Context

A lookup function that displays read-only information for the currently selected record, added as an action on an existing page (e.g., Receive Lines list).
This template can only be surfaced as an action. Context values are passed from the calling page, and a Main Menu item has no calling page to provide them.

## User flow

Select a receive line → tap the action → lookup result is displayed

## Technical flow

1. User selects a record and taps the lookup action
2. The lookup page opens and auto-accepts the header (which carries `OrderBackendID` transferred from the context of the calling page)
3. Device sends `Lookup` request → **Handle Lookup** reads the context values and returns display text
4. Result is shown to the user on the device

## Files

| File | Purpose |
|------|---------|
| `src/MyLookup2_GetReferenceData.Codeunit.al` | **Distribute Tweak** + **Define Header Fields** |
| `src/MyLookup2_Lookup.Codeunit.al` | **Handle Lookup** |
| `src/MyLookup2_GetMedia.Codeunit.al` | **Handle Icon** |
| `src/MyLookup2_SetupData.Codeunit.al` | **Create Setup Data** |
| `src/MyLookup2_Install.Codeunit.al` | Install codeunit |
| `resources/MyLookupFromContextTweak.xml` | Tweak XML |
| `resources/myicon.png` | Icon image |

## How to use

The codeunits contain `CreateSample*` procedures as starting points — use them as inspiration and adapt the logic, labels, and identifiers to your customization.

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyLookupFromContext` — your lookup identifier (page id, type, action id, and header configuration key)
   - `MY_LOOKUP_2_TITLE` — your message key for the page title and action label
   - `myicon` — your icon id
   - `ReceiveLines` — the id of the page where you want to add the action (e.g. `PickLines`, `ShipmentLines`)

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyLookupFromContext` in `InitConfigurationKey` if you changed the key.

5. In **Handle Lookup**, replace `MyLookupFromContext` in the type check, and implement your own logic to read context values and populate the lookup response with the information you want to show.

6. In **Handle Icon**, replace `myicon` with your icon id and provide your own image (`myicon.png` in `resources/`).

7. In **Create Setup Data**, replace `MY_LOOKUP_2_TITLE` and `MY_LOOKUP_2_ACTION` with your message keys and update the label texts (and provide translations as needed via xlf).

## When changes take effect

The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Setup Data** — Mobile Messages (returned in the language of the mobile user)

**Handle Lookup** is invoked dynamically per request and does not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

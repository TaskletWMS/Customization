# Template: Lookup - From Context

A lookup function that displays read-only information for the currently selected record, added as an action on an existing page (e.g., Receive Lines list).

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
| `src/MyLookupFromContext.Codeunit.al` | Main codeunit — event subscribers wiring up the template |
| `src/MyLookupSamples.Codeunit.al` | Sample implementations — replace with your own logic when implementing |
| `resources/MyLookupFromContextTweak.xml` | Tweak — registers the lookup page and the action on an existing page |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the file and renumber the object to fit your customization.

2. In the tweak XML, replace:
   - `MyLookupFromContext` — your lookup identifier (page id, type, action id, and header configuration key)
   - `MY_LOOKUP_2_TITLE` — your message key for the page title and action label
   - `myicon` — your icon id
   - `ReceiveLines` — the id of the page where you want to add the action (e.g. `PickLines`, `ShipmentLines`)

3. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

4. In **Define Header Fields**, replace `MyLookupFromContext` in `InitConfigurationKey` if you changed the key.

5. In **Handle Lookup**, replace `MyLookupFromContext` in the type check, and implement your own logic to read context values and populate the lookup response with the information you want to show.

6. In **Handle Icon**, replace `myicon` with your icon id and provide your own image (`myicon.png` in `resources/`).

7. In **Create Messages**, replace `MY_LOOKUP_2_TITLE` with your message key and update the label text (and provide translations as needed via xlf).

## When changes take effect

The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions
- **Create Messages** — Mobile Messages (returned in the language of the mobile user)

**Handle Lookup** is invoked dynamically per request and does not require a re-login.

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

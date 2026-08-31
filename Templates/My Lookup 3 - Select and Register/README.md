# Template: My Lookup 3 - Select and Register

A lookup function opened from the Main Menu. The user enters a header value, accepts, and the list is fetched from Business Central. The user selects a row, fills in the collected steps, and the registration is submitted. After a successful registration the page refreshes, so the list reflects the change.

## User flow

Select menu item → enter header value → accept → list loads → select a row → fill in steps → confirm → success message (list refreshes)

## Technical flow

1. User selects the menu item from the Main Menu
2. The lookup page opens with a header that is not auto-accepted; the user enters the header value(s) and accepts
3. Device sends `GetLookup` → **Handle Lookup** reads the header, queries BC, and returns the selectable rows. Each row carries its `ReferenceID`, display lines, quantity, and the registration-collector steps to gather after selection
4. User selects a row and fills in the collected steps
5. User confirms → Device sends `PostAdhocRegistration` → **Handle Registration** reads `Get_ReferenceID()` and the step values and runs business logic
6. Because `refreshOnSuccess="true"`, the device re-runs `GetLookup` → the list reloads and reflects the registration

## Files

| File | Purpose |
|------|---------|
| `src/MyLookup3_SetupData.Codeunit.al` | Create setup data — Mobile menu option and messages (also runs on install/upgrade) |
| `src/MyLookup3_GetReferenceData.Codeunit.al` | Distribute the tweak and define the header fields |
| `src/MyLookup3_Lookup.Codeunit.al` | Handle Lookup — read header, query rows, attach steps, show registered quantity |
| `src/MyLookup3_PostAdhocRegistration.Codeunit.al` | Handle Registration — read the selected row and step values, run business logic |
| `src/MyLookup3_GetMedia.Codeunit.al` | Handle Icon — return the menu icon as Base64 |
| `src/MyLookup3_Install.Codeunit.al` | Install codeunit — creates the setup data on install |
| `src/MyLookup3_SimulatedStorage.Codeunit.al` | Template-only simulated data store (delete in a real implementation) |
| `resources/MyLookupSelectAndRegisterTweak.xml` | Tweak — custom list layout, Lookup page, and Main Menu item |
| `resources/myicon.png` | Icon image — served to the device as Base64 on request |

## How to use

1. Rename the files and renumber the objects to fit your customization.

2. In the tweak XML, replace:
   - `MyLookupSelectAndRegister` — your lookup identifier (page id, type, menu id, and header configuration key)
   - `MyLookupList` — your custom list layout id
   - `MY_LOOKUP_3_TITLE` — your message key for the page title
   - `MY_LOOKUP_3_MENU` — your message key for the Main Menu item label
   - `myicon` — your icon id

3. In **Create Setup Data**, update the menu option key, the group code, and the message keys/labels. Add the languages you want to support.

4. In **Distribute Tweak**, update the unique tweak ID, the tweak name, and the filename reference to match your renamed tweak file.

5. In **Define Header Fields**, replace `MyLookupSelectAndRegister` in `InitConfigurationKey` if you changed the key, and define the header fields the user fills in (the sample defines a single `MyHeaderField` text field).

6. In **Handle Lookup**, replace `MyLookupSelectAndRegister` in the type check, implement `AddSampleLookupRows` to query BC and return the selectable rows, and set `Set_ReferenceID` on each row. Define the steps to collect in `CreateSampleSteps` (or remove them and set `useRegistrationCollector="false"` if none are needed).

7. In **Handle Registration**, replace `MyLookupSelectAndRegister` in the type check, read `Get_ReferenceID()` to identify the selected row, read the step values, and implement your business logic.

8. In **Handle Icon**, replace `myicon` with your icon id and provide your own image (`myicon.png` in `resources/`).

9. Remove the **simulated data store** — delete `MyLookup3_SimulatedStorage.Codeunit.al` and the calls to it — once your lookup reads real data.

## Notes

- The header is not auto-accepted (`automaticAccept="Never"`), so the user must enter the header value(s) and accept before the list loads. Set `automaticAccept="OnOpen"` if you want the list to load immediately.
- Steps are attached to each lookup row via `SetRegistrationCollector`, so they travel with the `GetLookup` response — there is no separate `GetRegistrationConfiguration` round-trip. Set `useRegistrationCollector="false"` if no steps are needed.
- `Set_ReferenceID` on each row is returned as `Get_ReferenceID()` in **Handle Registration** — set it if you need to identify the selected row. (`BackendID` is only available on planned/order-based functions.)
- `refreshOnSuccess="true"` re-runs the lookup after a successful post so the list reflects the registration. Without it, the registered row is removed from the device list after posting.
- The **simulated data store** (`MyLookup3_SimulatedStorage`) exists only because this template has no business table. It persists an accumulated quantity per row in Isolated Storage so the refresh has something to show. In a real implementation your lookup query reads live data instead.

## When changes take effect

The following are delivered as Reference Data on login. Any changes require the mobile user to re-login:
- **Distribute Tweak** — tweak XML
- **Define Header Fields** — header field definitions

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

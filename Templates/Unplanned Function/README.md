# Template: Unplanned Function

Barebones starting points for adding a custom Unplanned function to Tasklet Mobile WMS. Four patterns cover different combinations of header input, step input, and context values — pick the one that fits your use case.

---

## What is an Unplanned function?

An Unplanned function is a freestanding registration page that is not tied to an order or document. It can collect input through two optional phases, or skip both and rely entirely on context values from the calling page:

- **Header** — fields shown to and filled in by the user before the registration starts. Static configuration; sent to the device on login as Reference Data.
- **Steps** — fields collected one at a time after the header is accepted. Dynamic; returned from the backend on request.
- **Context values** — data from the currently selected row on the calling page (e.g. document number, item, location). Available in patterns triggered as an action.

Both the header and steps phases are optional and can be combined freely.

---

## Unplanned patterns

The table below shows the four patterns and their input combinations. Each can be placed in the **Main Menu** or triggered as an **action on an existing page** — except `MyUnplanned4_OnlyContext`, which requires context values from a calling page and therefore only works as an action.

| Pattern | Header input | Step input | Context values | Flow |
|---|---|---|---|---|
| `MyUnplanned1_HeaderAndSteps` | Yes | Yes | No | Menu item → header fields → steps → business logic |
| `MyUnplanned2_OnlyHeader` | Yes | No | No | Menu item → header fields → business logic |
| `MyUnplanned3_OnlySteps` | No | Yes | Yes | Action on existing page → (auto-accepted header) → steps → business logic |
| `MyUnplanned4_OnlyContext` | No | No | Yes | Action on existing page → (auto-accepted header) → business logic |

---

## How to use a template pattern

Each pattern is self-contained: one XML tweak file in `resources/` and one codeunit in `src/`. A shared `MyUnplanned Samples` codeunit provides sample implementations used by all four patterns — use it as inspiration and copy the patterns you need.

1. **Copy** the pattern's `.al` file, tweak `.xml`, and `MyUnplanned_Samples.Codeunit.al` into your project. Renumber the objects to fit your object range.
2. **Rename** objects and all occurrences of the placeholder names (see table below).
3. **Define the access point** — update the tweak XML and CREATE SETUP DATA to match. To switch from a menu item to an action (or vice versa), use one of the opposite-access patterns as a reference. Main Menu patterns include a menu option created as data; action patterns do not.
5. **Adjust** the header fields (DEFINE HEADER FIELDS) and/or steps (DEFINE STEPS) to match your data model.
6. **Implement** your business logic in the registration handler (HANDLE REGISTRATION).
7. **Update the Mobile Messages** in CREATE SETUP DATA — set the page title and menu/action label texts for your function.
8. **Log out and back in** on the device after changing anything delivered as Reference Data (see note below).

### Rename targets

| Pattern | Type/key placeholder | Page title key | Menu/action label key | Icon placeholder |
|---|---|---|---|---|
| `MyUnplanned1_HeaderAndSteps` | `MyUnplannedHeaderAndSteps` | `MY_UNPLANNED_ONE_TITLE` | `MY_UNPLANNED_ONE` | `myicon` |
| `MyUnplanned2_OnlyHeader` | `MyUnplannedOnlyHeader` | `MY_UNPLANNED_TWO_TITLE` | `MY_UNPLANNED_TWO` | `myicon` |
| `MyUnplanned3_OnlySteps` | `MyUnplannedOnlySteps` | `MY_UNPLANNED_THREE_TITLE` | `MY_UNPLANNED_THREE` | `myicon` |
| `MyUnplanned4_OnlyContext` | `MyUnplannedOnlyContext` | `MY_UNPLANNED_FOUR_TITLE` | `MY_UNPLANNED_FOUR` | `myicon` |

The template uses the same value for all placeholder occurrences, but only some must match across files:
- XML `configurationKey` must match AL `InitConfigurationKey(...)` (header field definition)
- XML `type` must match the `_RegistrationType` check in AL (step and registration handlers)
- XML page `id` must match the `id` on the menu item or action within the same XML file

Replace `myicon` with the icon id for your function in both the page definition and the menu item or action.

> **Reference Data and login refresh**  
> The tweak XML (DISTRIBUTE TWEAK), header field definitions (DEFINE HEADER FIELDS), and Mobile Messages (CREATE SETUP DATA) are all delivered to the device as Reference Data on login. Field labels and mobile messages are returned to the mobile app in the requested language (user language).
Any changes to these require the mobile user to log out and back in before they take effect.
Step definitions (DEFINE STEPS) are fetched dynamically per registration and do not require a re-login.

---

## Disclaimer

This template is provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.
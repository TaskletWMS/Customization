# Customization Templates

These templates provide ready-to-use starting points for adding custom functions to Tasklet Mobile WMS. Each template targets a specific function type and input combination — pick the one that fits your use case.

## Lookup Functions

A Lookup function is a page that fetches and displays data from Business Central on the mobile device. The list is driven by a backend call and can return a single result or a list of rows.

| Template | When to use | Entry point |
|---|---|---|
| [My Lookup 1 — From Input](My%20Lookup%201%20-%20From%20Input/README.md) | User types one or more criteria to retrieve a filtered list of matching records | Main Menu ¹ |
| [My Lookup 2 — From Context](My%20Lookup%202%20-%20From%20Context/README.md) | User has selected a record and wants to view additional information about it | Action only ² |

## Unplanned Functions

An Unplanned function is a custom registration not driven by an order. It can be surfaced as a Main Menu item or as an action on an existing page, and may open a dedicated registration page or execute immediately with no registration page.

User input is optional and comes in two forms:

- **Header** — user-filled fields collected before the registration starts. Defined as static configuration and delivered to the device on login.
- **Steps** — fields collected one at a time after the header is accepted. Defined dynamically and returned from the backend per registration.

When triggered as an action on an existing page, the function also has access to:

- **Context values** — data from the currently selected row (e.g. document number, item, location). Passed automatically from the calling page, no user input required.

| Template | Registration page | Header input | Step input | Context values | Entry point |
|---|---|---|---|---|---|
| [My Unplanned 1 — Header And Steps](My%20Unplanned%201%20-%20Header%20And%20Steps/README.md) | Yes | Yes | Yes | No | Main Menu ¹ |
| [My Unplanned 2 — Only Header](My%20Unplanned%202%20-%20Only%20Header/README.md) | Yes | Yes | No | No | Main Menu ¹ |
| [My Unplanned 3 — Only Steps](My%20Unplanned%203%20-%20Only%20Steps/README.md) | Yes | No | Yes | Yes | Action ¹ |
| [My Unplanned 4 — Only Context](My%20Unplanned%204%20-%20Only%20Context/README.md) | Yes | No | No | Yes | Action only ² |

---

¹ Can be switched to the opposite entry point. Switching requires changes in both the code and the XML. Use one of the templates with the opposite entry point as a reference. Main Menu patterns include a menu option created as data; action patterns do not.

² Can only be surfaced as an action on an existing page. Context values are passed from the calling page, and a Main Menu item has no calling page to provide them.

## Disclaimer

These templates are provided as-is and are not officially supported. Validate and test thoroughly before use in production. We aim to keep them up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.
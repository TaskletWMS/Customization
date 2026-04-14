# Unplanned Function Templates

These templates provide ready-to-use starting points for adding a custom Unplanned function to Tasklet Mobile WMS. Each template covers a different combination of header input, step input, and context values — pick the one that fits your use case.

## What is an Unplanned function?

An Unplanned function is a custom registration not driven by an order. It can be surfaced as a Main Menu item or as an action on an existing page, and may open a dedicated registration page or execute immediately without one.

User input is optional and comes in two forms:

- **Header** — user-filled fields collected before the registration starts. Defined as static configuration and delivered to the device on login.
- **Steps** — fields collected one at a time after the header is accepted. Defined dynamically and returned from the backend per registration.

When triggered as an action on an existing page, the function also has access to:

- **Context values** — data from the currently selected row (e.g. document number, item, location). Passed automatically from the calling page, no user input required.

## Templates

The table below lists the available templates and their input combinations. Use it to identify the pattern that matches your use case, then follow the link to the template's own README for setup instructions.

| Template | Registration page | Header input | Step input | Context values | Entry point |
|---|---|---|---|---|---|
| [My Unplanned 1 — Header And Steps](My%20Unplanned%201%20-%20Header%20And%20Steps/README.md) | Yes | Yes | Yes | No | Main Menu |
| [My Unplanned 2 — Only Header](My%20Unplanned%202%20-%20Only%20Header/README.md) | Yes | Yes | No | No | Main Menu |
| [My Unplanned 3 — Only Steps](My%20Unplanned%203%20-%20Only%20Steps/README.md) | Yes | No | Yes | Yes | Action on existing page |
| [My Unplanned 4 — Only Context](My%20Unplanned%204%20-%20Only%20Context/README.md) | Yes | No | No | Yes | Action on existing page |

## Disclaimer

These templates are provided as-is. Validate and test thoroughly before use in production. It is not supported to the same degree as Tasklet Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.
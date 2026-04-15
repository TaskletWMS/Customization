# Lookup Function Templates

These templates provide ready-to-use starting points for adding a custom Lookup function to Tasklet Mobile WMS.

## What is a Lookup function?

A Lookup function is a page that fetches and displays data from Business Central on the mobile device. The list is driven by a backend call and can contain one or many rows. The templates differ in how the page is opened and what drives the data returned.

## Templates

| Template | Header input | Result | Entry point |
|---|---|---|---|
| [Lookup 1 — From Input](My%20Lookup%201%20-%20From%20Input/README.md) | User-typed filter criteria | Filtered list of matching records | Main Menu ¹ |
| [Lookup 2 — From Context](My%20Lookup%202%20-%20From%20Context/README.md) | Auto-filled from context — no user input | Contextual info for the selected record | Action only ² |

¹ Can be switched to the opposite entry point. Switching requires changes in both the code and the XML. Use one of the templates with the opposite entry point as a reference. Main Menu patterns include a menu option created as data; action patterns do not.

² Can only be surfaced as an action on an existing page. Context values are passed from the calling page, and a Main Menu item has no calling page to provide them.

## Choosing a template

**Use Lookup 1** when you want to let the user filter information from the Main Menu by typing one or more criteria — such as an item number, bin code, or location. The result is a filtered list of matching records.

**Use Lookup 2** when the user has already selected a record (e.g. a line in Receive Lines) and wants to see additional information about it — such as a description, comment, or note — without doing any input.

## Disclaimer

These templates are provided as-is. Validate and test thoroughly before use in production. They are not supported to the same degree as Tasklet Mobile WMS, but we aim to keep them up to date as Business Central and Mobile WMS evolve.

Report bugs directly in GitHub.

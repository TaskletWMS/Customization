# Adding and Modifying Steps

Steps are the input fields shown on the mobile device during a warehouse registration. They determine what data the user is asked to scan or enter before a registration can be posted — bin code, lot number, quantity, serial number, and so on.

This project contains examples showing how to add and modify steps across different Mobile WMS function types.

## Step types

Step behavior differs across function types:

| Function type | Line / registration steps | Posting steps |
|--------------|--------------------------|---------------|
| **Planned** (Pick, Receive, Put-Away, …) | Per order line — from workflow config or `OnGet[Flow]OrderLines_OnAddStepsToAnyLine` | Always: `OnGet[Flow]OrderLines_OnAddStepsToAnyHeader` · Conditional: `OnPost[Flow]Order_OnAddStepsTo[Document]Header` |
| **Unplanned** | `OnGetRegistrationConfiguration_OnAddSteps` | `OnPostAdhocRegistration_OnAddSteps` |
| **Lookup** | Registration collector on each lookup row | `OnPostAdhocRegistration_OnAddSteps` |

### Step ordering

Steps are ordered by their `id` parameter, ascending. Built-in steps use IDs spaced apart (10, 20, 30, …) so custom steps can be inserted between them by choosing an ID in the gap.

## Examples

| Example | Function type | Description |
|---------|--------------|-------------|
| [Add ImageCapture Step to Pick](docs/Add%20ImageCapture%20step%20to%20Pick.md) | Planned | Adds an ImageCapture posting (header) step that interrupts Pick posting |
| [Add Line Steps to Capture Item Weights in Receive](docs/Add%20line%20steps%20to%20capture%20weight%20in%20Receive.md) | Planned | Adds decimal line steps to Warehouse Receipt to collect Net Weight and Gross Weight per line |
| [Add ImageCapture Step to Adjust Quantity](docs/Add%20ImageCapture%20step%20to%20Adjust%20Quantity.md) | Unplanned | Adds an ImageCapture registration step to Adjust Quantity — shown after the header is accepted, before posting |

## General resources

- [Understanding Steps](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/2066743297)
- [How-to: Add header steps to a planned function](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78943507)
- [How-to: Add line steps to a planned function](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78943503)
- [How-to: Add steps to an unplanned function](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/2114813957)
- [Event Patterns for Planned Flows](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/2077655054)
- [Integration Events (reference)](https://taskletfactory.atlassian.net/wiki/spaces/TFSK/pages/78951793)

## Object numbers and prefix

Please renumber and rename objects before using this code in a production environment.

## Disclaimer

This example extension is provided as-is. Please carefully validate and test the code and any solution built from it. The code is not supported to the same degree as Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Please report bugs directly in GitHub.

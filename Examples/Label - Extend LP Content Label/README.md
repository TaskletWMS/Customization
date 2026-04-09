# 📦 Customizing License Plate Content Label (Report Print)

This example shows how to add a **custom field to the License Plate Content Label** report in Mobile WMS by extending the dataset and layout.

## Use case

The standard License Plate Content Label may not include all the information a business requires on the printed label. This example shows how to add a custom field to the label — for example, a derived value or data from a related table — by extending the report dataset and cerating a new layout.

## What this example implements

Three AL objects work together to extend the standard `MOB LP Contents Label` report:

- **Table extension** (`src/Temp LP Report Content.TableExt.al`) — adds a `Custom Field` (Text[50]) to the `MOB Temp LP Report Content` buffer table, making the field available in the report dataset.
- **Report extension** (`src/LP Contents Label.ReportExt.al`) — adds `Custom Field` as a dataset column and registers a new RDLC layout (`License Plate Contents GS1 4x6 AddToDataset.rdl`) that includes the field.
- **Event subscriber codeunit** (`src/LP Contents Label Subscriber.Codeunit.al`) — subscribes to `OnLicensePlateContent2Dataset_OnBeforeInsertDataset` and populates `Custom Field` before each row is inserted into the dataset. Replace the placeholder logic with your own business logic.

The custom RDLC layout was produced by exporting the original layout from **Report Layouts** using the **Export Layout** action, then modifying it in Report Builder.

### Original layout
<img src="media/Original License Plate Content Label.png" width="60%">

### Customized layout
<img src="media/License Plate Content Label Custom Field.png" width="60%">

## Object numbers and prefix

Please renumber and rename the objects before using this code in a production environment.

## Disclaimer

This example extension is provided as-is. Please carefully validate and test the code and any solution built from it. The code is not supported to the same degree as Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Please report bugs directly in GitHub.
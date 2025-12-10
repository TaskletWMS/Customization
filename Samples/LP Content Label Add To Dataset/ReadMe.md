# 📦 Customizing License Plate Content Label (Report Print)

This repository contains an example of a **adding a field to License Plate Content Label** using a subscriber event.


## 🚀 The Example Included

The example extends on the `MOB LP Contents Label` report and the `MOB Temp LP Report Content` table.

Furthermore it uses a Subscriber Codeunit, which listens to the event: `OnLicensePlateContent2Dataset_OnBeforeInsertDataset`. This event makes it possible to modify/add to the dataset before it is inserted to the Report.

The report layout has been modified to accommodate for the new changes.


## ⚠️ Important Notes

In this example the original report layout has been exported and modifed using report builder.
To do this, you will need to find the layout under **Report Layouts** and press the action **Export layout**.


## Old Report
![Old Report](gfx\Old%20License%20Plate%20Content%20Label.png)

## New Customized Report
![New Report](gfx\License%20Plate%20Content%20Label%20Custom%20Field.png)


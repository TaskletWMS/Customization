## Introduction
This is the source code for the Tutorial "Tutorial: Create a Positive Adjustment function" on http://docs.taskletfactory.com
https://taskletfactory.atlassian.net/wiki/x/NLi0B

This tutorial will partially implement a fictional customer case for "Unplanned Positive AdjustQty" as a new menu item.

The customization implemented using IntegrationEvents from the codeunit "MOB WMS Adhoc Registr." and is valid for every other customization that will use Unplanned ("adhoc") Requests.

### Use case examples
"We would like to update or create a similar screen to the Adjust Quantity screen that would allow for a positive adjustment. Currently it only allows negative adjustment."

A menu item currently exists at the mobile device for negative adjustments only.
The existing "Unplanned Count" menu item could be used to create positive adjustments, by counting the new (total) quantity of the item at the bin. However, the customer requests a new, separate menu item for positive adjustments to be implemented. 

The "Positive adjustment" customization should:

- Create a new, separate entry at the mobile menu for positive adjustments
- Icon graphics to mirror the existing "Adjust Quantity" menu item, but with a green plus sign instead.
- Include roughly same steps as existing "Unplanned count", including steps unit for lot number, serial number (dependent of Item Tracking Code setup), Variant Code and Unit of Measure

### Configuration file
An application.cfg is included in the source code.

Please visit https://taskletfactory.atlassian.net/wiki/x/rZC0B for more information.

### Object numbers and prefix
Please renumber and rename the objects before using the sample code at a production environment.

## Disclaimer
The sample extension is provided as-is so please carefully validate and test the code and any solution made with the code. The code is not supported to the same degree as Mobile WMS but it is expected periodically to be kept up to date if future changes in Business Central or Mobile WMS requires it.

Please report bugs in the sample extension directly in GitHub.
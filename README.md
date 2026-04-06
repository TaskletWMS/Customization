# Customizing [Mobile WMS](https://taskletfactory.com/solutions/mobile-wms-365-bc-nav/) for Business Central

## Welcome
This repository accompanies [Tasklet Docs](https://docs.taskletfactory.com/display/TFSK/Customization) and [Tasklet University](https://university.taskletfactory.com/), providing example code and training material for extending Mobile WMS in Business Central.

## Folders

### Examples
Working example projects you can modify and develop further.

| Example | Description |
|---------|-------------|
| [ISV Shipping Connector](Examples/ISV%20Shipping%20Connector/) | Connects the Pack & Ship process to an external shipping provider using the Pack & Ship API. Use as a base for building your own connector. |
| [ISV Shipping Solution](Examples/ISV%20Shipping%20Solution/) | A simple Transport Document extension with Package Types, intended as a companion to the ISV Shipping Connector. |
| [LP Content Label Add To Dataset](Examples/LP%20Content%20Label%20Add%20To%20Dataset/) | Extends the License Plate Content Label report with a custom field using a subscriber event. |
| [Planned Function](Examples/Planned%20Function/) | A custom Planned Function that registers "Qty. To Ship" on Sales Order Picking documents. |
| [Unplanned as Action - Unable to pick](Examples/Unplanned%20as%20Action%20-%20Unable%20to%20pick/) | Adds a custom Unplanned Function as an action on the Pick Order Lines page, letting operators register a shortfall directly from the picking flow. |
| [Unplanned in Main Menu - Job Jnl Item Posting](Examples/Unplanned%20in%20Main%20Menu%20-%20Job%20Jnl%20Item%20Posting/) | Adds a mobile function for selecting a Job and registering positive and negative item consumptions via the Job Journal. |
| [Unplanned in Main Menu - Pick to Bin](Examples/Unplanned%20in%20Main%20Menu%20-%20Pick%20to%20Bin/) | Lets warehouse employees pick items into a bin for further processing, posting each movement immediately to Business Central. |
| [Unplanned in Main Menu - Positive Adjustment](Examples/Unplanned%20in%20Main%20Menu%20-%20Positive%20Adjustment/) | Adds a dedicated mobile menu item for positive quantity adjustments. |

### TaskletUniversity
Source code used in Tasklet University training videos.

## Support
As a Tasklet Partner you have access to [Tasklet Support](https://taskletfactory.com/about/support/) when needed.

## Disclaimer
The example extensions are provided as-is, so please carefully validate and test the code and any solution built from it. The code is not supported to the same degree as Mobile WMS, but we aim to keep it up to date as Business Central and Mobile WMS evolve.

Please report bugs directly in GitHub.
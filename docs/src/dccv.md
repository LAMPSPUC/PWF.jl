# DCCV

## Description

AC-DC converter control data.

## Usage

| Column                               | Description                                                                                                                     |
| ------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------- |
| Number                               | Converter control identifier number, as defined in DCNV                                                                         |
| Operation                            | Converter control addition, modification or removal                                                                             |
| Looseness                            | F for loose converter, N for normal one; One loose converter must be specified for each pole                                    |
| Inverter control mode                | G for gamma control, T for interface AC bus voltage control. Only valid to CCC inverters                                        |
| Converter control type               | C for converter control with constant current, P for constant power                                                             |
| Specified value                      | Specified value for converter control (A for current control, MW for power control)                                             |
| Current margin                       | Inverter current margin as defined in DCNV (nominal current %)                                                                  |
| Maximum overcurrent                  | Maximum overcurrent allowed for converter, as defined in DCNV (nominal current %)                                               |
| Converter angle                      | Desired converter angle (°)                                                                                                     |
| Minimum converter angle              | Minimum desired converter angle (°)                                                                                             |
| Maximum converter angle              | Maximum desired converter angle (°)                                                                                             |
| Minimum transformer tap              | Minimum transformer tap                                                                                                         |
| Maximum transformer tap              | Maximum transformer tap                                                                                                         |
| Transformer tap number of steps      | Transformer tap number of steps, where a step is the difference between maximum and minimum type divided by the number of steps |
| Minimum DC voltage for power control | DC voltage below which a converter power controller operates in current control                                                 | Implicit decimal point |
| Tap Hi MVAr mode                     | Converter tap value when Hi MVAr consumption mode, defined in DELO, is on                                                       |
| Tap reduced voltage mode             | Converter tap value when operating at lower voltage mode                                                                        |

## Example

![Alt text](docs/assets/DCCV.png)

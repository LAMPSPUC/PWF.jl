# DSHL

## Description

AC circuit shunt data. This section enables association between shunt devices and AC circuits, facilitating failure simultation. This devices are automatically removed or inserted alongside the associated circuit.

## Usage

| Column      | Description                                                                        |
| ----------- | ---------------------------------------------------------------------------------- |
| From bus    | Bus number from one circuit extremity, as defined in DBAR                          |
| Operation   | Shunt addition, removal or modification                                            |
| To bus      | Bus number from the other circuit extremity, as defined in DBAR                    |
| Circuit     | Identification number of the AC circuit                                            |
| Shunt from  | Shunt reactive power in 'from bus' extremity for nominal voltage (1.0 p.u.) (Mvar) |
| Shunt to    | Shunt reactive power in 'to bus' extremity for nominal voltage (1.0 p.u.) (Mvar)   |
| Status from | On or off status for 'from bus' extremity                                          |
| Status to   | On or off status for 'to bus' extremity                                            |

## Example

![Alt text](docs/assets/DSHL.png)

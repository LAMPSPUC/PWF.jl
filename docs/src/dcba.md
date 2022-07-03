# DCBA

## Description

DC bus data.

## Usage

| Column              | Description                                                                                                    |
| ------------------- | -------------------------------------------------------------------------------------------------------------- |
| Number              | DC bus identification number                                                                                   |
| Operation           | Bus addition or modification                                                                                   |
| Type                | 0 for non-specified voltage, 1 for specified voltage (slack bus); one slack bus must be specified to each pole |
| Polarity            | +- for positive pole; -- for negative pole; 0 for neutral bus                                                  |
| Name                | Bus alphanumeric identification                                                                                |
| Voltage limit group | Not used in PWF current version                                                                                |
| Voltage             | Initial bus voltage (kV); for slack buses, voltage to be kept constant                                         |
| Ground electrode    | Ground electrode resistance (\(\Omega\)); should only be filled for neutral buses                              |
| DC link             | DC link number, as defined in DELO; each bus on the same pole or bipole must be from the same DC link          |

## Example

![Alt text](docs/assets/DCBA.png)

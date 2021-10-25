# DLIN
## Description
This section includes information about circuit data, both for branches and transformers, in columns described as follows:
## Usage
Column   |   Description
---   |   ---
From bus    |   Bus number from one of the ends
Opening from bus    |   On or off status for the bus defined in 'From bus'
Opening to bus    |   On or off status for the bus defined in 'To bus'
To bus    |   Bus number from the other end
Circuit    |   Identification number of the circuit
Status    |   Status of the circuit - on or off
Owner    |   Whether the circuit belongs to the area of 'From bus' or 'To bus'. Power losses are accounted for that area and flows are calculated in that bus
Resistance    |   Circuit resistance (%). For transformers, resistance for nominal tap.
Reactance    |   Circuit reactance (%). For transformers, reactance for nominal tap.
Shunt susceptance    |   Total circuit shunt susceptance (Mvar)
Tap    |   For fixed tap transformers, 'From bus' tap; For variable ones, the estimated value (per unit).    |   If specified value is out of bounds, the violated bound is considered; if no value is specified, value is set to 1.0
 Minimum tap    |   Lower tap bound for variable tap transformers (per unit)
 Maximum tap    |   Upper tap bound for variable tap transformers (per unit)
 Lag    |   Angle lag for out-of-phase transformers, applied in relation to 'From bus' (degrees).
 Controlled bus    |   Bus number which voltage should be controlled, for variable tap transformers
 Normal capacity    |   Circuit loading capacity at normal conditions (MVA)
 Emergency capacity    |   Circuit loading capacity at emergency conditions (MVA)
 Number of taps    |   Amount of variable tap transformers positions, including minimum and maximum tap
 Equipament capacity    |   Lower capacity equipament connected to the circuit
 Aggregator 1-10    |   Additional information
 ## Example
![Alt text](assets/DLIN.png)
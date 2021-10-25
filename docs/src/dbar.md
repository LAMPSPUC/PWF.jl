# DBAR
## Description
This section includes general information about AC buses, in columns described as follows:
## Usage
Column   |   Description
---   |   ---
Number    |   Bus identification number   
Operation    |   Bus addition, removal or modification  
Status    |   Bus status - on or off  
Type    |   Bus type - PQ, PV or swing  
Base voltage group    |   Bus voltage group identifier, defined in DGBT section. If there is no such section or the group is not defined there, base voltage will be set to 1.0 kv  
Name    |   Bus alphanumeric identification  
Voltage limit group    |   Bus voltage bounds group identifier, defined in DGLT section. If there is no such section or the group is not defined there, bounds will be set to 0.9 and 1.1.  
Voltage    |   Initial voltage (per unit)
Angle    |   Initial phase angle (degrees)  
Active generation    |   Bus active generation (MW)  
Reactive generation    |   Bus reactive generation (Mvar)  
Minimum reactive generation    |   Lower bound for bus reative generation (Mvar)  
Maximum reactive generation    |   Upper bound for bus reative generation (Mvar)  
Controlled bus    |   Bus which voltage magnitude will be controlled as defined in Voltage field  
Active charge    |   Bus active charge (MW)  
Reactive charge    |   Bus reactive charge (Mvar)  
Total reactive power    |   Total injected power by capacitor reactor banks; Positive value for capacitor and negative for reactors        
Area    |   Number of area which the bus is a part of  
Charge definition voltage    |   Voltage in which active and reactive charge were measured
Visualization mode    |   Bus visualization in ANAREDE software  
Aggregator 1-10    |   Additional information  
## Example
![Alt text](assets/DBAR.png)
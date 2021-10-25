# DBSH
## Description
Capacitor or reactor banks connected to AC buses or branches. For groups or banks connected to the same bus, minimum and maximum voltage, controlled bus and voltage control strategies will always be the same. In that sense, capacitors/reactors connected to a branch are considered as connected to the bus of the end which they are connected.
## Usage
Column   |   Description
---   |   ---
From bus   |   Either the bus number which shunt capacitor/reactor banks are connected or bus number from one of the circuit ends where line capacitor/reactor banks are connected.
Operation   |   Groups or banks addition, removal or modification
To bus   |   Bus number from the other end where line capacitor/reacor banks are connected; Not used for shunt capacitor/reactor banks
Circuit   |   AC circuit identification number
Control mode   |   Automatic switching control; C for continuous, D for discrete and F for fixed
Minimum voltage   |   Lower bound for voltage range that determinates automatic switching control
Maximum voltage   |   Upper bound for voltage range that determinates automatic switching control
Controlled bus   |   Bus number which voltage will be controlled by automatic switching control or reactors connected to the bus defined in Bus field; Controlled voltage value depends on the fields Control and Control Type
Initial reactive injection   |   Initial reactive injection due to capacitor/reactor banks connected in the bus (Mvar); This field aims to represent initial reactive power injection value for power flow solving; If control mode is fixed, this value represents what is effectively injected in the bus
Control type   |   C if control is made by the center of the voltage range, L if it is made by the violated bounds
Erase DBAR data?   |   If filled with 'S', value in Capacitor/Reactor field (DBAR section) will be erased
Extremity   |   Bus number from the circuit end where shunt capacitor/reactor banks are connected to
### Capacitor/Reactor banks
Column   |   Description
---   |   ---
Group or bank   |   Identification number; Each group or bank can have one or more switching stages
Operation   |   Capacitor/reactor banks or group data addition, removal or modification
Status   |   L if the group or bank is on, D if it is off
Unities   |   Total number of unities or stages that constitute the group or bank. This field is used as memory of the total number and the maximum allowed for each bus is 6
Operating unities   |   Total number of unities or stages that constitute the group or bank that are effectively in operation
Capacitor reactor   |   Total reactive power injected by one unity(Mvar); This value refers to the injected reactive power at nominal voltage (1.0 p.u.) and should be positive for capacitors and negative for reactors
## Example
![Alt text](assets/DBSH.png)
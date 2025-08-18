within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types;
type SystemMode = enumeration(
    Off   "System is off",
    DischargingBoth   "Discharge chiller and storage at the same time for cooling",
    DischargingStorage   "Storage only is discharged for cooling",
    DischargingChiller   "Chiller is on only for cooling",
    ChargingStorage   "Chiller is on only for charging") "Operation modes";

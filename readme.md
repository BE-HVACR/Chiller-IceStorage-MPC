# Modelica Numercial Testbed for HIL Testbeds

## NIST Chiller Testbed


## Co-simulation

### Compile FMU
The demo HVAC example is located at `VirtualTestbed.NISTChillerTestbed.System.CoSimulation.Baseline`. When compiling this model to FMU in Dymola, the following settings has to be set:

> Advanced.FMI.UseExperimentSettings=false
> 
> Advanced.FMI.xmlIgnoreProtected=true

However, ignoring protected variabels in FMU generation may cause the following problems:
1. cannot simulate in simulink due to the loss of information
   
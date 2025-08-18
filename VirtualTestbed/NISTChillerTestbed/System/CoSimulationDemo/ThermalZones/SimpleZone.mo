within VirtualTestbed.NISTChillerTestbed.System.CoSimulationDemo.ThermalZones;
model SimpleZone "Simplified zone model that uses external loads"
  extends Buildings.BaseClasses.BaseIcon;
  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Medium model";
  parameter Integer nPorts=0 "Number of parts" annotation (Evaluate=true,
      Dialog(
      connectorSizing=true,
      tab="General",
      group="Ports"));
  parameter Modelica.SIunits.Area AFlo "Area of the floor";
  parameter Modelica.SIunits.Height hRoo "Height of the room";
  parameter Modelica.SIunits.MassFlowRate m_flow_nominal= AFlo*hRoo*1.2/3600
    "Nominal mass flow rate";

  parameter Modelica.Media.Interfaces.Types.Temperature T_start=293.15
    "Start value of temperature";

  Buildings.Fluid.MixingVolumes.MixingVolume rooVol(
    redeclare package Medium = Medium,
    T_start=T_start,
    nPorts=nPorts,
    V=hRoo*AFlo,
    m_flow_nominal=m_flow_nominal,
    energyDynamics=Modelica.Fluid.Types.Dynamics.FixedInitial)
    "Volume of air in the room" annotation (Placement(
        transformation(extent={{41,-40},{61,-20}})));
  Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b ports[nPorts](
      redeclare each package Medium = Medium) "Fluid inlets and outlets"
    annotation (Placement(transformation(
        extent={{-38,-12},{38,12}},
        rotation=180,
        origin={0,-100}), iconTransformation(
        extent={{-40.5,-13},{40.5,13}},
        rotation=180,
        origin={4.5,-87})));
  Modelica.Thermal.HeatTransfer.Sources.PrescribedHeatFlow QSou
    "Heat source of the room"
    annotation (Placement(transformation(extent={{-62,-10},{-42,10}})));

  Modelica.Blocks.Interfaces.RealInput Q_flow
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Modelica.Thermal.HeatTransfer.Interfaces.HeatPort_a heaPorAir
    "Heat port to air volume"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}}),
        iconTransformation(extent={{-10,-10},{10,10}})));

equation
  connect(rooVol.ports, ports) annotation (Line(
      points={{51,-40},{52,-40},{52,-80},{0,-80},{0,-100}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(QSou.port, rooVol.heatPort) annotation (Line(
      points={{-42,0},{-20,0},{-20,-30},{41,-30}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(QSou.Q_flow, Q_flow)
    annotation (Line(points={{-62,0},{-120,0}}, color={0,0,127}));
  connect(rooVol.heatPort, heaPorAir)
    annotation (Line(points={{41,-30},{0,-30},{0,0},{0,0}}, color={191,0,0}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=true, extent={{-100,-100},{100,
            100}}), graphics={Rectangle(
          extent={{-100,100},{100,-100}},
          lineColor={0,0,0},
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          lineThickness=1)}),
    Documentation(info="<html>
<p>
This is a simplified room model for a data center. There is no heat exchange between the room and ambient environment through the building envelope since it is negligible compared to the heat released by the servers.
</p></html>", revisions="<html>
<ul>
<li>
July 17, 2015, by Michael Wetter:<br/>
Added <code>prescribedHeatFlowRate=false</code> for both volumes.
This is for
<a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/282\">
issue 282</a> of the Annex 60 library.
</li>
<li>
July 21, 2011 by Wangda Zuo:<br/>
Merge to library.
</li>
<li>
December 10, 2010 by Wangda Zuo:<br/>
First implementation.
</li>
</ul>
</html>"));
end SimpleZone;

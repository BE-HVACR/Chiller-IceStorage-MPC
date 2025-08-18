within VirtualTestbed.NISTChillerTestbed.System.CoSimulationDemo.ThermalZones;
model SimpleFloor "Model of a floor of the building"
  replaceable package Medium = Modelica.Media.Interfaces.PartialMedium
    "Medium model for air" annotation (choicesAllMatching=true);

  constant Modelica.SIunits.Height hRoo=2.74 "Room height";

  SimpleZone sou(
    redeclare package Medium = Medium,
    AFlo=568.77/hRoo,
    hRoo=hRoo,
    nPorts=2)                      "South zone"
    annotation (Placement(transformation(extent={{-16,-88},{24,-48}})));
  SimpleZone eas(
    redeclare package Medium = Medium,
    AFlo=360.0785/hRoo,
    hRoo=hRoo,
    nPorts=2)                      "East zone"
    annotation (Placement(transformation(extent={{100,-2},{140,38}})));
  SimpleZone cor(
    redeclare package Medium = Medium,
    AFlo=2698/hRoo,
    hRoo=hRoo,
    nPorts=2)                      "Core zone"
    annotation (Placement(transformation(extent={{-16,-8},{24,32}})));
  Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b portsSou[2](
      redeclare package Medium = Medium) "Fluid inlets and outlets"
    annotation (Placement(transformation(extent={{-126,-28},{-86,-12}}),
        iconTransformation(extent={{-126,-28},{-86,-12}})));
  Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b portsEas[2](
      redeclare package Medium = Medium) "Fluid inlets and outlets"
    annotation (Placement(transformation(extent={{138,58},{178,74}}),
        iconTransformation(extent={{138,58},{178,74}})));
  Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b portsNor[2](
      redeclare package Medium = Medium) "Fluid inlets and outlets"
    annotation (Placement(transformation(extent={{-126,142},{-86,158}}),
        iconTransformation(extent={{-126,142},{-86,158}})));
  Modelica.Fluid.Vessels.BaseClasses.VesselFluidPorts_b portsCor[2](
      redeclare package Medium = Medium) "Fluid inlets and outlets"
    annotation (Placement(transformation(extent={{-126,58},{-86,74}}),
        iconTransformation(extent={{-126,58},{-86,74}})));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor temAirSou
    "Air temperature sensor"
    annotation (Placement(transformation(extent={{150,178},{170,198}})));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor temAirEas
    "Air temperature sensor"
    annotation (Placement(transformation(extent={{152,148},{172,168}})));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor temAirNor
    "Air temperature sensor"
    annotation (Placement(transformation(extent={{152,118},{172,138}})));
  Modelica.Thermal.HeatTransfer.Sensors.TemperatureSensor temAirCor
    "Air temperature sensor"
    annotation (Placement(transformation(extent={{150,78},{170,98}})));
  Modelica.Blocks.Routing.Multiplex4 multiplex4_1
    annotation (Placement(transformation(extent={{200,118},{220,138}})));
  Modelica.Blocks.Interfaces.RealOutput TRooAir[4](
    each unit="K",
    each displayUnit="degC") "Room air temperatures"
    annotation (Placement(transformation(extent={{240,60},{260,80}}),
        iconTransformation(extent={{240,60},{260,80}})));

  SimpleZone nor(
    redeclare package Medium = Medium,
    AFlo=568.77/hRoo,
    hRoo=hRoo,
    nPorts=2)
    annotation (Placement(transformation(extent={{-16,92},{24,132}})));
  Modelica.Blocks.Interfaces.RealInput Q_flow[4]
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-200,160},{-160,200}})));
equation
  connect(multiplex4_1.y, TRooAir) annotation (Line(
      points={{221,128},{232,128},{232,70},{250,70}},
      color={0,0,127},
      smooth=Smooth.None,
      pattern=LinePattern.Dash));
  connect(eas.heaPorAir, temAirEas.port) annotation (Line(
      points={{120,18},{120,158},{152,158}},
      color={191,0,0},
      smooth=Smooth.None));
  connect(sou.ports[1], portsSou[1]) annotation (Line(
      points={{8.95,-85.4},{-42,-85.4},{-42,-20},{-116,-20}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(sou.ports[2], portsSou[2]) annotation (Line(
      points={{0.85,-85.4},{-32,-85.4},{-32,-20},{-96,-20}},
      color={0,127,255},
      smooth=Smooth.None));
  connect(eas.ports[1], portsEas[1]) annotation (Line(
      points={{124.95,0.6},{96,0.6},{96,66},{148,66}},
      color={0,127,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(eas.ports[2], portsEas[2]) annotation (Line(
      points={{116.85,0.6},{100,0.6},{100,66},{168,66}},
      color={0,127,255},
      smooth=Smooth.None,
      thickness=0.5));
  connect(nor.ports[1], portsNor[1]) annotation (Line(points={{8.95,94.6},{8.95,
          88},{-116,88},{-116,150}},
                                   color={0,127,255}));
  connect(nor.ports[2], portsNor[2]) annotation (Line(points={{0.85,94.6},{0.85,
          88},{-96,88},{-96,150}},   color={0,127,255}));
  connect(portsCor[1], cor.ports[1]) annotation (Line(points={{-116,66},{-32,66},
          {-32,-5.4},{8.95,-5.4}},  color={0,127,255}));
  connect(portsCor[2], cor.ports[2]) annotation (Line(points={{-96,66},{-40,66},
          {-40,-8},{-20,-8},{-20,-5.4},{0.85,-5.4}},   color={0,127,255}));
  connect(nor.heaPorAir, temAirNor.port)
    annotation (Line(points={{4,112},{4,128},{152,128}}, color={191,0,0}));
  connect(cor.heaPorAir, temAirCor.port) annotation (Line(points={{4,12},{60,12},
          {60,88},{150,88}}, color={191,0,0}));
  connect(sou.heaPorAir, temAirSou.port) annotation (Line(points={{4,-68},{44,-68},
          {44,188},{150,188}}, color={191,0,0}));
  connect(temAirCor.T, multiplex4_1.u1[1]) annotation (Line(points={{170,88},{
          186,88},{186,137},{198,137}}, color={0,0,127}));
  connect(temAirSou.T, multiplex4_1.u2[1]) annotation (Line(points={{170,188},{
          190,188},{190,131},{198,131}}, color={0,0,127}));
  connect(temAirEas.T, multiplex4_1.u3[1]) annotation (Line(points={{172,158},{
          188,158},{188,125},{198,125}}, color={0,0,127}));
  connect(temAirNor.T, multiplex4_1.u4[1]) annotation (Line(points={{172,128},{
          184,128},{184,119},{198,119}}, color={0,0,127}));
  connect(Q_flow[1], cor.Q_flow) annotation (Line(points={{-180,165},{-62,165},
          {-62,12},{-20,12}}, color={0,0,127}));
  connect(Q_flow[2], sou.Q_flow) annotation (Line(points={{-180,175},{-54,175},
          {-54,-68},{-20,-68}}, color={0,0,127}));
  connect(Q_flow[3], eas.Q_flow) annotation (Line(points={{-180,185},{80,185},{
          80,18},{96,18}}, color={0,0,127}));
  connect(Q_flow[4], nor.Q_flow) annotation (Line(points={{-180,195},{-30,195},
          {-30,112},{-20,112}}, color={0,0,127}));
  annotation (Diagram(coordinateSystem(preserveAspectRatio=true, extent={{-160,-100},
            {240,220}},
        initialScale=0.1)),     Icon(coordinateSystem(
          preserveAspectRatio=true, extent={{-160,-100},{240,220}}), graphics={
        Rectangle(
          extent={{-164,-56},{236,202}},
          lineColor={95,95,95},
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-152,182},{216,-38}},
          pattern=LinePattern.None,
          lineColor={117,148,176},
          fillColor={170,213,255},
          fillPattern=FillPattern.Sphere),
        Rectangle(
          extent={{-80,-58},{214,-38}},
          lineColor={95,95,95},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-80,-52},{214,-44}},
          lineColor={95,95,95},
          fillColor={170,213,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-140,28},{104,120}},
          lineColor={95,95,95},
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-128,108},{92,44}},
          pattern=LinePattern.None,
          lineColor={117,148,176},
          fillColor={170,213,255},
          fillPattern=FillPattern.Sphere),
        Polygon(
          points={{106,34},{222,-38},{214,-44},{98,28},{106,34}},
          smooth=Smooth.None,
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Polygon(
          points={{102,122},{216,190},{224,184},{108,114},{102,122}},
          smooth=Smooth.None,
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-160,142},{-140,2}},
          lineColor={95,95,95},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-154,142},{-146,2}},
          lineColor={95,95,95},
          fillColor={170,213,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{216,144},{236,4}},
          lineColor={95,95,95},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{222,144},{230,4}},
          lineColor={95,95,95},
          fillColor={170,213,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-78,192},{216,200}},
          lineColor={95,95,95},
          fillColor={170,213,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-78,182},{216,202}},
          lineColor={95,95,95},
          fillColor={255,255,255},
          fillPattern=FillPattern.Solid),
        Rectangle(
          extent={{-78,188},{216,196}},
          lineColor={95,95,95},
          fillColor={170,213,255},
          fillPattern=FillPattern.Solid)}),
    Documentation(revisions="<html>
<ul>
<li>
May 1, 2013, by Michael Wetter:<br/>
Declared the parameter record to be a parameter, as declaring its elements
to be parameters does not imply that the whole record has the variability of a parameter.
</li>
<li>
January 23, 2020, by Milica Grahovac:<br/>
Updated core zone geometry parameters related to 
room heat and mass balance.
</li>
</ul>
</html>", info="<html>
<p>
Model of a floor that consists
of five thermal zones that are representative of one floor of the
new construction medium office building for Chicago, IL,
as described in the set of DOE Commercial Building Benchmarks.
There are four perimeter zones and one core zone.
The envelope thermal properties meet ASHRAE Standard 90.1-2004.
</p>
</html>"));
end SimpleFloor;

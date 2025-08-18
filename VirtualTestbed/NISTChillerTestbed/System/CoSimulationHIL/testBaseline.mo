within VirtualTestbed.NISTChillerTestbed.System.CoSimulationHIL;
model testBaseline
  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.CoSimulationHIL.Baseline baseline
    annotation (Placement(transformation(extent={{-62,-52},{100,50}})));
  Modelica.Blocks.Sources.CombiTimeTable combiTimeTable(table=[0.0,0.0; 7*3600,0.0;
        7*3600,1; 19*3600,1; 19*3600,0; 24*3600,0],       extrapolation=
        Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,70},{-80,90}})));
  Modelica.Blocks.Math.Gain gain2(k=3500)
    annotation (Placement(transformation(extent={{-60,80},{-40,100}})));
  Modelica.Blocks.Math.Gain gain1(k=1500)
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
equation
  connect(combiTimeTable.y[1], gain2.u) annotation (Line(points={{-79,80},{-70,80},
          {-70,90},{-62,90}}, color={0,0,127}));
  connect(combiTimeTable.y[1], gain1.u) annotation (Line(points={{-79,80},{-70,80},
          {-70,70},{-62,70}}, color={0,0,127}));
  connect(gain1.y, baseline.theLoaEncOff2) annotation (Line(points={{-39,70},{-26,
          70},{-26,52},{-70,52},{-70,47.8},{-64,47.8}}, color={0,0,127}));
  connect(gain2.y, baseline.theLoaOpeOff1) annotation (Line(points={{-39,90},{-30,
          90},{-30,54},{-76,54},{-76,44},{-64,44}}, color={0,0,127}));
  connect(gain1.y, baseline.theLoaEncOff5) annotation (Line(points={{-39,70},{-26,
          70},{-26,52},{-70,52},{-70,40},{-64,40}}, color={0,0,127}));
  connect(gain2.y, baseline.theLoaConRoo2) annotation (Line(points={{-39,90},{-30,
          90},{-30,54},{-76,54},{-76,36},{-64,36}}, color={0,0,127}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    experiment(
      StartTime=16416000,
      StopTime=16502400,
      __Dymola_Algorithm="Cvode"));
end testBaseline;

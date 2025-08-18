within VirtualTestbed.NISTChillerTestbed.System.CoSimulationDemo;
model testBaseline
  Baseline baseline
    annotation (Placement(transformation(extent={{-62,-52},{100,50}})));
  Modelica.Blocks.Sources.CombiTimeTable combiTimeTable(table=[0.0,0.0; 7*3600,0.0;
        7*3600,3000; 19*3600,3000; 19*3600,0; 24*3600,0], extrapolation=
        Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,60},{-80,80}})));
  Modelica.Blocks.Math.Gain gain(k=4)
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
equation
  connect(combiTimeTable.y[1], baseline.theLoaSou) annotation (Line(points={{-79,70},
          {-72,70},{-72,44},{-64,44}}, color={0,0,127}));
  connect(combiTimeTable.y[1], baseline.theLoaEas) annotation (Line(points={{-79,70},
          {-72,70},{-72,40},{-64,40}}, color={0,0,127}));
  connect(combiTimeTable.y[1], baseline.theLoaNor) annotation (Line(points={{-79,70},
          {-72,70},{-72,36},{-64,36}}, color={0,0,127}));
  connect(combiTimeTable.y[1], gain.u)
    annotation (Line(points={{-79,70},{-62,70}}, color={0,0,127}));
  connect(gain.y, baseline.theLoaCor) annotation (Line(points={{-39,70},{-22,70},
          {-22,52},{-76,52},{-76,47.8},{-64,47.8}}, color={0,0,127}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    experiment(
      StartTime=16416000,
      StopTime=16502400,
      __Dymola_Algorithm="Cvode"));
end testBaseline;

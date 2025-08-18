within VirtualTestbed.NISTChillerTestbed.System.CoSimulationHIL.Validation;
model Baseline
  VirtualTestbed.NISTChillerTestbed.System.CoSimulationHIL.Baseline hvac
    annotation (Placement(transformation(extent={{-62,-52},{100,50}})));
  Modelica.Blocks.Sources.CombiTimeTable theLoaConRoo2(table=[0.0,0.0; 7*3600,
        0.0; 7*3600,500; 9*3600,3000; 19*3600,3500; 19*3600,0; 24*3600,0],
      extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,60},{-80,80}})));
  Modelica.Blocks.Sources.CombiTimeTable theLoaEncOff2(table=[0.0,0.0; 7*3600,
        0.0; 7*3600,500; 9*3600,1500; 19*3600,1800; 19*3600,0; 24*3600,0],
      extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,20},{-80,40}})));
  Modelica.Blocks.Sources.CombiTimeTable theLoaEncOff5(table=[0.0,0.0; 7*3600,
        0.0; 7*3600,500; 9*3600,1500; 19*3600,1800; 19*3600,0; 24*3600,0],
      extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,-40},{-80,-20}})));
  Modelica.Blocks.Sources.CombiTimeTable theLoaOpeOff1(table=[0.0,0.0; 7*3600,
        0.0; 7*3600,500; 9*3600,5000; 19*3600,5000; 19*3600,0; 24*3600,0],
      extrapolation=Modelica.Blocks.Types.Extrapolation.Periodic)
    annotation (Placement(transformation(extent={{-100,-10},{-80,10}})));
equation
  connect(theLoaConRoo2.y[1], hvac.theLoaConRoo2) annotation (Line(points={{-79,
          70},{-76,70},{-76,36},{-64,36}}, color={0,0,127}));
  connect(theLoaEncOff2.y[1], hvac.theLoaEncOff2) annotation (Line(points={{-79,
          30},{-72,30},{-72,47.8},{-64,47.8}}, color={0,0,127}));
  connect(theLoaOpeOff1.y[1], hvac.theLoaOpeOff1) annotation (Line(points={{-79,
          0},{-74,0},{-74,44},{-64,44}}, color={0,0,127}));
  connect(theLoaEncOff5.y[1], hvac.theLoaEncOff5) annotation (Line(points={{-79,
          -30},{-70,-30},{-70,40},{-64,40}}, color={0,0,127}));
  annotation (
    Icon(coordinateSystem(preserveAspectRatio=false)),
    Diagram(coordinateSystem(preserveAspectRatio=false)),
    experiment(
      StartTime=16416000,
      StopTime=16502400,
      __Dymola_Algorithm="Cvode"));
end Baseline;

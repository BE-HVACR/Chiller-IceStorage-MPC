within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.Validation;
model SystemForMPC_2bInputs
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.SystemForMPC_2bInputs
    tesBed(mIce_start=0.3*2846.35*2)
    annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Math.Random.Examples.GenerateRandomNumbers generateRandomNumbers(
      samplePeriod=2*60*60)
    annotation (Placement(transformation(extent={{-98,-50},{-78,-30}})));
  Modelica.Blocks.Sources.RealExpression randomInt(y=generateRandomNumbers.r64)
    annotation (Placement(transformation(extent={{-72,-50},{-52,-30}})));
  Modelica.Blocks.Math.RealToBoolean bChi
    annotation (Placement(transformation(extent={{-36,-48},{-20,-32}})));
  Modelica.Math.Random.Examples.GenerateRandomNumbers generateRandomNumbers1(
    samplePeriod=2*60*60,
    globalSeed=30000,
    localSeed=600000)
    annotation (Placement(transformation(extent={{-98,-86},{-78,-66}})));
  Modelica.Blocks.Sources.RealExpression randomInt1(y=generateRandomNumbers1.r64)
    annotation (Placement(transformation(extent={{-72,-86},{-52,-66}})));
  Modelica.Blocks.Math.RealToBoolean bIce
    annotation (Placement(transformation(extent={{-36,-84},{-20,-68}})));
equation
  connect(randomInt.y, bChi.u)
    annotation (Line(points={{-51,-40},{-37.6,-40}}, color={0,0,127}));
  connect(randomInt1.y, bIce.u)
    annotation (Line(points={{-51,-76},{-37.6,-76}}, color={0,0,127}));
  connect(bChi.y, tesBed.bc) annotation (Line(points={{-19.2,-40},{-18,-40},{
          -18,6},{-12,6}}, color={255,0,255}));
  connect(bIce.y, tesBed.bi) annotation (Line(points={{-19.2,-76},{-12,-76},{
          -12,2}}, color={255,0,255}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the mode controller based on the storage-priority control strategy.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file=
          "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/ModeControl.mos"
        "Simulate and Plot"),
    experiment(
      StartTime=18316800,
      StopTime=19526400,
      Interval=299.999808,
      __Dymola_Algorithm="Cvode"));
end SystemForMPC_2bInputs;

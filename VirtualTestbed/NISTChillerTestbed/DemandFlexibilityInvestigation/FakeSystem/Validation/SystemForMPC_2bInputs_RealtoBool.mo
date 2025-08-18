within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.Validation;
model SystemForMPC_2bInputs_RealtoBool
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.SystemForMPC_2bInputs_RealtoBool
    tesBed(mIce_start=0.3*2846.35*2)
    annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Math.Random.Examples.GenerateRandomNumbers generateRandomNumbers(
      samplePeriod=60*15)
    annotation (Placement(transformation(extent={{-98,-50},{-78,-30}})));
  Modelica.Blocks.Sources.RealExpression randomInt(y=generateRandomNumbers.r64)
    annotation (Placement(transformation(extent={{-72,-50},{-52,-30}})));
  Modelica.Math.Random.Examples.GenerateRandomNumbers generateRandomNumbers1(
    samplePeriod=60*15,
    globalSeed=30000,
    localSeed=600000)
    annotation (Placement(transformation(extent={{-98,-86},{-78,-66}})));
  Modelica.Blocks.Sources.RealExpression randomInt1(y=generateRandomNumbers1.r64)
    annotation (Placement(transformation(extent={{-72,-86},{-52,-66}})));
equation
  connect(randomInt.y, tesBed.bc) annotation (Line(points={{-51,-40},{-20,-40},
          {-20,6},{-12,6}}, color={0,0,127}));
  connect(randomInt1.y, tesBed.bi) annotation (Line(points={{-51,-76},{-16,-76},
          {-16,2},{-12,2}}, color={0,0,127}));
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
      __Dymola_Algorithm="Cvode"));
end SystemForMPC_2bInputs_RealtoBool;

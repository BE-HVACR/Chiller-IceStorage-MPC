within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.Validation;
model SystemForMPC_1bInput_modeSignal
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.SystemForMPC_1bInput_modeSignal
    tesBed annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Math.Random.Examples.GenerateRandomNumbers generateRandomNumbers(
      samplePeriod=1*60*60, localSeed=61000)
    annotation (Placement(transformation(extent={{-96,-10},{-76,10}})));
  Modelica.Blocks.Sources.RealExpression randomInt(y=4*generateRandomNumbers.r64
         - 1.5) "[-1.5,2.5]"
    annotation (Placement(transformation(extent={{-70,-10},{-50,10}})));
  Modelica.Blocks.Math.RealToInteger uMod
    "-1: Charge TES; 0: off; 1: Discharge TES; 2: Discharge chiller"
    annotation (Placement(transformation(extent={{-40,-8},{-24,8}})));
equation
  connect(randomInt.y, uMod.u)
    annotation (Line(points={{-49,0},{-41.6,0}}, color={0,0,127}));
  connect(uMod.y, tesBed.uMod) annotation (Line(points={{-23.2,0},{-18,0},{-18,
          6},{-12,6}}, color={255,127,0}));
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
      StopTime=20995200,
      Interval=3600.00288,
      Tolerance=0.001,
      __Dymola_Algorithm="Cvode"));
end SystemForMPC_1bInput_modeSignal;

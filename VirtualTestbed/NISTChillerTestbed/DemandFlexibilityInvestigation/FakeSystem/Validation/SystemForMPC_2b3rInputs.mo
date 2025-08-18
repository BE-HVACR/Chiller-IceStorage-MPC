within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.Validation;
model SystemForMPC_2b3rInputs
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.FakeSystem.SystemForMPC_2b3rInputs
    tesBed(mIce_start=0.9*2846.35*2)
    annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Blocks.Sources.BooleanTable bc(startValue=false, table=10*{
        1800,3600,5400})
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
  Modelica.Blocks.Sources.TimeTable Tchi(
                                        startTime=0, table=[10*0.0,273.15
         + 10; 10*5400,273.15 + 10; 10*7200,273.15 + 0; 10*9000,273.15 -
        5; 10*10000,273.15 - 5])
    annotation (Placement(transformation(extent={{-60,-12},{-40,8}})));
  Modelica.Blocks.Sources.BooleanTable bi(startValue=false, table=10*{
        3600})
    annotation (Placement(transformation(extent={{-60,30},{-40,50}})));
  Modelica.Blocks.Sources.TimeTable TiceTan(startTime=0, table=[0.0,273.15 + 10;
        10*5400,273.15 + 10; 10*5800,273.15 + 5; 10*9000,273.15 + 5])
    annotation (Placement(transformation(extent={{-60,-46},{-40,-26}})));
  Modelica.Blocks.Sources.TimeTable dP(startTime=0, table=[0.0,106000])
    annotation (Placement(transformation(extent={{-60,-80},{-40,-60}})));
equation
  connect(bc.y, tesBed.bc) annotation (Line(points={{-39,70},{-26,70},{-26,6},{
          -12,6}}, color={255,0,255}));
  connect(bi.y, tesBed.bi) annotation (Line(points={{-39,40},{-26,40},{-26,2},{
          -12,2}}, color={255,0,255}));
  connect(Tchi.y, tesBed.TChi)
    annotation (Line(points={{-39,-2},{-12,-2}}, color={0,0,127}));
  connect(TiceTan.y, tesBed.TIceTan) annotation (Line(points={{-39,-36},{-26,-36},
          {-26,-6},{-12,-6}}, color={0,0,127}));
  connect(dP.y, tesBed.dPCHW) annotation (Line(points={{-39,-70},{-26,-70},{-26,
          -10},{-12,-10}}, color={0,0,127}));
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
    experiment(StopTime=90000, __Dymola_Algorithm="Cvode"));
end SystemForMPC_2b3rInputs;

within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control.Examples;
model ModeControlMPC_2b
  import VirtualTestbed;
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control.ModeControlMPC_2b
    stoCon annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Blocks.Sources.BooleanTable bc(startValue=false, table={1800,
        3600,5400})
    annotation (Placement(transformation(extent={{-60,60},{-40,80}})));
  Modelica.Blocks.Sources.TimeTable SOC(startTime=0, table=[0.0,0.2; 1800,0.02;
        3600,0; 5400,0.2; 7200,0.6; 9000,1])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
  Modelica.Blocks.Sources.BooleanTable bi(startValue=false, table={3600})
    annotation (Placement(transformation(extent={{-60,30},{-40,50}})));
equation
  connect(SOC.y, stoCon.SOC)
    annotation (Line(points={{-39,0},{-26,0},{-26,-2},{-12,-2}},
                                                 color={0,0,127}));
  connect(bc.y, stoCon.bc) annotation (Line(points={{-39,70},{-26,70},{
          -26,6},{-12,6}}, color={255,0,255}));
  connect(bi.y, stoCon.bi) annotation (Line(points={{-39,40},{-26,40},{
          -26,3},{-12,3}}, color={255,0,255}));
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
    experiment(StopTime=10000, __Dymola_Algorithm="Cvode"));
end ModeControlMPC_2b;

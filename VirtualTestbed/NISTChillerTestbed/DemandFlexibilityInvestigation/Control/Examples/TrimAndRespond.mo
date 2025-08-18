within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control.Examples;
model TrimAndRespond
  import VirtualTestbed;
  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.Control.TrimAndRespond triAndRes(
    uTri=0.9,
    yEqu0=0,
    yDec=-0.03,
    yInc=0.03,
    samplePeriod=10)
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.TimeTable uVal(startTime=0, table=[0,0; 600,0; 1000,1;
        1200,1; 1800,0; 2400,1; 2401,0; 3000,0])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
equation
  connect(uVal.y, triAndRes.u)
    annotation (Line(points={{-39,0},{-12,0}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the TrimAndRespond.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file=
          "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/TrimAndRespond.mos"
        "Simulate and Plot"));
end TrimAndRespond;

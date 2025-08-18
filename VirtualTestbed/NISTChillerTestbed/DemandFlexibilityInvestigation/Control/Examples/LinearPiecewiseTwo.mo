within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control.Examples;
model LinearPiecewiseTwo
  import VirtualTestbed;
  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.Control.LinearPiecewiseTwo linPieTwo(
    x0=0,
    x1=0.5,
    x2=1,
    y10=0.5*106000,
    y11=106000,
    y20=273.15 + 10,
    y21=273.15 + 5)
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.TimeTable uVal(startTime=0, table=[0,0; 600,0; 1000,1;
        1200,1; 1800,0; 2400,1; 2401,0; 3000,0])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
equation
  connect(uVal.y, linPieTwo.u)
    annotation (Line(points={{-39,0},{-12,0}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the LinearPiecewiseTwo &quot;Temperature setpoints and Differential pressure setpoints&quot;.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file(inherit=true)=
        "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/LinearPiecewiseTwo.mos"
        "Simulate and Plot"));
end LinearPiecewiseTwo;

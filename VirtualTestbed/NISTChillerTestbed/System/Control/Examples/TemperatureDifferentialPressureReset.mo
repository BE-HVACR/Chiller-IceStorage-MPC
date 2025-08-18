within VirtualTestbed.NISTChillerTestbed.System.Control.Examples;
model TemperatureDifferentialPressureReset
  import VirtualTestbed;
  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.Control.TemperatureDifferentialPressureReset
    temDifPreRes(
    TMin=273.15 + 5,
    TMax=273.15 + 10,
    samplePeriod=10,
    uTri=0.9) annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.IntegerTable sysMod(table=[0,1; 600,1; 601,2; 1200,2;
        1201,3; 1800,3; 1801,4; 2400,4; 2401,5; 3000,5])
    annotation (Placement(transformation(extent={{-60,20},{-40,40}})));
  Modelica.Blocks.Sources.TimeTable uVal(startTime=0, table=[0,0; 600,0; 1000,1;
        1200,1; 1800,0; 2400,1; 2401,0; 3000,0])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
equation
  connect(sysMod.y, temDifPreRes.uOpeMod) annotation (Line(points={{-39,30},{
          -26,30},{-26,6},{-12,6}}, color={255,127,0}));
  connect(uVal.y, temDifPreRes.u)
    annotation (Line(points={{-39,0},{-12,0}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the controller of outlet temperature setpoints and differential pressure setpoints.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file=
          "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/TemperatureDifferentialPressureReset.mos"
        "Simulate and Plot"));
end TemperatureDifferentialPressureReset;

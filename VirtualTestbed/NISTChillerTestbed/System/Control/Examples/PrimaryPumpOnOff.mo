within VirtualTestbed.NISTChillerTestbed.System.Control.Examples;
model PrimaryPumpOnOff

  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.Control.PrimaryPumpOnOff priPum
    annotation (Placement(transformation(extent={{-8,-10},{12,10}})));
  Modelica.Blocks.Sources.IntegerTable sysMod(table=[0,1; 60,1; 61,2; 120,2;
        121,3; 180,3; 181,4; 240,4; 241,5; 300,5])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
equation
  connect(sysMod.y, priPum.u)
    annotation (Line(points={{-39,0},{-10,0}}, color={255,127,0}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    experiment(StopTime=300, __Dymola_Algorithm="Dassl"),
    __Dymola_Commands(file=
          "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/PrimaryPumpOnOff.mos"
        "Simulate and Plot"),
    Documentation(info="<html>
<p>This example is to validate the on/off controller of the primary pump.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"));
end PrimaryPumpOnOff;

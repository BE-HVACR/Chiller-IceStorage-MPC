within VirtualTestbed.NISTChillerTestbed.System.Control.Examples;
model CoilValveOnOff "Test the controller of coil valve"
  import VirtualTestbed;
  extends Modelica.Icons.Example;

  VirtualTestbed.NISTChillerTestbed.System.Control.CoilValveOnOff
    coilValveOnOff
    annotation (Placement(transformation(extent={{-10,-10},{10,10}})));
  Modelica.Blocks.Sources.IntegerTable sysMod(table=[0,1; 60,1; 61,2; 120,2;
        121,3; 180,3; 181,4; 240,4; 241,5; 300,5])
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
equation
  connect(sysMod.y, coilValveOnOff.u)
    annotation (Line(points={{-39,0},{-12,0},{-12,0}}, color={255,127,0}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the on/off controller of the cooling coil valve.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file(inherit=true) =
        "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/CoilValveOnOff.mos"
        "Simulate and Plot"));
end CoilValveOnOff;

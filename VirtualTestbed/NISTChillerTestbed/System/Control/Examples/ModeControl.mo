within VirtualTestbed.NISTChillerTestbed.System.Control.Examples;
model ModeControl
  import VirtualTestbed;
  extends Modelica.Icons.Example;
  VirtualTestbed.NISTChillerTestbed.System.Control.ModeControl stoCon
    annotation (Placement(transformation(extent={{-10,-12},{10,8}})));
  Modelica.Blocks.Sources.BooleanTable occ(startValue=false, table={1800,3600,
        5400,7200}) "Occupied schedule"
    annotation (Placement(transformation(extent={{-60,20},{-40,40}})));
  Modelica.Blocks.Sources.TimeTable SOC(startTime=0, table=[0.0,0.5; 1800,0.9;
        3600,0; 5400,0.4; 6500,0; 7200,0])
    annotation (Placement(transformation(extent={{-60,-12},{-40,8}})));
equation
  connect(occ.y, stoCon.Occupied) annotation (Line(points={{-39,30},{-26,30},{
          -26,6},{-12,6}}, color={255,0,255}));
  connect(SOC.y, stoCon.SOC)
    annotation (Line(points={{-39,-2},{-12,-2}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    Documentation(info="<html>
<p>This example is to validate the mode controller based on the storage-priority control strategy.</p>
</html>", revisions="<html>
<p>April 2021, Guowen Li First implementation.</p>
</html>"),
    __Dymola_Commands(file=
          "modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/Control/Examples/ModeControl.mos"
        "Simulate and Plot"));
end ModeControl;

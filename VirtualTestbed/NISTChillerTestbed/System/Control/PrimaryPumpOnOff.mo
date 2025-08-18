within VirtualTestbed.NISTChillerTestbed.System.Control;
model PrimaryPumpOnOff
  Modelica.Blocks.Interfaces.IntegerInput u
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealOutput y "Real output signal"
    annotation (Placement(transformation(extent={{100,-20},{140,20}}),
        iconTransformation(extent={{100,-20},{140,20}})));
  Buildings.Controls.OBC.CDL.Integers.GreaterThreshold onPum(threshold=1)
    annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
  Modelica.Blocks.Math.BooleanToReal booToRea
    annotation (Placement(transformation(extent={{20,-10},{40,10}})));
equation
  connect(u, onPum.u)
    annotation (Line(points={{-120,0},{-42,0}}, color={255,127,0}));
  connect(onPum.y, booToRea.u)
    annotation (Line(points={{-18,0},{18,0}}, color={255,0,255}));
  connect(booToRea.y, y)
    annotation (Line(points={{41,0},{80,0},{80,0},{120,0}}, color={0,0,127}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
                                        Text(
        extent={{-148,150},{152,110}},
        textString="%name",
        lineColor={0,0,255}),   Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid)}), Diagram(coordinateSystem(
          preserveAspectRatio=false)));
end PrimaryPumpOnOff;

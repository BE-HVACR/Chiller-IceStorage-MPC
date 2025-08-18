within VirtualTestbed.NISTChillerTestbed.System.Control;
model CoilValveOnOff
  Modelica.Blocks.Interfaces.IntegerInput u
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Buildings.Controls.OBC.CDL.Integers.LessThreshold off(threshold=5)
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
  Modelica.Blocks.Math.BooleanToReal booToRea
    annotation (Placement(transformation(extent={{0,-10},{20,10}})));
  Modelica.Blocks.Interfaces.RealOutput y "Connector of Real output signal"
    annotation (Placement(transformation(extent={{100,-10},{120,10}})));
equation
  connect(off.y, booToRea.u)
    annotation (Line(points={{-38,0},{-2,0}}, color={255,0,255}));
  connect(booToRea.y, y)
    annotation (Line(points={{21,0},{110,0}}, color={0,0,127}));
  connect(u, off.u)
    annotation (Line(points={{-120,0},{-62,0}}, color={255,127,0}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
                                Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid), Text(
        extent={{-148,150},{152,110}},
        textString="%name",
        lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=
            false)));
end CoilValveOnOff;

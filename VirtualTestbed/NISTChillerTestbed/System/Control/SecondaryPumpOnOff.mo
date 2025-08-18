within VirtualTestbed.NISTChillerTestbed.System.Control;
model SecondaryPumpOnOff
  Modelica.Blocks.Interfaces.IntegerInput u
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Buildings.Controls.OBC.CDL.Interfaces.RealOutput y "Real output signal"
    annotation (Placement(transformation(extent={{100,-20},{140,20}}),
        iconTransformation(extent={{100,-20},{140,20}})));
  Buildings.Controls.OBC.CDL.Integers.GreaterThreshold on(threshold=1)
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
  Buildings.Controls.OBC.CDL.Logical.Switch swi
    annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant uti(k=1)
    annotation (Placement(transformation(extent={{-80,40},{-60,60}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant zer(k=0)
    annotation (Placement(transformation(extent={{-80,-60},{-60,-40}})));
  Buildings.Controls.OBC.CDL.Integers.LessThreshold les(threshold=5)
    annotation (Placement(transformation(extent={{0,20},{20,40}})));
  Buildings.Controls.OBC.CDL.Logical.Switch swi1
    annotation (Placement(transformation(extent={{60,-10},{80,10}})));
equation
  connect(u, on.u)
    annotation (Line(points={{-120,0},{-82,0}}, color={255,127,0}));
  connect(on.y, swi.u2)
    annotation (Line(points={{-58,0},{-42,0}}, color={255,0,255}));
  connect(uti.y, swi.u1) annotation (Line(points={{-58,50},{-50,50},{-50,8},{
          -42,8}}, color={0,0,127}));
  connect(zer.y, swi.u3) annotation (Line(points={{-58,-50},{-50,-50},{-50,-8},
          {-42,-8}}, color={0,0,127}));
  connect(u, les.u) annotation (Line(points={{-120,0},{-90,0},{-90,30},{-2,30}},
        color={255,127,0}));
  connect(les.y, swi1.u2) annotation (Line(points={{22,30},{40,30},{40,0},{58,0}},
        color={255,0,255}));
  connect(swi.y, swi1.u1)
    annotation (Line(points={{-18,0},{32,0},{32,8},{58,8}}, color={0,0,127}));
  connect(zer.y, swi1.u3) annotation (Line(points={{-58,-50},{40,-50},{40,-8},{
          58,-8}}, color={0,0,127}));
  connect(swi1.y, y)
    annotation (Line(points={{82,0},{94,0},{94,0},{120,0}}, color={0,0,127}));
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
end SecondaryPumpOnOff;

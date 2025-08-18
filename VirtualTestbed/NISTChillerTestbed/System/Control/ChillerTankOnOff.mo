within VirtualTestbed.NISTChillerTestbed.System.Control;
model ChillerTankOnOff "Chiller and tank on/off control"
  Modelica.Blocks.Interfaces.IntegerInput u
    annotation (Placement(transformation(extent={{-140,-20},{-100,20}})));
  Modelica.Blocks.Tables.CombiTable1Ds combiTable1Ds(table=[1,1,0; 2,3,1; 3,3,0;
        4,1,1; 5,2,1])
    annotation (Placement(transformation(extent={{-40,-10},{-20,10}})));
  Buildings.Controls.OBC.CDL.Conversions.IntegerToReal intToRea
    annotation (Placement(transformation(extent={{-80,-10},{-60,10}})));
  Modelica.Blocks.Math.RealToBoolean chiOn
    annotation (Placement(transformation(extent={{20,-40},{40,-20}})));
  Modelica.Blocks.Math.RealToInteger tanMod
    annotation (Placement(transformation(extent={{20,20},{40,40}})));
  Modelica.Blocks.Interfaces.IntegerOutput modTan
    "Connector of Integer output signal"
    annotation (Placement(transformation(extent={{100,20},{120,40}})));
  Modelica.Blocks.Interfaces.BooleanOutput onChi
    "Connector of Boolean output signal"
    annotation (Placement(transformation(extent={{100,-40},{120,-20}})));
equation
  connect(u, intToRea.u)
    annotation (Line(points={{-120,0},{-82,0}}, color={255,127,0}));
  connect(intToRea.y, combiTable1Ds.u)
    annotation (Line(points={{-58,0},{-42,0}}, color={0,0,127}));
  connect(combiTable1Ds.y[2], chiOn.u) annotation (Line(points={{-19,0},{4,0},{
          4,-30},{18,-30}}, color={0,0,127}));
  connect(combiTable1Ds.y[1], tanMod.u)
    annotation (Line(points={{-19,0},{4,0},{4,30},{18,30}}, color={0,0,127}));
  connect(tanMod.y, modTan)
    annotation (Line(points={{41,30},{110,30}}, color={255,127,0}));
  connect(chiOn.y, onChi)
    annotation (Line(points={{41,-30},{110,-30}}, color={255,0,255}));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false), graphics={
                                Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid), Text(
        extent={{-148,150},{152,110}},
        textString="%name",
        lineColor={0,0,255})}),                                  Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end ChillerTankOnOff;

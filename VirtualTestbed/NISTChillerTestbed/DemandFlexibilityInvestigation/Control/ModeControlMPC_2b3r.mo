within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control;
model ModeControlMPC_2b3r "Storage mode controller"

  parameter Modelica.SIunits.Time waiTim=0
    "Wait time before transition fires";

  Modelica.Blocks.Interfaces.IntegerOutput y "Connector of Integer output signal" annotation (Placement(
        transformation(extent={{100,-10},{120,10}}), iconTransformation(extent={
            {100,-10},{120,10}})));
  Modelica.StateGraph.StepWithSignal Charging(nIn=4, nOut=4) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-6,22})));
  Modelica.StateGraph.InitialStepWithSignal Off(nIn=4, nOut=4) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-6,68})));
  Modelica.StateGraph.StepWithSignal DischargingStorage(nIn=4, nOut=4)
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-6,-18})));
  Modelica.StateGraph.Transition ToCha[4](
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true and bi == true and Tchi < 273.15 + 0 and Tchi >=
        273.15 - 5) "to ChargingStorage mode"                annotation (
      Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-40,40})));
  Modelica.StateGraph.Transition ChaToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false and bi == false)
                            "Charging mode to Off mode" annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={14,44})));
  Modelica.StateGraph.Transition ToDisSto[4](
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false and bi == true) "to DischargingStorage mode"
                                 annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-50,-4})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntCha(
    final integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.ChargingStorage))
    annotation (Placement(transformation(extent={{50,12},{70,32}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisSto(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.DischargingStorage))
    annotation (Placement(transformation(extent={{50,-20},{70,0}})));
  Buildings.Controls.OBC.CDL.Integers.MultiSum mulSumInt(
    nin=5)
    annotation (Placement(transformation(extent={{76,-10},{96,10}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntOff(
    final integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.Off))
    annotation (Placement(transformation(extent={{50,58},{70,78}})));
  Modelica.Blocks.Interfaces.BooleanInput bc
    annotation (Placement(transformation(extent={{-140,60},{-100,100}})));

  Modelica.Blocks.Interfaces.RealInput SOC(unit="1") "soc" annotation (
      Placement(transformation(extent={{-140,-60},{-100,-20}}),
        iconTransformation(extent={{-140,-20},{-100,20}})));
  Modelica.StateGraph.StepWithSignal DischargingChiller(nIn=4, nOut=4)
  annotation (Placement(transformation(
      extent={{10,-10},{-10,10}},
      rotation=90,
      origin={-6,-56})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisChi(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.DischargingChiller))
    annotation (Placement(transformation(extent={{50,-56},{70,-36}})));
  Modelica.StateGraph.Transition DischaToOff[2](
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false and bi == false) "Discharging mode to off mode"
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={34,-64})));
  Modelica.StateGraph.Transition DisStoToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false and bi == false)
    "Dischargingstorage mode to off mode"                        annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={24,-36})));
  Modelica.Blocks.Interfaces.BooleanInput bi
    annotation (Placement(transformation(extent={{-140,30},{-100,70}})));
  Modelica.Blocks.Interfaces.RealInput Tchi(final quantity=
        "ThermodynamicTemperatrue", final unit="K")        annotation (
      Placement(transformation(extent={{-140,-90},{-100,-50}}),
        iconTransformation(extent={{-140,-90},{-100,-50}})));
  Modelica.StateGraph.Transition ToDisChi[4](
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true and bi == false) "to DischargingChiller mode"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-60,-38})));
  Modelica.StateGraph.StepWithSignal DischargingBoth(nOut=4, nIn=4) annotation (
     Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-6,-86})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisBot(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.DischargingBoth))
    "DischargingBoth Mode"
    annotation (Placement(transformation(extent={{50,-96},{70,-76}})));
  Modelica.StateGraph.Transition ToDisBot[4](
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true and bi == true and Tchi >= 273.15 + 0 and Tchi <=
        273.15 + 10)                "to dischargingBoth mode" annotation (
      Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-82,-70})));
equation
  connect(Charging.outPort[2], ChaToOff.inPort) annotation (Line(points={{-6.125,
          11.5},{-6.125,2},{14,2},{14,40}},     color={0,0,0}));
  connect(ChaToOff.outPort, Off.inPort[1]) annotation (Line(points={{14,45.5},
          {14,84},{-6.75,84},{-6.75,79}},
                                      color={0,0,0}));
  connect(booToIntOff.y, mulSumInt.u[1]) annotation (Line(points={{72,68},{
          72,5.6},{74,5.6}},          color={255,127,0}));
  connect(booToIntCha.y, mulSumInt.u[2])
    annotation (Line(points={{72,22},{72,2.8},{74,2.8}},   color={255,127,0}));
  connect(booToIntDisSto.y, mulSumInt.u[3]) annotation (Line(points={{72,-10},{72,
          0},{74,0}},            color={255,127,0}));
  connect(mulSumInt.y, y)
    annotation (Line(points={{98,0},{110,0}}, color={255,127,0}));
  connect(Off.active, booToIntOff.u) annotation (Line(points={{5,68},{48,68}},
                        color={255,0,255}));
  connect(Charging.active, booToIntCha.u)
    annotation (Line(points={{5,22},{48,22}},
                                            color={255,0,255}));
  connect(DischargingStorage.active, booToIntDisSto.u)
    annotation (Line(points={{5,-18},{30,-18},{30,-10},{48,-10}},
                                                color={255,0,255}));
  connect(DischargingChiller.active, booToIntDisChi.u)
    annotation (Line(points={{5,-56},{28,-56},{28,-46},{48,-46}},
                                                color={255,0,255}));
  connect(booToIntDisChi.y, mulSumInt.u[4]) annotation (Line(points={{72,-46},{72,
          -46},{74,-46},{74,-2.8}},
                               color={255,127,0}));
  connect(DischargingStorage.outPort[2], DisStoToOff.inPort) annotation (Line(
        points={{-6.125,-28.5},{-6,-28.5},{-6,-40},{24,-40}},
                                                    color={0,0,0}));
  connect(DisStoToOff.outPort, Off.inPort[2]) annotation (Line(points={{24,
          -34.5},{24,84},{-6.25,84},{-6.25,79}},
                                             color={0,0,0}));
  connect(booToIntDisBot.y, mulSumInt.u[5]) annotation (Line(points={{72,
          -86},{74,-86},{74,-5.6}}, color={255,127,0}));
  connect(DischargingBoth.active, booToIntDisBot.u)
    annotation (Line(points={{5,-86},{48,-86}}, color={255,0,255}));
  connect(DischargingBoth.outPort[4], DischaToOff[2].inPort) annotation (Line(
        points={{-5.625,-96.5},{16,-96.5},{16,-96},{34,-96},{34,-68}},
        color={0,0,0}));
  connect(DischargingChiller.outPort[1], DischaToOff[1].inPort) annotation (
      Line(points={{-6.375,-66.5},{-6.375,-68},{34,-68}},          color={0,0,0}));
  connect(DischaToOff[1].outPort, Off.inPort[3]) annotation (Line(points={{
          34,-62.5},{34,84},{-5.75,84},{-5.75,79}}, color={0,0,0}));
  connect(DischaToOff[2].outPort, Off.inPort[4]) annotation (Line(points={{
          34,-62.5},{34,84},{-5.25,84},{-5.25,79}}, color={0,0,0}));
  connect(Off.outPort[4], ToDisBot[1].inPort) annotation (Line(points={{
          -5.625,57.5},{-74,57.5},{-74,56},{-82,56},{-82,-66}}, color={0,0,
          0}));
  connect(ToDisBot[1].outPort, DischargingBoth.inPort[1]) annotation (Line(
        points={{-82,-71.5},{-82,-72},{-6,-72},{-6,-74},{-6.75,-74},{-6.75,
          -75}}, color={0,0,0}));
  connect(ToDisBot[2].outPort, DischargingBoth.inPort[2]) annotation (Line(
        points={{-82,-71.5},{-82,-72},{-6.25,-72},{-6.25,-75}}, color={0,0,
          0}));
  connect(ToDisBot[3].outPort, DischargingBoth.inPort[3]) annotation (Line(
        points={{-82,-71.5},{-82,-72},{-5.75,-72},{-5.75,-75}}, color={0,0,
          0}));
  connect(ToDisBot[4].outPort, DischargingBoth.inPort[4]) annotation (Line(
        points={{-82,-71.5},{-82,-72},{-5.25,-72},{-5.25,-75}}, color={0,0,
          0}));
  connect(Charging.outPort[4], ToDisBot[2].inPort) annotation (Line(points=
          {{-5.625,11.5},{-74,11.5},{-74,6},{-82,6},{-82,-66}}, color={0,0,
          0}));
  connect(DischargingStorage.outPort[4], ToDisBot[3].inPort) annotation (
      Line(points={{-5.625,-28.5},{-74,-28.5},{-74,-26},{-82,-26},{-82,-66}},
        color={0,0,0}));
  connect(DischargingChiller.outPort[4], ToDisBot[4].inPort) annotation (
      Line(points={{-5.625,-66.5},{-74,-66.5},{-74,-66},{-82,-66}}, color={
          0,0,0}));
  connect(DischargingBoth.outPort[1], ToDisChi[4].inPort) annotation (Line(
        points={{-6.375,-96.5},{-6,-96.5},{-6,-96},{-38,-96},{-38,-34},{-60,
          -34}}, color={0,0,0}));
  connect(ToDisChi[1].outPort, DischargingChiller.inPort[1]) annotation (
      Line(points={{-60,-39.5},{-34,-39.5},{-34,-45},{-6.75,-45}}, color={0,
          0,0}));
  connect(ToDisChi[2].outPort, DischargingChiller.inPort[2]) annotation (
      Line(points={{-60,-39.5},{-34,-39.5},{-34,-45},{-6.25,-45}}, color={0,
          0,0}));
  connect(ToDisChi[3].outPort, DischargingChiller.inPort[3]) annotation (
      Line(points={{-60,-39.5},{-34,-39.5},{-34,-45},{-5.75,-45}}, color={0,
          0,0}));
  connect(ToDisChi[4].outPort, DischargingChiller.inPort[4]) annotation (
      Line(points={{-60,-39.5},{-34,-39.5},{-34,-45},{-5.25,-45}}, color={0,
          0,0}));
  connect(Off.outPort[3], ToDisChi[1].inPort) annotation (Line(points={{
          -5.875,57.5},{-60,57.5},{-60,-34}}, color={0,0,0}));
  connect(Charging.outPort[3], ToDisChi[2].inPort) annotation (Line(points=
          {{-5.875,11.5},{-60,11.5},{-60,-34}}, color={0,0,0}));
  connect(DischargingStorage.outPort[1], ToDisChi[3].inPort) annotation (
      Line(points={{-6.375,-28.5},{-60,-28.5},{-60,-34}}, color={0,0,0}));
  connect(Off.outPort[2], ToDisSto[1].inPort) annotation (Line(points={{
          -6.125,57.5},{-50,57.5},{-50,0}}, color={0,0,0}));
  connect(Charging.outPort[1], ToDisSto[2].inPort) annotation (Line(points=
          {{-6.375,11.5},{-6,11.5},{-6,0},{-50,0}}, color={0,0,0}));
  connect(DischargingChiller.outPort[2], ToDisSto[3].inPort) annotation (
      Line(points={{-6.125,-66.5},{-28,-66.5},{-28,0},{-50,0},{-50,0}},
        color={0,0,0}));
  connect(DischargingBoth.outPort[3], ToDisSto[4].inPort) annotation (Line(
        points={{-5.875,-96.5},{-16,-96.5},{-16,-96},{-28,-96},{-28,0},{-50,
          0}}, color={0,0,0}));
  connect(ToDisSto[1].outPort, DischargingStorage.inPort[1]) annotation (
      Line(points={{-50,-5.5},{-28,-5.5},{-28,-7},{-6.75,-7}}, color={0,0,0}));
  connect(ToDisSto[2].outPort, DischargingStorage.inPort[2]) annotation (
      Line(points={{-50,-5.5},{-28,-5.5},{-28,-7},{-6.25,-7}}, color={0,0,0}));
  connect(ToDisSto[3].outPort, DischargingStorage.inPort[3]) annotation (
      Line(points={{-50,-5.5},{-28,-5.5},{-28,-7},{-5.75,-7}}, color={0,0,0}));
  connect(ToDisSto[4].outPort, DischargingStorage.inPort[4]) annotation (
      Line(points={{-50,-5.5},{-28,-5.5},{-28,-7},{-5.25,-7}}, color={0,0,0}));
  connect(Off.outPort[1], ToCha[1].inPort) annotation (Line(points={{-6.375,
          57.5},{-40,57.5},{-40,44}}, color={0,0,0}));
  connect(DischargingStorage.outPort[3], ToCha[2].inPort) annotation (Line(
        points={{-5.875,-28.5},{-22,-28.5},{-22,44},{-40,44}}, color={0,0,0}));
  connect(DischargingChiller.outPort[3], ToCha[3].inPort) annotation (Line(
        points={{-5.875,-66.5},{-22,-66.5},{-22,44},{-40,44}}, color={0,0,0}));
  connect(DischargingBoth.outPort[2], ToCha[4].inPort) annotation (Line(
        points={{-6.125,-96.5},{-22,-96.5},{-22,44},{-40,44}}, color={0,0,0}));
  connect(ToCha[1].outPort, Charging.inPort[1]) annotation (Line(points={{
          -40,38.5},{-18,38.5},{-18,33},{-6.75,33}}, color={0,0,0}));
  connect(ToCha[2].outPort, Charging.inPort[2]) annotation (Line(points={{
          -40,38.5},{-18,38.5},{-18,33},{-6.25,33}}, color={0,0,0}));
  connect(ToCha[3].outPort, Charging.inPort[3]) annotation (Line(points={{
          -40,38.5},{-18,38.5},{-18,33},{-5.75,33}}, color={0,0,0}));
  connect(ToCha[4].outPort, Charging.inPort[4]) annotation (Line(points={{
          -40,38.5},{-18,38.5},{-18,33},{-5.25,33}}, color={0,0,0}));
  annotation (defaultComponentName="stoCon",
  Icon(coordinateSystem(preserveAspectRatio=false), graphics={
                                Rectangle(
        extent={{-100,-100},{100,100}},
        lineColor={0,0,127},
        fillColor={255,255,255},
        fillPattern=FillPattern.Solid), Text(
        extent={{-148,150},{152,110}},
        textString="%name",
        lineColor={0,0,255})}), Diagram(coordinateSystem(preserveAspectRatio=false)));
end ModeControlMPC_2b3r;

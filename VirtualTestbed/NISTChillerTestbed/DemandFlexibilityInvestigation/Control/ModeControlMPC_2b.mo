within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control;
model ModeControlMPC_2b "Storage mode controller"

  parameter Modelica.SIunits.Time waiTim=0
    "Wait time before transition fires";

  Modelica.Blocks.Interfaces.IntegerOutput y "Connector of Integer output signal" annotation (Placement(
        transformation(extent={{100,-10},{120,10}}), iconTransformation(extent={
            {100,-10},{120,10}})));
  Modelica.StateGraph.StepWithSignal Charging(nIn=1, nOut=1) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-6,22})));
  Modelica.StateGraph.InitialStepWithSignal Off(nIn=3, nOut=3) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-6,68})));
  Modelica.StateGraph.StepWithSignal DischargingStorage(nIn=1, nOut=1)
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-6,-18})));
  Modelica.StateGraph.Transition ToCha(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true and bi == true and SOC <= 0.99)
    "to ChargingStorage mode" annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-40,40})));
  Modelica.StateGraph.Transition ChaToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false or bi == false or SOC > 0.99)
                            "Charging mode to Off mode" annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={14,44})));
  Modelica.StateGraph.Transition ToDisSto(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false and bi == true and SOC > 0.01)
                                          "to DischargingStorage mode"
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
    nin=4)
    annotation (Placement(transformation(extent={{76,-10},{96,10}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntOff(
    final integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.Off))
    annotation (Placement(transformation(extent={{50,58},{70,78}})));
  Modelica.Blocks.Interfaces.BooleanInput bc
    annotation (Placement(transformation(extent={{-140,60},{-100,100}})));

  Modelica.Blocks.Interfaces.RealInput SOC(unit="1") "soc" annotation (
      Placement(transformation(extent={{-140,-60},{-100,-20}}),
        iconTransformation(extent={{-140,-20},{-100,20}})));
  Modelica.StateGraph.StepWithSignal DischargingChiller(nIn=1, nOut=1)
  annotation (Placement(transformation(
      extent={{10,-10},{-10,10}},
      rotation=90,
      origin={-6,-56})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisChi(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.DischargingChiller))
    annotation (Placement(transformation(extent={{50,-56},{70,-36}})));
  Modelica.StateGraph.Transition DisStoToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true or bi == false or SOC <= 0.01)
                          "Dischargingstorage mode to off mode"  annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={24,-36})));
  Modelica.Blocks.Interfaces.BooleanInput bi
    annotation (Placement(transformation(extent={{-140,30},{-100,70}})));
  Modelica.StateGraph.Transition ToDisChi(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == true and bi == false) "to DischargingChiller mode"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-68,-38})));
  Modelica.StateGraph.Transition DisChiToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=bc == false or bi == true)
    "DischargingChiller mode to Off mode" annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={36,-76})));
equation
  connect(Charging.outPort[1], ChaToOff.inPort) annotation (Line(points={{-6,11.5},
          {-6,2},{14,2},{14,40}},               color={0,0,0}));
  connect(booToIntOff.y, mulSumInt.u[1]) annotation (Line(points={{72,68},{72,5.25},
          {74,5.25}},                 color={255,127,0}));
  connect(booToIntCha.y, mulSumInt.u[2])
    annotation (Line(points={{72,22},{72,1.75},{74,1.75}}, color={255,127,0}));
  connect(booToIntDisSto.y, mulSumInt.u[3]) annotation (Line(points={{72,-10},{72,
          -1.75},{74,-1.75}},    color={255,127,0}));
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
          -46},{74,-46},{74,-5.25}},
                               color={255,127,0}));
  connect(DischargingStorage.outPort[1], DisStoToOff.inPort) annotation (Line(
        points={{-6,-28.5},{-6,-28.5},{-6,-40},{24,-40}},
                                                    color={0,0,0}));
  connect(DisStoToOff.outPort, Off.inPort[2]) annotation (Line(points={{24,-34.5},
          {24,84},{-6,84},{-6,79}},          color={0,0,0}));
  connect(Off.outPort[3], ToDisChi.inPort) annotation (Line(points={{-5.66667,
          57.5},{-68,57.5},{-68,-34}},        color={0,0,0}));
  connect(Off.outPort[2], ToDisSto.inPort) annotation (Line(points={{-6,57.5},
          {-50,57.5},{-50,0}},              color={0,0,0}));
  connect(Off.outPort[1], ToCha.inPort) annotation (Line(points={{-6.33333,57.5},
          {-40,57.5},{-40,44}},       color={0,0,0}));
  connect(DischargingChiller.outPort[1], DisChiToOff.inPort)
    annotation (Line(points={{-6,-66.5},{-6,-80},{36,-80}}, color={0,0,0}));
  connect(DisChiToOff.outPort, Off.inPort[3]) annotation (Line(points={{36,-74.5},
          {40,-74.5},{40,84},{-4,84},{-4,80},{-5.33333,80},{-5.33333,79}},
        color={0,0,0}));
  connect(ChaToOff.outPort, Off.inPort[1]) annotation (Line(points={{14,45.5},{14,
          84},{-8,84},{-8,79},{-6.66667,79}}, color={0,0,0}));
  connect(ToDisChi.outPort, DischargingChiller.inPort[1])
    annotation (Line(points={{-68,-39.5},{-68,-45},{-6,-45}}, color={0,0,0}));
  connect(ToDisSto.outPort, DischargingStorage.inPort[1]) annotation (Line(
        points={{-50,-5.5},{-28,-5.5},{-28,-7},{-6,-7}}, color={0,0,0}));
  connect(ToCha.outPort, Charging.inPort[1]) annotation (Line(points={{-40,38.5},
          {-24,38.5},{-24,33},{-6,33}}, color={0,0,0}));
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
end ModeControlMPC_2b;

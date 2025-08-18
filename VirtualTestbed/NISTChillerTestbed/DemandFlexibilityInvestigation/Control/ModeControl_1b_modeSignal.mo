within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Control;
model ModeControl_1b_modeSignal "Storage mode controller"

  parameter Modelica.SIunits.Time waiTim=0
    "Wait time before transition fires";

  Modelica.Blocks.Interfaces.IntegerOutput y "Connector of Integer output signal" annotation (Placement(
        transformation(extent={{100,-10},{120,10}}), iconTransformation(extent={
            {100,-10},{120,10}})));
  Modelica.StateGraph.StepWithSignal Charging(nIn=2, nOut=2) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-10,0})));
  Modelica.StateGraph.InitialStepWithSignal Off(nOut=3, nIn=3) annotation (
      Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=-90,
        origin={-10,50})));
  Modelica.StateGraph.StepWithSignal DischargingStorage(nIn=2, nOut=2)
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-10,-36})));
  Modelica.StateGraph.Transition OffToCha(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod == -1 and SOC < 0.99) "Off to charging mode" annotation (
      Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-40,22})));
  Modelica.StateGraph.Transition ChaToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod <> -1 or SOC >= 0.99)
                            "Charging mode to Off mode" annotation (Placement(
        transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={12,22})));
  Modelica.StateGraph.Transition OffToDisTES(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod == 1 and SOC > 0.1) "Off to discharging TES mode"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-60,-4})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntCha(
    final integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.System.Types.SystemMode.ChargingStorage))
    annotation (Placement(transformation(extent={{48,-10},{68,10}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisSto(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.System.Types.SystemMode.DischargingStorage))
    annotation (Placement(transformation(extent={{48,-46},{68,-26}})));
  Buildings.Controls.OBC.CDL.Integers.MultiSum mulSumInt(
    nin=4)
    annotation (Placement(transformation(extent={{76,-10},{96,10}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntOff(
    final integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.System.Types.SystemMode.Off))
    annotation (Placement(transformation(extent={{48,40},{68,60}})));
  Modelica.Blocks.Interfaces.IntegerInput uMod
    "operation mode (0: off; 1: Charge TES; 2: Discharge TES; 3: Discharge chiller) "
    annotation (Placement(transformation(extent={{-140,60},{-100,100}})));

  Modelica.Blocks.Interfaces.RealInput SOC(unit="1") "soc" annotation (
      Placement(transformation(extent={{-140,-60},{-100,-20}}),
        iconTransformation(extent={{-140,-20},{-100,20}})));
  Modelica.StateGraph.StepWithSignal DischargingChiller(nIn=2, nOut=2)
  annotation (Placement(transformation(
      extent={{10,-10},{-10,10}},
      rotation=90,
      origin={-10,-74})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToInteger booToIntDisChi(final
      integerFalse=0, final integerTrue=Integer(VirtualTestbed.NISTChillerTestbed.System.Types.SystemMode.DischargingChiller))
    annotation (Placement(transformation(extent={{48,-84},{68,-64}})));
  Modelica.StateGraph.Transition DisStoToDisChi(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod == 2) "discharging storage to discharging chiller"
    annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={-80,-48})));
  Modelica.StateGraph.Transition DisChiToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod <> 2) "Dischargingchiller mode to off mode" annotation (
      Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={28,-56})));
  Modelica.StateGraph.Transition DisStoToOff(
    enableTimer=true,
    waitTime=waiTim,
    condition=uMod <> 1 or SOC <= 0.1) "Dischargingstorage mode to off mode"
    annotation (Placement(transformation(
        extent={{-10,-10},{10,10}},
        rotation=90,
        origin={18,-20})));
equation
  connect(Off.outPort[1], OffToCha.inPort) annotation (Line(points={{-10.3333,
          39.5},{-10.3333,40},{-40,40},{-40,26}},
                                          color={0,0,0}));
  connect(Off.outPort[2], OffToDisTES.inPort) annotation (Line(points={{-10,
          39.5},{-10,40},{-60,40},{-60,0}}, color={0,0,0}));
  connect(OffToCha.outPort, Charging.inPort[1]) annotation (Line(points={{-40,20.5},
          {-40,14},{-10.5,14},{-10.5,11}}, color={0,0,0}));
  connect(Charging.outPort[2], ChaToOff.inPort) annotation (Line(points={{-9.75,
          -10.5},{-9.75,-10},{12,-10},{12,18}}, color={0,0,0}));
  connect(ChaToOff.outPort, Off.inPort[1]) annotation (Line(points={{12,23.5},{
          12,66},{-10.6667,66},{-10.6667,61}},
                                      color={0,0,0}));
  connect(OffToDisTES.outPort, DischargingStorage.inPort[2]) annotation (Line(
        points={{-60,-5.5},{-60,-24},{-9.5,-24},{-9.5,-25}}, color={0,0,0}));
  connect(booToIntOff.y, mulSumInt.u[1]) annotation (Line(points={{70,50},
        {72,50},{72,5.25},{74,5.25}}, color={255,127,0}));
  connect(booToIntCha.y, mulSumInt.u[2])
    annotation (Line(points={{70,0},{72,0},{72,1.75},{74,1.75}},
                                                           color={255,127,0}));
  connect(booToIntDisSto.y, mulSumInt.u[3]) annotation (Line(points={{70,-36},{
          70,-1.75},{74,-1.75}}, color={255,127,0}));
  connect(mulSumInt.y, y)
    annotation (Line(points={{98,0},{110,0}}, color={255,127,0}));
  connect(Off.active, booToIntOff.u) annotation (Line(points={{1,50},{
        46,50}},        color={255,0,255}));
  connect(Charging.active, booToIntCha.u)
    annotation (Line(points={{1,0},{46,0}}, color={255,0,255}));
  connect(DischargingStorage.active, booToIntDisSto.u)
    annotation (Line(points={{1,-36},{46,-36}}, color={255,0,255}));
  connect(DischargingChiller.active, booToIntDisChi.u)
    annotation (Line(points={{1,-74},{46,-74}}, color={255,0,255}));
  connect(booToIntDisChi.y, mulSumInt.u[4]) annotation (Line(points={{70,-74},{
          74,-74},{74,-5.25}}, color={255,127,0}));
  connect(DisStoToDisChi.outPort, DischargingChiller.inPort[1]) annotation (
      Line(points={{-80,-49.5},{-80,-63},{-10.5,-63}}, color={0,0,0}));
  connect(DischargingChiller.outPort[1], DisChiToOff.inPort) annotation (Line(
        points={{-10.25,-84.5},{28,-84.5},{28,-60}},                   color={0,
          0,0}));
  connect(DisChiToOff.outPort, Off.inPort[3]) annotation (Line(points={{28,
          -54.5},{28,80},{-9.33333,80},{-9.33333,61}}, color={0,0,0}));
  connect(DischargingStorage.outPort[2], DisStoToOff.inPort) annotation (Line(
        points={{-9.75,-46.5},{18,-46.5},{18,-24}}, color={0,0,0}));
  connect(DisStoToOff.outPort, Off.inPort[2]) annotation (Line(points={{18,
          -18.5},{18,74},{-10,74},{-10,61}}, color={0,0,0}));
  connect(Off.outPort[3], DisStoToDisChi.inPort) annotation (Line(points={{
          -9.66667,39.5},{-10,39.5},{-10,40},{-80,40},{-80,-44}}, color={0,0,0}));
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
end ModeControl_1b_modeSignal;

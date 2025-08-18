within VirtualTestbed.NISTChillerTestbed.System.CoSimulationHIL;
model Baseline
  "Variable air volume flow system with terminal reheat and five thermal zones"
  //extends Modelica.Icons.Example;
  extends CoSimulationHIL.BaseClasses.PartialOpenLoop(
    cooCoi(m1_flow_nominal=m2_flow_chi_nominal, dp1_nominal=100000),
    flo(
      cor(T_start=297.15),
      sou(T_start=297.15),
      eas(T_start=297.15),
      nor(T_start=297.15),
      m_flow_nominal_nor=mNor_flow_nominal,
      m_flow_nominal_cor=mCor_flow_nominal,
      m_flow_nominal_sou=mSou_flow_nominal,
      m_flow_nominal_eas=mEas_flow_nominal),
    weaDat(filNam=ModelicaServices.ExternalReferences.loadResource(
      "modelica://VirtualTestbed/Resources/weatherdata/USA_GA_Atlanta-Hartsfield-Jackson.Intl.AP.722190_TMY3.mos")),
    occSch(occupancy=3600*{5,21}));

  parameter Modelica.SIunits.VolumeFlowRate VPriSysMax_flow=m_flow_nominal/1.2
    "Maximum expected system primary airflow rate at design stage";
  parameter Modelica.SIunits.VolumeFlowRate minZonPriFlo[numZon]={
      mCor_flow_nominal,mSou_flow_nominal,mEas_flow_nominal,mNor_flow_nominal}/1.2 "Minimum expected zone primary flow rate";
  parameter Modelica.SIunits.Time samplePeriod=120
    "Sample period of component, set to the same value as the trim and respond that process yPreSetReq";
  parameter Modelica.SIunits.PressureDifference dpDisRetMax=40
    "Maximum return fan discharge static pressure setpoint";

   parameter Modelica.SIunits.MassFlowRate m1_flow_chi_nominal= -QEva_nominal*(1+1/COP_nominal)/4190/6.5
    "Nominal mass flow rate at condenser water in the chillers";
  parameter Modelica.SIunits.MassFlowRate m2_flow_chi_nominal= QEva_nominal/3915/(5.56-11.56)
    "Nominal mass flow rate at evaporator water in the chillers";
  parameter Modelica.SIunits.PressureDifference dp1_chi_nominal = 46.2*1000
    "Nominal pressure";
  parameter Modelica.SIunits.PressureDifference dp2_chi_nominal = 44.8*1000
    "Nominal pressure";
    parameter Modelica.SIunits.Power QEva_nominal = -45300
    "Nominal cooling capaciaty(Negative means cooling) 45.3 kW for chiller 1 or 65.2 kW for chiller 2";
  parameter Real COP_nominal=4.254 "COP";

 // ice tank parameters
   parameter Modelica.SIunits.Mass mIce_max=2846.35
    "Nominal mass of ice in the tank";
  parameter Modelica.SIunits.Mass mIce_start=0.1*mIce_max
    "Start value of ice mass in the tank";

 // primary pumps
   parameter Buildings.Fluid.Movers.Data.Generic perPumPri(
    each pressure=Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters(
          V_flow=m2_flow_chi_nominal/1000*{0.2,0.6,1.0,1.2},
          dp=(dp2_chi_nominal+dp_tan_nominal+139700+6000)*{1.5,1.3,1.0,0.6}))
    "Performance data for primary pumps";

 //secondary pumps
    parameter Buildings.Fluid.Movers.Data.Generic perPumSec(
    each pressure=Buildings.Fluid.Movers.BaseClasses.Characteristics.flowParameters(
          V_flow=m2_flow_chi_nominal/1000*{0.2,0.6,1.0,1.2},
          dp=(100000+12000)*{1.5,1.3,1.0,0.6}))
    "Performance data for primary pumps";

 // control settings
  parameter Modelica.SIunits.Pressure dpSetPoi = 100000+6000
    "Differential pressure setpoint at cooling coil";

  parameter Modelica.SIunits.PressureDifference dp_tan_nominal=100000
    "Pressure difference";

  parameter PerformanceData.Chiller1 perChi(
    QEva_flow_nominal=QEva_nominal,
    COP_nominal=COP_nominal,
    mEva_flow_nominal=m2_flow_chi_nominal,
    mCon_flow_nominal=m1_flow_chi_nominal,
    capFunT={0.7252,0.0003532,-0.00001927,-0.0001164,0.00025,0.0006738})
    annotation (Placement(transformation(extent={{-278,-298},{-258,-278}})));
    Buildings.Controls.OBC.ASHRAE.G36_PR1.TerminalUnits.Controller conVAVCor(
    V_flow_nominal=mCor_flow_nominal/1.2,
    AFlo=AFloCor,
    final samplePeriod=samplePeriod) "Controller for terminal unit corridor"
    annotation (Placement(transformation(extent={{530,32},{550,52}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.TerminalUnits.Controller conVAVSou(
    V_flow_nominal=mSou_flow_nominal/1.2,
    AFlo=AFloSou,
    final samplePeriod=samplePeriod) "Controller for terminal unit south"
    annotation (Placement(transformation(extent={{700,30},{720,50}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.TerminalUnits.Controller conVAVEas(
    V_flow_nominal=mEas_flow_nominal/1.2,
    AFlo=AFloEas,
    final samplePeriod=samplePeriod) "Controller for terminal unit east"
    annotation (Placement(transformation(extent={{880,30},{900,50}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.TerminalUnits.Controller conVAVNor(
    V_flow_nominal=mNor_flow_nominal/1.2,
    AFlo=AFloNor,
    final samplePeriod=samplePeriod) "Controller for terminal unit north"
    annotation (Placement(transformation(extent={{1040,30},{1060,50}})));
  Modelica.Blocks.Routing.Multiplex4 TDis "Discharge air temperatures"
    annotation (Placement(transformation(extent={{220,270},{240,290}})));
  Modelica.Blocks.Routing.Multiplex4 VDis_flow
    "Air flow rate at the terminal boxes"
    annotation (Placement(transformation(extent={{220,230},{240,250}})));
  Buildings.Controls.OBC.CDL.Integers.MultiSum TZonResReq(nin=4)
    "Number of zone temperature requests"
    annotation (Placement(transformation(extent={{300,360},{320,380}})));
  Buildings.Controls.OBC.CDL.Integers.MultiSum PZonResReq(nin=4)
    "Number of zone pressure requests"
    annotation (Placement(transformation(extent={{300,330},{320,350}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant yOutDam(k=1)
    "Outdoor air damper control signal"
    annotation (Placement(transformation(extent={{-40,-20},{-20,0}})));
  Buildings.Controls.OBC.CDL.Logical.Switch swiFreSta "Switch for freeze stat"
    annotation (Placement(transformation(extent={{60,-202},{80,-182}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant freStaSetPoi1(
    final k=273.15 + 3) "Freeze stat for heating coil"
    annotation (Placement(transformation(extent={{-40,-96},{-20,-76}})));
  Buildings.Controls.OBC.CDL.Continuous.Sources.Constant yFreHeaCoi(final k=1)
    "Flow rate signal for heating coil when freeze stat is on"
    annotation (Placement(transformation(extent={{0,-192},{20,-172}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.TerminalUnits.ModeAndSetPoints TZonSet[
    numZon](
    final TZonHeaOn=fill(THeaOn, numZon),
    final TZonHeaOff=fill(THeaOff, numZon),
    final TZonCooOff=fill(TCooOff, numZon)) "Zone setpoint temperature"
    annotation (Placement(transformation(extent={{60,300},{80,320}})));
  Buildings.Controls.OBC.CDL.Routing.BooleanReplicator booRep(
    final nout=numZon)
    "Replicate boolean input"
    annotation (Placement(transformation(extent={{-120,280},{-100,300}})));
  Buildings.Controls.OBC.CDL.Routing.RealReplicator reaRep(
    final nout=numZon)
    "Replicate real input"
    annotation (Placement(transformation(extent={{-120,320},{-100,340}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.AHUs.MultiZone.VAV.Controller conAHU(
    final pMaxSet=410,
    final yFanMin=yFanMin,
    final VPriSysMax_flow=VPriSysMax_flow,
    final peaSysPop=1.2*sum({0.05*AFlo[i] for i in 1:numZon})) "AHU controller"
    annotation (Placement(transformation(extent={{340,510},{420,638}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.AHUs.MultiZone.VAV.SetPoints.OutdoorAirFlow.Zone
    zonOutAirSet[numZon](
    final AFlo=AFlo,
    final have_occSen=fill(false, numZon),
    final have_winSen=fill(false, numZon),
    final desZonPop={0.05*AFlo[i] for i in 1:numZon},
    final minZonPriFlo=minZonPriFlo)
    "Zone level calculation of the minimum outdoor airflow setpoint"
    annotation (Placement(transformation(extent={{220,580},{240,600}})));
  Buildings.Controls.OBC.ASHRAE.G36_PR1.AHUs.MultiZone.VAV.SetPoints.OutdoorAirFlow.SumZone
    zonToSys(final numZon=numZon) "Sum up zone calculation output"
    annotation (Placement(transformation(extent={{280,570},{300,590}})));
  Buildings.Controls.OBC.CDL.Routing.RealReplicator reaRep1(final nout=numZon)
    "Replicate design uncorrected minimum outdoor airflow setpoint"
    annotation (Placement(transformation(extent={{460,580},{480,600}})));
  Buildings.Controls.OBC.CDL.Routing.BooleanReplicator booRep1(final nout=numZon)
    "Replicate signal whether the outdoor airflow is required"
    annotation (Placement(transformation(extent={{460,550},{480,570}})));

  Component.IceTank iceTan(
    redeclare package Medium = MediumCHW,
    m_flow_nominal=m2_flow_chi_nominal,
    dp_nominal=dp_tan_nominal,
    waiTim=0,
    mIce_start=mIce_start,
    mIce_max=mIce_max)
    annotation (Placement(transformation(extent={{300,-170},{320,-150}})));
  Buildings.Fluid.Chillers.ElectricEIR chi(redeclare package Medium1 = MediumW,
      redeclare package Medium2 = MediumCHW,
    m1_flow_nominal=m1_flow_chi_nominal,
    m2_flow_nominal=m2_flow_chi_nominal,
    dp1_nominal=dp1_chi_nominal,
    dp2_nominal=dp2_chi_nominal,
    per=perChi)
    annotation (Placement(transformation(extent={{220,-160},{200,-180}})));
  Buildings.Fluid.Movers.SpeedControlled_y secPum(redeclare package Medium =
        MediumCHW,
    per=perPumSec, addPowerToMedium=false,
    use_inputFilter=false)
    annotation (Placement(transformation(extent={{10,-10},{-10,10}},
        rotation=-90,
        origin={240,-90})));
  Buildings.Fluid.Actuators.Valves.TwoWayLinear watVal(
    redeclare package Medium = MediumCHW,
    m_flow_nominal=m2_flow_chi_nominal,
    dpValve_nominal=6000,
    use_inputFilter=false,
    allowFlowReversal=true)
                          annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={180,-70})));
  Buildings.Fluid.Movers.FlowControlled_m_flow priPum(
    redeclare package Medium = MediumCHW,
    per=perPumPri,
    addPowerToMedium=false,
    use_inputFilter=false,
    m_flow_nominal=m2_flow_chi_nominal)
    annotation (Placement(transformation(extent={{250,-170},{270,-150}})));
  Buildings.Fluid.Sources.Boundary_pT expVesCHW(redeclare replaceable package
      Medium = MediumCHW, nPorts=1)
                                  "Expansion tank" annotation (Placement(
        transformation(
        extent={{-9,-9.5},{9,9.5}},
        rotation=180,
        origin={271,-61.5})));
  Buildings.Fluid.Sources.MassFlowSource_T cwSou(
    redeclare package Medium = MediumW,
    m_flow=m1_flow_chi_nominal,
    nPorts=1,
    T=298.15)
    "Condenser water source boundary"
    annotation (Placement(transformation(extent={{320,-240},{300,-220}})));
  Buildings.Fluid.Actuators.Valves.TwoWayLinear valCW(
    redeclare package Medium = MediumW,
    m_flow_nominal=m1_flow_chi_nominal,
    dpValve_nominal=6000,
    use_inputFilter=false)
                          annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=0,
        origin={270,-230})));
  Buildings.Fluid.Sources.Boundary_pT cwSin(redeclare package Medium = MediumW,
      nPorts=1)                                       "Condenser water sink"
    annotation (Placement(transformation(extent={{160,-240},{180,-220}})));
  Buildings.Fluid.Sensors.RelativePressure senRelPre(redeclare replaceable
      package Medium = MediumCHW)
    "Differential pressure"
    annotation (Placement(transformation(extent={{220,-60},{200,-80}})));
  Buildings.Fluid.Actuators.Valves.TwoWayLinear bypVal(
    redeclare package Medium = MediumCHW,
    m_flow_nominal=m2_flow_chi_nominal,
    dpValve_nominal=1000,
    use_inputFilter=false,
    allowFlowReversal=true)
                          annotation (Placement(transformation(
        extent={{-10,10},{10,-10}},
        rotation=180,
        origin={210,-114})));
  Control.ChillerTankOnOff chiTan
    annotation (Placement(transformation(extent={{500,-160},{520,-140}})));
  Control.PrimaryPumpOnOff priPumOn
    annotation (Placement(transformation(extent={{500,-190},{520,-170}})));
  Buildings.Controls.OBC.CDL.Continuous.Gain gai(k=m2_flow_chi_nominal)
    annotation (Placement(transformation(extent={{560,-190},{580,-170}})));
  Buildings.Controls.OBC.CDL.Conversions.BooleanToReal booToRea
    annotation (Placement(transformation(extent={{500,-230},{520,-210}})));
  Control.CoilValveOnOff coiValCon
    annotation (Placement(transformation(extent={{500,-90},{520,-70}})));
  Buildings.Controls.OBC.CDL.Continuous.Product pro
    annotation (Placement(transformation(extent={{540,-84},{560,-64}})));
  Buildings.Fluid.Sensors.TemperatureTwoPort TCHWSup(redeclare replaceable
      package Medium = MediumCHW, m_flow_nominal=m2_flow_chi_nominal)
    "Chilled water supply temperature"
    annotation (Placement(transformation(extent={{320,-130},{300,-110}})));
  Modelica.Blocks.Math.Gain dpSetGai(k=1/dpSetPoi) "Gain effect"
    annotation (Placement(transformation(extent={{582,-262},{602,-242}})));
  Modelica.Blocks.Math.Gain dpGai(k=1/dpSetPoi) "Gain effect"
    annotation (Placement(transformation(extent={{582,-298},{602,-278}})));
  Buildings.Controls.Continuous.LimPID pumSpe(
    yMin=0.2,
    controllerType=Modelica.Blocks.Types.SimpleController.PI,
    k=0.1,
    y_reset=0,
    Ti=40) "Pump speed controller"
    annotation (Placement(transformation(extent={{620,-262},{640,-242}})));
  Buildings.Fluid.FixedResistances.PressureDrop resCHW(
    dp_nominal=139700,
    m_flow_nominal=m2_flow_chi_nominal,
    redeclare package Medium = MediumCHW)
                       "Resistance in chilled water loop"
    annotation (Placement(transformation(extent={{-10,-10},{10,10}},
        rotation=90,
        origin={340,-142})));
  Buildings.Fluid.Sensors.TemperatureTwoPort TCHWRetCoi(redeclare replaceable
      package Medium = MediumCHW, m_flow_nominal=m2_flow_chi_nominal)
    "Chilled water supply temperature" annotation (Placement(transformation(
        extent={{10,-10},{-10,10}},
        rotation=90,
        origin={180,-96})));
  Control.TemperatureDifferentialPressureReset temDifPreRes(
                       dpMax(displayUnit="Pa") = dpSetPoi,
    TMin=273.15 + 5,
    x1=0.5,
    TMax=273.15 + 10,
    dpMin(displayUnit="Pa") = 0.5*dpSetPoi,
    uTri=0.9)
    annotation (Placement(transformation(extent={{500,-266},{520,-246}})));
  Control.SecondaryPumpOnOff secPumOn
    annotation (Placement(transformation(extent={{500,-120},{520,-100}})));
  Buildings.Controls.OBC.CDL.Continuous.Product proSec
    annotation (Placement(transformation(extent={{660,-260},{680,-240}})));
  Control.ModeControl modCon(waiTim=0) "Mode controller"
    annotation (Placement(transformation(extent={{400,-170},{420,-150}})));

  Modelica.Blocks.Interfaces.RealInput theLoaEncOff2
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-420,658},{-380,698}})));
  Modelica.Blocks.Interfaces.RealOutput TRooAirEncOff2
    "Core zone air temperatures"
    annotation (Placement(transformation(extent={{1240,530},{1260,550}})));
  Modelica.Blocks.Interfaces.RealOutput TRooAirOpeOff1
    "South zone air temperatures"
    annotation (Placement(transformation(extent={{1240,510},{1260,530}})));
  Modelica.Blocks.Interfaces.RealOutput TRooAirEncOff5
    "East zone air temperatures"
    annotation (Placement(transformation(extent={{1240,490},{1260,510}})));
  Modelica.Blocks.Interfaces.RealOutput TRooAirConRoo2
    "North zone air temperatures"
    annotation (Placement(transformation(extent={{1240,470},{1260,490}})));
  Modelica.Blocks.Interfaces.RealInput theLoaOpeOff1
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-420,620},{-380,660}})));
  Modelica.Blocks.Interfaces.RealInput theLoaEncOff5
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-420,580},{-380,620}})));
  Modelica.Blocks.Interfaces.RealInput theLoaConRoo2
    "Heat transferred to the zone. Negative - heating load; positive-cooling load"
    annotation (Placement(transformation(extent={{-420,540},{-380,580}})));
  Modelica.Blocks.Interfaces.RealOutput PFan "Electrical power consumed"
    annotation (Placement(transformation(extent={{380,-42},{400,-22}})));
  Modelica.Blocks.Interfaces.BooleanOutput occupied
    "Outputs true if occupied at current time"
    annotation (Placement(transformation(extent={{-224,-258},{-204,-238}})));
  Buildings.Controls.OBC.CDL.Interfaces.BooleanOutput ySupFan
    "Supply fan status, true if fan should be on"
    annotation (Placement(transformation(extent={{480,600},{520,640}})));
equation
  connect(fanSup.port_b, dpDisSupFan.port_a) annotation (Line(
      points={{320,-40},{320,0},{320,-10},{320,-10}},
      color={0,0,0},
      smooth=Smooth.None,
      pattern=LinePattern.Dot));
  connect(conVAVCor.TDis, TSupCor.T) annotation (Line(points={{528,36},{522,36},
          {522,40},{514,40},{514,92},{569,92}}, color={0,0,127}));
  connect(TSupSou.T, conVAVSou.TDis) annotation (Line(points={{749,92},{688,92},
          {688,34},{698,34}}, color={0,0,127}));
  connect(TSupEas.T, conVAVEas.TDis) annotation (Line(points={{929,90},{870,90},
          {870,34},{878,34}}, color={0,0,127}));
  connect(TSupNor.T, conVAVNor.TDis) annotation (Line(points={{1089,94},{1030,94},
          {1030,34},{1038,34}},     color={0,0,127}));
  connect(cor.yVAV, conVAVCor.yDam) annotation (Line(points={{566,50},{556,50},{
          556,48},{552,48}}, color={0,0,127}));
  connect(cor.yVal, conVAVCor.yVal) annotation (Line(points={{566,34},{560,34},{
          560,43},{552,43}}, color={0,0,127}));
  connect(conVAVSou.yDam, sou.yVAV) annotation (Line(points={{722,46},{730,46},{
          730,48},{746,48}}, color={0,0,127}));
  connect(conVAVSou.yVal, sou.yVal) annotation (Line(points={{722,41},{732.5,41},
          {732.5,32},{746,32}}, color={0,0,127}));
  connect(conVAVEas.yVal, eas.yVal) annotation (Line(points={{902,41},{912.5,41},
          {912.5,32},{926,32}}, color={0,0,127}));
  connect(conVAVEas.yDam, eas.yVAV) annotation (Line(points={{902,46},{910,46},{
          910,48},{926,48}}, color={0,0,127}));
  connect(conVAVNor.yDam, nor.yVAV) annotation (Line(points={{1062,46},{1072.5,46},
          {1072.5,48},{1086,48}},     color={0,0,127}));
  connect(conVAVNor.yVal, nor.yVal) annotation (Line(points={{1062,41},{1072.5,41},
          {1072.5,32},{1086,32}},     color={0,0,127}));
  connect(conVAVCor.yZonTemResReq, TZonResReq.u[1]) annotation (Line(points={{552,38},
          {554,38},{554,220},{280,220},{280,375.25},{298,375.25}},       color=
          {255,127,0}));
  connect(conVAVSou.yZonTemResReq, TZonResReq.u[2]) annotation (Line(points={{722,36},
          {726,36},{726,220},{280,220},{280,371.75},{298,371.75}},       color=
          {255,127,0}));
  connect(conVAVEas.yZonTemResReq, TZonResReq.u[3]) annotation (Line(points={{902,36},
          {904,36},{904,220},{280,220},{280,368.25},{298,368.25}},   color={255,
          127,0}));
  connect(conVAVNor.yZonTemResReq, TZonResReq.u[4]) annotation (Line(points={{1062,36},
          {1064,36},{1064,220},{280,220},{280,364.75},{298,364.75}},
        color={255,127,0}));
  connect(conVAVCor.yZonPreResReq, PZonResReq.u[1]) annotation (Line(points={{552,34},
          {558,34},{558,214},{288,214},{288,345.25},{298,345.25}},       color=
          {255,127,0}));
  connect(conVAVSou.yZonPreResReq, PZonResReq.u[2]) annotation (Line(points={{722,32},
          {728,32},{728,214},{288,214},{288,341.75},{298,341.75}},       color=
          {255,127,0}));
  connect(conVAVEas.yZonPreResReq, PZonResReq.u[3]) annotation (Line(points={{902,32},
          {906,32},{906,214},{288,214},{288,338.25},{298,338.25}},   color={255,
          127,0}));
  connect(conVAVNor.yZonPreResReq, PZonResReq.u[4]) annotation (Line(points={{1062,32},
          {1066,32},{1066,214},{288,214},{288,334.75},{298,334.75}},
        color={255,127,0}));
  connect(VSupCor_flow.V_flow, VDis_flow.u1[1]) annotation (Line(points={{569,130},
          {472,130},{472,206},{180,206},{180,249},{218,249}},      color={0,0,
          127}));
  connect(VSupSou_flow.V_flow, VDis_flow.u2[1]) annotation (Line(points={{749,130},
          {742,130},{742,206},{180,206},{180,243},{218,243}},      color={0,0,
          127}));
  connect(VSupEas_flow.V_flow, VDis_flow.u3[1]) annotation (Line(points={{929,128},
          {914,128},{914,206},{180,206},{180,237},{218,237}},      color={0,0,
          127}));
  connect(VSupNor_flow.V_flow, VDis_flow.u4[1]) annotation (Line(points={{1089,132},
          {1080,132},{1080,206},{180,206},{180,231},{218,231}},      color={0,0,
          127}));
  connect(TSupCor.T, TDis.u1[1]) annotation (Line(points={{569,92},{466,92},{466,
          210},{176,210},{176,289},{218,289}},     color={0,0,127}));
  connect(TSupSou.T, TDis.u2[1]) annotation (Line(points={{749,92},{688,92},{688,
          210},{176,210},{176,283},{218,283}},                       color={0,0,
          127}));
  connect(TSupEas.T, TDis.u3[1]) annotation (Line(points={{929,90},{870,90},{870,
          210},{174,210},{174,277},{218,277}},     color={0,0,127}));
  connect(TSupNor.T, TDis.u4[1]) annotation (Line(points={{1089,94},{1030,94},{1030,
          210},{174,210},{174,271},{218,271}},      color={0,0,127}));
  connect(conVAVCor.VDis_flow, VSupCor_flow.V_flow) annotation (Line(points={{528,40},
          {522,40},{522,130},{569,130}}, color={0,0,127}));
  connect(VSupSou_flow.V_flow, conVAVSou.VDis_flow) annotation (Line(points={{749,130},
          {690,130},{690,38},{698,38}},      color={0,0,127}));
  connect(VSupEas_flow.V_flow, conVAVEas.VDis_flow) annotation (Line(points={{929,128},
          {872,128},{872,38},{878,38}},      color={0,0,127}));
  connect(VSupNor_flow.V_flow, conVAVNor.VDis_flow) annotation (Line(points={{1089,
          132},{1032,132},{1032,38},{1038,38}}, color={0,0,127}));
  connect(TSup.T, conVAVCor.TSupAHU) annotation (Line(points={{340,-29},{340,
          -20},{514,-20},{514,34},{528,34}},
                                        color={0,0,127}));
  connect(TSup.T, conVAVSou.TSupAHU) annotation (Line(points={{340,-29},{340,
          -20},{686,-20},{686,32},{698,32}},
                                        color={0,0,127}));
  connect(TSup.T, conVAVEas.TSupAHU) annotation (Line(points={{340,-29},{340,
          -20},{864,-20},{864,32},{878,32}},
                                        color={0,0,127}));
  connect(TSup.T, conVAVNor.TSupAHU) annotation (Line(points={{340,-29},{340,
          -20},{1028,-20},{1028,32},{1038,32}},
                                           color={0,0,127}));
  connect(yOutDam.y, eco.yExh)
    annotation (Line(points={{-18,-10},{-3,-10},{-3,-34}}, color={0,0,127}));
  connect(swiFreSta.y, gaiHeaCoi.u) annotation (Line(points={{82,-192},{88,-192},
          {88,-210},{98,-210}}, color={0,0,127}));
  connect(freSta.y, swiFreSta.u2) annotation (Line(points={{22,-92},{40,-92},{40,
          -192},{58,-192}},    color={255,0,255}));
  connect(yFreHeaCoi.y, swiFreSta.u1) annotation (Line(points={{22,-182},{40,-182},
          {40,-184},{58,-184}}, color={0,0,127}));
  connect(TZonSet[1].yOpeMod, conVAVCor.uOpeMod) annotation (Line(points={{82,303},
          {130,303},{130,180},{420,180},{420,14},{520,14},{520,32},{528,32}},
        color={255,127,0}));
  connect(flo.TRooAir, TZonSet.TZon) annotation (Line(points={{1108.2,512.875},{
          1164,512.875},{1164,662},{46,662},{46,313},{58,313}},  color={0,0,127}));
  connect(occSch.occupied, booRep.u) annotation (Line(points={{-297,-216},{-160,
          -216},{-160,290},{-122,290}}, color={255,0,255}));
  connect(occSch.tNexOcc, reaRep.u) annotation (Line(points={{-297,-204},{-180,-204},
          {-180,330},{-122,330}}, color={0,0,127}));
  connect(reaRep.y, TZonSet.tNexOcc) annotation (Line(points={{-98,330},{-20,330},
          {-20,319},{58,319}}, color={0,0,127}));
  connect(booRep.y, TZonSet.uOcc) annotation (Line(points={{-98,290},{-20,290},{
          -20,316.025},{58,316.025}}, color={255,0,255}));
  connect(TZonSet[1].yOpeMod, conVAVSou.uOpeMod) annotation (Line(points={{82,303},
          {130,303},{130,180},{420,180},{420,14},{680,14},{680,30},{698,30}},
        color={255,127,0}));
  connect(TZonSet[1].yOpeMod, conVAVEas.uOpeMod) annotation (Line(points={{82,303},
          {130,303},{130,180},{420,180},{420,14},{860,14},{860,30},{878,30}},
        color={255,127,0}));
  connect(TZonSet[1].yOpeMod, conVAVNor.uOpeMod) annotation (Line(points={{82,303},
          {130,303},{130,180},{420,180},{420,14},{1020,14},{1020,30},{1038,30}},
        color={255,127,0}));
  connect(zonToSys.ySumDesZonPop, conAHU.sumDesZonPop) annotation (Line(points={{302,589},
          {308,589},{308,607.778},{336,607.778}},           color={0,0,127}));
  connect(zonToSys.VSumDesPopBreZon_flow, conAHU.VSumDesPopBreZon_flow)
    annotation (Line(points={{302,586},{310,586},{310,602.444},{336,602.444}},
        color={0,0,127}));
  connect(zonToSys.VSumDesAreBreZon_flow, conAHU.VSumDesAreBreZon_flow)
    annotation (Line(points={{302,583},{312,583},{312,597.111},{336,597.111}},
        color={0,0,127}));
  connect(zonToSys.yDesSysVenEff, conAHU.uDesSysVenEff) annotation (Line(points={{302,580},
          {314,580},{314,591.778},{336,591.778}},           color={0,0,127}));
  connect(zonToSys.VSumUncOutAir_flow, conAHU.VSumUncOutAir_flow) annotation (
      Line(points={{302,577},{316,577},{316,586.444},{336,586.444}}, color={0,0,
          127}));
  connect(zonToSys.VSumSysPriAir_flow, conAHU.VSumSysPriAir_flow) annotation (
      Line(points={{302,571},{318,571},{318,581.111},{336,581.111}}, color={0,0,
          127}));
  connect(zonToSys.uOutAirFra_max, conAHU.uOutAirFra_max) annotation (Line(
        points={{302,574},{320,574},{320,575.778},{336,575.778}}, color={0,0,127}));
  connect(zonOutAirSet.yDesZonPeaOcc, zonToSys.uDesZonPeaOcc) annotation (Line(
        points={{242,599},{270,599},{270,588},{278,588}},     color={0,0,127}));
  connect(zonOutAirSet.VDesPopBreZon_flow, zonToSys.VDesPopBreZon_flow)
    annotation (Line(points={{242,596},{268,596},{268,586},{278,586}},
                                                     color={0,0,127}));
  connect(zonOutAirSet.VDesAreBreZon_flow, zonToSys.VDesAreBreZon_flow)
    annotation (Line(points={{242,593},{266,593},{266,584},{278,584}},
        color={0,0,127}));
  connect(zonOutAirSet.yDesPriOutAirFra, zonToSys.uDesPriOutAirFra) annotation (
     Line(points={{242,590},{264,590},{264,578},{278,578}},     color={0,0,127}));
  connect(zonOutAirSet.VUncOutAir_flow, zonToSys.VUncOutAir_flow) annotation (
      Line(points={{242,587},{262,587},{262,576},{278,576}},     color={0,0,127}));
  connect(zonOutAirSet.yPriOutAirFra, zonToSys.uPriOutAirFra)
    annotation (Line(points={{242,584},{260,584},{260,574},{278,574}},
                                                     color={0,0,127}));
  connect(zonOutAirSet.VPriAir_flow, zonToSys.VPriAir_flow) annotation (Line(
        points={{242,581},{258,581},{258,572},{278,572}},     color={0,0,127}));
  connect(conAHU.yAveOutAirFraPlu, zonToSys.yAveOutAirFraPlu) annotation (Line(
        points={{424,584.667},{440,584.667},{440,468},{270,468},{270,582},{278,
          582}},
        color={0,0,127}));
  connect(conAHU.VDesUncOutAir_flow, reaRep1.u) annotation (Line(points={{424,
          595.333},{440,595.333},{440,590},{458,590}},
                                              color={0,0,127}));
  connect(reaRep1.y, zonOutAirSet.VUncOut_flow_nominal) annotation (Line(points={{482,590},
          {490,590},{490,464},{210,464},{210,581},{218,581}},          color={0,
          0,127}));
  connect(conAHU.yReqOutAir, booRep1.u) annotation (Line(points={{424,563.333},
          {444,563.333},{444,560},{458,560}},color={255,0,255}));
  connect(booRep1.y, zonOutAirSet.uReqOutAir) annotation (Line(points={{482,560},
          {496,560},{496,460},{206,460},{206,593},{218,593}}, color={255,0,255}));
  connect(flo.TRooAir, zonOutAirSet.TZon) annotation (Line(points={{1108.2,512.875},
          {1164,512.875},{1164,660},{210,660},{210,590},{218,590}}, color={0,0,127}));
  connect(TDis.y, zonOutAirSet.TDis) annotation (Line(points={{241,280},{252,280},
          {252,340},{200,340},{200,587},{218,587}}, color={0,0,127}));
  connect(VDis_flow.y, zonOutAirSet.VDis_flow) annotation (Line(points={{241,240},
          {260,240},{260,346},{194,346},{194,584},{218,584}}, color={0,0,127}));
  connect(TZonSet[1].yOpeMod, conAHU.uOpeMod) annotation (Line(points={{82,303},
          {140,303},{140,529.556},{336,529.556}}, color={255,127,0}));
  connect(TZonResReq.y, conAHU.uZonTemResReq) annotation (Line(points={{322,370},
          {330,370},{330,524.222},{336,524.222}}, color={255,127,0}));
  connect(PZonResReq.y, conAHU.uZonPreResReq) annotation (Line(points={{322,340},
          {326,340},{326,518.889},{336,518.889}}, color={255,127,0}));
  connect(TZonSet[1].TZonHeaSet, conAHU.TZonHeaSet) annotation (Line(points={{82,310},
          {110,310},{110,634.444},{336,634.444}},      color={0,0,127}));
  connect(TOut.y, conAHU.TOut) annotation (Line(points={{-279,180},{-260,180},{
          -260,623.778},{336,623.778}},
                                   color={0,0,127}));
  connect(dpDisSupFan.p_rel, conAHU.ducStaPre) annotation (Line(points={{311,0},
          {160,0},{160,618.444},{336,618.444}}, color={0,0,127}));
  connect(TSup.T, conAHU.TSup) annotation (Line(points={{340,-29},{340,-22},{
          152,-22},{152,565.111},{336,565.111}},
                                             color={0,0,127}));
  connect(TRet.T, conAHU.TOutCut) annotation (Line(points={{100,151},{100,
          559.778},{336,559.778}},
                          color={0,0,127}));
  connect(VOut1.V_flow, conAHU.VOut_flow) annotation (Line(points={{-61,-20.9},
          {-61,543.778},{336,543.778}},color={0,0,127}));
  connect(TMix.T, conAHU.TMix) annotation (Line(points={{40,-29},{40,536.667},{
          336,536.667}},
                     color={0,0,127}));
  connect(conAHU.yOutDamPos, eco.yOut) annotation (Line(points={{424,520.667},{
          448,520.667},{448,36},{-10,36},{-10,-34}},
                                                 color={0,0,127}));
  connect(conAHU.yRetDamPos, eco.yRet) annotation (Line(points={{424,531.333},{
          442,531.333},{442,40},{-16.8,40},{-16.8,-34}},
                                                     color={0,0,127}));
  connect(conAHU.yHea, swiFreSta.u3) annotation (Line(points={{424,552.667},{
          458,552.667},{458,-280},{40,-280},{40,-200},{58,-200}},
                                                              color={0,0,127}));
  connect(conAHU.ySupFanSpe, fanSup.y) annotation (Line(points={{424,616.667},{
          432,616.667},{432,-14},{310,-14},{310,-28}},
                                                   color={0,0,127}));
  connect(cor.y_actual,conVAVCor.yDam_actual)  annotation (Line(points={{612,58},
          {620,58},{620,74},{518,74},{518,38},{528,38}}, color={0,0,127}));
  connect(sou.y_actual,conVAVSou.yDam_actual)  annotation (Line(points={{792,56},
          {800,56},{800,76},{684,76},{684,36},{698,36}}, color={0,0,127}));
  connect(eas.y_actual,conVAVEas.yDam_actual)  annotation (Line(points={{972,56},
          {980,56},{980,74},{864,74},{864,36},{878,36}}, color={0,0,127}));
  connect(nor.y_actual,conVAVNor.yDam_actual)  annotation (Line(points={{1132,
          56},{1140,56},{1140,74},{1024,74},{1024,36},{1038,36}}, color={0,0,
          127}));
  connect(cooCoi.port_a1, secPum.port_b) annotation (Line(points={{210,-52},{240,
          -52},{240,-80}}, color={0,127,255}));
  connect(cooCoi.port_b1, watVal.port_a) annotation (Line(points={{190,-52},{180,
          -52},{180,-60}}, color={0,127,255}));
  connect(chi.port_b2, priPum.port_a) annotation (Line(points={{220,-164},{230,-164},
          {230,-160},{250,-160}}, color={0,127,255}));
  connect(priPum.port_b, iceTan.port_a)
    annotation (Line(points={{270,-160},{300,-160}}, color={0,127,255}));
  connect(chi.port_a1, valCW.port_b) annotation (Line(points={{220,-176},{240,-176},
          {240,-230},{260,-230}}, color={0,127,255}));
  connect(valCW.port_a, cwSou.ports[1])
    annotation (Line(points={{280,-230},{300,-230}}, color={0,127,255}));
  connect(cwSin.ports[1], chi.port_b1) annotation (Line(points={{180,-230},{190,
          -230},{190,-176},{200,-176}}, color={0,127,255}));
  connect(senRelPre.port_a, secPum.port_b) annotation (Line(points={{220,-70},{234,
          -70},{234,-80},{240,-80}}, color={0,127,255}));
  connect(secPum.port_a, bypVal.port_a) annotation (Line(points={{240,-100},{240,
          -114},{220,-114}}, color={0,127,255}));
  connect(chiTan.onChi, chi.on) annotation (Line(points={{521,-153},{548,-153},{
          548,-196},{244,-196},{244,-173},{222,-173}}, color={255,0,255}));
  connect(chiTan.modTan, iceTan.u) annotation (Line(points={{521,-147},{548,-147},
          {548,-130},{360,-130},{360,-140},{282,-140},{282,-152},{298,-152}},
        color={255,127,0}));
  connect(priPumOn.y, gai.u)
    annotation (Line(points={{522,-180},{558,-180}}, color={0,0,127}));
  connect(gai.y, priPum.m_flow_in) annotation (Line(points={{582,-180},{600,-180},
          {600,-128},{260,-128},{260,-148}}, color={0,0,127}));
  connect(chiTan.onChi, booToRea.u) annotation (Line(points={{521,-153},{548,-153},
          {548,-196},{490,-196},{490,-220},{498,-220}}, color={255,0,255}));
  connect(booToRea.y, valCW.y) annotation (Line(points={{522,-220},{546,-220},{546,
          -234},{340,-234},{340,-210},{270,-210},{270,-218}}, color={0,0,127}));
  connect(coiValCon.y, pro.u2)
    annotation (Line(points={{521,-80},{538,-80}}, color={0,0,127}));
  connect(conAHU.yCoo, pro.u1) annotation (Line(points={{424,542},{464,542},{
          464,-52},{532,-52},{532,-68},{538,-68}},
                                               color={0,0,127}));
  connect(pro.y, watVal.y) annotation (Line(points={{562,-74},{588,-74},{588,-94},
          {452,-94},{452,-48},{158,-48},{158,-70},{168,-70}}, color={0,0,127}));
  connect(TCHWSup.port_b, secPum.port_a) annotation (Line(points={{300,-120},{240,
          -120},{240,-100}}, color={0,127,255}));
  connect(dpSetGai.y,pumSpe. u_s)
    annotation (Line(points={{603,-252},{618,-252}},   color={0,0,127}));
  connect(dpGai.y,pumSpe. u_m) annotation (Line(points={{603,-288},{630,-288},{630,
          -264}},                           color={0,0,127}));
  connect(senRelPre.p_rel, dpGai.u) annotation (Line(points={{210,-61},{210,-58},
          {468,-58},{468,-288},{580,-288}}, color={0,0,127}));
  connect(pumSpe.y, proSec.u2) annotation (Line(points={{641,-252},{648,-252},{648,
          -256},{658,-256}}, color={0,0,127}));
  connect(secPumOn.y, proSec.u1) annotation (Line(points={{522,-110},{650,-110},
          {650,-244},{658,-244}}, color={0,0,127}));
  connect(proSec.y, secPum.y) annotation (Line(points={{682,-250},{698,-250},{698,
          -56},{376,-56},{376,-90},{252,-90}}, color={0,0,127}));
  connect(modCon.y, secPumOn.u) annotation (Line(points={{421,-160},{452,-160},{
          452,-110},{498,-110}}, color={255,127,0}));
  connect(modCon.y, chiTan.u) annotation (Line(points={{421,-160},{452,-160},{452,
          -150},{498,-150}}, color={255,127,0}));
  connect(modCon.y, priPumOn.u) annotation (Line(points={{421,-160},{452,-160},{
          452,-180},{498,-180}}, color={255,127,0}));
  connect(modCon.y, coiValCon.u) annotation (Line(points={{421,-160},{452,-160},
          {452,-80},{498,-80}}, color={255,127,0}));
  connect(iceTan.port_b, resCHW.port_a) annotation (Line(points={{320,-160},{
          340,-160},{340,-152}}, color={0,127,255}));
  connect(resCHW.port_b, TCHWSup.port_a) annotation (Line(points={{340,-132},{340,
          -120},{320,-120}}, color={0,127,255}));
  connect(bypVal.port_b, TCHWRetCoi.port_b) annotation (Line(points={{200,-114},
          {180,-114},{180,-106}}, color={0,127,255}));
  connect(chi.port_a2, TCHWRetCoi.port_b) annotation (Line(points={{200,-164},{180,
          -164},{180,-106}}, color={0,127,255}));
  connect(senRelPre.port_b, TCHWRetCoi.port_a) annotation (Line(points={{200,-70},
          {188,-70},{188,-86},{180,-86}}, color={0,127,255}));
  connect(expVesCHW.ports[1], priPum.port_a) annotation (Line(points={{262,-61.5},
          {256,-61.5},{256,-138},{240,-138},{240,-160},{250,-160}}, color={0,127,
          255}));
  connect(watVal.port_b, TCHWRetCoi.port_a)
    annotation (Line(points={{180,-80},{180,-86}}, color={0,127,255}));
  connect(TZonSet[1].TZonCooSet, conAHU.TZonCooSet) annotation (Line(points={{82,317},
          {120,317},{120,629.111},{336,629.111}},      color={0,0,127}));
  connect(occSch.occupied,modCon. Occupied) annotation (Line(points={{-297,-216},
          {-160,-216},{-160,-264},{386,-264},{386,-152},{398,-152}}, color={255,
          0,255}));
  connect(iceTan.SOC, modCon.SOC) annotation (Line(points={{321,-152},{359.5,-152},
          {359.5,-160},{398,-160}}, color={0,0,127}));
  connect(temDifPreRes.TChiSet, chi.TSet) annotation (Line(points={{521,-262},{528,
          -262},{528,-270},{232,-270},{232,-167},{222,-167}}, color={0,0,127}));
  connect(temDifPreRes.dpSet, dpSetGai.u) annotation (Line(points={{521,-251},{550.5,
          -251},{550.5,-252},{580,-252}}, color={0,0,127}));
  connect(modCon.y, temDifPreRes.uOpeMod) annotation (Line(points={{421,-160},{452,
          -160},{452,-250},{498,-250}}, color={255,127,0}));
  connect(watVal.y_actual, temDifPreRes.u) annotation (Line(points={{173,-75},{156,
          -75},{156,-256},{498,-256}}, color={0,0,127}));
  connect(priPumOn.y, bypVal.y) annotation (Line(points={{522,-180},{552,-180},{
          552,-122},{360,-122},{360,-102},{210,-102}}, color={0,0,127}));
  connect(temDifPreRes.TIceTanSet, iceTan.TOutSet) annotation (Line(points={{
          521,-261},{530,-261},{530,-272},{290,-272},{290,-157},{298,-157}},
        color={0,0,127}));
  connect(TRooAir.y1[1], conVAVCor.TZon) annotation (Line(
      points={{511,179},{516,179},{516,42},{528,42}},
      color={0,0,127},
      pattern=LinePattern.Dash));
  connect(TRooAir.y2[1], conVAVSou.TZon) annotation (Line(
      points={{511,173},{686,173},{686,40},{698,40}},
      color={0,0,127},
      pattern=LinePattern.Dash));
  connect(TRooAir.y3[1], conVAVEas.TZon) annotation (Line(
      points={{511,167},{862,167},{862,40},{878,40}},
      color={0,0,127},
      pattern=LinePattern.Dash));
  connect(TRooAir.y4[1], conVAVNor.TZon) annotation (Line(
      points={{511,161},{1022,161},{1022,40},{1038,40}},
      color={0,0,127},
      pattern=LinePattern.Dash));
  connect(TZonSet[1].TZonCooSet, conVAVCor.TZonCooSet) annotation (Line(points={
          {82,317},{524,317},{524,50},{528,50}}, color={0,0,127}));
  connect(TZonSet[2].TZonCooSet, conVAVSou.TZonCooSet) annotation (Line(points={
          {82,317},{692,317},{692,48},{698,48}}, color={0,0,127}));
  connect(TZonSet[3].TZonCooSet, conVAVEas.TZonCooSet) annotation (Line(points={
          {82,317},{874,317},{874,48},{878,48}}, color={0,0,127}));
  connect(TZonSet[4].TZonCooSet, conVAVNor.TZonCooSet) annotation (Line(points={
          {82,317},{1034,317},{1034,48},{1038,48}}, color={0,0,127}));
  connect(TZonSet[1].TZonHeaSet, conVAVCor.TZonHeaSet) annotation (Line(points={
          {82,310},{526,310},{526,52},{528,52}}, color={0,0,127}));
  connect(TZonSet[2].TZonHeaSet, conVAVSou.TZonHeaSet) annotation (Line(points={
          {82,310},{694,310},{694,50},{698,50}}, color={0,0,127}));
  connect(TZonSet[3].TZonHeaSet, conVAVEas.TZonHeaSet) annotation (Line(points={
          {82,310},{876,310},{876,50},{878,50}}, color={0,0,127}));
  connect(TZonSet[4].TZonHeaSet, conVAVNor.TZonHeaSet) annotation (Line(points={
          {82,310},{1036,310},{1036,50},{1038,50}}, color={0,0,127}));
  connect(flo.TRooAir[1], TRooAirEncOff2) annotation (Line(points={{1108.2,
          507.719},{1200,507.719},{1200,540},{1250,540}}, color={0,0,127}));
  connect(flo.TRooAir[2], TRooAirOpeOff1) annotation (Line(points={{1108.2,
          511.156},{1202,511.156},{1202,520},{1250,520}}, color={0,0,127}));
  connect(flo.TRooAir[3], TRooAirEncOff5) annotation (Line(points={{1108.2,
          514.594},{1202,514.594},{1202,500},{1250,500}}, color={0,0,127}));
  connect(flo.TRooAir[4], TRooAirConRoo2) annotation (Line(points={{1108.2,
          518.031},{1204,518.031},{1204,480},{1250,480}}, color={0,0,127}));
  connect(theLoaEncOff2, flo.Q_flow[1]) annotation (Line(points={{-400,678},{
          700,678},{700,578.188},{755.6,578.188}}, color={0,0,127}));
  connect(theLoaOpeOff1, flo.Q_flow[2]) annotation (Line(points={{-400,640},{
          -272,640},{-272,674},{698,674},{698,585.063},{755.6,585.063}}, color=
          {0,0,127}));
  connect(theLoaEncOff5, flo.Q_flow[3]) annotation (Line(points={{-400,600},{
          -266,600},{-266,672},{694,672},{694,591.938},{755.6,591.938}}, color=
          {0,0,127}));
  connect(theLoaConRoo2, flo.Q_flow[4]) annotation (Line(points={{-400,560},{
          -276,560},{-276,666},{696,666},{696,598.813},{755.6,598.813}}, color=
          {0,0,127}));
  connect(fanSup.P, PFan)
    annotation (Line(points={{321,-31},{390,-31},{390,-32}}, color={0,0,127}));
  connect(occSch.occupied, occupied) annotation (Line(points={{-297,-216},{-256,
          -216},{-256,-248},{-214,-248}}, color={255,0,255}));
  connect(conAHU.ySupFan, ySupFan) annotation (Line(points={{424,627.333},{452,
          627.333},{452,620},{500,620}}, color={255,0,255}));
  annotation (
    Diagram(coordinateSystem(preserveAspectRatio=false,extent={{-380,-320},{
            1240,700}})),
    Documentation(info="<html>
<p>
This model consist of an HVAC system, a building envelope model and a model
for air flow through building leakage and through open doors.
</p>
<p>
The HVAC system is a variable air volume (VAV) flow system with economizer
and a heating and cooling coil in the air handler unit. There is also a
reheat coil and an air damper in each of the five zone inlet branches.
</p>
<p>
See the model
<a href=\"modelica://Buildings.Examples.VAVReheat.BaseClasses.PartialOpenLoop\">
Buildings.Examples.VAVReheat.BaseClasses.PartialOpenLoop</a>
for a description of the HVAC system and the building envelope.
</p>
<p>
The control is based on ASHRAE Guideline 36, and implemented
using the sequences from the library
<a href=\"modelica://Buildings.Controls.OBC.ASHRAE.G36_PR1\">
Buildings.Controls.OBC.ASHRAE.G36_PR1</a> for
multi-zone VAV systems with economizer. The schematic diagram of the HVAC and control
sequence is shown in the figure below.
</p>
<p align=\"center\">
<img alt=\"image\" src=\"modelica://Buildings/Resources/Images/Examples/VAVReheat/vavControlSchematics.png\" border=\"1\"/>
</p>
<p>
A similar model but with a different control sequence can be found in
<a href=\"modelica://Buildings.Examples.VAVReheat.ASHRAE2006\">
Buildings.Examples.VAVReheat.ASHRAE2006</a>.
Note that this model, because of the frequent time sampling,
has longer computing time than
<a href=\"modelica://Buildings.Examples.VAVReheat.ASHRAE2006\">
Buildings.Examples.VAVReheat.ASHRAE2006</a>.
The reason is that the time integrator cannot make large steps
because it needs to set a time step each time the control samples
its input.
</p>
</html>", revisions="<html>
<ul>
<li>
April 20, 2020, by Jianjun Hu:<br/>
Exported actual VAV damper position as the measured input data for terminal controller.<br/>
This is
for <a href=\"https://github.com/lbl-srg/modelica-buildings/issues/1873\">issue #1873</a>
</li>
<li>
March 20, 2020, by Jianjun Hu:<br/>
Replaced the AHU controller with reimplemented one. The new controller separates the
zone level calculation from the system level calculation and does not include
vector-valued calculations.<br/>
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1829\">#1829</a>.
</li>
<li>
March 09, 2020, by Jianjun Hu:<br/>
Replaced the block that calculates operation mode and zone temperature setpoint,
with the new one that does not include vector-valued calculations.<br/>
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/1709\">#1709</a>.
</li>
<li>
May 19, 2016, by Michael Wetter:<br/>
Changed chilled water supply temperature to <i>6&deg;C</i>.
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/509\">#509</a>.
</li>
<li>
April 26, 2016, by Michael Wetter:<br/>
Changed controller for freeze protection as the old implementation closed
the outdoor air damper during summer.
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/511\">#511</a>.
</li>
<li>
January 22, 2016, by Michael Wetter:<br/>
Corrected type declaration of pressure difference.
This is
for <a href=\"https://github.com/ibpsa/modelica-ibpsa/issues/404\">#404</a>.
</li>
<li>
September 24, 2015 by Michael Wetter:<br/>
Set default temperature for medium to avoid conflicting
start values for alias variables of the temperature
of the building and the ambient air.
This is for
<a href=\"https://github.com/lbl-srg/modelica-buildings/issues/426\">issue 426</a>.
</li>
</ul>
</html>"),
    experiment(
      StartTime=0,
      StopTime=31536000,
      Tolerance=1e-06,
      __Dymola_Algorithm="Cvode"),
    Icon(coordinateSystem(extent={{-380,-320},{1240,700}}), graphics={Rectangle(
          extent={{-380,698},{1238,-330}},
          lineColor={0,0,127},
          pattern=LinePattern.Dash,
          fillPattern=FillPattern.Sphere,
          fillColor={170,213,255})}),
    __Dymola_Commands(file="modelica://VirtualTestbed/Resources/scripts/dymola/NISTChillerTestbed/System/FakeSystem/Baseline.mos"
        "Simulate and Plot"));
end Baseline;

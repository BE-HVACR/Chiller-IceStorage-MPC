within VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.Examples;
model SystemMode "System mode"
  extends Modelica.Icons.Example;

  Modelica.Blocks.Sources.IntegerConstant mod(
    k=Integer(VirtualTestbed.NISTChillerTestbed.DemandFlexibilityInvestigation.Types.SystemMode.Off))
    "Mode" annotation (Placement(transformation(extent={{-12,-10},{8,10}})));
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)),
    experiment(StopTime=14400, __Dymola_Algorithm="Dassl"));
end SystemMode;

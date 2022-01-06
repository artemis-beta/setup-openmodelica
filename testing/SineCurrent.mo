model SineCurrentModel
  Modelica.Electrical.Analog.Sources.SineCurrent sineCurrent(I = 1, freqHz = 50)  annotation(
    Placement(visible = true, transformation(origin = {0, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Ground ground annotation(
    Placement(visible = true, transformation(origin = {0, -10}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Resistor resistor(R = 1)  annotation(
    Placement(visible = true, transformation(origin = {50, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
  Modelica.Electrical.Analog.Basic.Inductor inductor(L = 1e-4)  annotation(
    Placement(visible = true, transformation(origin = {-48, 40}, extent = {{-10, -10}, {10, 10}}, rotation = 0)));
equation
  connect(sineCurrent.n, resistor.p) annotation(
    Line(points = {{10, 40}, {40, 40}}, color = {0, 0, 255}));
  connect(resistor.n, ground.p) annotation(
    Line(points = {{60, 40}, {80, 40}, {80, 0}, {0, 0}, {0, 0}}, color = {0, 0, 255}));
  connect(inductor.n, sineCurrent.p) annotation(
    Line(points = {{-38, 40}, {-10, 40}, {-10, 40}, {-10, 40}}, color = {0, 0, 255}));
  connect(inductor.p, ground.p) annotation(
    Line(points = {{-58, 40}, {-80, 40}, {-80, 0}, {0, 0}, {0, 0}}, color = {0, 0, 255}));
  assert(resistor.alpha >= 0, "Resistor Alpha must be positive", level=AssertionLevel.error);
  assert(resistor.alpha < 1, "Resistor Alpha must be positive", level=AssertionLevel.warning)

annotation();
end SineCurrentModel;

import 'dart:async';
import 'dart:html';

import 'package:petitparser_examples/math.dart';

class Viewport {
  Viewport({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.width,
    required this.height,
  });

  final num minX;
  final num maxX;

  final num minY;
  final num maxY;

  final int width;
  final int height;

  /// Resizes the canvas.
  void resize(CanvasElement canvas) {
    final pixelRatio = window.devicePixelRatio;
    canvas.style.width = '${width}px';
    canvas.style.height = '${height}px';
    canvas.width = (width * pixelRatio).truncate();
    canvas.height = (height * pixelRatio).truncate();
  }

  /// Clears the viewport.
  void clear(CanvasRenderingContext2D context) =>
      context.clearRect(0, 0, width, height);

  /// Plots the grid and axis.
  void grid(CanvasRenderingContext2D context,
      {String axisStyle = 'black', String gridStyle = 'gray'}) {
    for (var x = minX.floor(); x <= maxX.ceil(); x++) {
      final pixelX = toPixelX(x);
      context.strokeStyle = x == 0 ? axisStyle : gridStyle;
      context.beginPath();
      context.moveTo(pixelX, 0);
      context.lineTo(pixelX, height);
      context.stroke();
    }
    for (var y = minY.floor(); y <= maxY.ceil(); y++) {
      final pixelY = toPixelY(y);
      context.strokeStyle = y == 0 ? axisStyle : gridStyle;
      context.beginPath();
      context.moveTo(0, pixelY);
      context.lineTo(width, pixelY);
      context.stroke();
    }
  }

  /// Plots a numeric function.
  void plot(CanvasRenderingContext2D context, num Function(num x) function,
      {String functionStyle = 'blue'}) {
    context.strokeStyle = functionStyle;
    context.beginPath();
    for (var x = 0; x <= width; x++) {
      context.lineTo(x, toPixelY(function(fromPixelX(x))));
    }
    context.stroke();
  }

  /// Converts logical x-coordinate to pixel.
  num toPixelX(num value) => (value - minX) * width / (maxX - minX);

  /// Converts logical y-coordinate to pixel.
  num toPixelY(num value) => height - (value - minY) * height / (maxY - minY);

  /// Converts pixel to logical x-coordinate.
  num fromPixelX(num value) => value * (maxX - minX) / width + minX;

  /// Converts pixel to logical y-coordinate.
  num fromPixelY(num value) => (height - value) * (maxY - minY) / height + minY;
}

final input = querySelector('#input')! as TextInputElement;
final error = querySelector('#error')! as ParagraphElement;
final canvas = querySelector('#canvas')! as CanvasElement;
final context = canvas.getContext(
  "2d",
)! as CanvasRenderingContext2D;

final viewport =
    Viewport(minX: -5, maxX: 5, minY: -2.5, maxY: 2.5, width: 800, height: 400);

Expression expression = Value(double.nan);

void update() {
  try {
    expression = parser.parse(input.value ?? '0').value;
    expression.eval({'x': 0, 't': 0});
    error.text = '';
  } on Object catch (exception) {
    expression = Value(double.nan);
    error.text = exception.toString();
  }
}

void refresh(int tick) {
  viewport.clear(context);
  viewport.grid(context);
  viewport.plot(context, (x) => expression.eval({'x': x, 't': tick}));
}

void main() {
  update();
  viewport.resize(canvas);
  input.onInput.listen((event) => update());
  Timer.periodic(const Duration(milliseconds: 1000 ~/ 30),
      (Timer timer) => refresh(timer.tick));
}

import 'dart:async';
import 'dart:js_interop';

import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

class Viewport {
  Viewport(
    this.canvas, {
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  }) : context = canvas.context2D,
       width = canvas.offsetWidth,
       height = canvas.offsetHeight;

  final HTMLCanvasElement canvas;
  final CanvasRenderingContext2D context;

  final num minX;
  final num maxX;
  final num minY;
  final num maxY;

  num width;
  num height;

  /// Resizes the canvas.
  void resize(num width, num height) {
    final scale = window.devicePixelRatio;
    this.width = width;
    this.height = height;
    canvas.style.width = '${width}px';
    canvas.style.height = '${height}px';
    canvas.width = (width * scale).truncate();
    canvas.height = (height * scale).truncate();
    context.scale(scale, scale);
  }

  /// Clears the viewport.
  void clear() {
    context.beginPath();
    context.rect(0, 0, width, height);
    context.clip();
    context.clearRect(0, 0, width, height);
  }

  /// Plots the grid and axis.
  void grid({String axisStyle = 'black', String gridStyle = 'gray'}) {
    context.lineWidth = 0.5;
    for (var x = minX.floor(); x <= maxX.ceil(); x++) {
      final pixelX = toPixelX(x);
      context.strokeStyle = x == 0 ? axisStyle.toJS : gridStyle.toJS;
      context.beginPath();
      context.moveTo(pixelX, 0);
      context.lineTo(pixelX, height);
      context.stroke();
    }
    for (var y = minY.floor(); y <= maxY.ceil(); y++) {
      final pixelY = toPixelY(y);
      context.strokeStyle = y == 0 ? axisStyle.toJS : gridStyle.toJS;
      context.beginPath();
      context.moveTo(0, pixelY);
      context.lineTo(width, pixelY);
      context.stroke();
    }
  }

  /// Plots a numeric function.
  void plot(num Function(num x) function, {String functionStyle = 'blue'}) {
    context.strokeStyle = functionStyle.toJS;
    context.lineWidth = 1.0;
    context.beginPath();
    num lastY = double.infinity;
    for (var x = 0; x <= width; x++) {
      final currentY = function(fromPixelX(x));
      if (lastY.isInfinite ||
          currentY.isInfinite ||
          (lastY.sign != currentY.sign && (lastY - currentY).abs() > 100)) {
        context.moveTo(x, toPixelY(currentY));
      } else {
        context.lineTo(x, toPixelY(currentY));
      }
      lastY = currentY;
    }
    context.stroke();
  }

  /// Converts logical x-coordinate to pixel.
  num toPixelX(num value) => (value - minX) * width / (maxX - minX);

  /// Converts logical y-coordinate to pixel.
  num toPixelY(num value) => height - (value - minY) * height / (maxY - minY);

  /// Converts pixel to logical x-coordinate.
  num fromPixelX(num value) => value * (maxX - minX) / width + minX;
}

final input = document.querySelector('#input') as HTMLInputElement;
final error = document.querySelector('#error') as HTMLElement;
final canvas = document.querySelector('#canvas') as HTMLCanvasElement;

final viewport = Viewport(canvas, minX: -5, maxX: 5, minY: -2.5, maxY: 2.5);

Expression expression = Value(double.nan);

void resize(Event event) {
  final rect = canvas.parentElement?.getBoundingClientRect();
  if (rect != null) {
    viewport.resize(rect.width, rect.width / 2);
  }
}

void update() {
  final source = input.value;
  try {
    expression = parser.parse(source).value;
    expression.eval({'x': 0, 't': 0});
    error.textContent = '';
  } on Object catch (exception) {
    expression = Value(double.nan);
    error.textContent = exception.toString();
  }
  window.location.hash = Uri.encodeComponent(source);
}

void refresh(int tick) {
  viewport.clear();
  viewport.grid();
  viewport.plot((x) => expression.eval({'x': x, 't': tick}));
}

void main() {
  if (window.location.hash.startsWith('#')) {
    input.value = Uri.decodeComponent(window.location.hash.substring(1));
  }
  resize(Event('resize'));
  window.addEventListener('resize', resize.toJS);
  update();
  input.onInput.listen((event) => update());
  Timer.periodic(
    const Duration(milliseconds: 1000 ~/ 30),
    (Timer timer) => refresh(timer.tick),
  );
}

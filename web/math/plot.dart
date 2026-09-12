import 'dart:async';
import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

class Viewport {
  new(
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
  void plot(num Function(num x) function, {String functionStyle = '#0e5f8e'}) {
    context.strokeStyle = functionStyle.toJS;
    context.lineWidth = 2.0;
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
    error.style.display = 'none';
  } on Object catch (exception) {
    expression = Value(double.nan);
    error.textContent = exception is ParserException
        ? '${exception.message} at ${exception.failure.toPositionString()}'
        : exception.toString();
    error.style.display = 'block';
  }
  window.location.hash = Uri.encodeComponent(source);
}

final fpsDisplay = document.querySelector('#fps-display') as HTMLElement?;
final animationFrame = refresh.toJS;
final firstFrameTime = DateTime.now().millisecondsSinceEpoch;
var lastFrameTime = firstFrameTime;
var frameCount = 0;
var currentFps = 30;

void refresh() {
  frameCount++;
  final now = DateTime.now().millisecondsSinceEpoch;
  final delta = now - lastFrameTime;
  final offsetSec = (now - firstFrameTime) / 1000.0;
  if (delta >= 1000) {
    currentFps = ((frameCount * 1000) / delta).round();
    frameCount = 0;
    lastFrameTime = now;
    if (fpsDisplay != null) {
      fpsDisplay!.textContent = '$currentFps FPS';
    }
  }

  viewport.clear();
  viewport.grid();
  viewport.plot((x) => expression.eval({'x': x, 't': offsetSec}));

  window.requestAnimationFrame(animationFrame);
}

void main() {
  initShared();

  final presetRipple =
      document.querySelector('#preset-ripple') as HTMLButtonElement?;
  final presetSine =
      document.querySelector('#preset-sine') as HTMLButtonElement?;
  final presetDamped =
      document.querySelector('#preset-damped') as HTMLButtonElement?;
  final presetStanding =
      document.querySelector('#preset-standing') as HTMLButtonElement?;

  void setFunc(String fn) {
    input.value = fn;
    update();
  }

  presetRipple?.onClick.listen((_) => setFunc('x * sin(10 * cos(t) / x)'));
  presetSine?.onClick.listen((_) => setFunc('sin(x + 5 * t) * cos(5 * x)'));
  presetDamped?.onClick.listen(
    (_) => setFunc('2 * exp(-abs(x) / 2) * cos(3 * x - 5 * t)'),
  );
  presetStanding?.onClick.listen((_) => setFunc('sin(2 * x) * cos(10 * t)'));

  if (window.location.hash.startsWith('#')) {
    input.value = Uri.decodeComponent(window.location.hash.substring(1));
  }
  resize(Event('resize'));
  window.addEventListener('resize', resize.toJS);
  update();
  input.onInput.listen((event) => update());
  window.requestAnimationFrame(animationFrame);
}

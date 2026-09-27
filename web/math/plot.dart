import 'dart:js_interop';
import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

class Viewport {
  new(
    this.canvas, {
    this.minX = -5,
    this.maxX = 5,
    this.minY = -2.5,
    this.maxY = 2.5,
  }) : context = canvas.context2D,
       width = canvas.offsetWidth,
       height = canvas.offsetHeight,
       defaultMinX = minX,
       defaultMaxX = maxX,
       defaultMinY = minY,
       defaultMaxY = maxY;

  final HTMLCanvasElement canvas;
  final CanvasRenderingContext2D context;

  final num defaultMinX;
  final num defaultMaxX;
  final num defaultMinY;
  final num defaultMaxY;

  num minX;
  num maxX;
  num minY;
  num maxY;

  num width;
  num height;

  /// Resets the viewport bounds to default values.
  void reset() {
    minX = defaultMinX;
    maxX = defaultMaxX;
    minY = defaultMinY;
    maxY = defaultMaxY;
  }

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

  static num _calculateStep(num min, num max) {
    final span = max - min;
    if (span <= 0 || span.isInfinite || span.isNaN) return 1;
    final rawStep = span / 10;
    final power = (rawStep <= 0 ? 0 : (math.log(rawStep) / math.ln10).floor());
    final magnitude = math.pow(10, power);
    final norm = rawStep / magnitude;
    if (norm < 1.5) return magnitude;
    if (norm < 3.5) return 2 * magnitude;
    if (norm < 7.5) return 5 * magnitude;
    return 10 * magnitude;
  }

  /// Plots the grid and axis.
  void grid({String axisStyle = 'black', String gridStyle = 'gray'}) {
    context.lineWidth = 0.5;
    final stepX = _calculateStep(minX, maxX);
    final startX = (minX / stepX).floor() * stepX;
    for (var x = startX; x <= maxX + stepX / 2; x += stepX) {
      final pixelX = toPixelX(x);
      final isAxis = x.abs() < stepX * 0.1;
      context.strokeStyle = isAxis ? axisStyle.toJS : gridStyle.toJS;
      context.beginPath();
      context.moveTo(pixelX, 0);
      context.lineTo(pixelX, height);
      context.stroke();
    }
    final stepY = _calculateStep(minY, maxY);
    final startY = (minY / stepY).floor() * stepY;
    for (var y = startY; y <= maxY + stepY / 2; y += stepY) {
      final pixelY = toPixelY(y);
      final isAxis = y.abs() < stepY * 0.1;
      context.strokeStyle = isAxis ? axisStyle.toJS : gridStyle.toJS;
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
          lastY.isNaN ||
          currentY.isInfinite ||
          currentY.isNaN ||
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

  /// Converts pixel to logical y-coordinate.
  num fromPixelY(num value) => (height - value) * (maxY - minY) / height + minY;
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

final viewportRange = document.querySelector('#viewport-range') as HTMLElement?;

String _formatNum(num n) {
  if (n.abs() >= 1000 || (n.abs() > 0 && n.abs() < 0.01)) {
    return n.toStringAsExponential(2);
  }
  return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 2);
}

void updateViewportDisplay() {
  if (viewportRange != null) {
    viewportRange!.textContent =
        'x ∈ [${_formatNum(viewport.minX)}, ${_formatNum(viewport.maxX)}], '
        'y ∈ [${_formatNum(viewport.minY)}, ${_formatNum(viewport.maxY)}]';
  }
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
    viewport.reset();
    updateViewportDisplay();
    update();
  }

  presetRipple?.onClick.listen((_) => setFunc('x * sin(10 * cos(t) / x)'));
  presetSine?.onClick.listen((_) => setFunc('sin(x + 5 * t) * cos(5 * x)'));
  presetDamped?.onClick.listen(
    (_) => setFunc('2 * exp(-abs(x) / 2) * cos(3 * x - 5 * t)'),
  );
  presetStanding?.onClick.listen((_) => setFunc('sin(2 * x) * cos(10 * t)'));

  var isDragging = false;
  var dragStartX = 0.0;
  var dragStartY = 0.0;
  var origMinX = viewport.minX;
  var origMaxX = viewport.maxX;
  var origMinY = viewport.minY;
  var origMaxY = viewport.maxY;

  canvas.onMouseDown.listen((MouseEvent event) {
    if (event.button == 0) {
      isDragging = true;
      dragStartX = event.clientX.toDouble();
      dragStartY = event.clientY.toDouble();
      origMinX = viewport.minX;
      origMaxX = viewport.maxX;
      origMinY = viewport.minY;
      origMaxY = viewport.maxY;
      canvas.style.cursor = 'grabbing';
      event.preventDefault();
    }
  });

  window.addEventListener(
    'mousemove',
    ((MouseEvent event) {
      if (!isDragging) return;
      final dx = event.clientX - dragStartX;
      final dy = event.clientY - dragStartY;
      final logicalDx = dx * (origMaxX - origMinX) / viewport.width;
      final logicalDy = dy * (origMaxY - origMinY) / viewport.height;
      viewport.minX = origMinX - logicalDx;
      viewport.maxX = origMaxX - logicalDx;
      viewport.minY = origMinY + logicalDy;
      viewport.maxY = origMaxY + logicalDy;
      updateViewportDisplay();
    }).toJS,
  );

  window.addEventListener(
    'mouseup',
    ((MouseEvent event) {
      if (isDragging) {
        isDragging = false;
        canvas.style.cursor = 'grab';
      }
    }).toJS,
  );

  canvas.onWheel.listen((WheelEvent event) {
    event.preventDefault();
    final rect = canvas.getBoundingClientRect();
    final mouseX = event.clientX - rect.left;
    final mouseY = event.clientY - rect.top;
    final logicalX = viewport.fromPixelX(mouseX);
    final logicalY = viewport.fromPixelY(mouseY);
    final factor = event.deltaY < 0 ? 0.85 : 1.15;

    final newSpanX = (viewport.maxX - viewport.minX) * factor;
    final newSpanY = (viewport.maxY - viewport.minY) * factor;
    if (newSpanX > 1e-9 &&
        newSpanX < 1e9 &&
        newSpanY > 1e-9 &&
        newSpanY < 1e9) {
      viewport.minX = logicalX - (logicalX - viewport.minX) * factor;
      viewport.maxX = logicalX + (viewport.maxX - logicalX) * factor;
      viewport.minY = logicalY - (logicalY - viewport.minY) * factor;
      viewport.maxY = logicalY + (viewport.maxY - logicalY) * factor;
      updateViewportDisplay();
    }
  });

  canvas.addEventListener(
    'dblclick',
    ((Event event) {
      viewport.reset();
      updateViewportDisplay();
    }).toJS,
  );

  if (window.location.hash.startsWith('#')) {
    input.value = Uri.decodeComponent(window.location.hash.substring(1));
  }
  resize(Event('resize'));
  window.addEventListener('resize', resize.toJS);
  update();
  input.onInput.listen((event) => update());
  window.requestAnimationFrame(animationFrame);
}

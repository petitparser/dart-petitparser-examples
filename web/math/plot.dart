import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data' as typed_data;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

/// Checks whether an [Expression] AST contains a reference to variable [target].
bool hasVariable(Expression expr, String target) => switch (expr) {
  Variable(:final name) => name == target,
  Application(:final arguments) => arguments.any(
    (arg) => hasVariable(arg, target),
  ),
  _ => false,
};

/// Minimal column-major 4x4 float matrix for 3D and 2D WebGL transformations.
class Matrix4 {
  new fromValues(this.values);

  final typed_data.Float32List values;

  /// Creates a perspective projection matrix.
  static Matrix4 perspective(
    double fovYRadians,
    double aspect,
    double near,
    double far,
  ) {
    final f = 1.0 / math.tan(fovYRadians / 2.0);
    final rangeInv = 1.0 / (near - far);
    final m = typed_data.Float32List(16);
    m[0] = f / aspect;
    m[5] = f;
    m[10] = (near + far) * rangeInv;
    m[11] = -1.0;
    m[14] = (2.0 * near * far) * rangeInv;
    return Matrix4.fromValues(m);
  }

  /// Creates an orthographic projection matrix.
  static Matrix4 ortho(
    double left,
    double right,
    double bottom,
    double top,
    double near,
    double far,
  ) {
    final m = typed_data.Float32List(16);
    m[0] = 2.0 / (right - left);
    m[5] = 2.0 / (top - bottom);
    m[10] = -2.0 / (far - near);
    m[12] = -(right + left) / (right - left);
    m[13] = -(top + bottom) / (top - bottom);
    m[14] = -(far + near) / (far - near);
    m[15] = 1.0;
    return Matrix4.fromValues(m);
  }

  /// Creates a view matrix looking from eye towards target with up vector.
  static Matrix4 lookAt(
    double eyeX,
    double eyeY,
    double eyeZ,
    double targetX,
    double targetY,
    double targetZ,
    double upX,
    double upY,
    double upZ,
  ) {
    var z0 = eyeX - targetX;
    var z1 = eyeY - targetY;
    var z2 = eyeZ - targetZ;
    var len = math.sqrt(z0 * z0 + z1 * z1 + z2 * z2);
    if (len > 0) {
      z0 /= len;
      z1 /= len;
      z2 /= len;
    }

    var x0 = upY * z2 - upZ * z1;
    var x1 = upZ * z0 - upX * z2;
    var x2 = upX * z1 - upY * z0;
    len = math.sqrt(x0 * x0 + x1 * x1 + x2 * x2);
    if (len > 0) {
      x0 /= len;
      x1 /= len;
      x2 /= len;
    }

    final y0 = z1 * x2 - z2 * x1;
    final y1 = z2 * x0 - z0 * x2;
    final y2 = z0 * x1 - z1 * x0;

    final m = typed_data.Float32List(16);
    m[0] = x0;
    m[1] = y0;
    m[2] = z0;
    m[3] = 0;

    m[4] = x1;
    m[5] = y1;
    m[6] = z1;
    m[7] = 0;

    m[8] = x2;
    m[9] = y2;
    m[10] = z2;
    m[11] = 0;

    m[12] = -(x0 * eyeX + x1 * eyeY + x2 * eyeZ);
    m[13] = -(y0 * eyeX + y1 * eyeY + y2 * eyeZ);
    m[14] = -(z0 * eyeX + z1 * eyeY + z2 * eyeZ);
    m[15] = 1;
    return Matrix4.fromValues(m);
  }

  /// Multiplies matrix [a] by matrix [b] (column-major: `a * b`).
  static Matrix4 multiply(Matrix4 a, Matrix4 b) {
    final aV = a.values;
    final bV = b.values;
    final out = typed_data.Float32List(16);
    for (var i = 0; i < 4; i++) {
      final ai0 = aV[i];
      final ai1 = aV[i + 4];
      final ai2 = aV[i + 8];
      final ai3 = aV[i + 12];
      out[i] = ai0 * bV[0] + ai1 * bV[1] + ai2 * bV[2] + ai3 * bV[3];
      out[i + 4] = ai0 * bV[4] + ai1 * bV[5] + ai2 * bV[6] + ai3 * bV[7];
      out[i + 8] = ai0 * bV[8] + ai1 * bV[9] + ai2 * bV[10] + ai3 * bV[11];
      out[i + 12] = ai0 * bV[12] + ai1 * bV[13] + ai2 * bV[14] + ai3 * bV[15];
    }
    return Matrix4.fromValues(out);
  }
}

/// 3D Camera with interactive orbit, panning, and zoom controls.
class OrbitCamera {
  new({
    this.azimuth = 0.785,
    this.elevation = 0.55,
    this.distance = 16.0,
    this.targetX = 0.0,
    this.targetY = 0.0,
    this.targetZ = 0.0,
  }) : defaultAzimuth = azimuth,
       defaultElevation = elevation,
       defaultDistance = distance,
       defaultTargetX = targetX,
       defaultTargetY = targetY,
       defaultTargetZ = targetZ;

  final double defaultAzimuth;
  final double defaultElevation;
  final double defaultDistance;
  final double defaultTargetX;
  final double defaultTargetY;
  final double defaultTargetZ;

  double azimuth;
  double elevation;
  double distance;
  double targetX;
  double targetY;
  double targetZ;

  /// Resets the camera orientation and target to defaults.
  void reset() {
    azimuth = defaultAzimuth;
    elevation = defaultElevation;
    distance = defaultDistance;
    targetX = defaultTargetX;
    targetY = defaultTargetY;
    targetZ = defaultTargetZ;
  }

  /// Eye position in world coordinates.
  double get eyeX =>
      targetX + distance * math.cos(elevation) * math.sin(azimuth);
  double get eyeY => targetY + distance * math.sin(elevation);
  double get eyeZ =>
      targetZ + distance * math.cos(elevation) * math.cos(azimuth);

  /// Computes the View matrix for current camera state.
  Matrix4 computeViewMatrix() => Matrix4.lookAt(
    eyeX,
    eyeY,
    eyeZ,
    targetX,
    targetY,
    targetZ,
    0.0,
    1.0,
    0.0,
  );
}

/// User-selected plotting mode.
enum PlotMode { auto, mode2d, mode3d }

/// WebGL 2D/3D Math Plotter.
class WebGLPlotter {
  new(this.canvas) {
    final context = canvas.getContext('webgl') as WebGLRenderingContext?;
    if (context == null) {
      throw StateError('WebGL is not supported in this browser.');
    }
    gl = context;
    _initShaders();
    _initBuffers();
  }

  final HTMLCanvasElement canvas;
  late final WebGLRenderingContext gl;

  // 3D Surface shader
  late final WebGLProgram surfaceProgram;
  late final int aPositionLoc;
  late final int aNormalLoc;
  late final int aHeightLoc;
  late final WebGLUniformLocation uMVPLoc;
  late final WebGLUniformLocation uHeightRangeLoc;
  late final WebGLUniformLocation uViewPosLoc;

  // Line & Colored geometry shader (used for static 3D grid/axes and 2D curves)
  late final WebGLProgram colorProgram;
  late final int aColorPosLoc;
  late final int aColorColorLoc;
  late final WebGLUniformLocation uColorMVPLoc;

  // 3D Grid mesh resolution (optimized for 60 FPS on mobile devices)
  static const int resolution3D = 60;
  static const int vertexCount3D = (resolution3D + 1) * (resolution3D + 1);
  static const int triangleCount3D = resolution3D * resolution3D * 2;
  static const int indexCount3D = triangleCount3D * 3;
  static const int padStride3D = resolution3D + 3;

  late final WebGLBuffer surfaceVertexBuffer;
  late final WebGLBuffer surfaceIndexBuffer;
  late final WebGLBuffer dynamicLineBuffer;

  final typed_data.Float32List vertexData3D = typed_data.Float32List(
    vertexCount3D * 7,
  );
  final typed_data.Float32List heights3D = typed_data.Float32List(
    padStride3D * padStride3D,
  );
  final typed_data.Float32List staticLineData = typed_data.Float32List(2000);

  // Reusable environment map for zero-allocation AST evaluations
  final Map<String, num> env = <String, num>{'x': 0.0, 'y': 0.0, 't': 0.0};

  // 2D Curve sampling preallocated arrays
  static const int samples2D = 800;
  final typed_data.Float32List sampleX2D = typed_data.Float32List(
    samples2D + 1,
  );
  final typed_data.Float32List sampleY2D = typed_data.Float32List(
    samples2D + 1,
  );
  final typed_data.Float32List curveTriangles2D = typed_data.Float32List(
    samples2D * 6 * 7,
  );

  // 2D Viewport ranges
  double minX2D = -5.0;
  double maxX2D = 5.0;
  double minY2D = -3.0;
  double maxY2D = 3.0;

  // Grid and axis visibility
  bool showGrid = true;
  bool showAxes = true;

  num width = 0;
  num height = 0;

  void _initShaders() {
    // 3D Surface Shaders with Vibrant Turbo Gradient + Glossy Specular + Fresnel Rim
    const surfaceVertexShaderSource = '''
attribute vec3 aPosition;
attribute vec3 aNormal;
attribute float aHeight;

uniform mat4 uMVP;
uniform vec2 uHeightRange;

varying vec3 vNormal;
varying vec3 vPosition;
varying float vNormalizedHeight;

void main() {
  vPosition = aPosition;
  vNormal = aNormal;
  float range = max(0.001, uHeightRange.y - uHeightRange.x);
  vNormalizedHeight = clamp((aHeight - uHeightRange.x) / range, 0.0, 1.0);
  gl_Position = uMVP * vec4(aPosition, 1.0);
}
''';

    const surfaceFragmentShaderSource = '''
#ifdef GL_FRAGMENT_PRECISION_HIGH
precision highp float;
#else
precision mediump float;
#endif

varying vec3 vNormal;
varying vec3 vPosition;
varying float vNormalizedHeight;

uniform vec3 uViewPos;

void main() {
  // Discard fragments outside the vertical bounds [-3.0, 3.0] to form clean holes
  if (vPosition.y > 3.0 || vPosition.y < -3.0) {
    discard;
  }

  vec3 viewDir = normalize(uViewPos - vPosition);
  vec3 normal = normalize(vNormal);
  if (!gl_FrontFacing) normal = -normal;

  // Blue checkerboard pattern (1x1 unit squares in x, z coordinates)
  float checkX = floor(clamp(vPosition.x + 5.0, 0.0, 9.9999));
  float checkZ = floor(clamp(vPosition.z + 5.0, 0.0, 9.9999));
  float check = mod(checkX + checkZ, 2.0);
  vec3 cLight = vec3(0.25, 0.58, 0.95); // Vibrant Azure Blue
  vec3 cDark = vec3(0.12, 0.36, 0.80);  // Royal Cobalt Blue
  vec3 baseColor = mix(cDark, cLight, step(0.5, check));

  // Subtle height modulation (+-12%) for enhanced 3D topology perception
  baseColor = mix(baseColor * 0.88, baseColor * 1.12, vNormalizedHeight);

  // Underside styling: deep midnight navy checkerboard
  if (!gl_FrontFacing) {
    vec3 uLight = vec3(0.14, 0.28, 0.60);
    vec3 uDark = vec3(0.08, 0.18, 0.45);
    baseColor = mix(uDark, uLight, step(0.5, check));
  }

  // Clean, crisp cut rim along the boundary of the hole
  float distToCut = min(3.0 - vPosition.y, vPosition.y - (-3.0));
  if (distToCut < 0.045) {
    baseColor = gl_FrontFacing
        ? vec3(0.06, 0.20, 0.52)
        : vec3(0.04, 0.12, 0.32);
  }

  // Directional key and fill lights with two-sided orientation
  vec3 lightDir1 = gl_FrontFacing
      ? normalize(vec3(0.5, 1.2, 0.6))
      : normalize(vec3(0.4, -1.2, 0.5));
  vec3 lightDir2 = gl_FrontFacing
      ? normalize(vec3(-0.6, 0.8, -0.5))
      : normalize(vec3(-0.5, -0.8, -0.4));

  float diff1 = max(dot(normal, lightDir1), 0.0) * 0.55;
  float diff2 = max(dot(normal, lightDir2), 0.0) * 0.20;
  float ambient = 0.32;

  // Glossy Blinn-Phong specular highlight (sharp and clean)
  vec3 halfDir1 = normalize(lightDir1 + viewDir);
  float spec1 = pow(max(dot(normal, halfDir1), 0.0), 36.0) *
      (gl_FrontFacing ? 0.55 : 0.40);

  vec3 halfDir2 = normalize(lightDir2 + viewDir);
  float spec2 = pow(max(dot(normal, halfDir2), 0.0), 24.0) * 0.15;

  vec3 color = baseColor * (ambient + diff1 + diff2) + vec3(spec1 + spec2);
  gl_FragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
''';

    // Line & Colored geometry Shader (with per-vertex colors)
    const colorVertexShaderSource = '''
attribute vec3 aPosition;
attribute vec4 aColor;
uniform mat4 uMVP;
varying vec4 vColor;

void main() {
  vColor = aColor;
  gl_Position = uMVP * vec4(aPosition, 1.0);
}
''';

    const colorFragmentShaderSource = '''
precision mediump float;
varying vec4 vColor;

void main() {
  gl_FragColor = vColor;
}
''';

    surfaceProgram = _compileProgram(
      surfaceVertexShaderSource,
      surfaceFragmentShaderSource,
    );
    aPositionLoc = gl.getAttribLocation(surfaceProgram, 'aPosition');
    aNormalLoc = gl.getAttribLocation(surfaceProgram, 'aNormal');
    aHeightLoc = gl.getAttribLocation(surfaceProgram, 'aHeight');
    uMVPLoc = gl.getUniformLocation(surfaceProgram, 'uMVP')!;
    uHeightRangeLoc = gl.getUniformLocation(surfaceProgram, 'uHeightRange')!;
    uViewPosLoc = gl.getUniformLocation(surfaceProgram, 'uViewPos')!;

    colorProgram = _compileProgram(
      colorVertexShaderSource,
      colorFragmentShaderSource,
    );
    aColorPosLoc = gl.getAttribLocation(colorProgram, 'aPosition');
    aColorColorLoc = gl.getAttribLocation(colorProgram, 'aColor');
    uColorMVPLoc = gl.getUniformLocation(colorProgram, 'uMVP')!;
  }

  WebGLProgram _compileProgram(String vsSource, String fsSource) {
    final vs = gl.createShader(WebGLRenderingContext.VERTEX_SHADER)!;
    gl.shaderSource(vs, vsSource);
    gl.compileShader(vs);
    final vsOk = gl.getShaderParameter(
      vs,
      WebGLRenderingContext.COMPILE_STATUS,
    ) as JSBoolean?;
    if (vsOk == null || !vsOk.toDart) {
      final info = gl.getShaderInfoLog(vs);
      gl.deleteShader(vs);
      throw StateError('Vertex shader compilation error: $info');
    }

    final fs = gl.createShader(WebGLRenderingContext.FRAGMENT_SHADER)!;
    gl.shaderSource(fs, fsSource);
    gl.compileShader(fs);
    final fsOk = gl.getShaderParameter(
      fs,
      WebGLRenderingContext.COMPILE_STATUS,
    ) as JSBoolean?;
    if (fsOk == null || !fsOk.toDart) {
      final info = gl.getShaderInfoLog(fs);
      gl.deleteShader(fs);
      throw StateError('Fragment shader compilation error: $info');
    }

    final program = gl.createProgram()!;
    gl.attachShader(program, vs);
    gl.attachShader(program, fs);
    gl.linkProgram(program);
    final linked = gl.getProgramParameter(
      program,
      WebGLRenderingContext.LINK_STATUS,
    ) as JSBoolean?;
    if (linked == null || !linked.toDart) {
      final info = gl.getProgramInfoLog(program);
      throw StateError('Program linking error: $info');
    }
    return program;
  }

  void _initBuffers() {
    surfaceVertexBuffer = gl.createBuffer()!;
    surfaceIndexBuffer = gl.createBuffer()!;
    dynamicLineBuffer = gl.createBuffer()!;

    // Static 3D grid index buffer
    final indices = typed_data.Uint16List(indexCount3D);
    var indexPtr = 0;
    const stride = resolution3D + 1;
    for (var i = 0; i < resolution3D; i++) {
      for (var j = 0; j < resolution3D; j++) {
        final v0 = i * stride + j;
        final v1 = v0 + 1;
        final v2 = (i + 1) * stride + j;
        final v3 = v2 + 1;

        if ((i + j) % 2 == 0) {
          indices[indexPtr++] = v0;
          indices[indexPtr++] = v1;
          indices[indexPtr++] = v2;

          indices[indexPtr++] = v2;
          indices[indexPtr++] = v1;
          indices[indexPtr++] = v3;
        } else {
          indices[indexPtr++] = v0;
          indices[indexPtr++] = v1;
          indices[indexPtr++] = v3;

          indices[indexPtr++] = v0;
          indices[indexPtr++] = v3;
          indices[indexPtr++] = v2;
        }
      }
    }

    gl.bindBuffer(
      WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
      surfaceIndexBuffer,
    );
    gl.bufferData(
      WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
      indices.toJS,
      WebGLRenderingContext.STATIC_DRAW,
    );
  }

  /// Resizes canvas and viewport according to display pixel ratio.
  void resize(num cssWidth, num cssHeight) {
    final scale = window.devicePixelRatio;
    width = cssWidth;
    height = cssHeight;
    canvas.style.width = '${cssWidth}px';
    canvas.style.height = '${cssHeight}px';
    canvas.width = (cssWidth * scale).truncate();
    canvas.height = (cssHeight * scale).truncate();
  }

  /// Renders either 2D curve or 3D surface depending on [is3D].
  void render({
    required bool is3D,
    required Expression expression,
    required double t,
    required OrbitCamera camera,
  }) {
    if (width <= 0 || height <= 0) return;

    gl.viewport(0, 0, canvas.width, canvas.height);
    gl.clearColor(1.0, 1.0, 1.0, 1.0); // Clean white background
    gl.clearDepth(1.0);

    if (is3D) {
      _render3D(expression: expression, t: t, camera: camera);
    } else {
      _render2D(expression: expression, t: t);
    }
  }

  // ==========================================
  // 3D SURFACE RENDERING
  // ==========================================
  void _render3D({
    required Expression expression,
    required double t,
    required OrbitCamera camera,
  }) {
    gl.enable(WebGLRenderingContext.DEPTH_TEST);
    gl.depthFunc(WebGLRenderingContext.LEQUAL);
    gl.clear(
      WebGLRenderingContext.COLOR_BUFFER_BIT |
          WebGLRenderingContext.DEPTH_BUFFER_BIT,
    );

    // 1. Evaluate surface heights on fixed [-5, 5] grid with 1-cell border for exact normals
    const minX = -5.0;
    const maxX = 5.0;
    const minY = -5.0;
    const maxY = 5.0;
    const stepX = (maxX - minX) / resolution3D;
    const stepY = (maxY - minY) / resolution3D;
    const padStride = padStride3D;

    var minZ = double.infinity;
    var maxZ = double.negativeInfinity;

    env['t'] = t;

    for (var i = -1; i <= resolution3D + 1; i++) {
      final x = minX + i * stepX;
      final rowOffset = (i + 1) * padStride;
      env['x'] = x;
      for (var j = -1; j <= resolution3D + 1; j++) {
        final y = minY + j * stepY;
        env['y'] = y;
        double z;
        try {
          final res = expression.eval(env);
          final val = res.toDouble();
          z = (val.isNaN || val.isInfinite) ? double.nan : val.clamp(-6.0, 6.0);
        } on Object {
          z = double.nan;
        }

        heights3D[rowOffset + (j + 1)] = z;
        if (i >= 0 && i <= resolution3D && j >= 0 && j <= resolution3D) {
          if (!z.isNaN && z >= -3.0 && z <= 3.0) {
            if (z < minZ) minZ = z;
            if (z > maxZ) maxZ = z;
          }
        }
      }
    }
    if (minZ.isInfinite || maxZ.isInfinite) {
      minZ = -3.0;
      maxZ = 3.0;
    }

    // 2. Compute smooth central-difference normals and pack vertex data
    var vertexPtr = 0;
    const inv2StepX = 1.0 / (2.0 * stepX);
    const inv2StepY = 1.0 / (2.0 * stepY);
    const invStepX = 1.0 / stepX;
    const invStepY = 1.0 / stepY;

    for (var i = 0; i <= resolution3D; i++) {
      final x = minX + i * stepX;
      final rowOffset = (i + 1) * padStride;
      for (var j = 0; j <= resolution3D; j++) {
        final y = minY + j * stepY;
        final idx = rowOffset + (j + 1);
        final z = heights3D[idx];

        final zLeft = heights3D[idx - padStride];
        final zRight = heights3D[idx + padStride];
        final zDown = heights3D[idx - 1];
        final zUp = heights3D[idx + 1];

        double dzX;
        if (zLeft.isNaN && zRight.isNaN) {
          dzX = 0.0;
        } else if (zLeft.isNaN) {
          dzX = (zRight - (z.isNaN ? 0.0 : z)) * invStepX;
        } else if (zRight.isNaN) {
          dzX = ((z.isNaN ? 0.0 : z) - zLeft) * invStepX;
        } else {
          dzX = (zRight - zLeft) * inv2StepX;
        }

        double dzY;
        if (zDown.isNaN && zUp.isNaN) {
          dzY = 0.0;
        } else if (zDown.isNaN) {
          dzY = (zUp - (z.isNaN ? 0.0 : z)) * invStepY;
        } else if (zUp.isNaN) {
          dzY = ((z.isNaN ? 0.0 : z) - zDown) * invStepY;
        } else {
          dzY = (zUp - zDown) * inv2StepY;
        }

        // Map math coordinates to 3D world: X=x, Y=z (height up), Z=y
        var nx = -dzX;
        var ny = 1.0;
        var nz = -dzY;
        final nLen = math.sqrt(nx * nx + 1.0 + nz * nz);
        if (nLen > 0) {
          final invLen = 1.0 / nLen;
          nx *= invLen;
          ny = invLen;
          nz *= invLen;
        }

        final renderZ = z.isNaN ? 10.0 : z;
        vertexData3D[vertexPtr++] = x;
        vertexData3D[vertexPtr++] = renderZ;
        vertexData3D[vertexPtr++] = y;
        vertexData3D[vertexPtr++] = nx;
        vertexData3D[vertexPtr++] = ny;
        vertexData3D[vertexPtr++] = nz;
        vertexData3D[vertexPtr++] = renderZ;
      }
    }

    // 3. Upload dynamic surface vertex buffer
    gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, surfaceVertexBuffer);
    gl.bufferData(
      WebGLRenderingContext.ARRAY_BUFFER,
      vertexData3D.toJS,
      WebGLRenderingContext.DYNAMIC_DRAW,
    );

    // 4. Compute matrices
    final aspect = width / height;
    final proj = Matrix4.perspective(
      45.0 * math.pi / 180.0,
      aspect.toDouble(),
      0.05,
      100.0,
    );
    final view = camera.computeViewMatrix();
    final mvp = Matrix4.multiply(proj, view);

    // 5. Render lit surface
    gl.useProgram(surfaceProgram);
    gl.uniformMatrix4fv(uMVPLoc, false, mvp.values.toJS);
    gl.uniform2f(uHeightRangeLoc, minZ, maxZ);
    gl.uniform3f(uViewPosLoc, camera.eyeX, camera.eyeY, camera.eyeZ);

    const strideBytes = 7 * 4;
    gl.enableVertexAttribArray(aPositionLoc);
    gl.vertexAttribPointer(
      aPositionLoc,
      3,
      WebGLRenderingContext.FLOAT,
      false,
      strideBytes,
      0,
    );

    gl.enableVertexAttribArray(aNormalLoc);
    gl.vertexAttribPointer(
      aNormalLoc,
      3,
      WebGLRenderingContext.FLOAT,
      false,
      strideBytes,
      3 * 4,
    );

    gl.enableVertexAttribArray(aHeightLoc);
    gl.vertexAttribPointer(
      aHeightLoc,
      1,
      WebGLRenderingContext.FLOAT,
      false,
      strideBytes,
      6 * 4,
    );

    gl.bindBuffer(
      WebGLRenderingContext.ELEMENT_ARRAY_BUFFER,
      surfaceIndexBuffer,
    );
    gl.drawElements(
      WebGLRenderingContext.TRIANGLES,
      indexCount3D,
      WebGLRenderingContext.UNSIGNED_SHORT,
      0,
    );

    // 6. Draw STATIC 3D reference grid and axes (firmly anchored at fixed Y = -3.0)
    _drawStatic3DGridAndAxes(mvp, camera);
  }

  /// Draws static ground grid, back wall reference grids, and coordinate axes.
  void _drawStatic3DGridAndAxes(Matrix4 mvp, OrbitCamera camera) {
    const fixedFloorY = -3.0;
    var linePtr = 0;

    void addLine(
      double x1,
      double y1,
      double z1,
      double x2,
      double y2,
      double z2,
      double r,
      double g,
      double b,
      double a,
    ) {
      staticLineData[linePtr++] = x1;
      staticLineData[linePtr++] = y1;
      staticLineData[linePtr++] = z1;
      staticLineData[linePtr++] = r;
      staticLineData[linePtr++] = g;
      staticLineData[linePtr++] = b;
      staticLineData[linePtr++] = a;

      staticLineData[linePtr++] = x2;
      staticLineData[linePtr++] = y2;
      staticLineData[linePtr++] = z2;
      staticLineData[linePtr++] = r;
      staticLineData[linePtr++] = g;
      staticLineData[linePtr++] = b;
      staticLineData[linePtr++] = a;
    }

    const gridR = 0.82;
    const gridG = 0.85;
    const gridB = 0.90;
    const gridA = 1.0;

    if (showGrid) {
      // 1. Z-plane grid (horizontal ground floor at Y = -3.0)
      for (var i = -5; i <= 5; i++) {
        final v = i.toDouble();
        // Lines parallel to Z
        addLine(
          v,
          fixedFloorY,
          -5.0,
          v,
          fixedFloorY,
          5.0,
          gridR,
          gridG,
          gridB,
          gridA,
        );
        // Lines parallel to X
        addLine(
          -5.0,
          fixedFloorY,
          v,
          5.0,
          fixedFloorY,
          v,
          gridR,
          gridG,
          gridB,
          gridA,
        );
      }

      // 2. Y-plane grid (back wall perpendicular to depth/math y at backZ)
      final backZ = camera.eyeZ >= 0 ? -5.0 : 5.0;
      for (var i = -3; i <= 3; i++) {
        final y = i.toDouble();
        // Horizontal lines along X
        addLine(-5.0, y, backZ, 5.0, y, backZ, gridR, gridG, gridB, gridA);
      }
      for (var i = -5; i <= 5; i++) {
        final x = i.toDouble();
        // Vertical lines along height Y
        addLine(
          x,
          fixedFloorY,
          backZ,
          x,
          3.0,
          backZ,
          gridR,
          gridG,
          gridB,
          gridA,
        );
      }

      // 3. X-plane grid (side wall perpendicular to math x at backX)
      final backX = camera.eyeX >= 0 ? -5.0 : 5.0;
      for (var i = -3; i <= 3; i++) {
        final y = i.toDouble();
        // Horizontal lines along Z
        addLine(backX, y, -5.0, backX, y, 5.0, gridR, gridG, gridB, gridA);
      }
      for (var i = -5; i <= 5; i++) {
        final z = i.toDouble();
        // Vertical lines along height Y
        addLine(
          backX,
          fixedFloorY,
          z,
          backX,
          3.0,
          z,
          gridR,
          gridG,
          gridB,
          gridA,
        );
      }
    }

    // 4. 3D coordinate axes passing through (0, 0, 0) aligned with grid bounds
    if (showAxes) {
      // X Axis: Vibrant Red through (0, 0, 0)
      addLine(-5.0, 0.0, 0.0, 5.0, 0.0, 0.0, 0.92, 0.18, 0.18, 1.0);
      // Y Axis (math y, depth in 3D): Vibrant Green through (0, 0, 0)
      addLine(0.0, 0.0, -5.0, 0.0, 0.0, 5.0, 0.10, 0.72, 0.35, 1.0);
      // Z Axis (math z, vertical height): Vibrant Blue through (0, 0, 0)
      addLine(0.0, -3.0, 0.0, 0.0, 3.0, 0.0, 0.18, 0.45, 0.95, 1.0);
    }

    if (linePtr == 0) return;

    gl.useProgram(colorProgram);
    gl.uniformMatrix4fv(uColorMVPLoc, false, mvp.values.toJS);

    gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, dynamicLineBuffer);
    gl.bufferData(
      WebGLRenderingContext.ARRAY_BUFFER,
      staticLineData.toJS,
      WebGLRenderingContext.DYNAMIC_DRAW,
    );

    const stride = 7 * 4;
    gl.enableVertexAttribArray(aColorPosLoc);
    gl.vertexAttribPointer(
      aColorPosLoc,
      3,
      WebGLRenderingContext.FLOAT,
      false,
      stride,
      0,
    );

    gl.enableVertexAttribArray(aColorColorLoc);
    gl.vertexAttribPointer(
      aColorColorLoc,
      4,
      WebGLRenderingContext.FLOAT,
      false,
      stride,
      3 * 4,
    );

    gl.drawArrays(WebGLRenderingContext.LINES, 0, linePtr ~/ 7);
  }

  // ==========================================
  // 2D CURVE RENDERING (WebGL Orthographic)
  // ==========================================
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

  void _render2D({required Expression expression, required double t}) {
    gl.disable(WebGLRenderingContext.DEPTH_TEST);
    gl.clear(WebGLRenderingContext.COLOR_BUFFER_BIT);

    final ortho = Matrix4.ortho(minX2D, maxX2D, minY2D, maxY2D, -1.0, 1.0);

    // 1. Draw 2D static/adaptive grid lines and axes
    var linePtr = 0;
    void add2DLine(
      double x1,
      double y1,
      double x2,
      double y2,
      double r,
      double g,
      double b,
      double a,
    ) {
      staticLineData[linePtr++] = x1;
      staticLineData[linePtr++] = y1;
      staticLineData[linePtr++] = 0.0;
      staticLineData[linePtr++] = r;
      staticLineData[linePtr++] = g;
      staticLineData[linePtr++] = b;
      staticLineData[linePtr++] = a;

      staticLineData[linePtr++] = x2;
      staticLineData[linePtr++] = y2;
      staticLineData[linePtr++] = 0.0;
      staticLineData[linePtr++] = r;
      staticLineData[linePtr++] = g;
      staticLineData[linePtr++] = b;
      staticLineData[linePtr++] = a;
    }

    if (showGrid) {
      final stepX = _calculateStep(minX2D, maxX2D).toDouble();
      final startX = (minX2D / stepX).floor() * stepX;
      for (var x = startX; x <= maxX2D + stepX / 2; x += stepX) {
        add2DLine(x, minY2D, x, maxY2D, 0.88, 0.90, 0.94, 1.0);
      }

      final stepY = _calculateStep(minY2D, maxY2D).toDouble();
      final startY = (minY2D / stepY).floor() * stepY;
      for (var y = startY; y <= maxY2D + stepY / 2; y += stepY) {
        add2DLine(minX2D, y, maxX2D, y, 0.88, 0.90, 0.94, 1.0);
      }
    }

    if (showAxes) {
      // Prominent central axes through (0, 0)
      if (0 >= minX2D && 0 <= maxX2D) {
        add2DLine(0.0, minY2D, 0.0, maxY2D, 0.35, 0.40, 0.48, 1.0);
      }
      if (0 >= minY2D && 0 <= maxY2D) {
        add2DLine(minX2D, 0.0, maxX2D, 0.0, 0.35, 0.40, 0.48, 1.0);
      }
    }

    // 2. Sample 2D curve and generate a smooth thick ribbon
    const samples = samples2D;
    env['t'] = t;
    env['y'] = 0.0;

    for (var i = 0; i <= samples; i++) {
      final x = minX2D + i * (maxX2D - minX2D) / samples;
      env['x'] = x;
      var y = 0.0;
      try {
        final res = expression.eval(env);
        y = res.toDouble();
        if (y.isNaN) y = double.nan;
      } on Object {
        y = double.nan;
      }
      sampleX2D[i] = x;
      sampleY2D[i] = y;
    }

    final pixelWidth = (maxX2D - minX2D) / width;
    final pixelHeight = (maxY2D - minY2D) / height;
    const halfLineWidth = 1.0; // 2.0px line thickness for a crisp, fine curve

    var triPtr = 0;
    void addRibbonQuad(
      double x0,
      double y0,
      double nx0,
      double ny0,
      double x1,
      double y1,
      double nx1,
      double ny1,
      double r,
      double g,
      double b,
    ) {
      // 2 triangles forming quad: (v0, v1, v2) and (v2, v1, v3)
      final p0x = x0 + nx0;
      final p0y = y0 + ny0;
      final p1x = x0 - nx0;
      final p1y = y0 - ny0;
      final p2x = x1 + nx1;
      final p2y = y1 + ny1;
      final p3x = x1 - nx1;
      final p3y = y1 - ny1;

      curveTriangles2D[triPtr++] = p0x;
      curveTriangles2D[triPtr++] = p0y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;

      curveTriangles2D[triPtr++] = p1x;
      curveTriangles2D[triPtr++] = p1y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;

      curveTriangles2D[triPtr++] = p2x;
      curveTriangles2D[triPtr++] = p2y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;

      curveTriangles2D[triPtr++] = p2x;
      curveTriangles2D[triPtr++] = p2y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;

      curveTriangles2D[triPtr++] = p1x;
      curveTriangles2D[triPtr++] = p1y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;

      curveTriangles2D[triPtr++] = p3x;
      curveTriangles2D[triPtr++] = p3y;
      curveTriangles2D[triPtr++] = 0.0;
      curveTriangles2D[triPtr++] = r;
      curveTriangles2D[triPtr++] = g;
      curveTriangles2D[triPtr++] = b;
      curveTriangles2D[triPtr++] = 1.0;
    }

    for (var i = 0; i < samples; i++) {
      final y0 = sampleY2D[i];
      final y1 = sampleY2D[i + 1];
      if (y0.isNaN ||
          y0.isInfinite ||
          y1.isNaN ||
          y1.isInfinite ||
          (y1 - y0).abs() > (maxY2D - minY2D) * 1.5) {
        continue;
      }
      final x0 = sampleX2D[i];
      final x1 = sampleX2D[i + 1];

      final dx = (x1 - x0) / pixelWidth;
      final dy = (y1 - y0) / pixelHeight;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len <= 0) continue;

      final nx = -(dy / len) * halfLineWidth * pixelWidth;
      final ny = (dx / len) * halfLineWidth * pixelHeight;

      // Vibrant colormap along curve height
      final normY = ((y0 - minY2D) / (maxY2D - minY2D)).clamp(0.0, 1.0);
      final r = math.sin(normY * math.pi) * 0.2 + (1.0 - normY) * 0.1;
      final g = 0.42 + normY * 0.35;
      final b = 0.85 + normY * 0.12;

      addRibbonQuad(x0, y0, nx, ny, x1, y1, nx, ny, r, g, b);
    }

    // Render Grid Lines
    if (linePtr > 0) {
      gl.useProgram(colorProgram);
      gl.uniformMatrix4fv(uColorMVPLoc, false, ortho.values.toJS);
      gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, dynamicLineBuffer);
      gl.bufferData(
        WebGLRenderingContext.ARRAY_BUFFER,
        staticLineData.toJS,
        WebGLRenderingContext.DYNAMIC_DRAW,
      );

      const stride = 7 * 4;
      gl.enableVertexAttribArray(aColorPosLoc);
      gl.vertexAttribPointer(
        aColorPosLoc,
        3,
        WebGLRenderingContext.FLOAT,
        false,
        stride,
        0,
      );
      gl.enableVertexAttribArray(aColorColorLoc);
      gl.vertexAttribPointer(
        aColorColorLoc,
        4,
        WebGLRenderingContext.FLOAT,
        false,
        stride,
        3 * 4,
      );
      gl.drawArrays(WebGLRenderingContext.LINES, 0, linePtr ~/ 7);
    }

    // Render Curve Ribbon
    if (triPtr > 0) {
      gl.useProgram(colorProgram);
      gl.uniformMatrix4fv(uColorMVPLoc, false, ortho.values.toJS);
      gl.bindBuffer(WebGLRenderingContext.ARRAY_BUFFER, dynamicLineBuffer);
      gl.bufferData(
        WebGLRenderingContext.ARRAY_BUFFER,
        curveTriangles2D.toJS,
        WebGLRenderingContext.DYNAMIC_DRAW,
      );

      const stride = 7 * 4;
      gl.enableVertexAttribArray(aColorPosLoc);
      gl.vertexAttribPointer(
        aColorPosLoc,
        3,
        WebGLRenderingContext.FLOAT,
        false,
        stride,
        0,
      );
      gl.enableVertexAttribArray(aColorColorLoc);
      gl.vertexAttribPointer(
        aColorColorLoc,
        4,
        WebGLRenderingContext.FLOAT,
        false,
        stride,
        3 * 4,
      );
      gl.drawArrays(WebGLRenderingContext.TRIANGLES, 0, triPtr ~/ 7);
    }
  }
}

final input = document.querySelector('#input') as HTMLInputElement;
final error = document.querySelector('#error') as HTMLElement;
final canvas = document.querySelector('#canvas') as HTMLCanvasElement;
final viewportRange = document.querySelector('#viewport-range') as HTMLElement?;
final formulaLabel = document.querySelector('#formula-label') as HTMLElement?;
final interactionHint =
    document.querySelector('#interaction-hint') as HTMLElement?;
HTMLElement? fpsDisplay;

final toggleGrid = document.querySelector('#toggle-grid') as HTMLInputElement?;
final toggleAxis = document.querySelector('#toggle-axis') as HTMLInputElement?;

final modeAutoBtn = document.querySelector('#mode-auto') as HTMLButtonElement?;
final mode2DBtn = document.querySelector('#mode-2d') as HTMLButtonElement?;
final mode3DBtn = document.querySelector('#mode-3d') as HTMLButtonElement?;

late final WebGLPlotter plotter;
final camera = OrbitCamera();
PlotMode currentMode = PlotMode.auto;

Expression expression = Value(double.nan);

bool get is3DActive => switch (currentMode) {
  PlotMode.mode2d => false,
  PlotMode.mode3d => true,
  PlotMode.auto => hasVariable(expression, 'y'),
};

void updateModeUI() {
  modeAutoBtn?.classList.toggle('active-mode', currentMode == PlotMode.auto);
  mode2DBtn?.classList.toggle('active-mode', currentMode == PlotMode.mode2d);
  mode3DBtn?.classList.toggle('active-mode', currentMode == PlotMode.mode3d);

  final active3D = is3DActive;
  if (formulaLabel != null) {
    formulaLabel!.innerHTML =
        (active3D ? 'z = f<sub>t</sub>(x, y)' : 'y = f<sub>t</sub>(x)').toJS;
  }
  if (interactionHint != null) {
    interactionHint!.textContent = active3D
        ? 'Drag to rotate • Shift/2-finger drag to pan • Pinch/scroll to zoom • Double-tap to reset'
        : 'Drag to pan • Pinch/scroll to zoom • Double-tap to reset';
  }
  updateViewportDisplay();
}

void updateViewportDisplay() {
  if (viewportRange == null) return;
  if (is3DActive) {
    final azDeg = (camera.azimuth * 180 / math.pi).round();
    final elDeg = (camera.elevation * 180 / math.pi).round();
    viewportRange!.textContent =
        'x, y ∈ [-5, 5], z ∈ [-3, 3], rotation: $azDeg°, pitch: $elDeg°, zoom: ${camera.distance.toStringAsFixed(1)}';
  } else {
    String formatNum(double n) =>
        n.truncateToDouble() == n ? n.toInt().toString() : n.toStringAsFixed(2);
    viewportRange!.textContent =
        'x ∈ [${formatNum(plotter.minX2D)}, ${formatNum(plotter.maxX2D)}], '
        'y ∈ [${formatNum(plotter.minY2D)}, ${formatNum(plotter.maxY2D)}]';
  }
}

void resize(Event event) {
  final rect = canvas.parentElement?.getBoundingClientRect();
  if (rect != null) {
    final width = rect.width;
    // Adapt height to width and viewport height so the canvas stays proportional on mobile.
    final maxViewportHeight = window.innerHeight > 0
        ? window.innerHeight * 0.7
        : 500.0;
    final maxHeight = math.min(500.0, math.max(260.0, maxViewportHeight));
    final height = (width * 0.75).clamp(240.0, maxHeight);
    plotter.resize(width, height);
  }
}

void update() {
  final source = input.value;
  try {
    expression = parser.parse(source).value;
    expression.eval({'x': 0, 'y': 0, 't': 0});
    error.textContent = '';
    error.style.display = 'none';
  } on Object catch (exception) {
    expression = Value(double.nan);
    error.textContent = exception is ParserException
        ? '${exception.message} at ${exception.failure.toPositionString()}'
        : exception.toString();
    error.style.display = 'block';
  }
  updateModeUI();
  window.location.hash = Uri.encodeComponent(source);
}

final animationFrame = refresh.toJS;
final firstFrameTime = DateTime.now().millisecondsSinceEpoch;
var lastFrameTime = firstFrameTime;
var frameCount = 0;
var currentFps = 60;

void refresh() {
  frameCount++;
  final now = DateTime.now().millisecondsSinceEpoch;
  final delta = now - lastFrameTime;
  final offsetSec = (now - firstFrameTime) / 1000.0;
  if (delta >= 1000) {
    currentFps = ((frameCount * 1000) / delta).round();
    frameCount = 0;
    lastFrameTime = now;
    fpsDisplay ??= document.querySelector('#fps-display') as HTMLElement?;
    fpsDisplay?.textContent = '$currentFps FPS';
  }

  plotter.render(
    is3D: is3DActive,
    expression: expression,
    t: offsetSec,
    camera: camera,
  );

  window.requestAnimationFrame(animationFrame);
}

void main() {
  initShared();
  fpsDisplay = document.querySelector('#fps-display') as HTMLElement?;

  plotter = WebGLPlotter(canvas);

  void setFunc(String fn) {
    input.value = fn;
    camera.reset();
    plotter.minX2D = -5.0;
    plotter.maxX2D = 5.0;
    plotter.minY2D = -3.0;
    plotter.maxY2D = 3.0;
    update();
  }

  // 3D Presets
  document
      .querySelector('#preset-ripple-3d')
      ?.onClick
      .listen(
        (_) =>
            setFunc('sin(sqrt(x^2 + y^2) - 4 * t) / (1 + 0.2 * (x^2 + y^2))'),
      );
  document
      .querySelector('#preset-waves-3d')
      ?.onClick
      .listen((_) => setFunc('sin(x + 2 * t) * cos(y + 2 * t)'));
  document
      .querySelector('#preset-sombrero-3d')
      ?.onClick
      .listen(
        (_) => setFunc(
          '2 * sin(sqrt(x^2 + y^2) + 2 * t) / (sqrt(x^2 + y^2) + 0.5)',
        ),
      );
  document
      .querySelector('#preset-saddle-3d')
      ?.onClick
      .listen((_) => setFunc('(x^2 - y^2) / 10 * cos(2 * t)'));

  // 2D Presets
  document
      .querySelector('#preset-ripple-2d')
      ?.onClick
      .listen((_) => setFunc('x * sin(10 * cos(t) / x)'));
  document
      .querySelector('#preset-harmonic-2d')
      ?.onClick
      .listen((_) => setFunc('sin(x + 5 * t) * cos(5 * x)'));
  document
      .querySelector('#preset-damped-2d')
      ?.onClick
      .listen((_) => setFunc('2 * exp(-abs(x) / 2) * cos(3 * x - 5 * t)'));
  document
      .querySelector('#preset-standing-2d')
      ?.onClick
      .listen((_) => setFunc('sin(2 * x) * cos(10 * t)'));

  // Mode toggles
  modeAutoBtn?.onClick.listen((_) {
    currentMode = PlotMode.auto;
    updateModeUI();
  });
  mode2DBtn?.onClick.listen((_) {
    currentMode = PlotMode.mode2d;
    updateModeUI();
  });
  mode3DBtn?.onClick.listen((_) {
    currentMode = PlotMode.mode3d;
    updateModeUI();
  });

  void syncToggles() {
    plotter.showGrid = toggleGrid?.checked ?? true;
    plotter.showAxes = toggleAxis?.checked ?? true;
  }

  final syncCallback = ((Event _) => syncToggles()).toJS;
  toggleGrid?.addEventListener('change', syncCallback);
  toggleGrid?.addEventListener('input', syncCallback);
  toggleGrid?.addEventListener('click', syncCallback);

  toggleAxis?.addEventListener('change', syncCallback);
  toggleAxis?.addEventListener('input', syncCallback);
  toggleAxis?.addEventListener('click', syncCallback);

  syncToggles();

  var isDragging = false;
  var isPanning = false;
  var dragStartX = 0.0;
  var dragStartY = 0.0;
  var origAzimuth = camera.azimuth;
  var origElevation = camera.elevation;
  var origTargetX = camera.targetX;
  var origTargetY = camera.targetY;
  var origTargetZ = camera.targetZ;

  var origMinX2D = plotter.minX2D;
  var origMaxX2D = plotter.maxX2D;
  var origMinY2D = plotter.minY2D;
  var origMaxY2D = plotter.maxY2D;

  var isTouching = false;
  var touchStartX = 0.0;
  var touchStartY = 0.0;
  var lastTouchX = 0.0;
  var lastTouchY = 0.0;
  var tapTouchStartX = 0.0;
  var tapTouchStartY = 0.0;
  var touchStartTime = 0;
  var lastTapTime = 0;

  var touchStartMidX = 0.0;
  var touchStartMidY = 0.0;
  var touchStartDist = 0.0;
  var touchOrigDistance = camera.distance;

  canvas.addEventListener(
    'contextmenu',
    ((Event event) {
      event.preventDefault();
    }).toJS,
  );

  canvas.addEventListener(
    'mousedown',
    ((MouseEvent event) {
      if (isTouching) return;
      isDragging = true;
      isPanning = event.button == 2 || event.shiftKey;
      dragStartX = event.clientX.toDouble();
      dragStartY = event.clientY.toDouble();
      origAzimuth = camera.azimuth;
      origElevation = camera.elevation;
      origTargetX = camera.targetX;
      origTargetY = camera.targetY;
      origTargetZ = camera.targetZ;
      origMinX2D = plotter.minX2D;
      origMaxX2D = plotter.maxX2D;
      origMinY2D = plotter.minY2D;
      origMaxY2D = plotter.maxY2D;
      canvas.style.cursor = 'grabbing';
      event.preventDefault();
    }).toJS,
  );

  window.addEventListener(
    'mousemove',
    ((MouseEvent event) {
      if (!isDragging) return;
      final dx = event.clientX - dragStartX;
      final dy = event.clientY - dragStartY;

      if (is3DActive) {
        if (isPanning) {
          final rightX = math.cos(camera.azimuth);
          final rightZ = -math.sin(camera.azimuth);
          final panScale = camera.distance * 0.0025;
          camera.targetX = origTargetX - rightX * dx * panScale;
          camera.targetZ = origTargetZ - rightZ * dx * panScale;
          camera.targetY = origTargetY + dy * panScale;
        } else {
          camera.azimuth = origAzimuth - dx * 0.008;
          camera.elevation = (origElevation + dy * 0.008).clamp(-1.45, 1.45);
        }
      } else {
        // 2D pan
        final logicalDx = dx * (origMaxX2D - origMinX2D) / plotter.width;
        final logicalDy = dy * (origMaxY2D - origMinY2D) / plotter.height;
        plotter.minX2D = origMinX2D - logicalDx;
        plotter.maxX2D = origMaxX2D - logicalDx;
        plotter.minY2D = origMinY2D + logicalDy;
        plotter.maxY2D = origMaxY2D + logicalDy;
      }
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

  canvas.addEventListener(
    'wheel',
    ((WheelEvent event) {
      event.preventDefault();
      if (is3DActive) {
        final factor = event.deltaY < 0 ? 0.90 : 1.10;
        camera.distance = (camera.distance * factor).clamp(3.0, 50.0);
      } else {
        final rect = canvas.getBoundingClientRect();
        final mouseX = event.clientX - rect.left;
        final mouseY = event.clientY - rect.top;
        final factor = event.deltaY < 0 ? 0.85 : 1.15;
        final logX =
            mouseX * (plotter.maxX2D - plotter.minX2D) / plotter.width +
            plotter.minX2D;
        final logY =
            (plotter.height - mouseY) *
                (plotter.maxY2D - plotter.minY2D) /
                plotter.height +
            plotter.minY2D;

        plotter.minX2D = logX - (logX - plotter.minX2D) * factor;
        plotter.maxX2D = logX + (plotter.maxX2D - logX) * factor;
        plotter.minY2D = logY - (logY - plotter.minY2D) * factor;
        plotter.maxY2D = logY + (plotter.maxY2D - logY) * factor;
      }
      updateViewportDisplay();
    }).toJS,
  );

  canvas.addEventListener(
    'dblclick',
    ((Event event) {
      if (is3DActive) {
        camera.reset();
      } else {
        plotter.minX2D = -5.0;
        plotter.maxX2D = 5.0;
        plotter.minY2D = -3.0;
        plotter.maxY2D = 3.0;
      }
      updateViewportDisplay();
    }).toJS,
  );

  canvas.addEventListener(
    'touchstart',
    ((TouchEvent event) {
      isTouching = true;
      final touches = event.targetTouches;
      final touchCount = touches.length;

      if (touchCount == 1) {
        final t0 = touches.item(0)!;
        touchStartX = t0.clientX.toDouble();
        touchStartY = t0.clientY.toDouble();
        lastTouchX = touchStartX;
        lastTouchY = touchStartY;
        tapTouchStartX = touchStartX;
        tapTouchStartY = touchStartY;
        touchStartTime = DateTime.now().millisecondsSinceEpoch;

        origAzimuth = camera.azimuth;
        origElevation = camera.elevation;
        origMinX2D = plotter.minX2D;
        origMaxX2D = plotter.maxX2D;
        origMinY2D = plotter.minY2D;
        origMaxY2D = plotter.maxY2D;
      } else if (touchCount >= 2) {
        final t0 = touches.item(0)!;
        final t1 = touches.item(1)!;
        touchStartMidX = (t0.clientX + t1.clientX) / 2.0;
        touchStartMidY = (t0.clientY + t1.clientY) / 2.0;
        final dx = (t1.clientX - t0.clientX).toDouble();
        final dy = (t1.clientY - t0.clientY).toDouble();
        touchStartDist = math.sqrt(dx * dx + dy * dy);

        touchOrigDistance = camera.distance;
        origTargetX = camera.targetX;
        origTargetY = camera.targetY;
        origTargetZ = camera.targetZ;

        origMinX2D = plotter.minX2D;
        origMaxX2D = plotter.maxX2D;
        origMinY2D = plotter.minY2D;
        origMaxY2D = plotter.maxY2D;
      }
      event.preventDefault();
    }).toJS,
  );

  canvas.addEventListener(
    'touchmove',
    ((TouchEvent event) {
      final touches = event.targetTouches;
      final touchCount = touches.length;

      if (touchCount == 1) {
        final t0 = touches.item(0)!;
        lastTouchX = t0.clientX.toDouble();
        lastTouchY = t0.clientY.toDouble();
        final dx = lastTouchX - touchStartX;
        final dy = lastTouchY - touchStartY;

        if (is3DActive) {
          camera.azimuth = origAzimuth - dx * 0.008;
          camera.elevation = (origElevation + dy * 0.008).clamp(-1.45, 1.45);
        } else {
          // 2D 1-finger pan
          final logicalDx = dx * (origMaxX2D - origMinX2D) / plotter.width;
          final logicalDy = dy * (origMaxY2D - origMinY2D) / plotter.height;
          plotter.minX2D = origMinX2D - logicalDx;
          plotter.maxX2D = origMaxX2D - logicalDx;
          plotter.minY2D = origMinY2D + logicalDy;
          plotter.maxY2D = origMaxY2D + logicalDy;
        }
        updateViewportDisplay();
      } else if (touchCount >= 2) {
        final t0 = touches.item(0)!;
        final t1 = touches.item(1)!;
        final currentMidX = (t0.clientX + t1.clientX) / 2.0;
        final currentMidY = (t0.clientY + t1.clientY) / 2.0;
        final dx = (t1.clientX - t0.clientX).toDouble();
        final dy = (t1.clientY - t0.clientY).toDouble();
        final currentDist = math.sqrt(dx * dx + dy * dy);

        final midDx = currentMidX - touchStartMidX;
        final midDy = currentMidY - touchStartMidY;

        if (is3DActive) {
          // 3D 2-finger pan
          final rightX = math.cos(camera.azimuth);
          final rightZ = -math.sin(camera.azimuth);
          final panScale = camera.distance * 0.0025;
          camera.targetX = origTargetX - rightX * midDx * panScale;
          camera.targetZ = origTargetZ - rightZ * midDx * panScale;
          camera.targetY = origTargetY + midDy * panScale;

          // 3D 2-finger zoom (pinch)
          if (touchStartDist > 0 && currentDist > 0) {
            final factor = touchStartDist / currentDist;
            camera.distance = (touchOrigDistance * factor).clamp(3.0, 50.0);
          }
        } else {
          // 2D 2-finger pan & pinch zoom
          final rect = canvas.getBoundingClientRect();
          final canvasMidX = touchStartMidX - rect.left;
          final canvasMidY = touchStartMidY - rect.top;

          final factor = (touchStartDist > 0 && currentDist > 0)
              ? (touchStartDist / currentDist)
              : 1.0;

          final origSpanX = origMaxX2D - origMinX2D;
          final origSpanY = origMaxY2D - origMinY2D;
          final newSpanX = (origSpanX * factor).clamp(0.0001, 10000.0);
          final newSpanY = (origSpanY * factor).clamp(0.0001, 10000.0);

          final logX = canvasMidX * origSpanX / plotter.width + origMinX2D;
          final logY =
              (plotter.height - canvasMidY) * origSpanY / plotter.height +
              origMinY2D;

          final fracX = (logX - origMinX2D) / origSpanX;
          final fracY = (logY - origMinY2D) / origSpanY;

          final panLogicalDx = midDx * newSpanX / plotter.width;
          final panLogicalDy = midDy * newSpanY / plotter.height;

          plotter.minX2D = logX - fracX * newSpanX - panLogicalDx;
          plotter.maxX2D = plotter.minX2D + newSpanX;
          plotter.minY2D = logY - fracY * newSpanY + panLogicalDy;
          plotter.maxY2D = plotter.minY2D + newSpanY;
        }
        updateViewportDisplay();
      }
      event.preventDefault();
    }).toJS,
  );

  void handleTouchEnd(TouchEvent event) {
    final touches = event.targetTouches;
    final touchCount = touches.length;

    if (touchCount == 1) {
      // Re-anchor remaining finger so it does not jump
      final t0 = touches.item(0)!;
      touchStartX = t0.clientX.toDouble();
      touchStartY = t0.clientY.toDouble();
      lastTouchX = touchStartX;
      lastTouchY = touchStartY;
      origAzimuth = camera.azimuth;
      origElevation = camera.elevation;
      origMinX2D = plotter.minX2D;
      origMaxX2D = plotter.maxX2D;
      origMinY2D = plotter.minY2D;
      origMaxY2D = plotter.maxY2D;
    } else if (touchCount == 0) {
      isTouching = false;
      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsed = now - touchStartTime;
      final dx = (lastTouchX - tapTouchStartX).abs();
      final dy = (lastTouchY - tapTouchStartY).abs();

      // Detect double-tap: quick tap without significant dragging
      if (elapsed < 300 && dx < 15 && dy < 15) {
        if (now - lastTapTime < 350) {
          if (is3DActive) {
            camera.reset();
          } else {
            plotter.minX2D = -5.0;
            plotter.maxX2D = 5.0;
            plotter.minY2D = -3.0;
            plotter.maxY2D = 3.0;
          }
          updateViewportDisplay();
          lastTapTime = 0;
        } else {
          lastTapTime = now;
        }
      }
    }
    event.preventDefault();
  }

  canvas.addEventListener(
    'touchend',
    ((TouchEvent event) => handleTouchEnd(event)).toJS,
  );
  canvas.addEventListener(
    'touchcancel',
    ((TouchEvent event) => handleTouchEnd(event)).toJS,
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

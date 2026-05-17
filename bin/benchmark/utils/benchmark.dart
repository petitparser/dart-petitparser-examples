import 'package:data/stats.dart';

/// Function type to be benchmarked.
typedef Benchmark = int Function(int count);

/// Measures the time it takes to run [function] in microseconds.
///
/// A single measurement is repeated at least [minLoop] times, and for at
/// least [minDuration]. The measurement is sampled [sampleCount] times.
Jackknife<double> benchmark(
  Benchmark function, {
  int minLoop = 25,
  Duration minDuration = const Duration(milliseconds: 100),
  Duration warmupDuration = const Duration(seconds: 1),
  int sampleCount = 25,
  double confidenceLevel = 0.95,
}) {
  // Estimate count and warmup.
  var count = minLoop;
  while (_benchmark(function, count) <= minDuration) {
    count *= 2;
  }
  if (count == minLoop) {
    throw StateError(
      '$function cannot be performed $minLoop times '
      'in $minDuration.',
    );
  }
  // Warmup phase.
  final warmupWatch = Stopwatch()..start();
  while (warmupWatch.elapsed < warmupDuration) {
    _benchmark(function, count);
  }
  // Collect samples.
  final samples = <double>[];
  for (var i = 0; i < sampleCount; i++) {
    samples.add(_benchmark(function, count).inMicroseconds / count);
  }
  return Jackknife(
    samples,
    (list) => list.arithmeticMean(),
    confidenceLevel: confidenceLevel,
  );
}

/// Blackhole variable to prevent dead code elimination.
int blackhole = 0;

@pragma('vm:never-inline')
@pragma('vm:unsafe:no-interrupts')
Duration _benchmark(Benchmark function, int count) {
  final watch = Stopwatch();
  watch.start();
  final result = function(count);
  watch.stop();
  blackhole ^= result;
  return watch.elapsed;
}

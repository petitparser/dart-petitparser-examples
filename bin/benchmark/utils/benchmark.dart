import 'package:data/stats.dart';

/// Function type to be benchmarked.
typedef Benchmark = void Function();

/// Measures the time it takes to run [function] in microseconds.
///
/// A single measurement is repeated at least [minLoop] times, and for at
/// least [minDuration]. The measurement is sampled [sampleCount] times.
Jackknife<double> benchmark(
  Benchmark function, {
  int minLoop = 25,
  Duration minDuration = const Duration(milliseconds: 100),
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

@pragma('vm:never-inline')
@pragma('vm:unsafe:no-interrupts')
Duration _benchmark(Benchmark function, int count) {
  final watch = Stopwatch();
  watch.start();
  var n = count + 0;
  while (n-- > 0) {
    function();
  }
  watch.stop();
  return watch.elapsed;
}

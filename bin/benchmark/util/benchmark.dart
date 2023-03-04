/// Function type to be benchmarked.
typedef Benchmark = void Function();

/// Measures the time it takes to run [function] in microseconds.
///
/// It does so in two steps:
///
///  - the code is warmed up for the duration of [warmup]; and
///  - the code is benchmarked for the duration of [measure].
///
/// The resulting duration is the average time measured to run [function] once.
double benchmark(Benchmark function, {Duration? warmup, Duration? measure}) {
  _benchmark(function, warmup ?? const Duration(milliseconds: 200));
  return _benchmark(function, measure ?? const Duration(seconds: 2));
}

double _benchmark(Benchmark function, Duration duration) {
  final watch = Stopwatch();
  final micros = duration.inMicroseconds;
  var count = 0;
  var elapsed = 0;
  watch.start();
  while (elapsed < micros) {
    function();
    elapsed = watch.elapsedMicroseconds;
    count++;
  }
  return elapsed / count;
}

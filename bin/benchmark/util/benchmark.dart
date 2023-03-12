/// Function type to be benchmarked.
typedef Benchmark = void Function();

/// Measures the time it takes to run [function] in microseconds. The resulting
/// duration is the average time measured to run [function] once.
double benchmark(
  Benchmark function, {
  int minLoops = 128,
  Duration minDuration = const Duration(milliseconds: 500),
}) {
  // Figure out how many times we need to loop to reach the desired duration.
  var count = minLoops;
  while (_benchmark(function, count) <= minDuration) {
    count *= 2;
  }
  if (count == minLoops) {
    throw StateError('$function cannot be performed $minLoops times '
        'in $minDuration.');
  }
  return _benchmark(function, count).inMicroseconds / count;
}

@pragma('vm:never-inline')
@pragma('vm:no-interrupts')
Duration _benchmark(Benchmark function, int count) {
  final watch = Stopwatch();
  watch.start();
  while (count-- > 0) {
    function();
  }
  watch.stop();
  return watch.elapsed;
}

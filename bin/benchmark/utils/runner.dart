import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:data/stats.dart';
import 'package:more/more.dart';
import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

final defaultCharsInput = [
  // ASCII characters (265 times)
  ...List.generate(0xff, String.fromCharCode),
  // Mathematical symbols (32 times, UTF-16 chars)
  ...List.generate(0x20, (i) => String.fromCharCode(0x2200 + i)),
  // Alchemical symbols (32 times, UTF-32 chars)
  ...List.generate(0x20, (i) => String.fromCharCode(0x1f700 + i)),
].shuffled(Random(42));
final defaultStringInput = defaultCharsInput.join();

final List<MapEntry<String, Benchmark>> _benchmarkEntries = (() {
  Future.delayed(const Duration(milliseconds: 1)).then((_) {
    stdout.writeln(['name', 'parser', 'accept', 'native'].join('\t'));
    for (final benchmarkEntry in _benchmarkEntries) {
      benchmarkEntry.value();
    }
  });
  return SortedList<MapEntry<String, Benchmark>>(
      comparator: compareAsciiLowerCase.onResultOf((entry) => entry.key));
})();

final numberPrinter = FixedNumberPrinter(precision: 3, separator: ',');

String formatBenchmark(Jackknife<double> jackknife) =>
    numberPrinter(jackknife.estimate);

/// Generic benchmark runner.
void run(
  String name, {
  Benchmark? verify,
  required Benchmark parse,
  required Benchmark accept,
  Benchmark? native,
}) {
  _benchmarkEntries.add(MapEntry(name, () {
    stdout.write('$name\t');
    if (verify != null) {
      try {
        verify();
      } catch (error) {
        stdout.writeln(error);
        return;
      }
    }
    final parseJackknife = benchmark(parse);
    stdout.write('${formatBenchmark(parseJackknife)}\t');
    final acceptJackknife = benchmark(accept);
    stdout.write('${formatBenchmark(acceptJackknife)}\t');
    if (native != null) {
      final nativeJackknife = benchmark(native);
      stdout.write('${formatBenchmark(nativeJackknife)}\t');
    }
    stdout.writeln();
  }));
}

/// Generic character benchmark runner.
void runChars(String name, Parser<void> parser,
    {int? success, List<String>? input}) {
  final input_ = input ?? defaultCharsInput;
  final success_ = success ?? input_.length;
  run(
    name,
    verify: () {
      var count = 0;
      for (final char in input_) {
        if (parser.accept(char)) count++;
      }
      if (success_ != count) {
        throw StateError('Expected $success_ successes, but got $count');
      }
    },
    parse: () {
      for (final char in input_) {
        parser.parse(char);
      }
    },
    accept: () {
      for (final char in input_) {
        parser.accept(char);
      }
    },
  );
}

/// Generic string benchmark runner.
void runString(String name, Parser<void> parser,
    {int? position, String? input}) {
  final input_ = input ?? defaultStringInput;
  final position_ = position ?? input_.length;
  run(
    name,
    verify: () {
      final result = parser.parse(input_);
      if (result is Failure) {
        throw StateError('Expected parse success, but got ${result.message} '
            'at ${result.position}');
      }
      if (result.position != position_) {
        throw StateError('Expected parse success at $position_, but succeeded '
            'at ${result.position}');
      }
    },
    parse: () => parser.parse(input_),
    accept: () => parser.accept(input_),
  );
}

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:data/stats.dart';
import 'package:more/more.dart';
import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

/// Whether to run the actual benchmark.
var optionBenchmark = true;

/// Whether to run the verification code.
var optionVerification = true;

/// Whether to print the standard error.
var optionPrintStandardError = false;

/// Whether to print the confidence intervals.
var optionPrintConfidenceIntervals = false;

/// Whether to filter to a specific benchmark.
String? optionFilter;

/// Separator character for output.
String? optionSeparator = '\t';

/// if the output should be human readable.
var optionHumanReadable = true;

final defaultCharsInput = [
  // ASCII characters (265 times)
  ...List.generate(0xff, String.fromCharCode),
  // Mathematical symbols (32 times, UTF-16 chars)
  ...List.generate(0x20, (i) => String.fromCharCode(0x2200 + i)),
  // Alchemical symbols (32 times, UTF-32 chars)
  ...List.generate(0x20, (i) => String.fromCharCode(0x1f700 + i)),
].shuffled(Random(42));
final defaultStringInput = defaultCharsInput.join();

final List<({String name, Benchmark benchmark})> _benchmarkEntries = (() {
  Future.delayed(const Duration(milliseconds: 1)).then((_) {
    for (final (:name, :benchmark) in _benchmarkEntries) {
      if (optionFilter == null || optionFilter == name) benchmark();
    }
  });
  return SortedList<({String name, Benchmark benchmark})>(
    comparator: compareAsciiLowerCase.keyOf((entry) => entry.name),
  );
})();

final numberPrinter = FixedNumberPrinter(precision: 3);

/// Generic benchmark runner.
void run(
  String name, {
  required Benchmark verify,
  required Benchmark parse,
  required Benchmark accept,
  Benchmark? native,
}) {
  _benchmarkEntries.add((
    name: name,
    benchmark: () {
      // Print name.
      stdout.write(name);
      // Verification.
      if (optionVerification) {
        try {
          verify();
          if (!optionBenchmark) {
            stdout.write('\tOK');
          }
        } catch (error) {
          stdout.writeln('\t$error');
          return;
        }
      }
      // Benchmark.
      if (optionBenchmark) {
        final benchmarks = [
          benchmark(parse),
          benchmark(accept),
          native?.also(benchmark),
        ].whereType<Jackknife<double>>();
        for (final benchmark in benchmarks) {
          stdout.write(optionSeparator);
          stdout.write(numberPrinter(benchmark.estimate));
          if (optionPrintStandardError) {
            if (optionHumanReadable) {
              stdout.write(' ± ');
            } else {
              stdout.write(optionSeparator);
            }
            stdout.writeln(numberPrinter(benchmark.standardError));
          }
          if (optionPrintConfidenceIntervals) {
            if (optionHumanReadable) {
              stdout.write(
                ' [${numberPrinter(benchmark.lowerBound)}; '
                '${numberPrinter(benchmark.upperBound)}]',
              );
            } else {
              stdout.write(optionSeparator);
              stdout.write(numberPrinter(benchmark.lowerBound));
              stdout.write(optionSeparator);
              stdout.write(numberPrinter(benchmark.upperBound));
            }
          }
        }
      }
      // Complete.
      stdout.writeln();
    },
  ));
}

/// Generic character benchmark runner.
void runChars(String name, Parser<void> parser, {int? success, String? input}) {
  final input_ = input ?? defaultStringInput;
  final inputLength = input_.length;
  final success_ = success ?? input_.length;
  run(
    name,
    verify: () {
      var count = 0;
      for (var i = 0; i < inputLength; i++) {
        if (parser.accept(input_, start: i)) count++;
      }
      if (success_ != count) {
        throw StateError('Expected $success_ successes, but got $count');
      }
    },
    parse: () {
      for (var i = 0; i < inputLength; i++) {
        parser.parse(input_, start: i);
      }
    },
    accept: () {
      for (var i = 0; i < inputLength; i++) {
        parser.accept(input_, start: i);
      }
    },
  );
}

/// Generic string benchmark runner.
void runString(
  String name,
  Parser<void> parser, {
  int? position,
  String? input,
}) {
  final input_ = input ?? defaultStringInput;
  final position_ = position ?? input_.length;
  run(
    name,
    verify: () {
      final result = parser.parse(input_);
      if (result is Failure) {
        throw StateError(
          'Expected parse success, but got ${result.message} '
          'at ${result.position}',
        );
      }
      if (result.position != position_) {
        throw StateError(
          'Expected parse success at $position_, but succeeded '
          'at ${result.position}',
        );
      }
    },
    parse: () => parser.parse(input_),
    accept: () => parser.accept(input_),
  );
}

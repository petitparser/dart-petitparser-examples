import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:data/stats.dart';
import 'package:more/more.dart';
import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

final defaultCharsInput = List.generate(0xff, String.fromCharCode);
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
void runChars(String name, Parser<void> parser, int success, [String? input]) {
  final string = input ?? defaultStringInput;
  final stringLength = string.length;
  run(
    name,
    verify: () {
      var count = 0;
      for (var i = 0; i < stringLength; i++) {
        if (parser.accept(string, start: i)) count++;
      }
      if (success != count) {
        throw StateError('Expected $success success, but got $count');
      }
    },
    parse: () {
      for (var i = 0; i < stringLength; i++) {
        parser.parse(string, start: i);
      }
    },
    accept: () {
      for (var i = 0; i < stringLength; i++) {
        parser.accept(string, start: i);
      }
    },
  );
}

/// Generic string benchmark runner.
void runString(String name, Parser<void> parser, [String? input]) {
  final string = input ?? defaultStringInput;
  run(
    name,
    verify: () => parser.parse(string).value,
    parse: () {
      parser.parse(string);
    },
    accept: () {
      parser.accept(string);
    },
  );
}

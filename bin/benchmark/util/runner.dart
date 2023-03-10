import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:more/collection.dart';
import 'package:more/comparator.dart';
import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

final defaultCharsInput =
    List.generate(0xff, (value) => String.fromCharCode(value));
final defaultStringInput = defaultCharsInput.join();

final List<MapEntry<String, Benchmark>> _benchmarkEntries = (() {
  Future.delayed(const Duration(milliseconds: 1)).then((_) {
    stdout.writeln(['name', 'parser', 'accept', 'native'].join('\t'));
    for (var benchmarkEntry in _benchmarkEntries) {
      benchmarkEntry.value();
    }
  });
  return SortedList<MapEntry<String, Benchmark>>(
      comparator: compareAsciiLowerCase.onResultOf((entry) => entry.key));
})();

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
    final parseMs = benchmark(parse);
    stdout.write('${parseMs.toStringAsFixed(3)}\t');
    final acceptMs = benchmark(accept);
    stdout.write('${acceptMs.toStringAsFixed(3)}\t');
    if (native != null) {
      final nativeMs = benchmark(native);
      stdout.write('${nativeMs.toStringAsFixed(3)}\t');
    }
    stdout.writeln();
  }));
}

/// Generic character benchmark runner.
void runChars(String name, Parser<void> parser, int success, [String? input]) {
  final string = input ?? defaultStringInput;
  final stringLength = string.length;
  final fullContext = Context(string, isSkip: false);
  final skipContext = Context(string, isSkip: true);
  run(
    name,
    verify: () {
      var count = 0;
      for (var i = 0; i < stringLength; i++) {
        if (parser.accept(string[i])) count++;
      }
      if (success != count) {
        throw StateError('Expected $success success, but got $count');
      }
    },
    parse: () {
      for (var i = 0; i < stringLength; i++) {
        fullContext.position = i;
        parser.parseOn(fullContext);
      }
    },
    accept: () {
      for (var i = 0; i < stringLength; i++) {
        skipContext.position = i;
        parser.parseOn(skipContext);
      }
    },
  );
}

/// Generic string benchmark runner.
void runString(String name, Parser<void> parser, [String? input]) {
  final string = input ?? defaultStringInput;
  final fullContext = Context(string, isSkip: false);
  final skipContext = Context(string, isSkip: true);
  run(
    name,
    verify: () => parser.parse(string).value,
    parse: () {
      fullContext.position = 0;
      parser.parseOn(fullContext);
    },
    accept: () {
      skipContext.position = 0;
      parser.parseOn(skipContext);
    },
  );
}

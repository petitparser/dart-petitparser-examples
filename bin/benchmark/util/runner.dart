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

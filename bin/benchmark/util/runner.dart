import 'dart:io';

import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

final defaultCharsInput =
    List.generate(0xff, (value) => String.fromCharCode(value));
final defaultStringInput = defaultCharsInput.join();

/// Generic benchmark runner.
void run(
  String name, {
  Benchmark? verify,
  required Benchmark parse,
  required Benchmark accept,
  Benchmark? native,
}) {
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
}

/// Generic character benchmark runner.
void runChars(String name, Parser<void> parser, int success,
    [List<String>? charsInput]) {
  final chars = charsInput ?? defaultCharsInput;
  run(
    name,
    verify: () {
      var count = 0;
      for (var i = 0; i < chars.length; i++) {
        if (parser.accept(chars[i])) count++;
      }
      if (success != count) {
        throw StateError('Expected $success success, but got $count');
      }
    },
    parse: () {
      for (var i = 0; i < chars.length; i++) {
        parser.parse(chars[i]);
      }
    },
    accept: () {
      for (var i = 0; i < chars.length; i++) {
        parser.accept(chars[i]);
      }
    },
  );
}

/// Generic string benchmark runner.
void runString(String name, Parser<void> parser, [String? stringInput]) {
  final string = stringInput ?? defaultStringInput;
  run(
    name,
    verify: () => parser.parse(string).value,
    parse: () => parser.parse(string),
    accept: () => parser.accept(string),
  );
}

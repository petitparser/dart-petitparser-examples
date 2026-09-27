@TestOn('vm')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../../bin/benchmark/benchmark.dart' as benchmark_cli;
import '../../bin/benchmark/utils/runner.dart' as runner;

final dartExecutable = () {
  const sdkDart =
      '/opt/homebrew/Caskroom/flutter/3.29.3/flutter/bin/cache/dart-sdk/bin/dart';
  if (File(sdkDart).existsSync()) return sdkDart;
  return Platform.resolvedExecutable;
}();

void main() {
  group('benchmark ArgParser configuration', () {
    final parser = benchmark_cli.arguments;

    test('defines required flags and options', () {
      expect(parser.options.containsKey('help'), isTrue);
      expect(parser.options.containsKey('verify'), isTrue);
      expect(parser.options.containsKey('benchmark'), isTrue);
      expect(parser.options.containsKey('stderr'), isTrue);
      expect(parser.options.containsKey('confidence'), isTrue);
      expect(parser.options.containsKey('filter'), isTrue);
      expect(parser.options.containsKey('separator'), isTrue);
      expect(parser.options.containsKey('human'), isTrue);
    });

    test('parses options and sets runner properties via callbacks', () {
      parser.parse([
        '--no-benchmark',
        '--no-verify',
        '--stderr',
        '--confidence',
        '--filter=json',
        '--separator=,',
        '--no-human',
      ]);

      expect(runner.optionBenchmark, isFalse);
      expect(runner.optionVerification, isFalse);
      expect(runner.optionPrintStandardError, isTrue);
      expect(runner.optionPrintConfidenceIntervals, isTrue);
      expect(runner.optionFilter, equals('json'));
      expect(runner.optionSeparator, equals(','));
      expect(runner.optionHumanReadable, isFalse);

      // Restore defaults
      runner.optionBenchmark = true;
      runner.optionVerification = true;
      runner.optionPrintStandardError = false;
      runner.optionPrintConfidenceIntervals = false;
      runner.optionFilter = null;
      runner.optionSeparator = '\t';
      runner.optionHumanReadable = true;
    });
  });

  group('CLI execution', () {
    test('prints usage and exits with 1 on --help', () async {
      final res = await Process.run(dartExecutable, [
        'bin/benchmark/benchmark.dart',
        '--help',
      ]);
      expect(res.exitCode, equals(1));
      expect(res.stdout.toString(), contains('-h, --[no-]help'));
      expect(res.stdout.toString(), contains('-v, --[no-]verify'));
    });

    test('exits with 1 on unexpected positional argument', () async {
      final res = await Process.run(dartExecutable, [
        'bin/benchmark/benchmark.dart',
        'unexpected_arg',
      ]);
      expect(res.exitCode, equals(1));
      expect(res.stdout.toString(), contains('show the help text'));
    });

    test(
      'runs verification mode quickly with --no-benchmark --filter json',
      () async {
        final res = await Process.run(dartExecutable, [
          'bin/benchmark/benchmark.dart',
          '--no-benchmark',
          '--filter',
          'json',
        ]);
        expect(res.exitCode, equals(0));
        expect(res.stdout.toString(), contains('OK'));
      },
    );

    test(
      'runs verification mode quickly with --no-benchmark --filter char',
      () async {
        final res = await Process.run(dartExecutable, [
          'bin/benchmark/benchmark.dart',
          '--no-benchmark',
          '--filter',
          'char',
        ]);
        expect(res.exitCode, equals(0));
        expect(res.stdout.toString(), contains('OK'));
      },
    );
  });
}

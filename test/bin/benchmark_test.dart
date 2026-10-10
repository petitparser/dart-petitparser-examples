@TestOn('vm')
library;

import 'dart:io';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

import '../../bin/benchmark/benchmark.dart' as benchmark_cli;
import '../../bin/benchmark/utils/runner.dart' as runner;

final dartExecutable = Platform.resolvedExecutable;

void main() {
  group('benchmark ArgParser configuration', () {
    final parser = benchmark_cli.arguments;

    test('defines required flags and options', () {
      check(parser.options.containsKey('help')).isTrue();
      check(parser.options.containsKey('verify')).isTrue();
      check(parser.options.containsKey('benchmark')).isTrue();
      check(parser.options.containsKey('stderr')).isTrue();
      check(parser.options.containsKey('confidence')).isTrue();
      check(parser.options.containsKey('filter')).isTrue();
      check(parser.options.containsKey('separator')).isTrue();
      check(parser.options.containsKey('human')).isTrue();
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

      check(runner.optionBenchmark).isFalse();
      check(runner.optionVerification).isFalse();
      check(runner.optionPrintStandardError).isTrue();
      check(runner.optionPrintConfidenceIntervals).isTrue();
      check(runner.optionFilter).equals('json');
      check(runner.optionSeparator).equals(',');
      check(runner.optionHumanReadable).isFalse();

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
      check(res.exitCode).equals(1);
      check(res.stdout.toString()).contains('-h, --[no-]help');
      check(res.stdout.toString()).contains('-v, --[no-]verify');
    });

    test('exits with 1 on unexpected positional argument', () async {
      final res = await Process.run(dartExecutable, [
        'bin/benchmark/benchmark.dart',
        'unexpected_arg',
      ]);
      check(res.exitCode).equals(1);
      check(res.stdout.toString()).contains('show the help text');
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
        check(res.exitCode).equals(0);
        check(res.stdout.toString()).contains('OK');
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
        check(res.exitCode).equals(0);
        check(res.stdout.toString()).contains('OK');
      },
    );
  });
}

import 'dart:io';

import 'package:args/args.dart';

import 'suites/action_benchmark.dart' as action_benchmark;
import 'suites/character_benchmark.dart' as character_benchmark;
import 'suites/combinator_benchmark.dart' as combinator_benchmark;
import 'suites/example_benchmark.dart' as example_benchmark;
import 'suites/json_benchmark.dart' as json_benchmark;
import 'suites/misc_benchmark.dart' as misc_benchmark;
import 'suites/predicate_benchmark.dart' as predicate_benchmark;
import 'suites/regexp_benchmark.dart' as regexp_benchmark;
import 'suites/repeat_benchmark.dart' as repeat_benchmark;
import 'utils/runner.dart' as runner;

final arguments = ArgParser()
  ..addFlag('help', abbr: 'h', help: 'show the help text')
  ..addFlag(
    'verify',
    abbr: 'v',
    help: 'run the verification code',
    defaultsTo: runner.optionVerification,
    callback: (value) => runner.optionVerification = value,
  )
  ..addFlag(
    'benchmark',
    abbr: 'b',
    help: 'run the benchmark code',
    defaultsTo: runner.optionBenchmark,
    callback: (value) => runner.optionBenchmark = value,
  )
  ..addFlag(
    'stderr',
    abbr: 'e',
    help: 'print the standard error',
    defaultsTo: runner.optionPrintStandardError,
    callback: (value) => runner.optionPrintStandardError = value,
  )
  ..addFlag(
    'confidence',
    abbr: 'c',
    help: 'print the confidence intervals',
    defaultsTo: runner.optionPrintConfidenceIntervals,
    callback: (value) => runner.optionPrintConfidenceIntervals = value,
  )
  ..addOption(
    'filter',
    abbr: 'f',
    help: 'filter the benchmarks',
    defaultsTo: runner.optionFilter,
    callback: (value) => runner.optionFilter = value,
  )
  ..addOption(
    'separator',
    abbr: 's',
    help: 'separator between benchmark values',
    defaultsTo: runner.optionSeparator,
    callback: (value) => runner.optionSeparator = value,
  )
  ..addFlag(
    'human',
    abbr: 'u',
    help: 'print extras in human-readable format',
    defaultsTo: runner.optionHumanReadable,
    callback: (value) => runner.optionHumanReadable = value,
  );

void main(List<String> args) {
  // Parse the command line arguments.
  final results = arguments.parse(args);
  if (results['help'] || results.rest.isNotEmpty) {
    stdout.writeln(arguments.usage);
    exit(1);
  }
  // Run the benchmark.
  action_benchmark.main();
  character_benchmark.main();
  combinator_benchmark.main();
  example_benchmark.main();
  json_benchmark.main();
  misc_benchmark.main();
  predicate_benchmark.main();
  regexp_benchmark.main();
  repeat_benchmark.main();
}

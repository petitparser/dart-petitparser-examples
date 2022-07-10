import 'dart:io';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/json.dart';

import 'benchmark.dart';

// Function type

typedef BenchmarkFactory = Benchmark Function(bool optimized);

// Character tests

BenchmarkFactory charTest(List<String> inputs, Parser parser) => (optimized) {
      if (optimized) {
        return () {
          for (var i = 0; i < inputs.length; i++) {
            parser.accept(inputs[i]);
          }
        };
      } else {
        return () {
          for (var i = 0; i < inputs.length; i++) {
            parser.parse(inputs[i]);
          }
        };
      }
    };

final List<String> characters =
    List.generate(0xff, (value) => String.fromCharCode(value));

// String tests

BenchmarkFactory stringTest(String input, Parser parser) => (optimized) {
      if (optimized) {
        return () => parser.accept(input);
      } else {
        return () => parser.parse(input).isSuccess;
      }
    };

final String charactersString = characters.join();

// JSON tests

final json = JsonParserDefinition().build();

const String jsonEvent =
    '{"type": "change", "eventPhase": 2, "bubbles": true, "cancelable": true, '
    '"timeStamp": 0, "CAPTURING_PHASE": 1, "AT_TARGET": 2, '
    '"BUBBLING_PHASE": 3, "isTrusted": true, "MOUSEDOWN": 1, "MOUSEUP": 2, '
    '"MOUSEOVER": 4, "MOUSEOUT": 8, "MOUSEMOVE": 16, "MOUSEDRAG": 32, '
    '"CLICK": 64, "DBLCLICK": 128, "KEYDOWN": 256, "KEYUP": 512, '
    '"KEYPRESS": 1024, "DRAGDROP": 2048, "FOCUS": 4096, "BLUR": 8192, '
    '"SELECT": 16384, "CHANGE": 32768, "RESET": 65536, "SUBMIT": 131072, '
    '"SCROLL": 262144, "LOAD": 524288, "UNLOAD": 1048576, '
    '"XFER_DONE": 2097152, "ABORT": 4194304, "ERROR": 8388608, '
    '"LOCATE": 16777216, "MOVE": 33554432, "RESIZE": 67108864, '
    '"FORWARD": 134217728, "HELP": 268435456, "BACK": 536870912, '
    '"TEXT": 1073741824, "ALT_MASK": 1, "CONTROL_MASK": 2, '
    '"SHIFT_MASK": 4, "META_MASK": 8}';

// All benchmarks

final Map<String, BenchmarkFactory> benchmarks = {
  // char tests
  'any()': charTest(characters, any()),
  "anyOf('uncopyrightable')": charTest(characters, anyOf('uncopyrightable')),
  "char('a')": charTest(characters, char('a')),
  'digit()': charTest(characters, digit()),
  'letter()': charTest(characters, letter()),
  'lowercase()': charTest(characters, lowercase()),
  "noneOf('uncopyrightable')": charTest(characters, noneOf('uncopyrightable')),
  "pattern('^a')": charTest(characters, pattern('^a')),
  "pattern('^a-cx-zA-CX-Z1-37-9')":
      charTest(characters, pattern('^a-cx-zA-CX-Z1-37-9')),
  "pattern('^a-z')": charTest(characters, pattern('^a-z')),
  "pattern('^acegik')": charTest(characters, pattern('^acegik')),
  "pattern('a')": charTest(characters, pattern('a')),
  "pattern('a-cx-zA-CX-Z1-37-9')":
      charTest(characters, pattern('a-cx-zA-CX-Z1-37-9')),
  "pattern('a-z')": charTest(characters, pattern('a-z')),
  "pattern('acegik')": charTest(characters, pattern('acegik')),
  "range('a', 'z')": charTest(characters, range('a', 'z')),
  'uppercase()': charTest(characters, uppercase()),
  'whitespace()': charTest(characters, whitespace()),
  'word()': charTest(characters, word()),

  // combinator tests
  'and()': charTest(characters, any().and()),
  'cast()': charTest(characters, any().cast()),
  'castList()': charTest(characters, any().star().castList()),
  'end()': charTest(characters, any().end()),
  'epsilon()': charTest(characters, epsilon()),
  'epsilonWith()': charTest(characters, epsilonWith('!')),
  'failure()': charTest(characters, failure()),
  'flatten()': charTest(characters, any().flatten()),
  'label()': charTest(characters, any().labeled('label')),
  'map()': charTest(characters, any().map((_) => null)),
  'neg()': charTest(characters, any().neg()),
  'not()': charTest(characters, any().not()),
  'optional()': charTest(characters, any().optional()),
  'optionalWith()': charTest(characters, any().optionalWith('!')),
  'or()': charTest(characters, failure().or(any()).star()),
  'permute()': charTest(characters, any().star().permute([0])),
  'pick()': charTest(characters, any().star().pick(0)),
  'position()': charTest(characters, position()),
  'set()': charTest(characters, any().settable()),
  'token()': charTest(characters, any().token()),
  'trim()': charTest(characters, any().trim()),

  // repeater tests
  'star()': stringTest(charactersString, any().star()),
  'starGreedy()': stringTest(charactersString, any().starGreedy(failure())),
  'starLazy()': stringTest(charactersString, any().starLazy(failure())),
  'plus()': stringTest(charactersString, any().plus()),
  'plusGreedy()': stringTest(charactersString, any().plusGreedy(failure())),
  'plusLazy()': stringTest(charactersString, any().plusLazy(failure())),
  'times()': stringTest(charactersString, any().times(charactersString.length)),
  'seq()': stringTest(
    charactersString,
    List.filled(charactersString.length, any()).toSequenceParser(),
  ),

  // predicate tests
  'string': stringTest(charactersString, string(charactersString)),
  'stringIgnoreCase': stringTest(
    charactersString,
    stringIgnoreCase(charactersString),
  ),
  'predicate': stringTest(
    charactersString,
    predicate(
      charactersString.length,
      (value) => value == charactersString,
      'not found',
    ),
  ),
  'pattern (regexp)': stringTest(
    charactersString,
    PatternParser(RegExp('.*abc.*'), 'not found'),
  ),
  'pattern (string)': stringTest(
    charactersString,
    PatternParser(charactersString, 'not found'),
  ),

  // composite
  'JsonParser()': (optimized) {
    if (optimized) {
      return () => json.fastParseOn(jsonEvent, 0);
    } else {
      return () => json.parse(jsonEvent);
    }
  },
};

void main() {
  stdout.writeln('Name\tparseOn\tfastParseOn\tChange');
  for (final entry in benchmarks.entries) {
    final parseOnTime = benchmark(entry.value(false));
    final fastParseOnTime = benchmark(entry.value(true));
    stdout.writeln('${entry.key}\t'
        '${parseOnTime.toStringAsFixed(3)}\t'
        '${fastParseOnTime.toStringAsFixed(3)}\t'
        '${percentChange(parseOnTime, fastParseOnTime).round()}%');
  }
}

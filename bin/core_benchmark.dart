import 'dart:io';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:petitparser_examples/json.dart';
import 'package:petitparser_examples/math.dart' as math;
import 'package:petitparser_examples/uri.dart';

import 'benchmark.dart';

// Function type

enum BenchmarkType { verify, parse, accept }

typedef BenchmarkFactory = Benchmark Function(BenchmarkType type);

// Character tests

BenchmarkFactory charTest(List<String> inputs, Parser parser, int success) =>
    (type) {
      switch (type) {
        case BenchmarkType.verify:
          return () {
            var count = 0;
            for (var i = 0; i < inputs.length; i++) {
              if (parser.accept(inputs[i])) count++;
            }
            if (success != count) {
              throw StateError('Expected $success success, but got $count');
            }
          };
        case BenchmarkType.parse:
          return () {
            for (var i = 0; i < inputs.length; i++) {
              parser.parse(inputs[i]);
            }
          };
        case BenchmarkType.accept:
          return () {
            for (var i = 0; i < inputs.length; i++) {
              parser.accept(inputs[i]);
            }
          };
      }
    };

final characters = List.generate(0xff, (value) => String.fromCharCode(value));

// String tests

BenchmarkFactory stringTest(String input, Parser parser) => (type) {
      switch (type) {
        case BenchmarkType.verify:
          return () {
            if (!parser.accept(input)) throw StateError('Expected success');
          };
        case BenchmarkType.parse:
          return () => parser.parse(input);
        case BenchmarkType.accept:
          return () => parser.accept(input);
      }
    };

final charactersString = characters.join();

// Other tests

final bibtex = BibTeXDefinition().build();
final json = JsonDefinition().build();

const jsonInput =
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
const mathInput = '1 + 2 - (3 * 4 / sqrt(5 ^ pi)) - e';
const bibtexInput = '@inproceedings{Reng10c,\n'
    '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
    '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
    '\tMonth = jun,\n'
    '\tYear = 2010,\n'
    '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}}';
const uriInput =
    'https://www.lukas-renggli.ch/blog/petitparser-1?_s=Q5vcT_xEIhxf2Z4Q&_k=4pr02qyT&_n&42';

// All benchmarks

final benchmarks = <String, BenchmarkFactory>{
  // char tests
  'any()': charTest(characters, any(), 255),
  "anyOf('uncopyrightable')":
      charTest(characters, anyOf('uncopyrightable'), 15),
  "char('a')": charTest(characters, char('a'), 1),
  'digit()': charTest(characters, digit(), 10),
  'letter()': charTest(characters, letter(), 52),
  'lowercase()': charTest(characters, lowercase(), 26),
  "noneOf('uncopyrightable')":
      charTest(characters, noneOf('uncopyrightable'), 240),
  "pattern('^a')": charTest(characters, pattern('^a'), 254),
  "pattern('^a-cx-zA-CX-Z1-37-9')":
      charTest(characters, pattern('^a-cx-zA-CX-Z1-37-9'), 237),
  "pattern('^a-z')": charTest(characters, pattern('^a-z'), 229),
  "pattern('^acegik')": charTest(characters, pattern('^acegik'), 249),
  "pattern('a')": charTest(characters, pattern('a'), 1),
  "pattern('a-cx-zA-CX-Z1-37-9')":
      charTest(characters, pattern('a-cx-zA-CX-Z1-37-9'), 18),
  "pattern('a-z')": charTest(characters, pattern('a-z'), 26),
  "pattern('acegik')": charTest(characters, pattern('acegik'), 6),
  "range('a', 'z')": charTest(characters, range('a', 'z'), 26),
  'uppercase()': charTest(characters, uppercase(), 26),
  'whitespace()': charTest(characters, whitespace(), 8),
  'word()': charTest(characters, word(), 63),

  // combinator tests
  'and': charTest(characters, any().and(), 255),
  'cast': charTest(characters, any().cast(), 255),
  'castList': charTest(characters, any().star().castList(), 255),
  'end': charTest(characters, any().end(), 255),
  'epsilon': charTest(characters, epsilon(), 255),
  'epsilonWith': charTest(characters, epsilonWith('!'), 255),
  'failure': charTest(characters, failure(), 0),
  'flatten': charTest(characters, any().flatten(), 255),
  'label': charTest(characters, any().labeled('label'), 255),
  'map': charTest(characters, any().map((_) => null), 255),
  'newline': charTest(characters, newline(), 2),
  'neg': charTest(characters, any().neg(), 0),
  'not': charTest(characters, any().not(), 0),
  'optional': charTest(characters, any().optional(), 255),
  'optionalWith': charTest(characters, any().optionalWith('!'), 255),
  'or': charTest(characters, failure().or(any()).star(), 255),
  'permute': charTest(characters, any().star().permute([0]), 255),
  'pick': charTest(characters, any().star().pick(0), 255),
  'position': charTest(characters, position(), 255),
  'set': charTest(characters, any().settable(), 255),
  'skip': charTest(
      characters, any().skip(before: epsilon(), after: epsilon()), 255),
  'token': charTest(characters, any().token(), 255),
  'trim': charTest(characters, any().trim(), 247),
  'where': charTest(characters, any().where((_) => true), 255),

  // repeater tests
  'star': stringTest(charactersString, any().star()),
  'starGreedy':
      stringTest(charactersString, any().starGreedy(char(characters.last))),
  'starLazy':
      stringTest(charactersString, any().starLazy(char(characters.last))),
  'starSeparated': stringTest(charactersString, any().starSeparated(epsilon())),
  'plus': stringTest(charactersString, any().plus()),
  'plusGreedy':
      stringTest(charactersString, any().plusGreedy(char(characters.last))),
  'plusLazy':
      stringTest(charactersString, any().plusLazy(char(characters.last))),
  'plusSeparated': stringTest(charactersString, any().plusSeparated(epsilon())),
  'times': stringTest(charactersString, any().times(charactersString.length)),
  'timesSeparated': stringTest(charactersString,
      any().timesSeparated(epsilon(), charactersString.length)),
  for (var i = 2; i < charactersString.length; i *= 2)
    'seq($i chars)': stringTest(charactersString.substring(0, i),
        List.filled(i, any()).toSequenceParser()),
  'seq2': stringTest(charactersString.substring(0, 2), seq2(any(), any())),
  'seq3':
      stringTest(charactersString.substring(0, 3), seq3(any(), any(), any())),
  'seq4': stringTest(
      charactersString.substring(0, 4), seq4(any(), any(), any(), any())),
  'seq5': stringTest(charactersString.substring(0, 5),
      seq5(any(), any(), any(), any(), any())),
  'seq6': stringTest(charactersString.substring(0, 6),
      seq6(any(), any(), any(), any(), any(), any())),
  'seq7': stringTest(charactersString.substring(0, 7),
      seq7(any(), any(), any(), any(), any(), any(), any())),
  'seq8': stringTest(charactersString.substring(0, 8),
      seq8(any(), any(), any(), any(), any(), any(), any(), any())),
  'seq9': stringTest(charactersString.substring(0, 9),
      seq9(any(), any(), any(), any(), any(), any(), any(), any(), any())),

  // predicate tests
  'string': stringTest(charactersString, string(charactersString)),
  'stringIgnoreCase':
      stringTest(charactersString, stringIgnoreCase(charactersString)),
  'predicate': stringTest(
      charactersString, predicate(charactersString.length, (_) => true, '')),
  'pattern (regexp)': stringTest(
      charactersString, PatternParser(RegExp('.*abc.*', dotAll: true), '')),
  'pattern (string)':
      stringTest(charactersString, PatternParser(charactersString, '')),

  // composite
  'bibtex': stringTest(bibtexInput, bibtex),
  'json': stringTest(jsonInput, json),
  'math': stringTest(mathInput, math.parser),
  'uri': stringTest(uriInput, uri),
};

void main() {
  stdout.writeln('Name\tParse\tAccept\tChange');
  for (final entry in benchmarks.entries) {
    stdout.write('${entry.key}\t');
    try {
      entry.value(BenchmarkType.verify)();
    } on StateError catch (error) {
      stdout.writeln(error.message);
      continue;
    }
    final parse = benchmark(entry.value(BenchmarkType.parse));
    stdout.write('${parse.toStringAsFixed(3)}\t');
    final accept = benchmark(entry.value(BenchmarkType.accept));
    stdout.write('${accept.toStringAsFixed(3)}\t');
    stdout.writeln('${percentChange(parse, accept).round()}%');
  }
}

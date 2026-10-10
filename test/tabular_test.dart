import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/tabular.dart';
import 'package:test/scaffolding.dart';

import 'utils/checks.dart';

void main() {
  group('csv', () {
    final csv = TabularDefinition.csv().build();
    test('linter', () {
      check(linter(csv)).isEmpty();
    });
    test('basic string', () {
      check(csv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(csv).isSuccess(
        'ab',
        value: [
          ['ab'],
        ],
      );
      check(csv).isSuccess(
        'abc',
        value: [
          ['abc'],
        ],
      );
    });
    test('quoted string', () {
      check(csv).isSuccess(
        '""',
        value: [
          [''],
        ],
      );
      check(csv).isSuccess(
        '"a"',
        value: [
          ['a'],
        ],
      );
      check(csv).isSuccess(
        '"ab"',
        value: [
          ['ab'],
        ],
      );
      check(csv).isSuccess(
        '"abc"',
        value: [
          ['abc'],
        ],
      );
      check(csv).isSuccess(
        '""""',
        value: [
          ['"'],
        ],
      );
    });
    test('fields', () {
      check(csv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(csv).isSuccess(
        'a,b',
        value: [
          ['a', 'b'],
        ],
      );
      check(csv).isSuccess(
        'a,b,c',
        value: [
          ['a', 'b', 'c'],
        ],
      );
    });
    test('fields (empty)', () {
      check(csv).isSuccess(
        '',
        value: [
          [''],
        ],
      );
      check(csv).isSuccess(
        ',',
        value: [
          ['', ''],
        ],
      );
      check(csv).isSuccess(
        ',,',
        value: [
          ['', '', ''],
        ],
      );
    });
    test('lines', () {
      check(csv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(csv).isSuccess(
        'a\nb',
        value: [
          ['a'],
          ['b'],
        ],
      );
      check(csv).isSuccess(
        'a\nb\nc',
        value: [
          ['a'],
          ['b'],
          ['c'],
        ],
      );
    });
    test('lines (emtpy)', () {
      check(csv).isSuccess(
        '\n',
        value: [
          [''],
          [''],
        ],
      );
      check(csv).isSuccess(
        '\n\n',
        value: [
          [''],
          [''],
          [''],
        ],
      );
    });
    test('failures', () {
      check(csv).isFailure('"abc"xyz');
      check(csv).isFailure('"a"b"c"');
    });
  });
  group('tsv', () {
    final tsv = TabularDefinition.tsv().build();
    test('linter', () {
      check(linter(tsv)).isEmpty();
    });
    test('basic string', () {
      check(tsv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(tsv).isSuccess(
        'ab',
        value: [
          ['ab'],
        ],
      );
      check(tsv).isSuccess(
        'abc',
        value: [
          ['abc'],
        ],
      );
    });
    test('escaped string', () {
      check(tsv).isSuccess(
        r'\t',
        value: [
          ['\t'],
        ],
      );
      check(tsv).isSuccess(
        r'\n',
        value: [
          ['\n'],
        ],
      );
      check(tsv).isSuccess(
        r'\r',
        value: [
          ['\r'],
        ],
      );
      check(tsv).isSuccess(
        r'\\',
        value: [
          ['\\'],
        ],
      );
    });
    test('fields', () {
      check(tsv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(tsv).isSuccess(
        'a\tb',
        value: [
          ['a', 'b'],
        ],
      );
      check(tsv).isSuccess(
        'a\tb\tc',
        value: [
          ['a', 'b', 'c'],
        ],
      );
    });
    test('fields (empty)', () {
      check(tsv).isSuccess(
        '',
        value: [
          [''],
        ],
      );
      check(tsv).isSuccess(
        '\t',
        value: [
          ['', ''],
        ],
      );
      check(tsv).isSuccess(
        '\t\t',
        value: [
          ['', '', ''],
        ],
      );
    });
    test('lines', () {
      check(tsv).isSuccess(
        'a',
        value: [
          ['a'],
        ],
      );
      check(tsv).isSuccess(
        'a\nb',
        value: [
          ['a'],
          ['b'],
        ],
      );
      check(tsv).isSuccess(
        'a\nb\nc',
        value: [
          ['a'],
          ['b'],
          ['c'],
        ],
      );
    });
    test('lines (emtpy)', () {
      check(tsv).isSuccess(
        '\n',
        value: [
          [''],
          [''],
        ],
      );
      check(tsv).isSuccess(
        '\n\n',
        value: [
          [''],
          [''],
          [''],
        ],
      );
    });
  });
}

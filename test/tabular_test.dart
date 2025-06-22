import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/tabular.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

void main() {
  group('csv', () {
    final csv = TabularDefinition.csv().build();
    test('linter', () {
      expect(linter(csv, excludedTypes: {}), isEmpty);
    });
    test('basic string', () {
      expect(
        csv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'ab',
          value: [
            ['ab'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'abc',
          value: [
            ['abc'],
          ],
        ),
      );
    });
    test('quoted string', () {
      expect(
        csv,
        isSuccess(
          '""',
          value: [
            [''],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          '"a"',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          '"ab"',
          value: [
            ['ab'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          '"abc"',
          value: [
            ['abc'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          '""""',
          value: [
            ['"'],
          ],
        ),
      );
    });
    test('fields', () {
      expect(
        csv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'a,b',
          value: [
            ['a', 'b'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'a,b,c',
          value: [
            ['a', 'b', 'c'],
          ],
        ),
      );
    });
    test('fields (empty)', () {
      expect(
        csv,
        isSuccess(
          '',
          value: [
            [''],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          ',',
          value: [
            ['', ''],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          ',,',
          value: [
            ['', '', ''],
          ],
        ),
      );
    });
    test('lines', () {
      expect(
        csv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'a\nb',
          value: [
            ['a'],
            ['b'],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          'a\nb\nc',
          value: [
            ['a'],
            ['b'],
            ['c'],
          ],
        ),
      );
    });
    test('lines (emtpy)', () {
      expect(
        csv,
        isSuccess(
          '\n',
          value: [
            [''],
            [''],
          ],
        ),
      );
      expect(
        csv,
        isSuccess(
          '\n\n',
          value: [
            [''],
            [''],
            [''],
          ],
        ),
      );
    });
  });
  group('tsv', () {
    final tsv = TabularDefinition.tsv().build();
    test('linter', () {
      expect(linter(tsv, excludedTypes: {}), isEmpty);
    });
    test('basic string', () {
      expect(
        tsv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'ab',
          value: [
            ['ab'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'abc',
          value: [
            ['abc'],
          ],
        ),
      );
    });
    test('escaped string', () {
      expect(
        tsv,
        isSuccess(
          r'\t',
          value: [
            ['\t'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          r'\n',
          value: [
            ['\n'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          r'\r',
          value: [
            ['\r'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          r'\\',
          value: [
            ['\\'],
          ],
        ),
      );
    });
    test('fields', () {
      expect(
        tsv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'a\tb',
          value: [
            ['a', 'b'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'a\tb\tc',
          value: [
            ['a', 'b', 'c'],
          ],
        ),
      );
    });
    test('fields (empty)', () {
      expect(
        tsv,
        isSuccess(
          '',
          value: [
            [''],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          '\t',
          value: [
            ['', ''],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          '\t\t',
          value: [
            ['', '', ''],
          ],
        ),
      );
    });
    test('lines', () {
      expect(
        tsv,
        isSuccess(
          'a',
          value: [
            ['a'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'a\nb',
          value: [
            ['a'],
            ['b'],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          'a\nb\nc',
          value: [
            ['a'],
            ['b'],
            ['c'],
          ],
        ),
      );
    });
    test('lines (emtpy)', () {
      expect(
        tsv,
        isSuccess(
          '\n',
          value: [
            [''],
            [''],
          ],
        ),
      );
      expect(
        tsv,
        isSuccess(
          '\n\n',
          value: [
            [''],
            [''],
            [''],
          ],
        ),
      );
    });
  });
}

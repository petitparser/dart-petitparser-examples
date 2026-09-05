import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final typ = grammar.buildFrom(grammar.type()).end();

  group('named types', () {
    test('primitive and built-in types', () {
      expect(typ, isSuccess('int'));
      expect(typ, isSuccess('double'));
      expect(typ, isSuccess('num'));
      expect(typ, isSuccess('bool'));
      expect(typ, isSuccess('String'));
      expect(typ, isSuccess('void'));
      expect(typ, isSuccess('dynamic'));
      expect(typ, isSuccess('Never'));
      expect(typ, isSuccess('Null'));
      expect(typ, isSuccess('Object'));
    });

    test('qualified types', () {
      expect(typ, isSuccess('prefix.MyClass'));
      expect(typ, isSuccess('dart.core.String'));
    });
  });

  group('nullable types', () {
    test('simple nullables', () {
      expect(typ, isSuccess('int?'));
      expect(typ, isSuccess('String?'));
      expect(typ, isSuccess('dynamic?'));
      expect(typ, isSuccess('prefix.MyClass?'));
    });

    test('nested generic nullables', () {
      expect(typ, isSuccess('List<int>?'));
      expect(typ, isSuccess('List<int?>'));
      expect(typ, isSuccess('Map<String?, List<int?>?>?'));
    });
  });

  group('typeTestType', () {
    final testTyp = grammar.buildFrom(grammar.typeTestType()).end();
    final testTypUnended = grammar.buildFrom(grammar.typeTestType());

    test('non-nullable types succeed fully', () {
      expect(testTyp, isSuccess('int'));
      expect(testTyp, isSuccess('List<int?>'));
      expect(testTyp, isSuccess('void Function(int?)'));
      expect(testTyp, isSuccess('(int?, String)'));
    });

    test('does not consume top-level ?', () {
      expect(testTyp, isFailure('int?'));
      expect(testTypUnended, isSuccess('int?', position: 3));
      expect(testTypUnended, isSuccess('(int, String)?', position: 13));
    });
  });

  group('generics', () {
    test('type arguments', () {
      expect(typ, isSuccess('List<int>'));
      expect(typ, isSuccess('Map<String, int>'));
      expect(typ, isSuccess('Map<String, List<int>>'));
      expect(typ, isSuccess('Future<void>'));
      expect(typ, isSuccess('Stream<List<Map<String, dynamic>>>'));
    });
  });

  group('record types', () {
    test('empty record type', () {
      expect(typ, isSuccess('()'));
      expect(typ, isSuccess('()?'));
    });

    test('positional only', () {
      expect(typ, isSuccess('(int,)'));
      expect(typ, isSuccess('(int, String)'));
      expect(typ, isSuccess('(int, String, bool)'));
      expect(typ, isSuccess('(int a, String b)'));
      expect(typ, isSuccess('(int, String)?'));
    });

    test('named only', () {
      expect(typ, isSuccess('({int a})'));
      expect(typ, isSuccess('({int a, String b})'));
      expect(typ, isSuccess('({int a, String b,})'));
      expect(typ, isSuccess('({int a, String b})?'));
    });

    test('mixed positional and named', () {
      expect(typ, isSuccess('(int, {String b})'));
      expect(typ, isSuccess('(int a, {String b})'));
      expect(typ, isSuccess('(int, double, {String name, bool flag})'));
      expect(typ, isSuccess('(int, {String b,})'));
    });

    test('nested record types', () {
      expect(typ, isSuccess('((int, int), String)'));
      expect(typ, isSuccess('({(int, String) pair, bool flag})'));
    });
  });

  group('function types', () {
    test('standalone function types', () {
      expect(typ, isSuccess('Function()'));
      expect(typ, isSuccess('Function()?'));
      expect(typ, isSuccess('Function(int)'));
      expect(typ, isSuccess('Function(int, [String])'));
      expect(typ, isSuccess('Function(int, {String name})'));
    });

    test('function types with return type', () {
      expect(typ, isSuccess('void Function()'));
      expect(typ, isSuccess('int Function(String)'));
      expect(typ, isSuccess('int Function(String, [int])'));
      expect(typ, isSuccess('int Function(String, [int])?'));
      expect(typ, isSuccess('void Function(String, {bool flag})'));
      expect(typ, isSuccess('void Function(String, {required bool flag})'));
    });

    test('generic function types', () {
      expect(typ, isSuccess('T Function<T>(T)'));
      expect(typ, isSuccess('R Function<T, R>(T)'));
      expect(typ, isSuccess('T Function<T extends Object>(T)'));
    });

    test('higher order function types', () {
      expect(typ, isSuccess('void Function(void Function())'));
      expect(typ, isSuccess('int Function(int) Function(String)'));
    });
  });

  group('type parameters declaration', () {
    final typeParams = grammar.buildFrom(grammar.typeParameters()).end();

    test('single parameter', () {
      expect(typeParams, isSuccess('<T>'));
      expect(typeParams, isSuccess('<T extends Object>'));
      expect(typeParams, isSuccess('<T extends Comparable<T>>'));
    });

    test('multiple parameters', () {
      expect(typeParams, isSuccess('<T, R>'));
      expect(typeParams, isSuccess('<K, V extends List<K>>'));
    });
  });
}

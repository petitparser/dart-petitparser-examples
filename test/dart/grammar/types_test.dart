import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final typ = grammar.buildFrom(grammar.type()).end();

  group('named types', () {
    test('primitive and built-in types', () {
      check(typ).isSuccess('int');
      check(typ).isSuccess('double');
      check(typ).isSuccess('num');
      check(typ).isSuccess('bool');
      check(typ).isSuccess('String');
      check(typ).isSuccess('void');
      check(typ).isSuccess('dynamic');
      check(typ).isSuccess('Never');
      check(typ).isSuccess('Null');
      check(typ).isSuccess('Object');
    });

    test('qualified types', () {
      check(typ).isSuccess('prefix.MyClass');
      check(typ).isSuccess('dart.core.String');
    });
  });

  group('nullable types', () {
    test('simple nullables', () {
      check(typ).isSuccess('int?');
      check(typ).isSuccess('String?');
      check(typ).isSuccess('dynamic?');
      check(typ).isSuccess('prefix.MyClass?');
    });

    test('nested generic nullables', () {
      check(typ).isSuccess('List<int>?');
      check(typ).isSuccess('List<int?>');
      check(typ).isSuccess('Map<String?, List<int?>?>?');
    });
  });

  group('typeTestType', () {
    final testTyp = grammar.buildFrom(grammar.typeTestType()).end();
    final testTypUnended = grammar.buildFrom(grammar.typeTestType());

    test('non-nullable types succeed fully', () {
      check(testTyp).isSuccess('int');
      check(testTyp).isSuccess('List<int?>');
      check(testTyp).isSuccess('void Function(int?)');
      check(testTyp).isSuccess('(int?, String)');
    });

    test('does not consume top-level ?', () {
      check(testTyp).isFailure('int?');
      check(testTypUnended).isSuccess('int?', position: 3);
      check(testTypUnended).isSuccess('(int, String)?', position: 13);
    });
  });

  group('generics', () {
    test('type arguments', () {
      check(typ).isSuccess('List<int>');
      check(typ).isSuccess('Map<String, int>');
      check(typ).isSuccess('Map<String, List<int>>');
      check(typ).isSuccess('Future<void>');
      check(typ).isSuccess('Stream<List<Map<String, dynamic>>>');
    });
  });

  group('record types', () {
    test('empty record type', () {
      check(typ).isSuccess('()');
      check(typ).isSuccess('()?');
    });

    test('positional only', () {
      check(typ).isSuccess('(int,)');
      check(typ).isSuccess('(int, String)');
      check(typ).isSuccess('(int, String, bool)');
      check(typ).isSuccess('(int a, String b)');
      check(typ).isSuccess('(int, String)?');
    });

    test('named only', () {
      check(typ).isSuccess('({int a})');
      check(typ).isSuccess('({int a, String b})');
      check(typ).isSuccess('({int a, String b,})');
      check(typ).isSuccess('({int a, String b})?');
    });

    test('mixed positional and named', () {
      check(typ).isSuccess('(int, {String b})');
      check(typ).isSuccess('(int a, {String b})');
      check(typ).isSuccess('(int, double, {String name, bool flag})');
      check(typ).isSuccess('(int, {String b,})');
    });

    test('nested record types', () {
      check(typ).isSuccess('((int, int), String)');
      check(typ).isSuccess('({(int, String) pair, bool flag})');
    });
  });

  group('function types', () {
    test('standalone function types', () {
      check(typ).isSuccess('Function()');
      check(typ).isSuccess('Function()?');
      check(typ).isSuccess('Function(int)');
      check(typ).isSuccess('Function(int, [String])');
      check(typ).isSuccess('Function(int, {String name})');
    });

    test('function types with return type', () {
      check(typ).isSuccess('void Function()');
      check(typ).isSuccess('int Function(String)');
      check(typ).isSuccess('int Function(String, [int])');
      check(typ).isSuccess('int Function(String, [int])?');
      check(typ).isSuccess('void Function(String, {bool flag})');
      check(typ).isSuccess('void Function(String, {required bool flag})');
    });

    test('generic function types', () {
      check(typ).isSuccess('T Function<T>(T)');
      check(typ).isSuccess('R Function<T, R>(T)');
      check(typ).isSuccess('T Function<T extends Object>(T)');
    });

    test('higher order function types', () {
      check(typ).isSuccess('void Function(void Function())');
      check(typ).isSuccess('int Function(int) Function(String)');
    });
  });

  group('type parameters declaration', () {
    final typeParams = grammar.buildFrom(grammar.typeParameters()).end();

    test('single parameter', () {
      check(typeParams).isSuccess('<T>');
      check(typeParams).isSuccess('<T extends Object>');
      check(typeParams).isSuccess('<T extends Comparable<T>>');
    });

    test('multiple parameters', () {
      check(typeParams).isSuccess('<T, R>');
      check(typeParams).isSuccess('<K, V extends List<K>>');
    });
  });

  group('formal parameters', () {
    final formalParams = grammar.buildFrom(grammar.formalParameters()).end();

    test('parameters with metadata annotations', () {
      check(formalParams).isSuccess('(@isTest int x)');
      check(formalParams).isSuccess('(@foo @bar String s)');
      check(formalParams).isSuccess('({@required @deprecated int? x})');
      check(
        formalParams,
      ).isSuccess('(@Deprecated("Debug only") @doNotSubmit bool solo = false)');
      check(formalParams).isSuccess(
        '(Object? desc, FutureOr<dynamic> Function() body, {@Deprecated("msg") @doNotSubmit bool solo = false})',
      );
      check(formalParams).isSuccess('([@deprecated int count = 0])');
    });

    test('function-typed parameter with metadata annotations', () {
      final it = Condition.it<Object?>();
      final node = it
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<FunctionTypedParameterNode>();
      node.has('name', (p) => p.name).equals('cb');
      node.has('metadata', (p) => p.metadata).length.equals(1);
      check(formalParams).isSuccess('(@meta void cb())', value: it);
      check(formalParams).isSuccess('(@foo @bar int Function() cb)');
    });

    test('optional positional parameter defaults', () {
      final it1 = Condition.it<Object?>();
      final node1 = it1
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<SimpleParameterNode>();
      node1.has('name', (p) => p.name).equals('x');
      node1
          .has('defaultValue', (p) => p.defaultValue)
          .isA<IntegerLiteralNode>();
      check(formalParams).isSuccess('([int x = 42])', value: it1);
      final it2 = Condition.it<Object?>();
      final node2 = it2
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<FunctionTypedParameterNode>();
      node2.has('name', (p) => p.name).equals('cb');
      node2.has('defaultValue', (p) => p.defaultValue).isA<IdentifierNode>();
      check(formalParams)
          .isSuccess('([void cb() = defaultCallback])', value: it2);
    });

    test('named function-typed parameter defaults', () {
      final it1 = Condition.it<Object?>();
      final node1 = it1
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<FunctionTypedParameterNode>();
      node1.has('name', (p) => p.name).equals('cb');
      node1.has('isNamed', (p) => p.isNamed).isTrue;
      node1.has('defaultValue', (p) => p.defaultValue).isA<IdentifierNode>();
      check(formalParams)
          .isSuccess('({void cb() = defaultCallback})', value: it1);
      final it2 = Condition.it<Object?>();
      final node2 = it2
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<FunctionTypedParameterNode>();
      node2.has('name', (p) => p.name).equals('cb');
      node2.has('defaultValue', (p) => p.defaultValue).isA<IdentifierNode>();
      check(formalParams)
          .isSuccess('({void cb(): defaultCallback})', value: it2);
      final it3 = Condition.it<Object?>();
      final node3 = it3
          .isA<List<ParameterNode>>()
          .has('first', (list) => list.first)
          .isA<FunctionTypedParameterNode>();
      node3.has('metadata', (p) => p.metadata).length.equals(1);
      node3.has('isRequired', (p) => p.isRequired).isTrue;
      check(
        formalParams,
      ).isSuccess('({@meta required void cb() = defaultCallback})', value: it3);
    });
  });
}

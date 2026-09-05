import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final expr = grammar.buildFrom(grammar.expression()).end();

  group('primary and literals', () {
    test('literals', () {
      expect(expr, isSuccess('1'));
      expect(expr, isSuccess('1.5'));
      expect(expr, isSuccess('"hello"'));
      expect(expr, isSuccess('true'));
      expect(expr, isSuccess('false'));
      expect(expr, isSuccess('null'));
      expect(expr, isSuccess('#sym'));
    });

    test('keywords', () {
      expect(expr, isSuccess('this'));
      expect(expr, isSuccess('super'));
    });

    test('identifiers', () {
      expect(expr, isSuccess('x'));
      expect(expr, isSuccess('fooBar'));
      expect(expr, isSuccess('_private'));
    });
  });

  group('prefix operators', () {
    test('arithmetic & logical prefix', () {
      expect(expr, isSuccess('-a'));
      expect(expr, isSuccess('!a'));
      expect(expr, isSuccess('~a'));
      expect(expr, isSuccess('++a'));
      expect(expr, isSuccess('--a'));
    });

    test('await and throw', () {
      expect(expr, isSuccess('await a'));
      expect(expr, isSuccess('throw a'));
      expect(expr, isSuccess('throw Exception("err")'));
    });
  });

  group('postfix and selectors', () {
    test('increment & null-assert', () {
      expect(expr, isSuccess('a++'));
      expect(expr, isSuccess('a--'));
      expect(expr, isSuccess('a!'));
    });

    test('property access', () {
      expect(expr, isSuccess('a.b'));
      expect(expr, isSuccess('a?.b'));
      expect(expr, isSuccess('a.b.c'));
      expect(expr, isSuccess('a?.b?.c'));
      expect(expr, isSuccess('Foo.new'));
    });

    test('indexing', () {
      expect(expr, isSuccess('a[0]'));
      expect(expr, isSuccess('a[i + 1]'));
      expect(expr, isSuccess('a?[0]'));
      expect(expr, isSuccess('a[0][1]'));
    });

    test('invocations', () {
      expect(expr, isSuccess('a()'));
      expect(expr, isSuccess('a(1)'));
      expect(expr, isSuccess('a(1, 2)'));
      expect(expr, isSuccess('a(x: 1, y: 2)'));
      expect(expr, isSuccess('a(1, name: "val")'));
      expect(expr, isSuccess('a<int>()'));
      expect(expr, isSuccess('a<int, String>(1, b: 2)'));
      expect(expr, isSuccess('a.b().c()'));
    });
  });

  group('binary operators', () {
    test('multiplicative & additive', () {
      expect(expr, isSuccess('a * b'));
      expect(expr, isSuccess('a / b'));
      expect(expr, isSuccess('a ~/ b'));
      expect(expr, isSuccess('a % b'));
      expect(expr, isSuccess('a + b'));
      expect(expr, isSuccess('a - b'));
      expect(expr, isSuccess('a + b * c'));
      expect(expr, isSuccess('(a + b) * c'));
    });

    test('shift operators', () {
      expect(expr, isSuccess('a << 2'));
      expect(expr, isSuccess('a >> 2'));
      expect(expr, isSuccess('a >>> 2'));
    });

    test('relational and type test', () {
      expect(expr, isSuccess('a < b'));
      expect(expr, isSuccess('a <= b'));
      expect(expr, isSuccess('a > b'));
      expect(expr, isSuccess('a >= b'));
      expect(expr, isSuccess('a is int'));
      expect(expr, isSuccess('a is List<int?>'));
      expect(expr, isSuccess('a is! String'));
      expect(expr, isSuccess('a is! List<String?>'));
      expect(expr, isSuccess('a as double'));
      expect(expr, isSuccess('a as List<double?>'));
      expect(expr, isFailure('a is int?'));
      expect(expr, isFailure('a is! String?'));
      expect(expr, isFailure('a as double?'));
    });

    test('equality and bitwise', () {
      expect(expr, isSuccess('a == b'));
      expect(expr, isSuccess('a != b'));
      expect(expr, isSuccess('a & b'));
      expect(expr, isSuccess('a ^ b'));
      expect(expr, isSuccess('a | b'));
    });

    test('logical operators', () {
      expect(expr, isSuccess('a && b'));
      expect(expr, isSuccess('a || b'));
      expect(expr, isSuccess('a && b || c && d'));
    });

    test('if-null and conditional', () {
      expect(expr, isSuccess('a ?? b'));
      expect(expr, isSuccess('a ?? b ?? c'));
      expect(expr, isSuccess('a ? b : c'));
      expect(expr, isSuccess('a ? b ? c : d : e'));
      expect(expr, isSuccess('a is int ? b : c'));
      expect(expr, isSuccess('a is! int ? b : c'));
      expect(expr, isSuccess('a as int ? b : c'));
    });

    test('assignments', () {
      expect(expr, isSuccess('a = 1'));
      expect(expr, isSuccess('a += 1'));
      expect(expr, isSuccess('a -= 1'));
      expect(expr, isSuccess('a *= 2'));
      expect(expr, isSuccess('a /= 2'));
      expect(expr, isSuccess('a ~/= 2'));
      expect(expr, isSuccess('a %= 2'));
      expect(expr, isSuccess('a <<= 1'));
      expect(expr, isSuccess('a >>= 1'));
      expect(expr, isSuccess('a >>>= 1'));
      expect(expr, isSuccess('a &= 1'));
      expect(expr, isSuccess('a ^= 1'));
      expect(expr, isSuccess('a |= 1'));
      expect(expr, isSuccess('a ??= 1'));
    });
  });

  group('cascade expressions', () {
    test('single and chained cascades', () {
      expect(expr, isSuccess('a..b()'));
      expect(expr, isSuccess('a..b = 1..c = 2'));
      expect(expr, isSuccess('a..[0] = 1'));
      expect(expr, isSuccess('a?..b()..c = 1'));
    });
  });

  group('collection literals', () {
    test('lists', () {
      expect(expr, isSuccess('[]'));
      expect(expr, isSuccess('[1]'));
      expect(expr, isSuccess('[1, 2, 3]'));
      expect(expr, isSuccess('[1, 2, 3,]'));
      expect(expr, isSuccess('<int>[1, 2]'));
      expect(expr, isSuccess('const [1, 2]'));
    });

    test('sets and maps', () {
      expect(expr, isSuccess('{}'));
      expect(expr, isSuccess('{1, 2, 3}'));
      expect(expr, isSuccess('{"a": 1, "b": 2}'));
      expect(expr, isSuccess('<int>{1, 2}'));
      expect(expr, isSuccess('<String, int>{"a": 1}'));
      expect(expr, isSuccess('const {"a": 1}'));
    });

    test('control flow in collections', () {
      expect(expr, isSuccess('[...a]'));
      expect(expr, isSuccess('[...?a]'));
      expect(expr, isSuccess('[if (x) 1]'));
      expect(expr, isSuccess('[if (x) 1 else 2]'));
      expect(expr, isSuccess('[if (x case int y) y]'));
      expect(expr, isSuccess('[if (x case int y when y > 0) y else 0]'));
      expect(expr, isSuccess('[for (var x in list) x]'));
      expect(expr, isSuccess('[for (final (a, b) in pairs) a + b]'));
      expect(expr, isSuccess('[?a, ?b]'));
      expect(expr, isSuccess('{?k: ?v}'));
    });
  });

  group('record literals', () {
    test('empty and positional', () {
      expect(expr, isSuccess('()'));
      expect(expr, isSuccess('(1,)'));
      expect(expr, isSuccess('(1, 2)'));
      expect(expr, isSuccess('(1, 2, 3)'));
      expect(expr, isSuccess('const (1, 2)'));
    });

    test('named and mixed', () {
      expect(expr, isSuccess('(a: 1)'));
      expect(expr, isSuccess('(a: 1, b: 2)'));
      expect(expr, isSuccess('(1, b: 2)'));
      expect(expr, isSuccess('(1, a: 2, 3, b: 4)'));
    });
  });

  group('switch expressions', () {
    test('simple switch expression', () {
      expect(expr, isSuccess('switch (x) { 1 => "one", _ => "other" }'));
      expect(
        expr,
        isSuccess('switch (x) { 1 => "one", 2 => "two", _ => "many", }'),
      );
    });

    test('switch expression with pattern and when guard', () {
      expect(
        expr,
        isSuccess(
          'switch (x) { int y when y > 0 => "pos", _ => "zero or neg" }',
        ),
      );
      expect(
        expr,
        isSuccess(
          'switch (point) { Point(x: 0, y: 0) => "origin", _ => "point" }',
        ),
      );
    });
  });

  group('function expressions (closures)', () {
    test('arrow closures', () {
      expect(expr, isSuccess('() => 42'));
      expect(expr, isSuccess('(x) => x + 1'));
      expect(expr, isSuccess('(x, y) => x + y'));
      expect(expr, isSuccess('(int x, {String y = ""}) => x'));
      expect(expr, isSuccess('() async => await fetch()'));
    });

    test('block closures', () {
      expect(expr, isSuccess('() { return 42; }'));
      expect(expr, isSuccess('(x) { if (x > 0) return x; return -x; }'));
    });
  });

  group('constructor invocations', () {
    test('new and const', () {
      expect(expr, isSuccess('new Point(1, 2)'));
      expect(expr, isSuccess('const Point(1, 2)'));
      expect(expr, isSuccess('const Point.origin()'));
      expect(expr, isSuccess('new List<int>.filled(5, 0)'));
    });

    test('constructor invocations without new or const', () {
      expect(expr, isSuccess('Point(1, 2)'));
      expect(expr, isSuccess('Point.origin()'));
      expect(expr, isSuccess('Map<Variable, Node>.identity()'));
      expect(expr, isSuccess('List<int>.filled(5, 0)'));
    });
  });
}

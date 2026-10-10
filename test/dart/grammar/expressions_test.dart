import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final expr = grammar.buildFrom(grammar.expression()).end();

  group('primary and literals', () {
    test('literals', () {
      check(expr).isSuccess('1');
      check(expr).isSuccess('1.5');
      check(expr).isSuccess('"hello"');
      check(expr).isSuccess('true');
      check(expr).isSuccess('false');
      check(expr).isSuccess('null');
      check(expr).isSuccess('#sym');
    });

    test('keywords', () {
      check(expr).isSuccess('this');
      check(expr).isSuccess('super');
    });

    test('identifiers', () {
      check(expr).isSuccess('x');
      check(expr).isSuccess('fooBar');
      check(expr).isSuccess('_private');
    });
  });

  group('prefix operators', () {
    test('arithmetic & logical prefix', () {
      check(expr).isSuccess('-a');
      check(expr).isSuccess('!a');
      check(expr).isSuccess('~a');
      check(expr).isSuccess('++a');
      check(expr).isSuccess('--a');
    });

    test('await and throw', () {
      check(expr).isSuccess('await a');
      check(expr).isSuccess('throw a');
      check(expr).isSuccess('throw Exception("err")');
    });
  });

  group('postfix and selectors', () {
    test('increment & null-assert', () {
      check(expr).isSuccess('a++');
      check(expr).isSuccess('a--');
      check(expr).isSuccess('a!');
    });

    test('property access', () {
      check(expr).isSuccess('a.b');
      check(expr).isSuccess('a?.b');
      check(expr).isSuccess('a.b.c');
      check(expr).isSuccess('a?.b?.c');
      check(expr).isSuccess('Foo.new');
    });

    test('indexing', () {
      check(expr).isSuccess('a[0]');
      check(expr).isSuccess('a[i + 1]');
      check(expr).isSuccess('a?[0]');
      check(expr).isSuccess('a[0][1]');
    });

    test('invocations', () {
      check(expr).isSuccess('a()');
      check(expr).isSuccess('a(1)');
      check(expr).isSuccess('a(1, 2)');
      check(expr).isSuccess('a(x: 1, y: 2)');
      check(expr).isSuccess('a(1, name: "val")');
      check(expr).isSuccess('a<int>()');
      check(expr).isSuccess('a<int, String>(1, b: 2)');
      check(expr).isSuccess('a.b().c()');
    });
  });

  group('binary operators', () {
    test('multiplicative & additive', () {
      check(expr).isSuccess('a * b');
      check(expr).isSuccess('a / b');
      check(expr).isSuccess('a ~/ b');
      check(expr).isSuccess('a % b');
      check(expr).isSuccess('a + b');
      check(expr).isSuccess('a - b');
      check(expr).isSuccess('a + b * c');
      check(expr).isSuccess('(a + b) * c');
    });

    test('shift operators', () {
      check(expr).isSuccess('a << 2');
      check(expr).isSuccess('a >> 2');
      check(expr).isSuccess('a >>> 2');
    });

    test('relational and type test', () {
      check(expr).isSuccess('a < b');
      check(expr).isSuccess('a <= b');
      check(expr).isSuccess('a > b');
      check(expr).isSuccess('a >= b');
      check(expr).isSuccess('a is int');
      check(expr).isSuccess('a is List<int?>');
      check(expr).isSuccess('a is! String');
      check(expr).isSuccess('a is! List<String?>');
      check(expr).isSuccess('a as double');
      check(expr).isSuccess('a as List<double?>');
      check(expr).isFailure('a is int?');
      check(expr).isFailure('a is! String?');
      check(expr).isFailure('a as double?');
    });

    test('equality and bitwise', () {
      check(expr).isSuccess('a == b');
      check(expr).isSuccess('a != b');
      check(expr).isSuccess('a & b');
      check(expr).isSuccess('a ^ b');
      check(expr).isSuccess('a | b');
    });

    test('logical operators', () {
      check(expr).isSuccess('a && b');
      check(expr).isSuccess('a || b');
      check(expr).isSuccess('a && b || c && d');
    });

    test('if-null and conditional', () {
      check(expr).isSuccess('a ?? b');
      check(expr).isSuccess('a ?? b ?? c');
      check(expr).isSuccess('a ? b : c');
      check(expr).isSuccess('a ? b ? c : d : e');
      check(expr).isSuccess('a is int ? b : c');
      check(expr).isSuccess('a is! int ? b : c');
      check(expr).isSuccess('a as int ? b : c');
    });

    test('assignments', () {
      check(expr).isSuccess('a = 1');
      check(expr).isSuccess('a += 1');
      check(expr).isSuccess('a -= 1');
      check(expr).isSuccess('a *= 2');
      check(expr).isSuccess('a /= 2');
      check(expr).isSuccess('a ~/= 2');
      check(expr).isSuccess('a %= 2');
      check(expr).isSuccess('a <<= 1');
      check(expr).isSuccess('a >>= 1');
      check(expr).isSuccess('a >>>= 1');
      check(expr).isSuccess('a &= 1');
      check(expr).isSuccess('a ^= 1');
      check(expr).isSuccess('a |= 1');
      check(expr).isSuccess('a ??= 1');
    });
  });

  group('cascade expressions', () {
    test('single and chained cascades', () {
      check(expr).isSuccess('a..b()');
      check(expr).isSuccess('a..b = 1..c = 2');
      check(expr).isSuccess('a..[0] = 1');
      check(expr).isSuccess('a?..b()..c = 1');
    });
  });

  group('collection literals', () {
    test('lists', () {
      check(expr).isSuccess('[]');
      check(expr).isSuccess('[1]');
      check(expr).isSuccess('[1, 2, 3]');
      check(expr).isSuccess('[1, 2, 3,]');
      check(expr).isSuccess('<int>[1, 2]');
      check(expr).isSuccess('const [1, 2]');
    });

    test('sets and maps', () {
      check(expr).isSuccess('{}');
      check(expr).isSuccess('{1, 2, 3}');
      check(expr).isSuccess('{"a": 1, "b": 2}');
      check(expr).isSuccess('<int>{1, 2}');
      check(expr).isSuccess('<String, int>{"a": 1}');
      check(expr).isSuccess('const {"a": 1}');
    });

    test('control flow in collections', () {
      check(expr).isSuccess('[...a]');
      check(expr).isSuccess('[...?a]');
      check(expr).isSuccess('[if (x) 1]');
      check(expr).isSuccess('[if (x) 1 else 2]');
      check(expr).isSuccess('[if (x case int y) y]');
      check(expr).isSuccess('[if (x case int y when y > 0) y else 0]');
      check(expr).isSuccess('[for (var x in list) x]');
      check(expr).isSuccess('[for (final (a, b) in pairs) a + b]');
      check(expr).isSuccess(
        "[for (var i = 0; i < n.values.length; i++) {'key': n.keys[i], 'value': n.values[i]}]",
      );
      check(expr).isSuccess('[for (var i = 0; i < 10; i++) i]');
      check(expr).isSuccess('[for (int i = 0, j = 10; i < j; i++, j--) i + j]');
      check(expr).isSuccess('[for (;;) 1]');
      check(expr).isSuccess('[for (; i < 10; i++) i]');
      check(expr).isSuccess(
        '<String, dynamic>{for (var i = 0; i < n.values.length; i++) n.keys[i]: n.values[i]}',
      );
      check(expr).isSuccess('[?a, ?b]');
      check(expr).isSuccess('{?k: ?v}');
    });
  });

  group('record literals', () {
    test('empty and positional', () {
      check(expr).isSuccess('()');
      check(expr).isSuccess('(1,)');
      check(expr).isSuccess('(1, 2)');
      check(expr).isSuccess('(1, 2, 3)');
      check(expr).isSuccess('const (1, 2)');
    });

    test('named and mixed', () {
      check(expr).isSuccess('(a: 1)');
      check(expr).isSuccess('(a: 1, b: 2)');
      check(expr).isSuccess('(1, b: 2)');
      check(expr).isSuccess('(1, a: 2, 3, b: 4)');
    });
  });

  group('switch expressions', () {
    test('simple switch expression', () {
      check(expr).isSuccess('switch (x) { 1 => "one", _ => "other" }');
      check(expr)
          .isSuccess('switch (x) { 1 => "one", 2 => "two", _ => "many", }');
    });

    test('switch expression with pattern and when guard', () {
      check(expr).isSuccess(
        'switch (x) { int y when y > 0 => "pos", _ => "zero or neg" }',
      );
      check(expr).isSuccess(
        'switch (point) { Point(x: 0, y: 0) => "origin", _ => "point" }',
      );
    });
  });

  group('function expressions (closures)', () {
    test('arrow closures', () {
      check(expr).isSuccess('() => 42');
      check(expr).isSuccess('(x) => x + 1');
      check(expr).isSuccess('(x, y) => x + y');
      check(expr).isSuccess('(int x, {String y = ""}) => x');
      check(expr).isSuccess('() async => await fetch()');
    });

    test('block closures', () {
      check(expr).isSuccess('() { return 42; }');
      check(expr).isSuccess('(x) { if (x > 0) return x; return -x; }');
    });
  });

  group('constructor invocations', () {
    test('new and const', () {
      check(expr).isSuccess('new Point(1, 2)');
      check(expr).isSuccess('const Point(1, 2)');
      check(expr).isSuccess('const Point.origin()');
      check(expr).isSuccess('new List<int>.filled(5, 0)');
    });

    test('constructor invocations without new or const', () {
      check(expr).isSuccess('Point(1, 2)');
      check(expr).isSuccess('Point.origin()');
      check(expr).isSuccess('Map<Variable, Node>.identity()');
      check(expr).isSuccess('List<int>.filled(5, 0)');
    });
  });
}

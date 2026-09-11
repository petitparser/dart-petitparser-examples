import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final expr = grammar.buildFrom(grammar.expression()).end();

  group('literals and atoms', () {
    test('constants', () {
      expect(expr, isSuccess('None'));
      expect(expr, isSuccess('True'));
      expect(expr, isSuccess('False'));
      expect(expr, isSuccess('42'));
      expect(expr, isSuccess('"hello"'));
    });

    test('identifiers', () {
      expect(expr, isSuccess('x'));
      expect(expr, isSuccess('foo_bar'));
    });

    test('tuples', () {
      expect(expr, isSuccess('()'));
      expect(expr, isSuccess('(1,)'));
      expect(expr, isSuccess('(1, 2)'));
      expect(expr, isSuccess('(1, 2, 3)'));
      expect(expr, isSuccess('1, 2'));
    });

    test('lists', () {
      expect(expr, isSuccess('[]'));
      expect(expr, isSuccess('[1]'));
      expect(expr, isSuccess('[1, 2, 3]'));
    });

    test('dicts and sets', () {
      expect(expr, isSuccess('{}'));
      expect(expr, isSuccess('{1}'));
      expect(expr, isSuccess('{1, 2, 3}'));
      expect(expr, isSuccess('{"key": "value"}'));
      expect(expr, isSuccess('{"a": 1, "b": 2, **extra}'));
    });
  });

  group('comprehensions', () {
    test('list comprehension', () {
      expect(expr, isSuccess('[x for x in data]'));
      expect(expr, isSuccess('[x for x in data if x > 0]'));
      expect(expr, isSuccess('[x for row in matrix for x in row]'));
    });

    test('set comprehension', () {
      expect(expr, isSuccess('{x for x in data}'));
      expect(expr, isSuccess('{x for x in data if x != 0}'));
    });

    test('dict comprehension', () {
      expect(expr, isSuccess('{k: v for k, v in items}'));
      expect(expr, isSuccess('{k: v for k, v in items if k}'));
    });

    test('generator expression', () {
      expect(expr, isSuccess('(x for x in data)'));
      expect(expr, isSuccess('(x for x in data if x)'));
    });
  });

  group('operators and precedence', () {
    test('arithmetic', () {
      expect(expr, isSuccess('1 + 2'));
      expect(expr, isSuccess('1 - 2'));
      expect(expr, isSuccess('2 * 3'));
      expect(expr, isSuccess('4 / 2'));
      expect(expr, isSuccess('7 // 2'));
      expect(expr, isSuccess('7 % 3'));
      expect(expr, isSuccess('2 ** 3'));
      expect(expr, isSuccess('A @ B'));
    });

    test('bitwise and shifts', () {
      expect(expr, isSuccess('a & b'));
      expect(expr, isSuccess('a ^ b'));
      expect(expr, isSuccess('a | b'));
      expect(expr, isSuccess('a << 2'));
      expect(expr, isSuccess('b >> 1'));
      expect(expr, isSuccess('~x'));
    });

    test('unary operators', () {
      expect(expr, isSuccess('+x'));
      expect(expr, isSuccess('-x'));
      expect(expr, isSuccess('not x'));
    });

    test('comparisons and chained comparisons', () {
      expect(expr, isSuccess('a == b'));
      expect(expr, isSuccess('a != b'));
      expect(expr, isSuccess('a < b'));
      expect(expr, isSuccess('a <= b'));
      expect(expr, isSuccess('a > b'));
      expect(expr, isSuccess('a >= b'));
      expect(expr, isSuccess('a is b'));
      expect(expr, isSuccess('a is not b'));
      expect(expr, isSuccess('a in b'));
      expect(expr, isSuccess('a not in b'));
      expect(expr, isSuccess('0 < x <= 10 == y'));
    });

    test('boolean logic', () {
      expect(expr, isSuccess('a and b'));
      expect(expr, isSuccess('a or b'));
      expect(expr, isSuccess('a and not b or c'));
    });

    test('ternary if-else', () {
      expect(expr, isSuccess('x if cond else y'));
      expect(expr, isSuccess('a + 1 if cond else b - 1'));
    });

    test('walrus named expression', () {
      expect(expr, isSuccess('x := 10'));
      expect(expr, isSuccess('(n := len(a)) > 10'));
    });

    test('lambdas', () {
      expect(expr, isSuccess('lambda: 42'));
      expect(expr, isSuccess('lambda x: x + 1'));
      expect(expr, isSuccess('lambda x, y: x * y'));
    });
  });

  group('calls, subscripts, attributes', () {
    test('function calls', () {
      expect(expr, isSuccess('fn()'));
      expect(expr, isSuccess('fn(1, 2)'));
      expect(expr, isSuccess('fn(x, y=1, *args, **kwargs)'));
      expect(expr, isSuccess('fn(x for x in data)'));
    });

    test('attribute access', () {
      expect(expr, isSuccess('a.b'));
      expect(expr, isSuccess('a.b.c'));
      expect(expr, isSuccess('fn().attribute'));
    });

    test('subscripts and slices', () {
      expect(expr, isSuccess('a[0]'));
      expect(expr, isSuccess('a[1:2]'));
      expect(expr, isSuccess('a[1:10:2]'));
      expect(expr, isSuccess('a[:5]'));
      expect(expr, isSuccess('a[2:]'));
      expect(expr, isSuccess('a[:: -1]'));
      expect(expr, isSuccess('matrix[1, 2]'));
    });
  });

  group('async and generator expressions', () {
    test('await', () {
      expect(expr, isSuccess('await fetch()'));
    });

    test('yield and yield from', () {
      expect(expr, isSuccess('yield'));
      expect(expr, isSuccess('yield 42'));
      expect(expr, isSuccess('yield 1, 2'));
      expect(expr, isSuccess('yield from generator'));
    });
  });

  group('ellipsis', () {
    test('ellipsis atom', () {
      expect(expr, isSuccess('...'));
      expect(expr, isSuccess('Callable[..., Any]'));
      expect(expr, isSuccess('Callable[..., T]'));
      expect(expr, isSuccess('tuple[int, ...]'));
    });
  });

  group('star expressions in displays', () {
    test('star in tuple literals', () {
      expect(expr, isSuccess('(*args,)'));
      expect(expr, isSuccess('(1, *rest)'));
      expect(expr, isSuccess('(*a, None)'));
      expect(expr, isSuccess('(a, b, *c)'));
    });

    test('star in list literals', () {
      expect(expr, isSuccess('[*items]'));
      expect(expr, isSuccess('[1, *rest, 2]'));
    });
  });

  group('generator ternary elements', () {
    test('ternary expression as generator element', () {
      expect(expr, isSuccess('(x if c else y for x in data)'));
      expect(expr, isSuccess('any(r.host if m else r.sub for r in rules)'));
      expect(expr, isSuccess('[a if cond else b for a in items]'));
    });
  });

  group('lambdas with full parameters', () {
    test('lambda with *args and **kwargs', () {
      expect(expr, isSuccess('lambda *args: args'));
      expect(expr, isSuccess('lambda **kwargs: kwargs'));
      expect(expr, isSuccess('lambda *args, **kwargs: (args, kwargs)'));
    });

    test('lambda with defaults', () {
      expect(expr, isSuccess('lambda x=1: x'));
      expect(expr, isSuccess('lambda x=1, y=2: x + y'));
    });

    test('lambda with positional-only separator', () {
      expect(expr, isSuccess('lambda x, /, y: x + y'));
    });

    test('lambda with keyword-only args', () {
      expect(expr, isSuccess('lambda *, key: key'));
      expect(expr, isSuccess('lambda x, *, key=None: (x, key)'));
    });
  });
}

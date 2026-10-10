import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final expr = grammar.buildFrom(grammar.expression()).end();

  group('literals and atoms', () {
    test('constants', () {
      check(expr).isSuccess('None');
      check(expr).isSuccess('True');
      check(expr).isSuccess('False');
      check(expr).isSuccess('42');
      check(expr).isSuccess('"hello"');
    });

    test('identifiers', () {
      check(expr).isSuccess('x');
      check(expr).isSuccess('foo_bar');
    });

    test('tuples', () {
      check(expr).isSuccess('()');
      check(expr).isSuccess('(1,)');
      check(expr).isSuccess('(1, 2)');
      check(expr).isSuccess('(1, 2, 3)');
      check(expr).isSuccess('1, 2');
    });

    test('lists', () {
      check(expr).isSuccess('[]');
      check(expr).isSuccess('[1]');
      check(expr).isSuccess('[1, 2, 3]');
    });

    test('dicts and sets', () {
      check(expr).isSuccess('{}');
      check(expr).isSuccess('{1}');
      check(expr).isSuccess('{1, 2, 3}');
      check(expr).isSuccess('{"key": "value"}');
      check(expr).isSuccess('{"a": 1, "b": 2, **extra}');
    });
  });

  group('comprehensions', () {
    test('list comprehension', () {
      check(expr).isSuccess('[x for x in data]');
      check(expr).isSuccess('[x for x in data if x > 0]');
      check(expr).isSuccess('[x for row in matrix for x in row]');
    });

    test('set comprehension', () {
      check(expr).isSuccess('{x for x in data}');
      check(expr).isSuccess('{x for x in data if x != 0}');
    });

    test('dict comprehension', () {
      check(expr).isSuccess('{k: v for k, v in items}');
      check(expr).isSuccess('{k: v for k, v in items if k}');
    });

    test('generator expression', () {
      check(expr).isSuccess('(x for x in data)');
      check(expr).isSuccess('(x for x in data if x)');
    });
  });

  group('operators and precedence', () {
    test('arithmetic', () {
      check(expr).isSuccess('1 + 2');
      check(expr).isSuccess('1 - 2');
      check(expr).isSuccess('2 * 3');
      check(expr).isSuccess('4 / 2');
      check(expr).isSuccess('7 // 2');
      check(expr).isSuccess('7 % 3');
      check(expr).isSuccess('2 ** 3');
      check(expr).isSuccess('A @ B');
    });

    test('bitwise and shifts', () {
      check(expr).isSuccess('a & b');
      check(expr).isSuccess('a ^ b');
      check(expr).isSuccess('a | b');
      check(expr).isSuccess('a << 2');
      check(expr).isSuccess('b >> 1');
      check(expr).isSuccess('~x');
    });

    test('unary operators', () {
      check(expr).isSuccess('+x');
      check(expr).isSuccess('-x');
      check(expr).isSuccess('not x');
    });

    test('comparisons and chained comparisons', () {
      check(expr).isSuccess('a == b');
      check(expr).isSuccess('a != b');
      check(expr).isSuccess('a < b');
      check(expr).isSuccess('a <= b');
      check(expr).isSuccess('a > b');
      check(expr).isSuccess('a >= b');
      check(expr).isSuccess('a is b');
      check(expr).isSuccess('a is not b');
      check(expr).isSuccess('a in b');
      check(expr).isSuccess('a not in b');
      check(expr).isSuccess('0 < x <= 10 == y');
    });

    test('boolean logic', () {
      check(expr).isSuccess('a and b');
      check(expr).isSuccess('a or b');
      check(expr).isSuccess('a and not b or c');
    });

    test('ternary if-else', () {
      check(expr).isSuccess('x if cond else y');
      check(expr).isSuccess('a + 1 if cond else b - 1');
    });

    test('walrus named expression', () {
      check(expr).isSuccess('x := 10');
      check(expr).isSuccess('(n := len(a)) > 10');
    });

    test('lambdas', () {
      check(expr).isSuccess('lambda: 42');
      check(expr).isSuccess('lambda x: x + 1');
      check(expr).isSuccess('lambda x, y: x * y');
    });
  });

  group('calls, subscripts, attributes', () {
    test('function calls', () {
      check(expr).isSuccess('fn()');
      check(expr).isSuccess('fn(1, 2)');
      check(expr).isSuccess('fn(x, y=1, *args, **kwargs)');
      check(expr).isSuccess('fn(x for x in data)');
    });

    test('attribute access', () {
      check(expr).isSuccess('a.b');
      check(expr).isSuccess('a.b.c');
      check(expr).isSuccess('fn().attribute');
    });

    test('subscripts and slices', () {
      check(expr).isSuccess('a[0]');
      check(expr).isSuccess('a[1:2]');
      check(expr).isSuccess('a[1:10:2]');
      check(expr).isSuccess('a[:5]');
      check(expr).isSuccess('a[2:]');
      check(expr).isSuccess('a[:: -1]');
      check(expr).isSuccess('matrix[1, 2]');
    });
  });

  group('async and generator expressions', () {
    test('await', () {
      check(expr).isSuccess('await fetch()');
    });

    test('yield and yield from', () {
      check(expr).isSuccess('yield');
      check(expr).isSuccess('yield 42');
      check(expr).isSuccess('yield 1, 2');
      check(expr).isSuccess('yield from generator');
    });
  });

  group('ellipsis', () {
    test('ellipsis atom', () {
      check(expr).isSuccess('...');
      check(expr).isSuccess('Callable[..., Any]');
      check(expr).isSuccess('Callable[..., T]');
      check(expr).isSuccess('tuple[int, ...]');
    });
  });

  group('star expressions in displays', () {
    test('star in tuple literals', () {
      check(expr).isSuccess('(*args,)');
      check(expr).isSuccess('(1, *rest)');
      check(expr).isSuccess('(*a, None)');
      check(expr).isSuccess('(a, b, *c)');
    });

    test('star in list literals', () {
      check(expr).isSuccess('[*items]');
      check(expr).isSuccess('[1, *rest, 2]');
    });
  });

  group('generator ternary elements', () {
    test('ternary expression as generator element', () {
      check(expr).isSuccess('(x if c else y for x in data)');
      check(expr).isSuccess('any(r.host if m else r.sub for r in rules)');
      check(expr).isSuccess('[a if cond else b for a in items]');
    });
  });

  group('lambdas with full parameters', () {
    test('lambda with *args and **kwargs', () {
      check(expr).isSuccess('lambda *args: args');
      check(expr).isSuccess('lambda **kwargs: kwargs');
      check(expr).isSuccess('lambda *args, **kwargs: (args, kwargs)');
    });

    test('lambda with defaults', () {
      check(expr).isSuccess('lambda x=1: x');
      check(expr).isSuccess('lambda x=1, y=2: x + y');
    });

    test('lambda with positional-only separator', () {
      check(expr).isSuccess('lambda x, /, y: x + y');
    });

    test('lambda with keyword-only args', () {
      check(expr).isSuccess('lambda *, key: key');
      check(expr).isSuccess('lambda x, *, key=None: (x, key)');
    });
  });
}

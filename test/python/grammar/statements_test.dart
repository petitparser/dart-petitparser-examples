import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final stmt = grammar.buildFrom(grammar.statementLine()).end();
  final simpleStmt = grammar.buildFrom(grammar.simpleStatements()).end();

  group('simple statements', () {
    test('pass, break, continue', () {
      expect(simpleStmt, isSuccess('pass\n'));
      expect(simpleStmt, isSuccess('break\n'));
      expect(simpleStmt, isSuccess('continue\n'));
      expect(simpleStmt, isSuccess('pass; break; continue\n'));
    });

    test('assert statement', () {
      expect(simpleStmt, isSuccess('assert x > 0\n'));
      expect(simpleStmt, isSuccess('assert x > 0, "must be positive"\n'));
    });

    test('assignment statements', () {
      expect(simpleStmt, isSuccess('x = 1\n'));
      expect(simpleStmt, isSuccess('x = y = z = 0\n'));
      expect(simpleStmt, isSuccess('a, b = 1, 2\n'));
      expect(simpleStmt, isSuccess('x += 1\n'));
      expect(simpleStmt, isSuccess('x: int = 1\n'));
      expect(simpleStmt, isSuccess('x: int\n'));
    });

    test('type alias statement (PEP 695)', () {
      expect(simpleStmt, isSuccess('type Point = tuple[float, float]\n'));
      expect(simpleStmt, isSuccess('type ListOrSet[T] = list[T] | set[T]\n'));
    });

    test('del, return, yield, raise', () {
      expect(simpleStmt, isSuccess('del x\n'));
      expect(simpleStmt, isSuccess('del a, b, c\n'));
      expect(simpleStmt, isSuccess('return\n'));
      expect(simpleStmt, isSuccess('return 42\n'));
      expect(simpleStmt, isSuccess('yield\n'));
      expect(simpleStmt, isSuccess('yield 42\n'));
      expect(simpleStmt, isSuccess('raise\n'));
      expect(simpleStmt, isSuccess('raise ValueError("bad")\n'));
      expect(simpleStmt, isSuccess('raise ValueError("bad") from cause\n'));
    });

    test('imports', () {
      expect(simpleStmt, isSuccess('import math\n'));
      expect(simpleStmt, isSuccess('import sys, os\n'));
      expect(simpleStmt, isSuccess('import numpy as np, pandas as pd\n'));
      expect(simpleStmt, isSuccess('from math import sin, cos as cosine\n'));
      expect(simpleStmt, isSuccess('from . import local_mod\n'));
      expect(simpleStmt, isSuccess('from ..parent import item\n'));
      expect(simpleStmt, isSuccess('from package import *\n'));
    });

    test('global and nonlocal', () {
      expect(simpleStmt, isSuccess('global x\n'));
      expect(simpleStmt, isSuccess('global x, y, z\n'));
      expect(simpleStmt, isSuccess('nonlocal a, b\n'));
    });

    test('expression statements', () {
      expect(simpleStmt, isSuccess('print("hello")\n'));
      expect(simpleStmt, isSuccess('1 + 2\n'));
    });
  });

  group('compound statements', () {
    test('if, elif, else', () {
      expect(stmt, isSuccess('if x:\n  pass\n'));
      expect(stmt, isSuccess('if x:\n  pass\nelse:\n  pass\n'));
      expect(
        stmt,
        isSuccess('if x:\n  pass\nelif y:\n  pass\nelse:\n  pass\n'),
      );
    });

    test('while loop', () {
      expect(stmt, isSuccess('while True:\n  pass\n'));
      expect(
        stmt,
        isSuccess('while count < 10:\n  count += 1\nelse:\n  print("done")\n'),
      );
    });

    test('for loop and async for', () {
      expect(stmt, isSuccess('for i in range(10):\n  pass\n'));
      expect(stmt, isSuccess('for k, v in items:\n  pass\nelse:\n  pass\n'));
      expect(stmt, isSuccess('async for item in stream:\n  pass\n'));
    });

    test('try, except, except*, finally', () {
      expect(stmt, isSuccess('try:\n  pass\nexcept ValueError:\n  pass\n'));
      expect(
        stmt,
        isSuccess(
          'try:\n  pass\nexcept (TypeError, ValueError) as err:\n  pass\n',
        ),
      );
      expect(
        stmt,
        isSuccess('try:\n  pass\nexcept* ExceptionGroup:\n  pass\n'),
      );
      expect(stmt, isSuccess('try:\n  pass\nfinally:\n  clean_up()\n'));
    });

    test('with and async with', () {
      expect(stmt, isSuccess('with open("f") as f:\n  data = f.read()\n'));
      expect(stmt, isSuccess('with lock1, lock2:\n  pass\n'));
      expect(stmt, isSuccess('async with lock:\n  pass\n'));
    });

    test('match and case (PEP 634)', () {
      expect(
        stmt,
        isSuccess('match x:\n  case 1:\n    pass\n  case 2:\n    pass\n'),
      );
      expect(
        stmt,
        isSuccess(
          'match shape:\n  case Point(x, y) if x > 0:\n    print(x)\n  case _:\n    pass\n',
        ),
      );
    });
  });

  group('starred assignment targets', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('starred target on left side', () {
      expect(mod, isSuccess('*parts, tail = x.split(".")\n'));
      expect(mod, isSuccess('head, *rest = items\n'));
      expect(mod, isSuccess('first, *middle, last = values\n'));
    });
  });

  group('assignment with comparison RHS', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('== operator in RHS does not break assignment', () {
      expect(mod, isSuccess('x = a == b\n'));
      expect(mod, isSuccess('is_ok = result == "ok"\n'));
      expect(mod, isSuccess('flag = x is not None\n'));
    });

    test('== in RHS inside function', () {
      expect(mod, isSuccess('def foo():\n  c = b == "adhoc"\n  return c\n'));
    });
  });

  group('try-except with else and subsequent statements', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('try-except-else at module level', () {
      expect(
        mod,
        isSuccess(
          'try:\n  x = 1\nexcept ValueError:\n  x = 2\nelse:\n  x = 3\n',
        ),
      );
    });

    test('try-except followed by assignment with == in nested function', () {
      expect(
        mod,
        isSuccess(
          'def foo():\n'
          '  try:\n'
          '    b = 1\n'
          '  except Exception:\n'
          '    b = 2\n'
          '  c = b == "adhoc"\n',
        ),
      );
    });

    test('try-except-else followed by statements in function', () {
      expect(
        mod,
        isSuccess(
          'def foo():\n'
          '  try:\n'
          '    a = compute()\n'
          '  except ValueError:\n'
          '    a = default\n'
          '  else:\n'
          '    process(a)\n'
          '  return a\n',
        ),
      );
    });
  });

  group('indentation in suites', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('simple indentation', () {
      expect(mod, isSuccess('def foo():\n  x = 1\n  y = 2\n'));
    });

    test('blank lines and comments within indented block', () {
      expect(
        mod,
        isSuccess(
          'def foo():\n'
          '  x = 1\n'
          '\n'
          '  # comment\n'
          '  y = 2\n',
        ),
      );
    });

    test('nested indentation blocks', () {
      expect(
        mod,
        isSuccess(
          'if True:\n'
          '  if False:\n'
          '    pass\n'
          '  x = 1\n',
        ),
      );
    });

    test('inconsistent indentation fails', () {
      expect(
        parser.buildFrom(parser.statementLine()).end(),
        isFailure('if True:\n  x = 1\n    y = 2\n'),
      );
    });
  });
}

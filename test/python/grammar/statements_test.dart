import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final stmt = grammar.buildFrom(grammar.statementLine()).end();
  final simpleStmt = grammar.buildFrom(grammar.simpleStatements()).end();

  group('simple statements', () {
    test('pass, break, continue', () {
      check(simpleStmt).isSuccess('pass\n');
      check(simpleStmt).isSuccess('break\n');
      check(simpleStmt).isSuccess('continue\n');
      check(simpleStmt).isSuccess('pass; break; continue\n');
    });

    test('assert statement', () {
      check(simpleStmt).isSuccess('assert x > 0\n');
      check(simpleStmt).isSuccess('assert x > 0, "must be positive"\n');
    });

    test('assignment statements', () {
      check(simpleStmt).isSuccess('x = 1\n');
      check(simpleStmt).isSuccess('x = y = z = 0\n');
      check(simpleStmt).isSuccess('a, b = 1, 2\n');
      check(simpleStmt).isSuccess('x += 1\n');
      check(simpleStmt).isSuccess('x: int = 1\n');
      check(simpleStmt).isSuccess('x: int\n');
    });

    test('type alias statement (PEP 695)', () {
      check(simpleStmt).isSuccess('type Point = tuple[float, float]\n');
      check(simpleStmt).isSuccess('type ListOrSet[T] = list[T] | set[T]\n');
    });

    test('del, return, yield, raise', () {
      check(simpleStmt).isSuccess('del x\n');
      check(simpleStmt).isSuccess('del a, b, c\n');
      check(simpleStmt).isSuccess('return\n');
      check(simpleStmt).isSuccess('return 42\n');
      check(simpleStmt).isSuccess('yield\n');
      check(simpleStmt).isSuccess('yield 42\n');
      check(simpleStmt).isSuccess('raise\n');
      check(simpleStmt).isSuccess('raise ValueError("bad")\n');
      check(simpleStmt).isSuccess('raise ValueError("bad") from cause\n');
    });

    test('imports', () {
      check(simpleStmt).isSuccess('import math\n');
      check(simpleStmt).isSuccess('import sys, os\n');
      check(simpleStmt).isSuccess('import numpy as np, pandas as pd\n');
      check(simpleStmt).isSuccess('from math import sin, cos as cosine\n');
      check(simpleStmt).isSuccess('from . import local_mod\n');
      check(simpleStmt).isSuccess('from ..parent import item\n');
      check(simpleStmt).isSuccess('from package import *\n');
    });

    test('global and nonlocal', () {
      check(simpleStmt).isSuccess('global x\n');
      check(simpleStmt).isSuccess('global x, y, z\n');
      check(simpleStmt).isSuccess('nonlocal a, b\n');
    });

    test('expression statements', () {
      check(simpleStmt).isSuccess('print("hello")\n');
      check(simpleStmt).isSuccess('1 + 2\n');
    });
  });

  group('compound statements', () {
    test('if, elif, else', () {
      check(stmt).isSuccess('if x:\n  pass\n');
      check(stmt).isSuccess('if x:\n  pass\nelse:\n  pass\n');
      check(stmt).isSuccess('if x:\n  pass\nelif y:\n  pass\nelse:\n  pass\n');
    });

    test('while loop', () {
      check(stmt).isSuccess('while True:\n  pass\n');
      check(
        stmt,
      ).isSuccess('while count < 10:\n  count += 1\nelse:\n  print("done")\n');
    });

    test('for loop and async for', () {
      check(stmt).isSuccess('for i in range(10):\n  pass\n');
      check(stmt).isSuccess('for k, v in items:\n  pass\nelse:\n  pass\n');
      check(stmt).isSuccess('async for item in stream:\n  pass\n');
    });

    test('try, except, except*, finally', () {
      check(stmt).isSuccess('try:\n  pass\nexcept ValueError:\n  pass\n');
      check(stmt).isSuccess(
        'try:\n  pass\nexcept (TypeError, ValueError) as err:\n  pass\n',
      );
      check(stmt).isSuccess('try:\n  pass\nexcept* ExceptionGroup:\n  pass\n');
      check(stmt).isSuccess('try:\n  pass\nfinally:\n  clean_up()\n');
    });

    test('with and async with', () {
      check(stmt).isSuccess('with open("f") as f:\n  data = f.read()\n');
      check(stmt).isSuccess('with lock1, lock2:\n  pass\n');
      check(stmt).isSuccess('async with lock:\n  pass\n');
    });

    test('match and case (PEP 634)', () {
      check(stmt)
          .isSuccess('match x:\n  case 1:\n    pass\n  case 2:\n    pass\n');
      check(stmt).isSuccess(
        'match shape:\n  case Point(x, y) if x > 0:\n    print(x)\n  case _:\n    pass\n',
      );
    });
  });

  group('starred assignment targets', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('starred target on left side', () {
      check(mod).isSuccess('*parts, tail = x.split(".")\n');
      check(mod).isSuccess('head, *rest = items\n');
      check(mod).isSuccess('first, *middle, last = values\n');
    });
  });

  group('assignment with comparison RHS', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('== operator in RHS does not break assignment', () {
      check(mod).isSuccess('x = a == b\n');
      check(mod).isSuccess('is_ok = result == "ok"\n');
      check(mod).isSuccess('flag = x is not None\n');
    });

    test('== in RHS inside function', () {
      check(mod).isSuccess('def foo():\n  c = b == "adhoc"\n  return c\n');
    });
  });

  group('try-except with else and subsequent statements', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('try-except-else at module level', () {
      check(mod).isSuccess(
        'try:\n  x = 1\nexcept ValueError:\n  x = 2\nelse:\n  x = 3\n',
      );
    });

    test('try-except followed by assignment with == in nested function', () {
      check(mod).isSuccess(
        'def foo():\n'
        '  try:\n'
        '    b = 1\n'
        '  except Exception:\n'
        '    b = 2\n'
        '  c = b == "adhoc"\n',
      );
    });

    test('try-except-else followed by statements in function', () {
      check(mod).isSuccess(
        'def foo():\n'
        '  try:\n'
        '    a = compute()\n'
        '  except ValueError:\n'
        '    a = default\n'
        '  else:\n'
        '    process(a)\n'
        '  return a\n',
      );
    });
  });

  group('indentation in suites', () {
    final parser = PythonGrammarDefinition();
    final mod = parser.build();

    test('simple indentation', () {
      check(mod).isSuccess('def foo():\n  x = 1\n  y = 2\n');
    });

    test('blank lines and comments within indented block', () {
      check(mod).isSuccess(
        'def foo():\n'
        '  x = 1\n'
        '\n'
        '  # comment\n'
        '  y = 2\n',
      );
    });

    test('nested indentation blocks', () {
      check(mod).isSuccess(
        'if True:\n'
        '  if False:\n'
        '    pass\n'
        '  x = 1\n',
      );
    });

    test('inconsistent indentation fails', () {
      check(parser.buildFrom(parser.statementLine()).end())
          .isFailure('if True:\n  x = 1\n    y = 2\n');
    });
  });
}

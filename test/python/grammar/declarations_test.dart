import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final decl = grammar.buildFrom(grammar.declaration()).end();

  group('function definitions', () {
    test('simple function', () {
      expect(decl, isSuccess('def foo():\n  pass\n'));
      expect(decl, isSuccess('def foo(x):\n  return x\n'));
      expect(decl, isSuccess('def foo(x, y=1):\n  return x + y\n'));
    });

    test('return type annotation', () {
      expect(decl, isSuccess('def foo() -> int:\n  return 42\n'));
      expect(decl, isSuccess('def foo(x: str) -> str:\n  return x\n'));
    });

    test('complex parameter combinations (PEP 570 / PEP 3102)', () {
      expect(
        decl,
        isSuccess('def f(pos1, pos2, /, pos_or_kwd, *, kwd1, kwd2):\n  pass\n'),
      );
      expect(decl, isSuccess('def f(*args, **kwargs):\n  pass\n'));
      expect(decl, isSuccess('def f(a, b=1, *args, c=2, **kwargs):\n  pass\n'));
      expect(decl, isSuccess('def f(a: int = 0, /) -> None:\n  pass\n'));
    });

    test('async functions', () {
      expect(decl, isSuccess('async def fetch():\n  pass\n'));
      expect(
        decl,
        isSuccess('async def fetch(url: str) -> bytes:\n  return b""\n'),
      );
    });

    test('generic functions (PEP 695)', () {
      expect(decl, isSuccess('def identity[T](x: T) -> T:\n  return x\n'));
      expect(decl, isSuccess('def process[T: str, *Ts, **P](x: T):\n  pass\n'));
    });

    test('decorated functions', () {
      expect(decl, isSuccess('@staticmethod\ndef foo():\n  pass\n'));
      expect(decl, isSuccess('@dec1\n@dec2(opt=True)\ndef foo():\n  pass\n'));
    });
  });

  group('class definitions', () {
    test('simple class', () {
      expect(decl, isSuccess('class Point:\n  pass\n'));
      expect(decl, isSuccess('class Point():\n  pass\n'));
    });

    test('inheritance and metaclass', () {
      expect(decl, isSuccess('class Child(Base):\n  pass\n'));
      expect(
        decl,
        isSuccess('class Child(Base1, Base2, metaclass=Meta):\n  pass\n'),
      );
    });

    test('generic classes (PEP 695)', () {
      expect(decl, isSuccess('class Stack[T]:\n  pass\n'));
      expect(decl, isSuccess('class Mapping[Key, Value]:\n  pass\n'));
    });

    test('decorated classes', () {
      expect(decl, isSuccess('@dataclass\nclass Point:\n  x: int\n'));
      expect(
        decl,
        isSuccess('@decorator(param="value")\nclass Foo:\n  pass\n'),
      );
    });
  });

  group('type parameters (PEP 695)', () {
    final typeParamsParser = grammar.buildFrom(grammar.typeParams()).end();
    test('type parameters list', () {
      expect(typeParamsParser, isSuccess('[T]'));
      expect(typeParamsParser, isSuccess('[T: int]'));
      expect(typeParamsParser, isSuccess('[T = int]'));
      expect(typeParamsParser, isSuccess('[*Ts]'));
      expect(typeParamsParser, isSuccess('[**P]'));
      expect(typeParamsParser, isSuccess('[T, *Args, **Kwargs]'));
    });
  });
}

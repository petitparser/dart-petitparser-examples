import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final decl = grammar.buildFrom(grammar.declaration()).end();

  group('function definitions', () {
    test('simple function', () {
      check(decl).isSuccess('def foo():\n  pass\n');
      check(decl).isSuccess('def foo(x):\n  return x\n');
      check(decl).isSuccess('def foo(x, y=1):\n  return x + y\n');
    });

    test('return type annotation', () {
      check(decl).isSuccess('def foo() -> int:\n  return 42\n');
      check(decl).isSuccess('def foo(x: str) -> str:\n  return x\n');
    });

    test('complex parameter combinations (PEP 570 / PEP 3102)', () {
      check(
        decl,
      ).isSuccess('def f(pos1, pos2, /, pos_or_kwd, *, kwd1, kwd2):\n  pass\n');
      check(decl).isSuccess('def f(*args, **kwargs):\n  pass\n');
      check(decl).isSuccess('def f(a, b=1, *args, c=2, **kwargs):\n  pass\n');
      check(decl).isSuccess('def f(a: int = 0, /) -> None:\n  pass\n');
    });

    test('async functions', () {
      check(decl).isSuccess('async def fetch():\n  pass\n');
      check(decl)
          .isSuccess('async def fetch(url: str) -> bytes:\n  return b""\n');
    });

    test('generic functions (PEP 695)', () {
      check(decl).isSuccess('def identity[T](x: T) -> T:\n  return x\n');
      check(decl).isSuccess('def process[T: str, *Ts, **P](x: T):\n  pass\n');
    });

    test('decorated functions', () {
      check(decl).isSuccess('@staticmethod\ndef foo():\n  pass\n');
      check(decl).isSuccess('@dec1\n@dec2(opt=True)\ndef foo():\n  pass\n');
    });

    test('decorated async functions', () {
      check(decl).isSuccess(
        '@staticmethod\nasync def foo():\n  pass\n',
        value: (Subject it) {
          final fn = it.isA<AsyncFunctionDefNode>();
          fn.has((fn) => fn.name, 'name').equals('foo');
          fn.has((fn) => fn.decoratorList, 'decoratorList').length.equals(1);
        },
      );
      check(decl).isSuccess(
        '@dec1\n@dec2(opt=True)\nasync def foo(x: int) -> str:\n  return "x"\n',
        value: (Subject it) {
          final fn = it.isA<AsyncFunctionDefNode>();
          fn.has((fn) => fn.decoratorList, 'decoratorList').length.equals(2);
          fn.has((fn) => fn.returns, 'returns').isA<NameNode>();
        },
      );
    });
  });

  group('class definitions', () {
    test('simple class', () {
      check(decl).isSuccess('class Point:\n  pass\n');
      check(decl).isSuccess('class Point():\n  pass\n');
    });

    test('inheritance and metaclass', () {
      check(decl).isSuccess('class Child(Base):\n  pass\n');
      check(decl)
          .isSuccess('class Child(Base1, Base2, metaclass=Meta):\n  pass\n');
    });

    test('generic classes (PEP 695)', () {
      check(decl).isSuccess('class Stack[T]:\n  pass\n');
      check(decl).isSuccess('class Mapping[Key, Value]:\n  pass\n');
    });

    test('decorated classes', () {
      check(decl).isSuccess('@dataclass\nclass Point:\n  x: int\n');
      check(decl).isSuccess('@decorator(param="value")\nclass Foo:\n  pass\n');
    });
  });

  group('type parameters (PEP 695)', () {
    final typeParamsParser = grammar.buildFrom(grammar.typeParams()).end();
    test('type parameters list', () {
      check(typeParamsParser).isSuccess('[T]');
      check(typeParamsParser).isSuccess('[T: int]');
      check(typeParamsParser).isSuccess('[T = int]');
      check(typeParamsParser).isSuccess('[*Ts]');
      check(typeParamsParser).isSuccess('[**P]');
      check(typeParamsParser).isSuccess('[T, *Args, **Kwargs]');
    });
  });
}

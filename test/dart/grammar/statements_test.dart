import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final stmt = grammar.buildFrom(grammar.statement()).end();

  group('blocks and empty statements', () {
    test('empty block and empty statement', () {
      check(stmt).isSuccess(';');
      check(stmt).isSuccess('{}');
      check(stmt).isSuccess('{ ; ; }');
    });

    test('block with statements', () {
      check(stmt).isSuccess('{ int a = 1; int b = 2; print(a + b); }');
    });
  });

  group('variable declaration statements', () {
    test('simple variables', () {
      check(stmt).isSuccess('var a = 1;');
      check(stmt).isSuccess('final a = 1;');
      check(stmt).isSuccess('const a = 1;');
      check(stmt).isSuccess('int a = 1;');
      check(stmt).isSuccess('int a;');
      check(stmt).isSuccess('int a = 1, b = 2, c;');
      check(stmt).isSuccess('late int a;');
      check(stmt).isSuccess('late final int a;');
      check(stmt).isSuccess('var f = () => 42;');
      check(stmt).isSuccess('final int Function(int) addOne = (x) => x + 1;');
      check(stmt)
          .isSuccess('String Function(String) fn = (s) => s.toUpperCase();');
    });

    test('pattern variable declarations', () {
      check(stmt).isSuccess('var (a, b) = pair;');
      check(stmt).isSuccess('final [x, y] = list;');
      check(stmt).isSuccess('final {"a": val} = map;');
      check(stmt).isSuccess('var Point(:x, :y) = point;');
    });
  });

  group('if statements', () {
    test('simple if and if-else', () {
      check(stmt).isSuccess('if (flag) doSomething();');
      check(stmt).isSuccess('if (flag) { doSomething(); }');
      check(stmt).isSuccess('if (flag) a(); else b();');
      check(stmt).isSuccess('if (a) 1; else if (b) 2; else 3;');
    });

    test('if-case pattern matching', () {
      check(stmt).isSuccess('if (x case int y) print(y);');
      check(stmt).isSuccess('if (x case int y when y > 0) print(y);');
      check(stmt).isSuccess(
        'if (pair case (var a, var b)) print(a + b); else print("no");',
      );
    });
  });

  group('switch statements', () {
    test('traditional and pattern cases', () {
      check(stmt).isSuccess('switch (x) {}');
      check(stmt).isSuccess('switch (x) { case 1: break; }');
      check(stmt)
          .isSuccess('switch (x) { case 1: print(1); break; default: break; }');
      check(stmt)
          .isSuccess('switch (x) { case int y when y > 0: print(y); break; }');
      check(stmt)
          .isSuccess('switch (x) { case Color.red when active: break; }');
      check(stmt).isSuccess('switch (x) { label: case 1: break; }');
    });
  });

  group('loops', () {
    test('while and do-while', () {
      check(stmt).isSuccess('while (true) ;');
      check(stmt).isSuccess('while (cond) { step(); }');
      check(stmt).isSuccess('do ; while (cond);');
      check(stmt).isSuccess('do { step(); } while (cond);');
    });

    test('classic for loops', () {
      check(stmt).isSuccess('for (;;) ;');
      check(stmt).isSuccess('for (int i = 0; i < 10; i++) print(i);');
      check(stmt).isSuccess('for (var i = 0, j = 10; i < j; i++, j--) {}');
      check(stmt).isSuccess(
        'for (var node = event.target as Node?; node != null; node = null) {}',
      );
    });

    test('for-in loops', () {
      check(stmt).isSuccess('for (var x in items) print(x);');
      check(stmt).isSuccess('for (final String s in strings) print(s);');
      check(stmt).isSuccess('await for (var event in stream) print(event);');
    });

    test('pattern for-in loops', () {
      check(stmt).isSuccess('for (final (a, b) in pairs) print(a);');
      check(stmt)
          .isSuccess('for (var [first, ...rest] in lists) print(first);');
    });
  });

  group('try-catch-finally', () {
    test('try catch forms', () {
      check(stmt).isSuccess('try {} catch (e) {}');
      check(stmt).isSuccess('try {} catch (e, stack) {}');
      check(stmt).isSuccess('try {} on Exception {}');
      check(stmt).isSuccess('try {} on FormatException catch (e) {}');
      check(stmt).isSuccess('try {} finally {}');
      check(stmt).isSuccess('try {} catch (e) {} finally {}');
      check(stmt).isSuccess('try {} on Exception catch (e) {} finally {}');
    });
  });

  group('control flow jumps', () {
    test('return, break, continue, rethrow', () {
      check(stmt).isSuccess('return;');
      check(stmt).isSuccess('return 42;');
      check(stmt).isSuccess('break;');
      check(stmt).isSuccess('break myLoop;');
      check(stmt).isSuccess('continue;');
      check(stmt).isSuccess('continue myLoop;');
      check(stmt).isSuccess('rethrow;');
    });

    test('yield and yield*', () {
      check(stmt).isSuccess('yield 1;');
      check(stmt).isSuccess('yield* stream;');
    });

    test('assert statement', () {
      check(stmt).isSuccess('assert(cond);');
      check(stmt).isSuccess('assert(cond, "message");');
      check(stmt).isSuccess('assert(cond, () => "computed message");');
    });
  });

  group('local functions', () {
    test('local function declarations', () {
      check(stmt).isSuccess('void foo() {}');
      check(stmt).isSuccess('int add(int a, int b) => a + b;');
      check(stmt).isSuccess('Iterable<int> count() sync* { yield 1; }');
      check(stmt).isSuccess('Future<void> run() async { await null; }');
      check(stmt).isSuccess('Stream<int> events() async* { yield 1; }');
      check(stmt).isSuccess('T identity<T>(T val) => val;');
      check(stmt).isSuccess('bar() { return 42; }');
      check(stmt).isSuccess('int get answer => 42;');
      check(stmt).isSuccess('set value(int v) {}');
      check(
        stmt,
      ).isSuccess('void greet(String name, [int times = 1]) { print(name); }');
      check(
        stmt,
      ).isSuccess('void log({required String msg, bool verbose = false}) {}');
    });

    test('nested local functions in blocks', () {
      check(stmt).isSuccess(
        '{\n  int outer() {\n    int inner() => 1;\n    return inner();\n  }\n}',
      );
    });
  });
}

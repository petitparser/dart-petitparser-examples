import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final stmt = grammar.buildFrom(grammar.statement()).end();

  group('blocks and empty statements', () {
    test('empty block and empty statement', () {
      expect(stmt, isSuccess(';'));
      expect(stmt, isSuccess('{}'));
      expect(stmt, isSuccess('{ ; ; }'));
    });

    test('block with statements', () {
      expect(stmt, isSuccess('{ int a = 1; int b = 2; print(a + b); }'));
    });
  });

  group('variable declaration statements', () {
    test('simple variables', () {
      expect(stmt, isSuccess('var a = 1;'));
      expect(stmt, isSuccess('final a = 1;'));
      expect(stmt, isSuccess('const a = 1;'));
      expect(stmt, isSuccess('int a = 1;'));
      expect(stmt, isSuccess('int a;'));
      expect(stmt, isSuccess('int a = 1, b = 2, c;'));
      expect(stmt, isSuccess('late int a;'));
      expect(stmt, isSuccess('late final int a;'));
      expect(stmt, isSuccess('var f = () => 42;'));
      expect(stmt, isSuccess('final int Function(int) addOne = (x) => x + 1;'));
      expect(
        stmt,
        isSuccess('String Function(String) fn = (s) => s.toUpperCase();'),
      );
    });

    test('pattern variable declarations', () {
      expect(stmt, isSuccess('var (a, b) = pair;'));
      expect(stmt, isSuccess('final [x, y] = list;'));
      expect(stmt, isSuccess('final {"a": val} = map;'));
      expect(stmt, isSuccess('var Point(:x, :y) = point;'));
    });
  });

  group('if statements', () {
    test('simple if and if-else', () {
      expect(stmt, isSuccess('if (flag) doSomething();'));
      expect(stmt, isSuccess('if (flag) { doSomething(); }'));
      expect(stmt, isSuccess('if (flag) a(); else b();'));
      expect(stmt, isSuccess('if (a) 1; else if (b) 2; else 3;'));
    });

    test('if-case pattern matching', () {
      expect(stmt, isSuccess('if (x case int y) print(y);'));
      expect(stmt, isSuccess('if (x case int y when y > 0) print(y);'));
      expect(
        stmt,
        isSuccess(
          'if (pair case (var a, var b)) print(a + b); else print("no");',
        ),
      );
    });
  });

  group('switch statements', () {
    test('traditional and pattern cases', () {
      expect(stmt, isSuccess('switch (x) {}'));
      expect(stmt, isSuccess('switch (x) { case 1: break; }'));
      expect(
        stmt,
        isSuccess('switch (x) { case 1: print(1); break; default: break; }'),
      );
      expect(
        stmt,
        isSuccess('switch (x) { case int y when y > 0: print(y); break; }'),
      );
      expect(
        stmt,
        isSuccess('switch (x) { case Color.red when active: break; }'),
      );
      expect(stmt, isSuccess('switch (x) { label: case 1: break; }'));
    });
  });

  group('loops', () {
    test('while and do-while', () {
      expect(stmt, isSuccess('while (true) ;'));
      expect(stmt, isSuccess('while (cond) { step(); }'));
      expect(stmt, isSuccess('do ; while (cond);'));
      expect(stmt, isSuccess('do { step(); } while (cond);'));
    });

    test('classic for loops', () {
      expect(stmt, isSuccess('for (;;) ;'));
      expect(stmt, isSuccess('for (int i = 0; i < 10; i++) print(i);'));
      expect(stmt, isSuccess('for (var i = 0, j = 10; i < j; i++, j--) {}'));
      expect(
        stmt,
        isSuccess(
          'for (var node = event.target as Node?; node != null; node = null) {}',
        ),
      );
    });

    test('for-in loops', () {
      expect(stmt, isSuccess('for (var x in items) print(x);'));
      expect(stmt, isSuccess('for (final String s in strings) print(s);'));
      expect(stmt, isSuccess('await for (var event in stream) print(event);'));
    });

    test('pattern for-in loops', () {
      expect(stmt, isSuccess('for (final (a, b) in pairs) print(a);'));
      expect(
        stmt,
        isSuccess('for (var [first, ...rest] in lists) print(first);'),
      );
    });
  });

  group('try-catch-finally', () {
    test('try catch forms', () {
      expect(stmt, isSuccess('try {} catch (e) {}'));
      expect(stmt, isSuccess('try {} catch (e, stack) {}'));
      expect(stmt, isSuccess('try {} on Exception {}'));
      expect(stmt, isSuccess('try {} on FormatException catch (e) {}'));
      expect(stmt, isSuccess('try {} finally {}'));
      expect(stmt, isSuccess('try {} catch (e) {} finally {}'));
      expect(stmt, isSuccess('try {} on Exception catch (e) {} finally {}'));
    });
  });

  group('control flow jumps', () {
    test('return, break, continue, rethrow', () {
      expect(stmt, isSuccess('return;'));
      expect(stmt, isSuccess('return 42;'));
      expect(stmt, isSuccess('break;'));
      expect(stmt, isSuccess('break myLoop;'));
      expect(stmt, isSuccess('continue;'));
      expect(stmt, isSuccess('continue myLoop;'));
      expect(stmt, isSuccess('rethrow;'));
    });

    test('yield and yield*', () {
      expect(stmt, isSuccess('yield 1;'));
      expect(stmt, isSuccess('yield* stream;'));
    });

    test('assert statement', () {
      expect(stmt, isSuccess('assert(cond);'));
      expect(stmt, isSuccess('assert(cond, "message");'));
      expect(stmt, isSuccess('assert(cond, () => "computed message");'));
    });
  });

  group('local functions', () {
    test('local function declarations', () {
      expect(stmt, isSuccess('void foo() {}'));
      expect(stmt, isSuccess('int add(int a, int b) => a + b;'));
      expect(stmt, isSuccess('Iterable<int> count() sync* { yield 1; }'));
      expect(stmt, isSuccess('Future<void> run() async { await null; }'));
      expect(stmt, isSuccess('Stream<int> events() async* { yield 1; }'));
      expect(stmt, isSuccess('T identity<T>(T val) => val;'));
      expect(stmt, isSuccess('bar() { return 42; }'));
      expect(stmt, isSuccess('int get answer => 42;'));
      expect(stmt, isSuccess('set value(int v) {}'));
      expect(
        stmt,
        isSuccess('void greet(String name, [int times = 1]) { print(name); }'),
      );
      expect(
        stmt,
        isSuccess('void log({required String msg, bool verbose = false}) {}'),
      );
    });

    test('nested local functions in blocks', () {
      expect(
        stmt,
        isSuccess(
          '{\n  int outer() {\n    int inner() => 1;\n    return inner();\n  }\n}',
        ),
      );
    });
  });
}

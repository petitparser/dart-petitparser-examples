import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();
  test('grammar linter', () {
    expect(linter(grammar.build()), isEmpty);
  });
  group('directives', () {
    final directives = grammar.buildFrom(grammar.start()).end();
    test('hashbang', () {
      expect(directives, isSuccess('#!/bin/dart\n'));
    });
    test('library', () {
      expect(directives, isSuccess('library a;'));
      expect(directives, isSuccess('library a.b;'));
      expect(directives, isSuccess('library a.b.c_d;'));
    });
    test('part of', () {
      expect(directives, isSuccess('part of a;'));
      expect(directives, isSuccess('part of a.b;'));
      expect(directives, isSuccess('part of a.b.c_d;'));
    });
    test('part', () {
      expect(directives, isSuccess('part "abc";'));
    });
    test('import', () {
      expect(directives, isSuccess('import "abc";'));
      expect(directives, isSuccess('import "abc" deferred;'));
      expect(directives, isSuccess('import "abc" as a;'));
      expect(directives, isSuccess('import "abc" deferred as a;'));
      expect(directives, isSuccess('import "abc" show a;'));
      expect(directives, isSuccess('import "abc" deferred show a, b;'));
      expect(directives, isSuccess('import "abc" hide a;'));
      expect(directives, isSuccess('import "abc" deferred hide a, b;'));
    });
    test('export', () {
      expect(directives, isSuccess('export "abc";'));
      expect(directives, isSuccess('export "abc" show a;'));
      expect(directives, isSuccess('export "abc" show a, b;'));
      expect(directives, isSuccess('export "abc" hide a;'));
      expect(directives, isSuccess('export "abc" hide a, b;'));
    });
    test('full', () {
      expect(directives, isSuccess('library test;'));
      expect(directives, isSuccess('library test; void main() { }'));
      expect(
        directives,
        isSuccess('library test; void main() { print(2 + 3); }'),
      );
    });
  });
  group('expression', () {
    final expression = grammar.buildFrom(grammar.expression()).end();
    test('literal numbers', () {
      expect(expression, isSuccess('1'));
      expect(expression, isSuccess('1.2'));
      expect(expression, isSuccess('1.2e3'));
      expect(expression, isSuccess('1.2e-3'));
      expect(expression, isSuccess('-1.2e3'));
      expect(expression, isSuccess('-1.2e-3'));
      expect(expression, isSuccess('-1.2E-3'));
    });
    test('literal objects', () {
      expect(expression, isSuccess('true'));
      expect(expression, isSuccess('false'));
      expect(expression, isSuccess('null'));
    });
    test('literal array', () {
      expect(expression, isSuccess('[]'));
      expect(expression, isSuccess('[a]'));
      expect(expression, isSuccess('[a, b]'));
      expect(expression, isSuccess('[a, b, c]'));
    });
    test('literal map', () {
      expect(expression, isSuccess('{}'));
      expect(expression, isSuccess('{"a": b}'));
      expect(expression, isSuccess('{"a": b, "c": d}'));
      expect(expression, isSuccess('{"a": b, "c": d, "e": f}'));
    });
    test('literal (nested)', () {
      expect(expression, isSuccess('[1, true, [1], {"a": b}]'));
      expect(
        expression,
        isSuccess('{"a": 1, "b": true, "c": [1], "d": {"a": b}}'),
      );
    });
    test('conditional', () {
      expect(expression, isSuccess('a ? b : c'));
      expect(expression, isSuccess('a ? b ? c : d : c'));
    });
    test('relational', () {
      expect(expression, isSuccess('a is b'));
      expect(expression, isSuccess('a is !b'));
    });
    test('unary increment/decrement', () {
      expect(expression, isSuccess('++a'));
      expect(expression, isSuccess('--a'));
      expect(expression, isSuccess('a++'));
      expect(expression, isSuccess('a--'));
    });
    test('unary operators', () {
      expect(expression, isSuccess('+a'));
      expect(expression, isSuccess('-a'));
      expect(expression, isSuccess('!a'));
      expect(expression, isSuccess('~a'));
    });
    test('binary arithmetic operators', () {
      expect(expression, isSuccess('a + b'));
      expect(expression, isSuccess('a - b'));
      expect(expression, isSuccess('a * b'));
      expect(expression, isSuccess('a / b'));
      expect(expression, isSuccess('a ~/ b'));
      expect(expression, isSuccess('a % b'));
    });
    test('binary logical operators', () {
      expect(expression, isSuccess('a & b'));
      expect(expression, isSuccess('a | b'));
      expect(expression, isSuccess('a ^ b'));
      expect(expression, isSuccess('a && b'));
      expect(expression, isSuccess('a || b'));
    });
    test('binary conditional operators', () {
      expect(expression, isSuccess('a > b'));
      expect(expression, isSuccess('a >= b'));
      expect(expression, isSuccess('a < b'));
      expect(expression, isSuccess('a <= b'));
      expect(expression, isSuccess('a == b'));
      expect(expression, isSuccess('a != b'));
      expect(expression, isSuccess('a === b'));
      expect(expression, isSuccess('a !== b'));
    });
    test('binary shift operators', () {
      expect(expression, isSuccess('a << b'));
      expect(expression, isSuccess('a >>> b'));
      expect(expression, isSuccess('a >> b'));
    });
    test('parenthesis', () {
      expect(expression, isSuccess('(a + b)'));
      expect(expression, isSuccess('a * (b + c)'));
      expect(expression, isSuccess('(a * b) + c'));
    });
    test('access', () {
      expect(expression, isSuccess('a.b'));
      expect(expression, isSuccess('a.b.c'));
      expect(expression, isSuccess('a?.b'));
      expect(expression, isSuccess('a.b?'));
      expect(expression, isSuccess('a.b!'));
      expect(expression, isFailure('?.a.b'));
      expect(expression, isFailure('?a.b'));
      expect(expression, isFailure('a?b'));
      expect(expression, isFailure('a!b'));
      expect(expression, isFailure('a?.?b'));
    });

    test('invoke', () {
      expect(expression, isSuccess('a()'));
      expect(expression, isSuccess('a(b)'));
      expect(expression, isSuccess('a(b, c)'));
      expect(expression, isSuccess('a(b: c)'));
      expect(expression, isSuccess('a(b: c!.d)'));
      expect(expression, isSuccess('a(b: c?.d)'));
      expect(expression, isSuccess('a(b: c, d: e)'));
      expect(expression, isSuccess('a(b: c, d: e,)'));
      expect(expression, isSuccess('b()!'));
      expect(expression, isSuccess('a.b()?'));
      expect(expression, isSuccess('a?.b()'));
      expect(expression, isFailure('a?()'));
    });
    test('invoke (double)', () {
      expect(expression, isSuccess('a()()'));
      expect(expression, isSuccess('a(b)(b)'));
      expect(expression, isSuccess('a(b, c)(b, c)'));
      expect(expression, isSuccess('a(b: c)(b: c)'));
      expect(expression, isSuccess('a(b: c, d: e)(b: c, d: e)'));
      expect(expression, isSuccess('a(b: c, d: e,)(b: c, d: e,)'));
    });
    test('constructor', () {
      expect(expression, isSuccess('new a()'));
      expect(expression, isSuccess('const a()'));
      expect(expression, isSuccess('new a<b>()'));
      expect(expression, isSuccess('const a<b>()'));
      expect(expression, isSuccess('new a.b()'));
      expect(expression, isSuccess('const a.b()'));
    });
    test('function (expression)', () {
      expect(expression, isSuccess('() => a'));
      expect(expression, isSuccess('a() => b'));
      expect(expression, isSuccess('a () => b'));
      expect(expression, isSuccess('a b() => c'));
      expect(expression, isSuccess('a (b) => c'));
      expect(expression, isSuccess('a b(c) => d'));
    });
    test('function (block)', () {
      expect(expression, isSuccess('() {}'));
      expect(expression, isSuccess('a() {}'));
      expect(expression, isSuccess('a () {}'));
      expect(expression, isSuccess('a b() {}'));
      expect(expression, isSuccess('a (b) {}'));
      expect(expression, isSuccess('a b(c) {}'));
    });
    test('assignment', () {
      expect(expression, isSuccess('a = b'));
      expect(expression, isSuccess('a += b'));
      expect(expression, isSuccess('a -= b'));
      expect(expression, isSuccess('a *= b'));
      expect(expression, isSuccess('a /= b'));
      expect(expression, isSuccess('a %= b'));
      expect(expression, isSuccess('a ~/= b'));
      expect(expression, isSuccess('a <<= b'));
      expect(expression, isSuccess('a >>>= b'));
      expect(expression, isSuccess('a >>= b'));
      expect(expression, isSuccess('a &= b'));
      expect(expression, isSuccess('a ^= b'));
      expect(expression, isSuccess('a |= b'));
    });
  });
  group('statement', () {
    final statement = grammar.buildFrom(grammar.statement()).end();
    test('label', () {
      expect(statement, isSuccess('a: {}'));
      expect(statement, isSuccess('a: b: {}'));
      expect(statement, isSuccess('a: b: c: {}'));
    });
    test('block', () {
      expect(statement, isSuccess('{}'));
      expect(statement, isSuccess('{{}}'));
    });
    test('declaration', () {
      expect(statement, isSuccess('var a;'));
      expect(statement, isSuccess('final a;'));
    });
    test('declaration (initialized)', () {
      expect(statement, isSuccess('var a = b;'));
      expect(statement, isSuccess('final a = b;'));
    });
    test('declaration (typed)', () {
      expect(statement, isSuccess('a b;'));
      expect(statement, isSuccess('final a b;'));
    });
    test('declaration (typed, initialized)', () {
      expect(statement, isSuccess('a b = c;'));
      expect(statement, isSuccess('final a b = c;'));
    });
    test('while', () {
      expect(statement, isSuccess('while (a) {}'));
    });
    test('do', () {
      expect(statement, isSuccess('do {} while (b);'));
    });
    test('for', () {
      expect(statement, isSuccess('for (;;) {}'));
      expect(statement, isSuccess('for (var a = b; c; d++) {}'));
      expect(statement, isSuccess('for (var a = b, c = d; e; f++) {}'));
      expect(statement, isSuccess('for (a in b) {}'));
    });
    test('if', () {
      expect(statement, isSuccess('if (a) {}'));
      expect(statement, isSuccess('if (a) {} else {}'));
      expect(statement, isSuccess('if (a) {} else if (b) {}'));
      expect(statement, isSuccess('if (a) {} else if (b) {} else {}'));
    });
    test('switch', () {
      expect(statement, isSuccess('switch (a) {}'));
      expect(statement, isSuccess('switch (a) { case b: {} }'));
      expect(statement, isSuccess('switch (a) { case b: {} case d: {}}'));
      expect(statement, isSuccess('switch (a) { case b: {} default: {}}'));
    });
    test('try', () {
      expect(statement, isSuccess('try {} finally {}'));
      expect(statement, isSuccess('try {} catch (a b) {}'));
      expect(statement, isSuccess('try {} catch (a b, c d) {}'));
      expect(statement, isSuccess('try {} catch (a b) {} finally {}'));
      expect(statement, isSuccess('try {} catch (a b, c d) {} finally {}'));
      expect(statement, isSuccess('try {} catch (a b) {} catch (c d) {}'));
      expect(
        statement,
        isSuccess('try {} catch (a b) {} catch (c d) {} finally {}'),
      );
    });
    test('break', () {
      expect(statement, isSuccess('break;'));
      expect(statement, isSuccess('break a;'));
    });
    test('continue', () {
      expect(statement, isSuccess('continue;'));
      expect(statement, isSuccess('continue a;'));
    });
    test('return', () {
      expect(statement, isSuccess('return;'));
      expect(statement, isSuccess('return b;'));
    });
    test('throw', () {
      expect(statement, isSuccess('throw;'));
      expect(statement, isSuccess('throw b;'));
    });
    test('expression', () {
      expect(statement, isSuccess('a;'));
      expect(statement, isSuccess('a + b;'));
    });
    test('assert', () {
      expect(statement, isSuccess('assert(a);'));
    });
    test('invocation', () {
      expect(statement, isSuccess('a();'));
      expect(statement, isSuccess('a(b);'));
      expect(statement, isSuccess('a(b, c);'));
      expect(statement, isSuccess('a(b, c, d);'));
    });
    test('invocation (named)', () {
      expect(statement, isSuccess('a(b: c);'));
      expect(statement, isSuccess('a(b: c, d: e);'));
      expect(statement, isSuccess('a(b: c, d: e, f: g);'));
    });
  });
  group('member', () {
    final member = grammar.buildFrom(grammar.classMemberDefinition()).end();
    test('function', () {
      expect(member, isSuccess('a() {}'));
      expect(member, isSuccess('a b() {}'));
    });
    test('function (abstract)', () {
      expect(member, isSuccess('abstract a();'));
      expect(member, isSuccess('abstract a b();'));
    });
    test('function (static)', () {
      expect(member, isSuccess('static a() {}'));
      expect(member, isSuccess('static a b() {}'));
    });
    test('function (expression)', () {
      expect(member, isSuccess('a() => b;'));
      expect(member, isSuccess('a b() => c;'));
    });
    test('function arguments (plain)', () {
      expect(member, isSuccess('a() {}'));
      expect(member, isSuccess('a(b) {}'));
      expect(member, isSuccess('a(b, c) {}'));
      expect(member, isSuccess('a(b, c, d) {}'));
    });
    test('function arguments (optional)', () {
      expect(member, isSuccess('a([b]) {}'));
      expect(member, isSuccess('a([b, c]) {}'));
      expect(member, isSuccess('a(b, [c, d]) {}'));
      expect(member, isSuccess('a(b, c, [d, e]) {}'));
    });
    test('function arguments (optional, defaults)', () {
      expect(member, isSuccess('a([b = c]) {}'));
      expect(member, isSuccess('a([b = c, d = e]) {}'));
      expect(member, isSuccess('a(b, [c = d, e = f]) {}'));
      expect(member, isSuccess('a(b, c, [d = e, f = g]) {}'));
    });
    test('function arguments (named)', () {
      expect(member, isSuccess('a({b}) {}'));
      expect(member, isSuccess('a({b, c}) {}'));
      expect(member, isSuccess('a(b, {c, d}) {}'));
      expect(member, isSuccess('a(b, c, {d, e}) {}'));
    });
    test('function arguments (named, defaults)', () {
      expect(member, isSuccess('a({b: c}) {}'));
      expect(member, isSuccess('a({b: c, d: e}) {}'));
      expect(member, isSuccess('a(b, {c: d, e: f}) {}'));
      expect(member, isSuccess('a(b, c, {d: e, f: g}) {}'));
    });
    test('constructor', () {
      expect(member, isSuccess('A();'));
      expect(member, isSuccess('A() {}'));
      expect(member, isSuccess('A() : super();'));
      expect(member, isSuccess('A() : super() {}'));
      expect(member, isSuccess('A() : super(), a = b;'));
      expect(member, isSuccess('A() : super(), a = b {}'));
      expect(member, isSuccess('A() : super(), a = b, c = d;'));
      expect(member, isSuccess('A() : super(), a = b, c = d {}'));
    });
    test('constructor (field)', () {
      expect(member, isSuccess('A(this.a);'));
      expect(member, isSuccess('A(this.a) {}'));
      expect(member, isSuccess('A(this.a, this.b);'));
      expect(member, isSuccess('A(this.a, this.b) {}'));
    });
    test('constructor (const)', () {
      expect(member, isSuccess('const A();'));
      expect(member, isSuccess('const A._();'));
    });
    test('constructor (named)', () {
      expect(member, isSuccess('A._() {}'));
      expect(member, isSuccess('A._() : super();'));
      expect(member, isSuccess('A._() : super() {}'));
      expect(member, isSuccess('A._() : super(), a = b;'));
      expect(member, isSuccess('A._() : super(), a = b {}'));
      expect(member, isSuccess('A._() : super(), a = b, c = d;'));
      expect(member, isSuccess('A._() : super(), a = b, c = d {}'));
    });
    test('constructor (factory)', () {
      expect(member, isSuccess('factory A() {}'));
    });
    test('constructor (factory, named)', () {
      expect(member, isSuccess('factory A._() {}'));
    });
  });
  group('definition', () {
    final definition = grammar.buildFrom(grammar.topLevelDefinition()).end();
    test('class', () {
      expect(definition, isSuccess('class A {}'));
      expect(definition, isSuccess('class A extends B {}'));
      expect(definition, isSuccess('class A implements B {}'));
      expect(definition, isSuccess('class A implements B, C {}'));
      expect(definition, isSuccess('class A extends B implements C {}'));
      expect(definition, isSuccess('class A extends B implements C, D {}'));
    });
    test('class (typed)', () {
      expect(definition, isSuccess('class A<T> {}'));
      expect(definition, isSuccess('class A<T> extends B<T> {}'));
      expect(definition, isSuccess('class A<T> implements B<T> {}'));
      expect(definition, isSuccess('class A<T> implements B<T>, C<T> {}'));
      expect(
        definition,
        isSuccess('class A<T> extends B<T> implements C<T> {}'),
      );
      expect(
        definition,
        isSuccess('class A<T> extends B<T> implements C<T>, D<T> {}'),
      );
    });
    test('class (abstract)', () {
      expect(definition, isSuccess('abstract class A {}'));
      expect(definition, isSuccess('abstract class A extends B {}'));
      expect(definition, isSuccess('abstract class A implements B {}'));
      expect(definition, isSuccess('abstract class A implements B, C {}'));
      expect(
        definition,
        isSuccess('abstract class A extends B implements C {}'),
      );
      expect(
        definition,
        isSuccess('abstract class A extends B implements C, D {}'),
      );
    });
    test('typedef', () {
      expect(definition, isSuccess('typedef a b();'));
      expect(definition, isSuccess('typedef a b(c);'));
      expect(definition, isSuccess('typedef a b(c d);'));
    });
    test('typedef (typed)', () {
      expect(definition, isSuccess('typedef a b<T>();'));
      expect(definition, isSuccess('typedef a b<T>(c);'));
      expect(definition, isSuccess('typedef a b<T>(c d);'));
    });
    test('final', () {
      expect(definition, isSuccess('final a = 0;'));
      expect(definition, isSuccess('final a b = 0;'));
    });
    test('const', () {
      expect(definition, isSuccess('const a = 0;'));
      expect(definition, isSuccess('const a b = 0;'));
    });
  });
  group('whitespace', () {
    final whitespaces = grammar.buildFrom(grammar.hiddenWhitespace()).end();
    test('whitespace', () {
      expect(whitespaces, isSuccess(' '));
      expect(whitespaces, isSuccess('\t'));
      expect(whitespaces, isSuccess('\n'));
      expect(whitespaces, isSuccess('\r'));
      expect(whitespaces, isFailure('a'));
    });
    test('single-line comment', () {
      expect(whitespaces, isSuccess('//'));
      expect(whitespaces, isSuccess('// foo'));
      expect(whitespaces, isSuccess('//\n'));
      expect(whitespaces, isSuccess('// foo\n'));
    });
    test('single-line documentation', () {
      expect(whitespaces, isSuccess('///'));
      expect(whitespaces, isSuccess('/// foo'));
      expect(whitespaces, isSuccess('/// \n'));
      expect(whitespaces, isSuccess('/// foo\n'));
    });
    test('multi-line comment', () {
      expect(whitespaces, isSuccess('/**/'));
      expect(whitespaces, isSuccess('/* foo */'));
      expect(whitespaces, isSuccess('/* foo \n bar */'));
      expect(whitespaces, isSuccess('/* foo ** bar */'));
      expect(whitespaces, isSuccess('/* foo * / bar */'));
    });
    test('multi-line documentation', () {
      expect(whitespaces, isSuccess('/***/'));
      expect(whitespaces, isSuccess('/*******/'));
      expect(whitespaces, isSuccess('/** foo */'));
      expect(whitespaces, isSuccess('/**\n *\n *\n */'));
    });
    test('multi-line nested', () {
      expect(whitespaces, isSuccess('/* outer /* nested */ */'));
      expect(
        whitespaces,
        isSuccess('/* outer /* nested /* deeply nested */ */ */'),
      );
      expect(whitespaces, isFailure('/* outer /* not closed */'));
    });
    test('combined', () {
      expect(whitespaces, isSuccess('/**/'));
      expect(whitespaces, isSuccess(' /**/'));
      expect(whitespaces, isSuccess('/**/ '));
      expect(whitespaces, isSuccess(' /**/ '));
      expect(whitespaces, isSuccess('/**///'));
      expect(whitespaces, isSuccess('/**/ //'));
      expect(whitespaces, isSuccess(' /**/ //'));
    });
  });
  group('child parsers', () {
    final parser = grammar.buildFrom(grammar.stringLexicalToken()).end();
    test('singleLineString', () {
      expect(parser, isSuccess("'hi'"));
      expect(parser, isSuccess('"hi"'));
      expect(parser, isFailure('no quotes'));
      expect(parser, isFailure('"missing quote'));
      expect(parser, isFailure("'missing quote"));
    });
  });
  group('official', () {
    test('identifier', () {
      final parser = grammar.buildFrom(grammar.identifier()).end();
      expect(parser, isSuccess('foo'));
      expect(parser, isSuccess('bar9'));
      expect(parser, isSuccess('dollar\$'));
      expect(parser, isSuccess('_foo'));
      expect(parser, isSuccess('_bar9'));
      expect(parser, isSuccess('_dollar\$'));
      expect(parser, isSuccess('\$'));
      expect(parser, isSuccess(' leadingSpace'));
      expect(parser, isFailure('9'));
      expect(parser, isFailure('3foo'));
      expect(parser, isFailure(''));
    });
    test('numeric literal', () {
      final parser = grammar.buildFrom(grammar.literal()).end();
      expect(parser, isSuccess('0'));
      expect(parser, isSuccess('1984'));
      expect(parser, isSuccess(' 1984'));
      expect(parser, isSuccess('0xCAFE'));
      expect(parser, isSuccess('0XCAFE'));
      expect(parser, isSuccess('0xcafe'));
      expect(parser, isSuccess('0Xcafe'));
      expect(parser, isSuccess('0xCaFe'));
      expect(parser, isSuccess('0XCaFe'));
      expect(parser, isSuccess('3e4'));
      expect(parser, isSuccess('3e-4'));
      expect(parser, isSuccess('3E4'));
      expect(parser, isSuccess('3E-4'));
      expect(parser, isSuccess('3.14E4'));
      expect(parser, isSuccess('3.14E-4'));
      expect(parser, isSuccess('3.14'));
      expect(parser, isFailure('3e--4'));
      expect(parser, isFailure('5.'));
      expect(parser, isFailure('CAFE'));
      expect(parser, isFailure('0xGHIJ'));
      expect(parser, isFailure('-'));
      expect(parser, isFailure(''));
    });
    test('boolean literal', () {
      final parser = grammar.buildFrom(grammar.literal()).end();
      expect(parser, isSuccess('true'));
      expect(parser, isSuccess('false'));
      expect(parser, isSuccess(' true'));
      expect(parser, isSuccess(' false'));
    });
  });
}

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();

  group('directives', () {
    final directive = grammar.buildFrom(grammar.directive()).end();

    test('library', () {
      final lib = grammar.buildFrom(grammar.libraryDirective()).end();
      expect(lib, isSuccess('library;'));
      expect(lib, isSuccess('library my_lib;'));
      expect(lib, isSuccess('library my.sub.lib;'));
    });

    test('import', () {
      expect(directive, isSuccess("import 'dart:core';"));
      expect(directive, isSuccess("import 'package:foo/foo.dart' as foo;"));
      expect(directive, isSuccess("import 'foo.dart' deferred as foo;"));
      expect(directive, isSuccess("import 'foo.dart' show A, B;"));
      expect(directive, isSuccess("import 'foo.dart' hide C, D;"));
      expect(directive, isSuccess("import 'foo.dart' as f show A hide B;"));
      expect(
        directive,
        isSuccess("import 'foo.dart' if (dart.library.io) 'bar.dart';"),
      );
      expect(
        directive,
        isSuccess(
          "import 'foo.dart' if (dart.library.io == 'true') 'bar.dart';",
        ),
      );
      expect(
        directive,
        isSuccess(
          "import 'foo.dart' if (dart.library.io) 'bar.dart' if (dart.library.html) 'baz.dart' as f show A;",
        ),
      );
    });

    test('export', () {
      expect(directive, isSuccess("export 'src/foo.dart';"));
      expect(directive, isSuccess("export 'src/foo.dart' show A, B;"));
      expect(directive, isSuccess("export 'src/foo.dart' hide C;"));
      expect(
        directive,
        isSuccess("export 'src/foo.dart' if (dart.library.io) 'src/bar.dart';"),
      );
      expect(
        directive,
        isSuccess(
          "export 'src/foo.dart' if (dart.library.io == 'true') 'src/bar.dart' show A;",
        ),
      );
    });

    test('part and part of', () {
      expect(directive, isSuccess("part 'foo.dart';"));
      expect(directive, isSuccess("part of 'parent.dart';"));
      expect(directive, isSuccess("part of my_lib;"));
    });
  });

  group('type alias (typedef)', () {
    final typeAlias = grammar.buildFrom(grammar.typeAliasDeclaration()).end();

    test('typedefs', () {
      expect(typeAlias, isSuccess('typedef IntList = List<int>;'));
      expect(typeAlias, isSuccess('typedef Predicate<T> = bool Function(T);'));
      expect(typeAlias, isSuccess('typedef JSON = Map<String, dynamic>;'));
      expect(typeAlias, isSuccess('typedef void Callback(int x);'));
      expect(typeAlias, isSuccess('typedef T Transformation<S, T>(S input);'));
      expect(typeAlias, isSuccess('typedef Action();'));
      expect(
        typeAlias,
        isSuccess('typedef String Formatter(Object value, [String pattern]);'),
      );
      expect(typeAlias, isSuccess('typedef Handler({required String event});'));
    });
  });

  group('class declarations', () {
    final classDecl = grammar.buildFrom(grammar.classDeclaration()).end();

    test('simple class', () {
      expect(classDecl, isSuccess('class Point {}'));
      expect(classDecl, isSuccess('abstract class Shape {}'));
      expect(classDecl, isSuccess('base class BaseClass {}'));
      expect(classDecl, isSuccess('interface class InterfaceClass {}'));
      expect(classDecl, isSuccess('final class FinalClass {}'));
      expect(classDecl, isSuccess('sealed class SealedClass {}'));
      expect(classDecl, isSuccess('mixin class MixinClass {}'));
      expect(classDecl, isSuccess('abstract base class AbstractBase {}'));
    });

    test('class with type parameters and hierarchy', () {
      expect(classDecl, isSuccess('class Box<T> {}'));
      expect(classDecl, isSuccess('class Sub extends Super {}'));
      expect(classDecl, isSuccess('class Sub extends Super with M1, M2 {}'));
      expect(classDecl, isSuccess('class Sub with M1 implements I1, I2 {}'));
      expect(
        classDecl,
        isSuccess('class Sub extends Super with M implements I {}'),
      );
    });

    test('class with members', () {
      expect(
        classDecl,
        isSuccess('''class Point {
          final int x;
          final int y;
          Point(this.x, this.y);
          Point.origin() : x = 0, y = 0;
          int get dist => x * x + y * y;
          void move(int dx, int dy) {}
          Point operator +(Point other) => Point(x + other.x, y + other.y);
        }'''),
      );
    });
  });

  group('mixin declarations', () {
    final mixinDecl = grammar.buildFrom(grammar.mixinDeclaration()).end();

    test('mixins', () {
      expect(mixinDecl, isSuccess('mixin Musical {}'));
      expect(mixinDecl, isSuccess('base mixin Musical {}'));
      expect(
        mixinDecl,
        isSuccess('mixin Musical<T> on Performer implements Playable {}'),
      );
      expect(mixinDecl, isSuccess('mixin Musical { void play() {} }'));
    });
  });

  group('extension and extension type declarations', () {
    final extDecl = grammar.buildFrom(grammar.extensionDeclaration()).end();
    final extTypeDecl = grammar
        .buildFrom(grammar.extensionTypeDeclaration())
        .end();

    test('extensions', () {
      expect(extDecl, isSuccess('extension on String {}'));
      expect(extDecl, isSuccess('extension StringExt on String {}'));
      expect(
        extDecl,
        isSuccess('extension Ext<T> on List<T> { int get count => length; }'),
      );
    });

    test('extension types', () {
      expect(extTypeDecl, isSuccess('extension type Id(int i) {}'));
      expect(extTypeDecl, isSuccess('extension type const Id(int i) {}'));
      expect(
        extTypeDecl,
        isSuccess('extension type Id<T>(T value) implements Object {}'),
      );
      expect(
        extTypeDecl,
        isSuccess(
          'extension type PrivateToken._(JSObject _) implements JSObject {}',
        ),
      );
      expect(
        extTypeDecl,
        isSuccess('extension type PrivateToken.named(JSObject _) {}'),
      );
      expect(
        extTypeDecl,
        isSuccess('extension type PrivateToken.new(JSObject _) {}'),
      );
      expect(
        extTypeDecl,
        isSuccess('extension type PrivateToken<T>._(T val) {}'),
      );
      expect(extTypeDecl, isSuccess('extension type Id(int i);'));
      expect(extTypeDecl, isSuccess('extension type Id._(int i);'));
      expect(extTypeDecl, isSuccess('extension type const Id._(int i);'));
    });
  });

  group('enum declarations', () {
    final enumDecl = grammar.buildFrom(grammar.enumDeclaration()).end();

    test('simple enum', () {
      expect(enumDecl, isSuccess('enum Color { red, green, blue }'));
      expect(enumDecl, isSuccess('enum Color { red, green, blue, }'));
    });

    test('enhanced enum with members', () {
      expect(
        enumDecl,
        isSuccess('''enum Vehicle implements Comparable<Vehicle> {
          car(tires: 4),
          bicycle(tires: 2);

          const Vehicle({required this.tires});
          final int tires;
          @override
          int compareTo(Vehicle other) => tires - other.tires;
        }'''),
      );
    });
  });

  group('constructors and members', () {
    final ctorDecl = grammar.buildFrom(grammar.constructorDeclaration()).end();
    final funcDecl = grammar.buildFrom(grammar.functionDeclaration()).end();
    final fieldDecl = grammar.buildFrom(grammar.fieldDeclaration()).end();

    test('constructors', () {
      expect(ctorDecl, isSuccess('Point(this.x, this.y);'));
      expect(ctorDecl, isSuccess('const Point(this.x, this.y);'));
      expect(ctorDecl, isSuccess('Point.named(this.x);'));
      expect(ctorDecl, isSuccess('Point.origin() : x = 0, y = 0;'));
      expect(ctorDecl, isSuccess('Point.fromSuper() : super(0);'));
      expect(ctorDecl, isSuccess('Point.fromSuper(super.x, super.y);'));
      expect(ctorDecl, isSuccess('Point.redirect() : this(0, 0);'));
      expect(ctorDecl, isSuccess('factory Point.create() => Point(0, 0);'));
      expect(ctorDecl, isSuccess('factory Point.redirecting() = OtherPoint;'));
      expect(ctorDecl, isSuccess('Point.new(this.x, this.y);'));
      expect(ctorDecl, isSuccess('const new();'));
      expect(ctorDecl, isSuccess('new([super.owner]);'));
      expect(ctorDecl, isSuccess('new(this._name);'));
      expect(ctorDecl, isSuccess('new _internal(this._name);'));
    });

    test('functions and methods', () {
      expect(funcDecl, isSuccess('void main() {}'));
      expect(funcDecl, isSuccess('int add(int a, int b) => a + b;'));
      expect(funcDecl, isSuccess('Future<void> run() async {}'));
      expect(funcDecl, isSuccess('Stream<int> count() async* {}'));
      expect(funcDecl, isSuccess('Iterable<int> syncCount() sync* {}'));
      expect(funcDecl, isSuccess('static void helper() {}'));
      expect(funcDecl, isSuccess('external int get length;'));
      expect(funcDecl, isSuccess('int get width => 0;'));
      expect(funcDecl, isSuccess('set width(int w) {}'));
      expect(funcDecl, isSuccess('bool operator ==(Object other) => true;'));
    });

    test('fields', () {
      expect(fieldDecl, isSuccess('var x = 1;'));
      expect(fieldDecl, isSuccess('final int x = 1;'));
      expect(fieldDecl, isSuccess('static const double pi = 3.14;'));
      expect(fieldDecl, isSuccess('late final String name;'));
      expect(fieldDecl, isSuccess('covariant num x;'));
      expect(
        fieldDecl,
        isSuccess(
          'bool Function(Source) inferenceLoggingPredicate = (_) => false;',
        ),
      );
      expect(fieldDecl, isSuccess('var fn = () => 42;'));
    });
  });

  group('compilation units', () {
    final unit = grammar.buildFrom(grammar.compilationUnit()).end();

    test('empty compilation unit', () {
      expect(unit, isSuccess(''));
      expect(unit, isSuccess('// just a comment\n'));
    });

    test('script with hashbang', () {
      expect(unit, isSuccess('#!/usr/bin/env dart\nvoid main() {}'));
    });

    test('library with imports and declarations', () {
      expect(
        unit,
        isSuccess('''
library my_lib;

import 'dart:math' as math;
export 'src/api.dart';

part 'src/part.dart';

const double pi = 3.14159;

void main() {
  print(pi);
}
'''),
      );
    });

    test('library with main method ', () {
      expect(unit, isSuccess('void main() {}'));
      expect(unit, isSuccess('void main(List<String> args) {}'));
    });

    test('library with main method missing return type', () {
      expect(unit, isSuccess('main() {}'));
      expect(unit, isSuccess('main(List<String> args) {}'));
    });

    test('library with mixin', () {
      expect(unit, isSuccess('mixin Mixin {}'));
      expect(unit, isSuccess('mixin Mixin implements Interface {}'));
      expect(unit, isSuccess('mixin Mixin on Base {}'));
      expect(unit, isSuccess('mixin Mixin on Base implements Interface {}'));
    });

    test('library with top-level functions', () {
      expect(unit, isSuccess('Map<String, int> create() => {};'));
      expect(unit, isSuccess('Set<int> collect() { return {}; }'));
    });

    test('library with emtpy mixin', () {
      expect(unit, isSuccess('mixin Mixin;'));
      expect(unit, isSuccess('mixin Mixin implements Interface;'));
      expect(unit, isSuccess('mixin Mixin on Base;'));
    });

    test('library with class', () {
      expect(unit, isSuccess('class Clazz {}'));
      expect(unit, isSuccess('class Clazz extends Clazz {}'));
      expect(unit, isSuccess('class Clazz implements Clazz {}'));
      expect(unit, isSuccess('class Clazz with Clazz {}'));
    });

    test('library with special class', () {
      expect(unit, isSuccess('final class Clazz {}'));
      expect(unit, isSuccess('abstract class Clazz {}'));
      expect(unit, isSuccess('sealed class Clazz {}'));
      expect(unit, isSuccess('mixin class Clazz {}'));
      expect(unit, isSuccess('interface class Clazz {}'));
    });

    test('library with empty class', () {
      expect(unit, isSuccess('class Clazz;'));
      expect(unit, isSuccess('class Clazz extends Clazz;'));
      expect(unit, isSuccess('class Clazz implements Clazz;'));
      expect(unit, isSuccess('class Clazz with Clazz;'));
    });

    test('library with extension type', () {
      expect(unit, isSuccess('extension on Clazz {}'));
      expect(unit, isSuccess('extension Ext on Clazz {}'));
    });

    test('library with empty extension type', () {
      expect(unit, isSuccess('extension on Clazz;'));
      expect(unit, isSuccess('extension Ext on Clazz;'));
    });

    test('class with factory and new constructor', () {
      expect(
        unit,
        isSuccess('''
class Name {
  factory(String name) =>
      _interned.putIfAbsent(name, () => Name._internal(name));

  new _internal(this._name);

  static final Map<String, Name> _interned = {};

  final String _name;

  @override
  String toString() => _name;
}
'''),
      );
    });
  });
}

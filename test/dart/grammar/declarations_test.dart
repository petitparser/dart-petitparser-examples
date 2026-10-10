import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();

  group('directives', () {
    final directive = grammar.buildFrom(grammar.directive()).end();

    test('library', () {
      final lib = grammar.buildFrom(grammar.libraryDirective()).end();
      check(lib).isSuccess('library;');
      check(lib).isSuccess('library my_lib;');
      check(lib).isSuccess('library my.sub.lib;');
    });

    test('import', () {
      check(directive).isSuccess("import 'dart:core';");
      check(directive).isSuccess("import 'package:foo/foo.dart' as foo;");
      check(directive).isSuccess("import 'foo.dart' deferred as foo;");
      check(directive).isSuccess("import 'foo.dart' show A, B;");
      check(directive).isSuccess("import 'foo.dart' hide C, D;");
      check(directive).isSuccess("import 'foo.dart' as f show A hide B;");
      check(directive)
          .isSuccess("import 'foo.dart' if (dart.library.io) 'bar.dart';");
      check(directive).isSuccess(
        "import 'foo.dart' if (dart.library.io == 'true') 'bar.dart';",
      );
      check(directive).isSuccess(
        "import 'foo.dart' if (dart.library.io) 'bar.dart' if (dart.library.html) 'baz.dart' as f show A;",
      );
    });

    test('export', () {
      check(directive).isSuccess("export 'src/foo.dart';");
      check(directive).isSuccess("export 'src/foo.dart' show A, B;");
      check(directive).isSuccess("export 'src/foo.dart' hide C;");
      check(
        directive,
      ).isSuccess("export 'src/foo.dart' if (dart.library.io) 'src/bar.dart';");
      check(directive).isSuccess(
        "export 'src/foo.dart' if (dart.library.io == 'true') 'src/bar.dart' show A;",
      );
    });

    test('part and part of', () {
      check(directive).isSuccess("part 'foo.dart';");
      check(directive).isSuccess("part of 'parent.dart';");
      check(directive).isSuccess("part of my_lib;");
    });
  });

  group('type alias (typedef)', () {
    final typeAlias = grammar.buildFrom(grammar.typeAliasDeclaration()).end();

    test('typedefs', () {
      check(typeAlias).isSuccess('typedef IntList = List<int>;');
      check(typeAlias).isSuccess('typedef Predicate<T> = bool Function(T);');
      check(typeAlias).isSuccess('typedef JSON = Map<String, dynamic>;');
      check(typeAlias).isSuccess('typedef void Callback(int x);');
      check(typeAlias).isSuccess('typedef T Transformation<S, T>(S input);');
      check(typeAlias).isSuccess('typedef Action();');
      check(
        typeAlias,
      ).isSuccess('typedef String Formatter(Object value, [String pattern]);');
      check(typeAlias).isSuccess('typedef Handler({required String event});');
    });
  });

  group('class declarations', () {
    final classDecl = grammar.buildFrom(grammar.classDeclaration()).end();

    test('simple class', () {
      check(classDecl).isSuccess('class Point {}');
      check(classDecl).isSuccess('abstract class Shape {}');
      check(classDecl).isSuccess('base class BaseClass {}');
      check(classDecl).isSuccess('interface class InterfaceClass {}');
      check(classDecl).isSuccess('final class FinalClass {}');
      check(classDecl).isSuccess('sealed class SealedClass {}');
      check(classDecl).isSuccess('mixin class MixinClass {}');
      check(classDecl).isSuccess('abstract base class AbstractBase {}');
    });

    test('class with type parameters and hierarchy', () {
      check(classDecl).isSuccess('class Box<T> {}');
      check(classDecl).isSuccess('class Sub extends Super {}');
      check(classDecl).isSuccess('class Sub extends Super with M1, M2 {}');
      check(classDecl).isSuccess('class Sub with M1 implements I1, I2 {}');
      check(classDecl)
          .isSuccess('class Sub extends Super with M implements I {}');
    });

    test('class with members', () {
      check(classDecl).isSuccess('''class Point {
          final int x;
          final int y;
          Point(this.x, this.y);
          Point.origin() : x = 0, y = 0;
          int get dist => x * x + y * y;
          void move(int dx, int dy) {}
          Point operator +(Point other) => Point(x + other.x, y + other.y);
        }''');
    });
  });

  group('mixin declarations', () {
    final mixinDecl = grammar.buildFrom(grammar.mixinDeclaration()).end();

    test('mixins', () {
      check(mixinDecl).isSuccess('mixin Musical {}');
      check(mixinDecl).isSuccess('base mixin Musical {}');
      check(mixinDecl)
          .isSuccess('mixin Musical<T> on Performer implements Playable {}');
      check(mixinDecl).isSuccess('mixin Musical { void play() {} }');
    });
  });

  group('extension and extension type declarations', () {
    final extDecl = grammar.buildFrom(grammar.extensionDeclaration()).end();
    final extTypeDecl = grammar
        .buildFrom(grammar.extensionTypeDeclaration())
        .end();

    test('extensions', () {
      check(extDecl).isSuccess('extension on String {}');
      check(extDecl).isSuccess('extension StringExt on String {}');
      check(
        extDecl,
      ).isSuccess('extension Ext<T> on List<T> { int get count => length; }');
    });

    test('extension types', () {
      check(extTypeDecl).isSuccess('extension type Id(int i) {}');
      check(extTypeDecl).isSuccess('extension type const Id(int i) {}');
      check(extTypeDecl)
          .isSuccess('extension type Id<T>(T value) implements Object {}');
      check(extTypeDecl).isSuccess(
        'extension type PrivateToken._(JSObject _) implements JSObject {}',
      );
      check(extTypeDecl)
          .isSuccess('extension type PrivateToken.named(JSObject _) {}');
      check(extTypeDecl)
          .isSuccess('extension type PrivateToken.new(JSObject _) {}');
      check(extTypeDecl)
          .isSuccess('extension type PrivateToken<T>._(T val) {}');
      check(extTypeDecl).isSuccess('extension type Id(int i);');
      check(extTypeDecl).isSuccess('extension type Id._(int i);');
      check(extTypeDecl).isSuccess('extension type const Id._(int i);');
    });
  });

  group('enum declarations', () {
    final enumDecl = grammar.buildFrom(grammar.enumDeclaration()).end();

    test('simple enum', () {
      check(enumDecl).isSuccess('enum Color { red, green, blue }');
      check(enumDecl).isSuccess('enum Color { red, green, blue, }');
    });

    test('enhanced enum with members', () {
      check(enumDecl).isSuccess('''enum Vehicle implements Comparable<Vehicle> {
          car(tires: 4),
          bicycle(tires: 2);

          const Vehicle({required this.tires});
          final int tires;
          @override
          int compareTo(Vehicle other) => tires - other.tires;
        }''');
    });
  });

  group('constructors and members', () {
    final ctorDecl = grammar.buildFrom(grammar.constructorDeclaration()).end();
    final memberDecl = grammar.buildFrom(grammar.classMemberDefinition()).end();
    final fieldDecl = grammar.buildFrom(grammar.fieldDeclaration()).end();

    test('constructors', () {
      check(ctorDecl).isSuccess('Point(this.x, this.y);');
      check(ctorDecl).isSuccess('const Point(this.x, this.y);');
      check(ctorDecl).isSuccess('Point.named(this.x);');
      check(ctorDecl).isSuccess('Point.origin() : x = 0, y = 0;');
      check(ctorDecl).isSuccess('Point.fromSuper() : super(0);');
      check(ctorDecl).isSuccess('Point.fromSuper(super.x, super.y);');
      check(ctorDecl).isSuccess('Point.redirect() : this(0, 0);');
      check(ctorDecl).isSuccess('Point._() : assert(false, "msg");');
      check(ctorDecl).isSuccess('Point() : assert(1 == 1), x = 2;');
      check(ctorDecl).isSuccess('factory Point.create() => Point(0, 0);');
      check(ctorDecl).isSuccess('factory Point.redirecting() = OtherPoint;');
      check(ctorDecl)
          .isSuccess('factory Point() = LinkBuilderImplementation<T>;');
      check(ctorDecl).isSuccess('Point.new(this.x, this.y);');
      check(ctorDecl).isSuccess('const new();');
      check(ctorDecl).isSuccess('new([super.owner]);');
      check(ctorDecl).isSuccess('new(this._name);');
      check(ctorDecl).isSuccess('new _internal(this._name);');
    });

    test('functions and methods', () {
      check(memberDecl).isSuccess('void main() {}');
      check(memberDecl).isSuccess('int add(int a, int b) => a + b;');
      check(memberDecl).isSuccess('Future<void> run() async {}');
      check(memberDecl).isSuccess('Stream<int> count() async* {}');
      check(memberDecl).isSuccess('Iterable<int> syncCount() sync* {}');
      check(memberDecl).isSuccess('static void helper() {}');
      check(memberDecl).isSuccess('external int get length;');
      check(memberDecl).isSuccess('get length => 0;');
      check(memberDecl).isSuccess('set length(v) {}');
      check(memberDecl).isSuccess('operator ==(other) => false;');
      check(memberDecl).isSuccess('int get width => 0;');
      check(memberDecl).isSuccess('set width(int w) {}');
      check(memberDecl).isSuccess('bool operator ==(Object other) => true;');
      check(memberDecl).isSuccess('@override\n()? getTagInfo() => null;');
      check(memberDecl)
          .isSuccess("@override\n(int, String) foo() => (1, 'a');");
    });

    test('fields', () {
      check(fieldDecl).isSuccess('var x = 1;');
      check(fieldDecl).isSuccess('final int x = 1;');
      check(fieldDecl).isSuccess('static const double pi = 3.14;');
      check(fieldDecl).isSuccess('late final String name;');
      check(fieldDecl).isSuccess('covariant num x;');
      check(fieldDecl).isSuccess(
        'bool Function(Source) inferenceLoggingPredicate = (_) => false;',
      );
      check(fieldDecl).isSuccess('var fn = () => 42;');
    });
  });

  group('compilation units', () {
    final unit = grammar.buildFrom(grammar.compilationUnit()).end();

    test('empty compilation unit', () {
      check(unit).isSuccess('');
      check(unit).isSuccess('// just a comment\n');
    });

    test('script with hashbang', () {
      check(unit).isSuccess('#!/usr/bin/env dart\nvoid main() {}');
    });

    test('library with imports and declarations', () {
      check(unit).isSuccess('''
library my_lib;

import 'dart:math' as math;
export 'src/api.dart';

part 'src/part.dart';

const double pi = 3.14159;

void main() {
  print(pi);
}
''');
    });

    test('library with main method ', () {
      check(unit).isSuccess('void main() {}');
      check(unit).isSuccess('void main(List<String> args) {}');
    });

    test('library with main method missing return type', () {
      check(unit).isSuccess('main() {}');
      check(unit).isSuccess('main(List<String> args) {}');
    });

    test('library with mixin', () {
      check(unit).isSuccess('mixin Mixin {}');
      check(unit).isSuccess('mixin Mixin implements Interface {}');
      check(unit).isSuccess('mixin Mixin on Base {}');
      check(unit).isSuccess('mixin Mixin on Base implements Interface {}');
    });

    test('library with top-level functions', () {
      check(unit).isSuccess('Map<String, int> create() => {};');
      check(unit).isSuccess('Set<int> collect() { return {}; }');
    });

    test('library with emtpy mixin', () {
      check(unit).isSuccess('mixin Mixin;');
      check(unit).isSuccess('mixin Mixin implements Interface;');
      check(unit).isSuccess('mixin Mixin on Base;');
    });

    test('library with class', () {
      check(unit).isSuccess('class Clazz {}');
      check(unit).isSuccess('class Clazz extends Clazz {}');
      check(unit).isSuccess('class Clazz implements Clazz {}');
      check(unit).isSuccess('class Clazz with Clazz {}');
    });

    test('library with special class', () {
      check(unit).isSuccess('final class Clazz {}');
      check(unit).isSuccess('abstract class Clazz {}');
      check(unit).isSuccess('sealed class Clazz {}');
      check(unit).isSuccess('mixin class Clazz {}');
      check(unit).isSuccess('interface class Clazz {}');
    });

    test('library with empty class', () {
      check(unit).isSuccess('class Clazz;');
      check(unit).isSuccess('class Clazz extends Clazz;');
      check(unit).isSuccess('class Clazz implements Clazz;');
      check(unit).isSuccess('class Clazz with Clazz;');
    });

    test('library with extension type', () {
      check(unit).isSuccess('extension on Clazz {}');
      check(unit).isSuccess('extension Ext on Clazz {}');
    });

    test('library with empty extension type', () {
      check(unit).isSuccess('extension on Clazz;');
      check(unit).isSuccess('extension Ext on Clazz;');
    });

    test('class with factory and new constructor', () {
      check(unit).isSuccess('''
class Name {
  factory(String name) =>
      _interned.putIfAbsent(name, () => Name._internal(name));

  new _internal(this._name);

  static final Map<String, Name> _interned = {};

  final String _name;

  @override
  String toString() => _name;
}
''');
    });
  });
}

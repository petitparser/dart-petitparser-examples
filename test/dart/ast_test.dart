import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

void main() {
  group('AST verification', () {
    test('parseDart produces CompilationUnitNode', () {
      final unit = parseDart('''
library sample;

import "dart:math";

class Point {
  const Point(this.x, this.y);
  final double x;
  final double y;
}

void main() {
  const p = Point(1.0, 2.0);
  print(p);
}
''');
      expect(unit.directives, hasLength(2));
      expect(unit.directives[0], isA<LibraryDirectiveNode>());
      expect(unit.directives[1], isA<ImportDirectiveNode>());
      expect(unit.declarations, hasLength(2));
      expect(unit.declarations[0], isA<ClassDeclarationNode>());
      expect(unit.declarations[1], isA<FunctionDeclarationNode>());

      final classNode = unit.declarations[0] as ClassDeclarationNode;
      expect(classNode.name, 'Point');
      expect(classNode.members, hasLength(3));
    });
  });
}

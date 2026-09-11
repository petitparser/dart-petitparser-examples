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

    test(
      'collection for elements produce ForElementNode and ForInElementNode',
      () {
        final unit = parseDart('''
void main() {
  final a = [for (var i = 0; i < 10; i++) i];
  final b = [for (final String x in items) x];
  final c = [for (final (k, v) in pairs) k + v];
}
''');
        final fn = unit.declarations[0] as FunctionDeclarationNode;
        final body = fn.body as BlockFunctionBodyNode;
        final stmtA =
            body.block.statements[0] as VariableDeclarationStatementNode;
        final listA = stmtA.variables[0].initializer as CollectionLiteralNode;
        expect(listA.elements, hasLength(1));
        expect(listA.elements[0], isA<ForElementNode>());

        final forA = listA.elements[0] as ForElementNode;
        expect(forA.initialization, isA<VariableDeclarationStatementNode>());
        expect(forA.condition, isA<BinaryExpressionNode>());
        expect(forA.updates, hasLength(1));
        expect(forA.updates[0], isA<UnaryExpressionNode>());
        expect(forA.body, isA<ExpressionElementNode>());

        final stmtB =
            body.block.statements[1] as VariableDeclarationStatementNode;
        final listB = stmtB.variables[0].initializer as CollectionLiteralNode;
        expect(listB.elements, hasLength(1));
        expect(listB.elements[0], isA<ForInElementNode>());

        final forB = listB.elements[0] as ForInElementNode;
        expect(forB.variable, isA<VariableDeclarationStatementNode>());
        expect(forB.iterable, isA<IdentifierNode>());
        expect(forB.body, isA<ExpressionElementNode>());

        final stmtC =
            body.block.statements[2] as VariableDeclarationStatementNode;
        final listC = stmtC.variables[0].initializer as CollectionLiteralNode;
        expect(listC.elements, hasLength(1));
        expect(listC.elements[0], isA<ForInElementNode>());

        final forC = listC.elements[0] as ForInElementNode;
        expect(forC.pattern, isA<RecordPatternNode>());
        expect(forC.iterable, isA<IdentifierNode>());
        expect(forC.body, isA<ExpressionElementNode>());
      },
    );
  });
}

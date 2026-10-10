import 'package:checks/checks.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

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
      check(unit.directives).length.equals(2);
      check(unit.directives[0]).isA<LibraryDirectiveNode>();
      check(unit.directives[1]).isA<ImportDirectiveNode>();
      check(unit.declarations).length.equals(2);
      check(unit.declarations[0]).isA<ClassDeclarationNode>();
      check(unit.declarations[1]).isA<FunctionDeclarationNode>();

      final classNode = unit.declarations[0] as ClassDeclarationNode;
      check(classNode.name).equals('Point');
      check(classNode.members).length.equals(3);
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
        check(listA.elements).length.equals(1);
        check(listA.elements[0]).isA<ForElementNode>();

        final forA = listA.elements[0] as ForElementNode;
        check(forA.initialization).isA<VariableDeclarationStatementNode>();
        check(forA.condition).isA<BinaryExpressionNode>();
        check(forA.updates).length.equals(1);
        check(forA.updates[0]).isA<UnaryExpressionNode>();
        check(forA.body).isA<ExpressionElementNode>();

        final stmtB =
            body.block.statements[1] as VariableDeclarationStatementNode;
        final listB = stmtB.variables[0].initializer as CollectionLiteralNode;
        check(listB.elements).length.equals(1);
        check(listB.elements[0]).isA<ForInElementNode>();

        final forB = listB.elements[0] as ForInElementNode;
        check(forB.variable).isA<VariableDeclarationStatementNode>();
        check(forB.iterable).isA<IdentifierNode>();
        check(forB.body).isA<ExpressionElementNode>();

        final stmtC =
            body.block.statements[2] as VariableDeclarationStatementNode;
        final listC = stmtC.variables[0].initializer as CollectionLiteralNode;
        check(listC.elements).length.equals(1);
        check(listC.elements[0]).isA<ForInElementNode>();

        final forC = listC.elements[0] as ForInElementNode;
        check(forC.pattern).isA<RecordPatternNode>();
        check(forC.iterable).isA<IdentifierNode>();
        check(forC.body).isA<ExpressionElementNode>();
      },
    );

    group('directives', () {
      test('LibraryDirectiveNode, PartOfDirectiveNode, PartDirectiveNode', () {
        const lib = LibraryDirectiveNode('my_lib');
        check(lib.name).equals('my_lib');
        check(lib.toString()).equals('LibraryDirectiveNode(my_lib)');

        const partOf = PartOfDirectiveNode('parent_lib');
        check(partOf.library).equals('parent_lib');
        check(partOf.toString()).equals('PartOfDirectiveNode(parent_lib)');

        const part = PartDirectiveNode('foo.dart');
        check(part.uri).equals('foo.dart');
        check(part.toString()).equals('PartDirectiveNode(foo.dart)');
      });

      test('ConfigurationUriNode & Import/Export with Combinators', () {
        const config = ConfigurationUriNode(
          uri: 'io.dart',
          name: 'dart.library.io',
          value: 'true',
        );
        check(config.uri).equals('io.dart');
        check(config.toString())
            .contains('ConfigurationUriNode(if (dart.library.io');

        const show = ShowCombinatorNode(['a', 'b']);
        check(show.identifiers).deepEquals(['a', 'b']);
        check(show.toString()).equals('ShowCombinatorNode([a, b])');

        const hide = HideCombinatorNode(['c']);
        check(hide.identifiers).deepEquals(['c']);
        check(hide.toString()).equals('HideCombinatorNode([c])');

        const importNode = ImportDirectiveNode(
          uri: 'dart:async',
          asName: 'async',
          combinators: [show, hide],
          configurations: [config],
          isDeferred: false,
        );
        check(importNode.asName).equals('async');
        check(importNode.combinators).length.equals(2);
        check(importNode.toString())
            .contains('ImportDirectiveNode(dart:async, as: async)');

        const exportNode = ExportDirectiveNode(
          uri: 'src/model.dart',
          combinators: [show],
        );
        check(exportNode.uri).equals('src/model.dart');
        check(exportNode.toString())
            .equals('ExportDirectiveNode(src/model.dart)');
      });
    });

    group('declarations', () {
      test('MixinDeclarationNode & ExtensionDeclarationNode', () {
        const mixin = MixinDeclarationNode(
          name: 'MyMixin',
          onTypes: [NamedTypeNode(name: 'BaseClass')],
          interfaces: [NamedTypeNode(name: 'MyInterface')],
          members: [],
        );
        check(mixin.name).equals('MyMixin');
        check(mixin.onTypes).length.equals(1);
        check(mixin.toString()).equals('MixinDeclarationNode(MyMixin)');

        const ext = ExtensionDeclarationNode(
          name: 'MyExtension',
          onType: NamedTypeNode(name: 'String'),
          members: [],
        );
        check(ext.name).equals('MyExtension');
        check(ext.toString()).contains('ExtensionDeclarationNode(MyExtension');
      });

      test('ExtensionTypeDeclarationNode & EnumDeclarationNode', () {
        const extType = ExtensionTypeDeclarationNode(
          name: 'Id',
          representationType: NamedTypeNode(name: 'int'),
          representationName: 'value',
          members: [],
        );
        check(extType.name).equals('Id');
        check(extType.representationName).equals('value');
        check(extType.toString()).contains('ExtensionTypeDeclarationNode(Id');

        const enumDecl = EnumDeclarationNode(
          name: 'Status',
          constants: [
            EnumConstantNode(name: 'active'),
            EnumConstantNode(name: 'inactive'),
          ],
        );
        check(enumDecl.constants).length.equals(2);
        check(enumDecl.constants.first.toString())
            .equals('EnumConstantNode(active)');
        check(enumDecl.toString()).contains('EnumDeclarationNode(Status');
      });

      test('ConstructorDeclarationNode & Initializers', () {
        const superInit = SuperConstructorInitializerNode(
          constructorName: 'named',
          arguments: [],
        );
        check(superInit.constructorName).equals('named');
        check(superInit.toString())
            .equals('SuperConstructorInitializerNode(named)');

        const redirectInit = RedirectingConstructorInitializerNode(
          constructorName: 'other',
          arguments: [],
        );
        check(redirectInit.constructorName).equals('other');
        check(redirectInit.toString())
            .contains('RedirectingConstructorInitializerNode');

        const fieldInit = FieldInitializerNode(
          fieldName: 'x',
          value: IntegerLiteralNode(10),
        );
        check(fieldInit.fieldName).equals('x');
        check(fieldInit.toString())
            .contains('FieldInitializerNode(x = IntegerLiteralNode(10))');

        const assertInit = AssertInitializerNode(
          AssertStatementNode(BooleanLiteralNode(true)),
        );
        check(assertInit.toString()).contains('AssertInitializerNode');

        const ctor = ConstructorDeclarationNode(
          name: 'Point',
          constructorName: 'origin',
          parameters: [],
          initializers: [fieldInit],
        );
        check(ctor.name).equals('Point');
        check(ctor.constructorName).equals('origin');
        check(ctor.toString())
            .contains('ConstructorDeclarationNode(Point.origin)');
      });

      test('FieldDeclarationNode & TypeAliasDeclarationNode', () {
        const field = FieldDeclarationNode(
          variables: [
            VariableDeclaratorNode(
              name: 'count',
              initializer: IntegerLiteralNode(0),
            ),
          ],
          isStatic: true,
        );
        check(field.isStatic).isTrue();
        check(field.variables.first.toString())
            .equals('VariableDeclaratorNode(count = IntegerLiteralNode(0))');
        check(field.toString()).contains('FieldDeclarationNode');

        const alias = TypeAliasDeclarationNode(
          name: 'IntList',
          type: NamedTypeNode(name: 'List'),
        );
        check(alias.name).equals('IntList');
        check(alias.toString()).contains('TypeAliasDeclarationNode(IntList');
      });
    });

    group('types and parameters', () {
      test(
        'TypeNodes: RecordTypeNode, FunctionTypeNode, TypeParameterNode',
        () {
          const recType = RecordTypeNode(
            positionalFields: [
              RecordTypeFieldNode(type: NamedTypeNode(name: 'int')),
            ],
            namedFields: [
              RecordTypeFieldNode(
                type: NamedTypeNode(name: 'String'),
                name: 'name',
              ),
            ],
          );
          check(recType.positionalFields).length.equals(1);
          check(recType.namedFields.first.name).equals('name');
          check(recType.namedFields.first.toString())
              .contains('RecordTypeFieldNode');
          check(recType.toString()).contains('RecordTypeNode');

          const fnType = FunctionTypeNode(
            returnType: NamedTypeNode(name: 'void'),
            parameters: [
              SimpleParameterNode(
                name: 'x',
                type: NamedTypeNode(name: 'int'),
              ),
            ],
          );
          check(fnType.parameters).length.equals(1);
          check(fnType.toString()).contains('FunctionTypeNode');

          const typeParam = TypeParameterNode(
            name: 'T',
            bound: NamedTypeNode(name: 'Object'),
          );
          check(typeParam.bound).isNotNull();
          check(typeParam.toString())
              .contains('TypeParameterNode(T extends NamedTypeNode(Object))');
        },
      );

      test('ParameterNodes & FunctionBodyNodes', () {
        const simple = SimpleParameterNode(
          name: 'x',
          type: NamedTypeNode(name: 'int'),
          defaultValue: IntegerLiteralNode(1),
          isFinal: true,
          isNamed: true,
        );
        check(simple.isFinal).isTrue();
        check(simple.toString()).contains('ParameterNode(x');

        const fnParam = FunctionTypedParameterNode(
          name: 'cb',
          type: NamedTypeNode(name: 'void'),
          parameters: [],
        );
        check(fnParam.name).equals('cb');
        check(fnParam.toString()).equals('FunctionTypedParameterNode(cb)');

        const emptyBody = EmptyFunctionBodyNode();
        const exprBody = ExpressionFunctionBodyNode(IntegerLiteralNode(42));
        const blockBody = BlockFunctionBodyNode(BlockStatementNode([]));

        check(emptyBody.toString()).equals('EmptyFunctionBodyNode()');
        check(exprBody.toString()).contains('ExpressionFunctionBodyNode');
        check(blockBody.toString()).equals('BlockFunctionBodyNode()');
      });
    });

    group('statements', () {
      test('control flow statements and expressions', () {
        const emptyStmt = EmptyStatementNode();
        check(emptyStmt.toString()).equals('EmptyStatementNode()');

        const exprStmt = ExpressionStatementNode(IntegerLiteralNode(1));
        check(exprStmt.toString()).contains('ExpressionStatementNode');

        const fnStmt = FunctionDeclarationStatementNode(
          FunctionDeclarationNode(
            name: 'localFn',
            body: EmptyFunctionBodyNode(),
          ),
        );
        check(fnStmt.toString()).contains('FunctionDeclarationStatementNode');

        const ifStmt = IfStatementNode(
          condition: BooleanLiteralNode(true),
          thenBranch: EmptyStatementNode(),
          elseBranch: EmptyStatementNode(),
        );
        check(ifStmt.condition).isA<BooleanLiteralNode>();
        check(ifStmt.toString()).contains('IfStatementNode');

        const switchStmt = SwitchStatementNode(
          expression: IntegerLiteralNode(1),
          cases: [
            SwitchPatternCaseNode(
              patterns: [ConstantPatternNode(IntegerLiteralNode(1))],
              statements: [BreakStatementNode()],
            ),
          ],
        );
        check(switchStmt.cases).length.equals(1);
        check(switchStmt.cases.first.toString())
            .contains('SwitchPatternCaseNode');
        check(switchStmt.toString()).contains('SwitchStatementNode');

        const forStmt = ForStatementNode(
          initialization: VariableDeclarationStatementNode(
            variables: [
              VariableDeclaratorNode(
                name: 'i',
                initializer: IntegerLiteralNode(0),
              ),
            ],
          ),
          condition: BooleanLiteralNode(true),
          updates: [
            UnaryExpressionNode(
              operator: '++',
              operand: IdentifierNode('i'),
              isPrefix: false,
            ),
          ],
          body: EmptyStatementNode(),
        );
        check(forStmt.updates).length.equals(1);
        check(forStmt.toString()).equals('ForStatementNode()');

        const whileStmt = WhileStatementNode(
          condition: BooleanLiteralNode(false),
          body: EmptyStatementNode(),
        );
        check(whileStmt.toString()).contains('WhileStatementNode');

        const doWhile = DoWhileStatementNode(
          body: EmptyStatementNode(),
          condition: BooleanLiteralNode(false),
        );
        check(doWhile.toString()).contains('DoWhileStatementNode');

        const tryStmt = TryStatementNode(
          body: BlockStatementNode([]),
          catchClauses: [
            CatchClauseNode(
              exceptionType: NamedTypeNode(name: 'Exception'),
              exceptionParameter: 'e',
              stackTraceParameter: 'st',
              body: BlockStatementNode([]),
            ),
          ],
          finallyBlock: BlockStatementNode([]),
        );
        check(tryStmt.catchClauses).length.equals(1);
        check(tryStmt.catchClauses.first.toString())
            .contains('CatchClauseNode');
        check(tryStmt.toString()).equals('TryStatementNode()');

        const retStmt = ReturnStatementNode(IntegerLiteralNode(5));
        const breakStmt = BreakStatementNode('loop');
        const contStmt = ContinueStatementNode('loop');
        const rethrowStmt = RethrowStatementNode();
        const yieldStmt = YieldStatementNode(
          IntegerLiteralNode(1),
          isStar: true,
        );
        const assertStmt = AssertStatementNode(
          BooleanLiteralNode(true),
          StringLiteralNode('msg'),
        );
        const labeledStmt = LabeledStatementNode(
          label: 'loop',
          statement: emptyStmt,
        );

        check(retStmt.toString()).contains('ReturnStatementNode');
        check(breakStmt.toString()).equals('BreakStatementNode(loop)');
        check(contStmt.toString()).equals('ContinueStatementNode(loop)');
        check(rethrowStmt.toString()).equals('RethrowStatementNode()');
        check(
          yieldStmt.toString(),
        ).contains('YieldStatementNode(IntegerLiteralNode(1), isStar: true)');
        check(assertStmt.toString()).contains('AssertStatementNode');
        check(labeledStmt.toString()).contains('LabeledStatementNode(loop)');
      });
    });

    group('expressions, elements and literals', () {
      test('literals and basic expressions', () {
        const doubleLit = DoubleLiteralNode(3.14);
        const boolLit = BooleanLiteralNode(false);
        const strLit = StringLiteralNode('abc');
        const symLit = SymbolLiteralNode('sym');
        const nullLit = NullLiteralNode();

        check(doubleLit.toString()).equals('DoubleLiteralNode(3.14)');
        check(boolLit.toString()).equals('BooleanLiteralNode(false)');
        check(strLit.toString()).equals('StringLiteralNode(abc, isRaw: false)');
        check(symLit.toString()).equals('SymbolLiteralNode(#sym)');
        check(nullLit.toString()).equals('NullLiteralNode()');

        const interp = InterpolatedStringNode([
          StringLiteralNode('val='),
          IdentifierNode('x'),
        ]);
        check(interp.parts).length.equals(2);
        check(interp.parts.first.toString()).contains('StringLiteralNode(val=');
        check(interp.parts.last.toString()).equals('IdentifierNode(x)');
        check(interp.toString()).contains('InterpolatedStringNode');

        const setMap = CollectionLiteralNode(
          elements: [
            MapEntryElementNode(
              key: StringLiteralNode('a'),
              value: IntegerLiteralNode(1),
            ),
          ],
        );
        check(setMap.elements).length.equals(1);
        check(setMap.elements.first.toString()).contains('MapEntryElementNode');
        check(setMap.toString()).contains('CollectionLiteralNode');

        const recLit = RecordLiteralNode(
          fields: [
            RecordLiteralFieldNode(value: IntegerLiteralNode(1)),
            RecordLiteralFieldNode(name: 'b', value: StringLiteralNode('2')),
          ],
        );
        check(recLit.fields).length.equals(2);
        check(recLit.fields.first.toString())
            .contains('RecordLiteralFieldNode');
        check(recLit.toString()).contains('RecordLiteralNode');
      });

      test('complex operators, invocations and elements', () {
        const cond = ConditionalExpressionNode(
          condition: BooleanLiteralNode(true),
          thenExpression: IntegerLiteralNode(1),
          elseExpression: IntegerLiteralNode(2),
        );
        check(cond.toString()).contains('ConditionalExpressionNode');

        const cascade = CascadeExpressionNode(
          target: IdentifierNode('sb'),
          cascadeSections: [
            InvocationExpressionNode(
              target: IdentifierNode('write'),
              arguments: [ArgumentNode(value: StringLiteralNode('hi'))],
            ),
          ],
        );
        check(cascade.cascadeSections).length.equals(1);
        check(cascade.toString()).contains('CascadeExpressionNode');

        const prop = PropertyAccessNode(
          target: IdentifierNode('a'),
          propertyName: 'b',
        );
        const idx = IndexExpressionNode(
          target: IdentifierNode('a'),
          index: IntegerLiteralNode(0),
        );
        const paren = ParenthesizedExpressionNode(IntegerLiteralNode(1));
        const thisExpr = ThisExpressionNode();
        const superExpr = SuperExpressionNode();

        check(prop.toString())
            .equals('PropertyAccessNode(IdentifierNode(a).b)');
        check(idx.toString()).equals(
          'IndexExpressionNode(IdentifierNode(a)[IntegerLiteralNode(0)])',
        );
        check(paren.toString())
            .equals('ParenthesizedExpressionNode(IntegerLiteralNode(1))');
        check(thisExpr.toString()).equals('ThisExpressionNode()');
        check(superExpr.toString()).equals('SuperExpressionNode()');

        const fnInv = InvocationExpressionNode(
          target: IdentifierNode('f'),
          arguments: [],
        );
        check(fnInv.toString()).contains('InvocationExpressionNode');

        const typeTest = TypeTestExpressionNode(
          expression: IdentifierNode('x'),
          type: NamedTypeNode(name: 'int'),
          isNegated: true,
        );
        check(typeTest.isNegated).isTrue();
        check(typeTest.toString()).contains(
          'TypeTestExpressionNode(IdentifierNode(x) is! NamedTypeNode(int))',
        );

        const asExpr = TypeCastExpressionNode(
          expression: IdentifierNode('x'),
          type: NamedTypeNode(name: 'num'),
        );
        check(asExpr.toString()).contains('TypeCastExpressionNode');

        const throwExpr = ThrowExpressionNode(IdentifierNode('e'));
        check(throwExpr.toString()).contains('ThrowExpressionNode');

        const assignExpr = BinaryExpressionNode(
          left: IdentifierNode('x'),
          operator: '=',
          right: IntegerLiteralNode(1),
        );
        check(assignExpr.toString()).contains('BinaryExpressionNode');

        const spread = SpreadElementNode(
          expression: IdentifierNode('list'),
          isNullAware: true,
        );
        check(spread.isNullAware).isTrue();
        check(spread.toString())
            .equals('SpreadElementNode(...?IdentifierNode(list))');

        const ifElem = IfElementNode(
          condition: BooleanLiteralNode(true),
          thenElement: ExpressionElementNode(IntegerLiteralNode(1)),
          elseElement: ExpressionElementNode(IntegerLiteralNode(2)),
        );
        check(ifElem.elseElement).isNotNull();
        check(ifElem.toString()).contains('IfElementNode');
      });
    });

    group('patterns', () {
      test('pattern nodes', () {
        const declared = VariablePatternNode(
          name: 'val',
          type: NamedTypeNode(name: 'int'),
          isFinal: true,
        );
        check(declared.isFinal).isTrue();
        check(declared.toString()).contains('VariablePatternNode(val');

        const rel = RelationalPatternNode(
          operator: '>',
          operand: IntegerLiteralNode(0),
        );
        check(rel.operator).equals('>');
        check(rel.toString())
            .equals('RelationalPatternNode(> IntegerLiteralNode(0))');

        const castP = CastPatternNode(
          VariablePatternNode(name: 'v'),
          NamedTypeNode(name: 'num'),
        );
        check(castP.toString()).contains('CastPatternNode');

        const nullCheck = NullCheckPatternNode(VariablePatternNode(name: 'v'));
        const nullAssert = NullAssertPatternNode(
          VariablePatternNode(name: 'v'),
        );
        check(nullCheck.toString()).contains('NullCheckPatternNode');
        check(nullAssert.toString()).contains('NullAssertPatternNode');

        const andP = LogicalPatternNode(
          left: RelationalPatternNode(
            operator: '>',
            operand: IntegerLiteralNode(0),
          ),
          operator: '&&',
          right: RelationalPatternNode(
            operator: '<',
            operand: IntegerLiteralNode(10),
          ),
        );
        check(andP.toString()).contains('LogicalPatternNode');

        const orP = LogicalPatternNode(
          left: ConstantPatternNode(IntegerLiteralNode(1)),
          operator: '||',
          right: ConstantPatternNode(IntegerLiteralNode(2)),
        );
        check(orP.toString()).contains('LogicalPatternNode');

        const parenP = ParenthesizedPatternNode(
          ConstantPatternNode(IntegerLiteralNode(1)),
        );
        check(parenP.toString()).contains('ParenthesizedPatternNode');

        const listP = ListPatternNode(
          elements: [
            ConstantPatternNode(IntegerLiteralNode(1)),
            RestPatternNode(),
          ],
        );
        check(listP.elements).length.equals(2);
        check(listP.elements.last.toString()).equals('RestPatternNode(null)');
        check(listP.toString()).contains('ListPatternNode');

        const mapP = MapPatternNode(
          entries: [
            MapPatternEntryNode(
              key: StringLiteralNode('k'),
              value: ConstantPatternNode(IntegerLiteralNode(1)),
            ),
          ],
        );
        check(mapP.entries).length.equals(1);
        check(mapP.entries.first.toString()).contains('MapPatternEntryNode');
        check(mapP.toString()).contains('MapPatternNode');

        const recFieldP = PatternFieldNode(
          pattern: ConstantPatternNode(IntegerLiteralNode(1)),
          name: 'x',
        );
        check(recFieldP.name).equals('x');
        check(recFieldP.toString()).contains('PatternFieldNode');

        const objFieldP = PatternFieldNode(
          name: 'length',
          pattern: ConstantPatternNode(IntegerLiteralNode(5)),
        );
        check(objFieldP.name).equals('length');
        check(objFieldP.toString()).contains('PatternFieldNode');

        const objP = ObjectPatternNode(
          type: NamedTypeNode(name: 'String'),
          fields: [objFieldP],
        );
        check(objP.fields).length.equals(1);
        check(objP.toString()).contains('ObjectPatternNode');
      });
    });
  });
}

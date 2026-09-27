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

    group('directives', () {
      test('LibraryDirectiveNode, PartOfDirectiveNode, PartDirectiveNode', () {
        const lib = LibraryDirectiveNode('my_lib');
        expect(lib.name, 'my_lib');
        expect(lib.toString(), 'LibraryDirectiveNode(my_lib)');

        const partOf = PartOfDirectiveNode('parent_lib');
        expect(partOf.library, 'parent_lib');
        expect(partOf.toString(), 'PartOfDirectiveNode(parent_lib)');

        const part = PartDirectiveNode('foo.dart');
        expect(part.uri, 'foo.dart');
        expect(part.toString(), 'PartDirectiveNode(foo.dart)');
      });

      test('ConfigurationUriNode & Import/Export with Combinators', () {
        const config = ConfigurationUriNode(
          uri: 'io.dart',
          name: 'dart.library.io',
          value: 'true',
        );
        expect(config.uri, 'io.dart');
        expect(
          config.toString(),
          contains('ConfigurationUriNode(if (dart.library.io'),
        );

        const show = ShowCombinatorNode(['a', 'b']);
        expect(show.identifiers, ['a', 'b']);
        expect(show.toString(), 'ShowCombinatorNode([a, b])');

        const hide = HideCombinatorNode(['c']);
        expect(hide.identifiers, ['c']);
        expect(hide.toString(), 'HideCombinatorNode([c])');

        const importNode = ImportDirectiveNode(
          uri: 'dart:async',
          asName: 'async',
          combinators: [show, hide],
          configurations: [config],
          isDeferred: false,
        );
        expect(importNode.asName, 'async');
        expect(importNode.combinators, hasLength(2));
        expect(
          importNode.toString(),
          contains('ImportDirectiveNode(dart:async, as: async)'),
        );

        const exportNode = ExportDirectiveNode(
          uri: 'src/model.dart',
          combinators: [show],
        );
        expect(exportNode.uri, 'src/model.dart');
        expect(exportNode.toString(), 'ExportDirectiveNode(src/model.dart)');
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
        expect(mixin.name, 'MyMixin');
        expect(mixin.onTypes, hasLength(1));
        expect(mixin.toString(), 'MixinDeclarationNode(MyMixin)');

        const ext = ExtensionDeclarationNode(
          name: 'MyExtension',
          onType: NamedTypeNode(name: 'String'),
          members: [],
        );
        expect(ext.name, 'MyExtension');
        expect(
          ext.toString(),
          contains('ExtensionDeclarationNode(MyExtension'),
        );
      });

      test('ExtensionTypeDeclarationNode & EnumDeclarationNode', () {
        const extType = ExtensionTypeDeclarationNode(
          name: 'Id',
          representationType: NamedTypeNode(name: 'int'),
          representationName: 'value',
          members: [],
        );
        expect(extType.name, 'Id');
        expect(extType.representationName, 'value');
        expect(extType.toString(), contains('ExtensionTypeDeclarationNode(Id'));

        const enumDecl = EnumDeclarationNode(
          name: 'Status',
          constants: [
            EnumConstantNode(name: 'active'),
            EnumConstantNode(name: 'inactive'),
          ],
        );
        expect(enumDecl.constants, hasLength(2));
        expect(enumDecl.constants.first.toString(), 'EnumConstantNode(active)');
        expect(enumDecl.toString(), contains('EnumDeclarationNode(Status'));
      });

      test('ConstructorDeclarationNode & Initializers', () {
        const superInit = SuperConstructorInitializerNode(
          constructorName: 'named',
          arguments: [],
        );
        expect(superInit.constructorName, 'named');
        expect(superInit.toString(), 'SuperConstructorInitializerNode(named)');

        const redirectInit = RedirectingConstructorInitializerNode(
          constructorName: 'other',
          arguments: [],
        );
        expect(redirectInit.constructorName, 'other');
        expect(
          redirectInit.toString(),
          contains('RedirectingConstructorInitializerNode'),
        );

        const fieldInit = FieldInitializerNode(
          fieldName: 'x',
          value: IntegerLiteralNode(10),
        );
        expect(fieldInit.fieldName, 'x');
        expect(
          fieldInit.toString(),
          contains('FieldInitializerNode(x = IntegerLiteralNode(10))'),
        );

        const assertInit = AssertInitializerNode(
          AssertStatementNode(BooleanLiteralNode(true)),
        );
        expect(assertInit.toString(), contains('AssertInitializerNode'));

        const ctor = ConstructorDeclarationNode(
          name: 'Point',
          constructorName: 'origin',
          parameters: [],
          initializers: [fieldInit],
        );
        expect(ctor.name, 'Point');
        expect(ctor.constructorName, 'origin');
        expect(
          ctor.toString(),
          contains('ConstructorDeclarationNode(Point.origin)'),
        );
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
        expect(field.isStatic, isTrue);
        expect(
          field.variables.first.toString(),
          'VariableDeclaratorNode(count = IntegerLiteralNode(0))',
        );
        expect(field.toString(), contains('FieldDeclarationNode'));

        const alias = TypeAliasDeclarationNode(
          name: 'IntList',
          type: NamedTypeNode(name: 'List'),
        );
        expect(alias.name, 'IntList');
        expect(alias.toString(), contains('TypeAliasDeclarationNode(IntList'));
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
          expect(recType.positionalFields, hasLength(1));
          expect(recType.namedFields.first.name, 'name');
          expect(
            recType.namedFields.first.toString(),
            contains('RecordTypeFieldNode'),
          );
          expect(recType.toString(), contains('RecordTypeNode'));

          const fnType = FunctionTypeNode(
            returnType: NamedTypeNode(name: 'void'),
            parameters: [
              SimpleParameterNode(
                name: 'x',
                type: NamedTypeNode(name: 'int'),
              ),
            ],
          );
          expect(fnType.parameters, hasLength(1));
          expect(fnType.toString(), contains('FunctionTypeNode'));

          const typeParam = TypeParameterNode(
            name: 'T',
            bound: NamedTypeNode(name: 'Object'),
          );
          expect(typeParam.bound, isNotNull);
          expect(
            typeParam.toString(),
            contains('TypeParameterNode(T extends NamedTypeNode(Object))'),
          );
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
        expect(simple.isFinal, isTrue);
        expect(simple.toString(), contains('ParameterNode(x'));

        const fnParam = FunctionTypedParameterNode(
          name: 'cb',
          type: NamedTypeNode(name: 'void'),
          parameters: [],
        );
        expect(fnParam.name, 'cb');
        expect(fnParam.toString(), 'FunctionTypedParameterNode(cb)');

        const emptyBody = EmptyFunctionBodyNode();
        const exprBody = ExpressionFunctionBodyNode(IntegerLiteralNode(42));
        const blockBody = BlockFunctionBodyNode(BlockStatementNode([]));

        expect(emptyBody.toString(), 'EmptyFunctionBodyNode()');
        expect(exprBody.toString(), contains('ExpressionFunctionBodyNode'));
        expect(blockBody.toString(), 'BlockFunctionBodyNode()');
      });
    });

    group('statements', () {
      test('control flow statements and expressions', () {
        const emptyStmt = EmptyStatementNode();
        expect(emptyStmt.toString(), 'EmptyStatementNode()');

        const exprStmt = ExpressionStatementNode(IntegerLiteralNode(1));
        expect(exprStmt.toString(), contains('ExpressionStatementNode'));

        const fnStmt = FunctionDeclarationStatementNode(
          FunctionDeclarationNode(
            name: 'localFn',
            body: EmptyFunctionBodyNode(),
          ),
        );
        expect(fnStmt.toString(), contains('FunctionDeclarationStatementNode'));

        const ifStmt = IfStatementNode(
          condition: BooleanLiteralNode(true),
          thenBranch: EmptyStatementNode(),
          elseBranch: EmptyStatementNode(),
        );
        expect(ifStmt.condition, isA<BooleanLiteralNode>());
        expect(ifStmt.toString(), contains('IfStatementNode'));

        const switchStmt = SwitchStatementNode(
          expression: IntegerLiteralNode(1),
          cases: [
            SwitchPatternCaseNode(
              patterns: [ConstantPatternNode(IntegerLiteralNode(1))],
              statements: [BreakStatementNode()],
            ),
          ],
        );
        expect(switchStmt.cases, hasLength(1));
        expect(
          switchStmt.cases.first.toString(),
          contains('SwitchPatternCaseNode'),
        );
        expect(switchStmt.toString(), contains('SwitchStatementNode'));

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
        expect(forStmt.updates, hasLength(1));
        expect(forStmt.toString(), 'ForStatementNode()');

        const whileStmt = WhileStatementNode(
          condition: BooleanLiteralNode(false),
          body: EmptyStatementNode(),
        );
        expect(whileStmt.toString(), contains('WhileStatementNode'));

        const doWhile = DoWhileStatementNode(
          body: EmptyStatementNode(),
          condition: BooleanLiteralNode(false),
        );
        expect(doWhile.toString(), contains('DoWhileStatementNode'));

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
        expect(tryStmt.catchClauses, hasLength(1));
        expect(
          tryStmt.catchClauses.first.toString(),
          contains('CatchClauseNode'),
        );
        expect(tryStmt.toString(), 'TryStatementNode()');

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

        expect(retStmt.toString(), contains('ReturnStatementNode'));
        expect(breakStmt.toString(), 'BreakStatementNode(loop)');
        expect(contStmt.toString(), 'ContinueStatementNode(loop)');
        expect(rethrowStmt.toString(), 'RethrowStatementNode()');
        expect(
          yieldStmt.toString(),
          contains('YieldStatementNode(IntegerLiteralNode(1), isStar: true)'),
        );
        expect(assertStmt.toString(), contains('AssertStatementNode'));
        expect(labeledStmt.toString(), contains('LabeledStatementNode(loop)'));
      });
    });

    group('expressions, elements and literals', () {
      test('literals and basic expressions', () {
        const doubleLit = DoubleLiteralNode(3.14);
        const boolLit = BooleanLiteralNode(false);
        const strLit = StringLiteralNode('abc');
        const symLit = SymbolLiteralNode('sym');
        const nullLit = NullLiteralNode();

        expect(doubleLit.toString(), 'DoubleLiteralNode(3.14)');
        expect(boolLit.toString(), 'BooleanLiteralNode(false)');
        expect(strLit.toString(), 'StringLiteralNode(abc, isRaw: false)');
        expect(symLit.toString(), 'SymbolLiteralNode(#sym)');
        expect(nullLit.toString(), 'NullLiteralNode()');

        const interp = InterpolatedStringNode([
          StringLiteralNode('val='),
          IdentifierNode('x'),
        ]);
        expect(interp.parts, hasLength(2));
        expect(
          interp.parts.first.toString(),
          contains('StringLiteralNode(val='),
        );
        expect(interp.parts.last.toString(), 'IdentifierNode(x)');
        expect(interp.toString(), contains('InterpolatedStringNode'));

        const setMap = CollectionLiteralNode(
          elements: [
            MapEntryElementNode(
              key: StringLiteralNode('a'),
              value: IntegerLiteralNode(1),
            ),
          ],
        );
        expect(setMap.elements, hasLength(1));
        expect(
          setMap.elements.first.toString(),
          contains('MapEntryElementNode'),
        );
        expect(setMap.toString(), contains('CollectionLiteralNode'));

        const recLit = RecordLiteralNode(
          fields: [
            RecordLiteralFieldNode(value: IntegerLiteralNode(1)),
            RecordLiteralFieldNode(name: 'b', value: StringLiteralNode('2')),
          ],
        );
        expect(recLit.fields, hasLength(2));
        expect(
          recLit.fields.first.toString(),
          contains('RecordLiteralFieldNode'),
        );
        expect(recLit.toString(), contains('RecordLiteralNode'));
      });

      test('complex operators, invocations and elements', () {
        const cond = ConditionalExpressionNode(
          condition: BooleanLiteralNode(true),
          thenExpression: IntegerLiteralNode(1),
          elseExpression: IntegerLiteralNode(2),
        );
        expect(cond.toString(), contains('ConditionalExpressionNode'));

        const cascade = CascadeExpressionNode(
          target: IdentifierNode('sb'),
          cascadeSections: [
            InvocationExpressionNode(
              target: IdentifierNode('write'),
              arguments: [ArgumentNode(value: StringLiteralNode('hi'))],
            ),
          ],
        );
        expect(cascade.cascadeSections, hasLength(1));
        expect(cascade.toString(), contains('CascadeExpressionNode'));

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

        expect(prop.toString(), 'PropertyAccessNode(IdentifierNode(a).b)');
        expect(
          idx.toString(),
          'IndexExpressionNode(IdentifierNode(a)[IntegerLiteralNode(0)])',
        );
        expect(
          paren.toString(),
          'ParenthesizedExpressionNode(IntegerLiteralNode(1))',
        );
        expect(thisExpr.toString(), 'ThisExpressionNode()');
        expect(superExpr.toString(), 'SuperExpressionNode()');

        const fnInv = InvocationExpressionNode(
          target: IdentifierNode('f'),
          arguments: [],
        );
        expect(fnInv.toString(), contains('InvocationExpressionNode'));

        const typeTest = TypeTestExpressionNode(
          expression: IdentifierNode('x'),
          type: NamedTypeNode(name: 'int'),
          isNegated: true,
        );
        expect(typeTest.isNegated, isTrue);
        expect(
          typeTest.toString(),
          contains(
            'TypeTestExpressionNode(IdentifierNode(x) is! NamedTypeNode(int))',
          ),
        );

        const asExpr = TypeCastExpressionNode(
          expression: IdentifierNode('x'),
          type: NamedTypeNode(name: 'num'),
        );
        expect(asExpr.toString(), contains('TypeCastExpressionNode'));

        const throwExpr = ThrowExpressionNode(IdentifierNode('e'));
        expect(throwExpr.toString(), contains('ThrowExpressionNode'));

        const assignExpr = BinaryExpressionNode(
          left: IdentifierNode('x'),
          operator: '=',
          right: IntegerLiteralNode(1),
        );
        expect(assignExpr.toString(), contains('BinaryExpressionNode'));

        const spread = SpreadElementNode(
          expression: IdentifierNode('list'),
          isNullAware: true,
        );
        expect(spread.isNullAware, isTrue);
        expect(
          spread.toString(),
          'SpreadElementNode(...?IdentifierNode(list))',
        );

        const ifElem = IfElementNode(
          condition: BooleanLiteralNode(true),
          thenElement: ExpressionElementNode(IntegerLiteralNode(1)),
          elseElement: ExpressionElementNode(IntegerLiteralNode(2)),
        );
        expect(ifElem.elseElement, isNotNull);
        expect(ifElem.toString(), contains('IfElementNode'));
      });
    });

    group('patterns', () {
      test('pattern nodes', () {
        const declared = VariablePatternNode(
          name: 'val',
          type: NamedTypeNode(name: 'int'),
          isFinal: true,
        );
        expect(declared.isFinal, isTrue);
        expect(declared.toString(), contains('VariablePatternNode(val'));

        const rel = RelationalPatternNode(
          operator: '>',
          operand: IntegerLiteralNode(0),
        );
        expect(rel.operator, '>');
        expect(
          rel.toString(),
          'RelationalPatternNode(> IntegerLiteralNode(0))',
        );

        const castP = CastPatternNode(
          VariablePatternNode(name: 'v'),
          NamedTypeNode(name: 'num'),
        );
        expect(castP.toString(), contains('CastPatternNode'));

        const nullCheck = NullCheckPatternNode(VariablePatternNode(name: 'v'));
        const nullAssert = NullAssertPatternNode(
          VariablePatternNode(name: 'v'),
        );
        expect(nullCheck.toString(), contains('NullCheckPatternNode'));
        expect(nullAssert.toString(), contains('NullAssertPatternNode'));

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
        expect(andP.toString(), contains('LogicalPatternNode'));

        const orP = LogicalPatternNode(
          left: ConstantPatternNode(IntegerLiteralNode(1)),
          operator: '||',
          right: ConstantPatternNode(IntegerLiteralNode(2)),
        );
        expect(orP.toString(), contains('LogicalPatternNode'));

        const parenP = ParenthesizedPatternNode(
          ConstantPatternNode(IntegerLiteralNode(1)),
        );
        expect(parenP.toString(), contains('ParenthesizedPatternNode'));

        const listP = ListPatternNode(
          elements: [
            ConstantPatternNode(IntegerLiteralNode(1)),
            RestPatternNode(),
          ],
        );
        expect(listP.elements, hasLength(2));
        expect(listP.elements.last.toString(), 'RestPatternNode(null)');
        expect(listP.toString(), contains('ListPatternNode'));

        const mapP = MapPatternNode(
          entries: [
            MapPatternEntryNode(
              key: StringLiteralNode('k'),
              value: ConstantPatternNode(IntegerLiteralNode(1)),
            ),
          ],
        );
        expect(mapP.entries, hasLength(1));
        expect(mapP.entries.first.toString(), contains('MapPatternEntryNode'));
        expect(mapP.toString(), contains('MapPatternNode'));

        const recFieldP = PatternFieldNode(
          pattern: ConstantPatternNode(IntegerLiteralNode(1)),
          name: 'x',
        );
        expect(recFieldP.name, 'x');
        expect(recFieldP.toString(), contains('PatternFieldNode'));

        const objFieldP = PatternFieldNode(
          name: 'length',
          pattern: ConstantPatternNode(IntegerLiteralNode(5)),
        );
        expect(objFieldP.name, 'length');
        expect(objFieldP.toString(), contains('PatternFieldNode'));

        const objP = ObjectPatternNode(
          type: NamedTypeNode(name: 'String'),
          fields: [objFieldP],
        );
        expect(objP.fields, hasLength(1));
        expect(objP.toString(), contains('ObjectPatternNode'));
      });
    });
  });
}

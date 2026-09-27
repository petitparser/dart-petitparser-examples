import 'package:petitparser_examples/pascal.dart';
import 'package:test/test.dart';

/// Test visitor that records visits and returns the node class name.
class TestPascalVisitor implements PascalVisitor<String, String> {
  const new();

  @override
  String visitProgram(ProgramNode node, String? context) =>
      'ProgramNode:${node.name}:$context';

  @override
  String visitBlock(BlockNode node, String? context) => 'BlockNode:$context';

  @override
  String visitConstantDefinition(
    ConstantDefinitionNode node,
    String? context,
  ) => 'ConstantDefinitionNode:${node.name}:$context';

  @override
  String visitTypeDefinition(TypeDefinitionNode node, String? context) =>
      'TypeDefinitionNode:${node.name}:$context';

  @override
  String visitVariableDeclaration(
    VariableDeclarationNode node,
    String? context,
  ) => 'VariableDeclarationNode:${node.names.join(",")}:$context';

  @override
  String visitFormalParameter(FormalParameterNode node, String? context) =>
      'FormalParameterNode:${node.names.join(",")}:$context';

  @override
  String visitProcedure(ProcedureNode node, String? context) =>
      'ProcedureNode:${node.name}:$context';

  @override
  String visitFunction(FunctionNode node, String? context) =>
      'FunctionNode:${node.name}:$context';

  @override
  String visitSimpleType(SimpleTypeNode node, String? context) =>
      'SimpleTypeNode:${node.name}:$context';

  @override
  String visitSubrangeType(SubrangeTypeNode node, String? context) =>
      'SubrangeTypeNode:$context';

  @override
  String visitEnumeratedType(EnumeratedTypeNode node, String? context) =>
      'EnumeratedTypeNode:${node.values.join(",")}:$context';

  @override
  String visitPointerType(PointerTypeNode node, String? context) =>
      'PointerTypeNode:$context';

  @override
  String visitArrayType(ArrayTypeNode node, String? context) =>
      'ArrayTypeNode:$context';

  @override
  String visitRecordType(RecordTypeNode node, String? context) =>
      'RecordTypeNode:$context';

  @override
  String visitSetType(SetTypeNode node, String? context) =>
      'SetTypeNode:$context';

  @override
  String visitFileType(FileTypeNode node, String? context) =>
      'FileTypeNode:$context';

  @override
  String visitCompoundStatement(CompoundStatementNode node, String? context) =>
      'CompoundStatementNode:$context';

  @override
  String visitAssignmentStatement(
    AssignmentStatementNode node,
    String? context,
  ) => 'AssignmentStatementNode:$context';

  @override
  String visitProcedureStatement(
    ProcedureStatementNode node,
    String? context,
  ) => 'ProcedureStatementNode:${node.name}:$context';

  @override
  String visitIfStatement(IfStatementNode node, String? context) =>
      'IfStatementNode:$context';

  @override
  String visitCaseStatement(CaseStatementNode node, String? context) =>
      'CaseStatementNode:$context';

  @override
  String visitCaseElement(CaseElementNode node, String? context) =>
      'CaseElementNode:$context';

  @override
  String visitWhileStatement(WhileStatementNode node, String? context) =>
      'WhileStatementNode:$context';

  @override
  String visitRepeatStatement(RepeatStatementNode node, String? context) =>
      'RepeatStatementNode:$context';

  @override
  String visitForStatement(ForStatementNode node, String? context) =>
      'ForStatementNode:${node.variable}:${node.isDownTo}:$context';

  @override
  String visitWithStatement(WithStatementNode node, String? context) =>
      'WithStatementNode:$context';

  @override
  String visitGotoStatement(GotoStatementNode node, String? context) =>
      'GotoStatementNode:${node.targetLabel}:$context';

  @override
  String visitEmptyStatement(EmptyStatementNode node, String? context) =>
      'EmptyStatementNode:$context';

  @override
  String visitBinaryExpression(BinaryExpressionNode node, String? context) =>
      'BinaryExpressionNode:${node.operator}:$context';

  @override
  String visitUnaryExpression(UnaryExpressionNode node, String? context) =>
      'UnaryExpressionNode:${node.operator}:$context';

  @override
  String visitVariableExpression(
    VariableExpressionNode node,
    String? context,
  ) => 'VariableExpressionNode:${node.name}:$context';

  @override
  String visitArrayAccessExpression(
    ArrayAccessExpressionNode node,
    String? context,
  ) => 'ArrayAccessExpressionNode:$context';

  @override
  String visitFieldAccessExpression(
    FieldAccessExpressionNode node,
    String? context,
  ) => 'FieldAccessExpressionNode:${node.field}:$context';

  @override
  String visitPointerDereferenceExpression(
    PointerDereferenceExpressionNode node,
    String? context,
  ) => 'PointerDereferenceExpressionNode:$context';

  @override
  String visitFunctionCallExpression(
    FunctionCallExpressionNode node,
    String? context,
  ) => 'FunctionCallExpressionNode:${node.name}:$context';

  @override
  String visitLiteralExpression(LiteralExpressionNode node, String? context) =>
      'LiteralExpressionNode:${node.value}:$context';

  @override
  String visitSetExpression(SetExpressionNode node, String? context) =>
      'SetExpressionNode:$context';

  @override
  String visitSetElement(SetElementNode node, String? context) =>
      'SetElementNode:$context';
}

void main() {
  const visitor = TestPascalVisitor();
  const ctx = 'test';

  group('program and block nodes', () {
    test('ProgramNode and BlockNode', () {
      const block = BlockNode(
        labels: ['10', '20'],
        statement: CompoundStatementNode(statements: [EmptyStatementNode()]),
      );
      const program = ProgramNode(
        name: 'MyProg',
        parameters: ['input', 'output'],
        block: block,
      );

      expect(program.accept(visitor, ctx), equals('ProgramNode:MyProg:test'));
      expect(program.children, equals([block]));
      expect(program.parameters, equals(['input', 'output']));

      expect(block.accept(visitor, ctx), equals('BlockNode:test'));
      expect(block.labels, equals(['10', '20']));
      expect(block.children, contains(isA<CompoundStatementNode>()));
    });
  });

  group('declaration and subroutine nodes', () {
    const lit = LiteralExpressionNode(raw: '42', value: 42);
    const simple = SimpleTypeNode('integer');

    test('ConstantDefinitionNode', () {
      const constDef = ConstantDefinitionNode(name: 'MAX', value: lit);
      expect(
        constDef.accept(visitor, ctx),
        equals('ConstantDefinitionNode:MAX:test'),
      );
      expect(constDef.children, equals([lit]));
    });

    test('TypeDefinitionNode', () {
      const typeDef = TypeDefinitionNode(name: 'TInt', type: simple);
      expect(
        typeDef.accept(visitor, ctx),
        equals('TypeDefinitionNode:TInt:test'),
      );
      expect(typeDef.children, equals([simple]));
    });

    test('VariableDeclarationNode', () {
      const varDecl = VariableDeclarationNode(names: ['x', 'y'], type: simple);
      expect(
        varDecl.accept(visitor, ctx),
        equals('VariableDeclarationNode:x,y:test'),
      );
      expect(varDecl.children, equals([simple]));
    });

    test('FormalParameterNode', () {
      const param = FormalParameterNode(
        isVar: true,
        names: ['a', 'b'],
        type: simple,
      );
      expect(
        param.accept(visitor, ctx),
        equals('FormalParameterNode:a,b:test'),
      );
      expect(param.children, equals([simple]));
      expect(param.isVar, isTrue);
      expect(param.type, equals(simple));
    });

    test('ProcedureNode and FunctionNode', () {
      const param = FormalParameterNode(
        isVar: false,
        names: ['p'],
        type: SimpleTypeNode('real'),
      );
      const block = BlockNode(statement: CompoundStatementNode(statements: []));

      const proc = ProcedureNode(
        name: 'DoWork',
        parameters: [param],
        block: block,
      );
      expect(proc.accept(visitor, ctx), equals('ProcedureNode:DoWork:test'));
      expect(proc.children, equals([param, block]));

      const func = FunctionNode(
        name: 'GetVal',
        parameters: [param],
        returnType: SimpleTypeNode('real'),
        block: block,
      );
      expect(func.accept(visitor, ctx), equals('FunctionNode:GetVal:test'));
      expect(
        func.children,
        equals([param, const SimpleTypeNode('real'), block]),
      );
      expect(func.returnType, equals(const SimpleTypeNode('real')));
    });
  });

  group('type nodes', () {
    const simple = SimpleTypeNode('char');
    const lit1 = LiteralExpressionNode(raw: '1', value: 1);
    const lit10 = LiteralExpressionNode(raw: '10', value: 10);

    test('SimpleTypeNode and SubrangeTypeNode', () {
      expect(simple.accept(visitor, ctx), equals('SimpleTypeNode:char:test'));
      expect(simple.children, isEmpty);

      const subrange = SubrangeTypeNode(start: lit1, end: lit10);
      expect(subrange.accept(visitor, ctx), equals('SubrangeTypeNode:test'));
      expect(subrange.children, equals([lit1, lit10]));
    });

    test('EnumeratedTypeNode and PointerTypeNode', () {
      const enumType = EnumeratedTypeNode(['red', 'green', 'blue']);
      expect(
        enumType.accept(visitor, ctx),
        equals('EnumeratedTypeNode:red,green,blue:test'),
      );
      expect(enumType.children, isEmpty);

      const ptrType = PointerTypeNode(SimpleTypeNode('node'));
      expect(ptrType.accept(visitor, ctx), equals('PointerTypeNode:test'));
      expect(ptrType.children, equals([const SimpleTypeNode('node')]));
    });

    test('ArrayTypeNode and RecordTypeNode', () {
      const subrange = SubrangeTypeNode(start: lit1, end: lit10);
      const arrayType = ArrayTypeNode(indices: [subrange], elementType: simple);
      expect(arrayType.accept(visitor, ctx), equals('ArrayTypeNode:test'));
      expect(arrayType.children, equals([subrange, simple]));

      const field = VariableDeclarationNode(names: ['name'], type: simple);
      const recordType = RecordTypeNode(fields: [field]);
      expect(recordType.accept(visitor, ctx), equals('RecordTypeNode:test'));
      expect(recordType.children, equals([field]));
    });

    test('SetTypeNode and FileTypeNode', () {
      const setType = SetTypeNode(simple);
      expect(setType.accept(visitor, ctx), equals('SetTypeNode:test'));
      expect(setType.children, equals([simple]));

      const fileType = FileTypeNode(simple);
      expect(fileType.accept(visitor, ctx), equals('FileTypeNode:test'));
      expect(fileType.children, equals([simple]));
    });
  });

  group('statement nodes', () {
    const expr = LiteralExpressionNode(raw: 'true', value: true);
    const vExpr = VariableExpressionNode('x');
    const empty = EmptyStatementNode();

    test('CompoundStatementNode and EmptyStatementNode', () {
      expect(empty.accept(visitor, ctx), equals('EmptyStatementNode:test'));
      expect(empty.children, isEmpty);

      const compound = CompoundStatementNode(statements: [empty, empty]);
      expect(
        compound.accept(visitor, ctx),
        equals('CompoundStatementNode:test'),
      );
      expect(compound.children, equals([empty, empty]));
    });

    test('AssignmentStatementNode and ProcedureStatementNode', () {
      const assign = AssignmentStatementNode(
        variable: vExpr,
        value: LiteralExpressionNode(raw: '10', value: 10),
      );
      expect(
        assign.accept(visitor, ctx),
        equals('AssignmentStatementNode:test'),
      );
      expect(assign.children.length, equals(2));

      const procStmt = ProcedureStatementNode(
        name: 'WriteLn',
        arguments: [LiteralExpressionNode(raw: "'hello'", value: 'hello')],
      );
      expect(
        procStmt.accept(visitor, ctx),
        equals('ProcedureStatementNode:WriteLn:test'),
      );
      expect(procStmt.children.length, equals(1));
    });

    test('IfStatementNode with and without else', () {
      const ifElse = IfStatementNode(
        condition: expr,
        thenStatement: empty,
        elseStatement: empty,
      );
      expect(ifElse.accept(visitor, ctx), equals('IfStatementNode:test'));
      expect(ifElse.children, equals([expr, empty, empty]));

      const ifOnly = IfStatementNode(condition: expr, thenStatement: empty);
      expect(ifOnly.children, equals([expr, empty]));
    });

    test('CaseStatementNode and CaseElementNode', () {
      const caseElem = CaseElementNode(
        constants: [LiteralExpressionNode(raw: '1', value: 1)],
        statement: empty,
      );
      expect(caseElem.accept(visitor, ctx), equals('CaseElementNode:test'));
      expect(caseElem.children.length, equals(2));

      const caseStmt = CaseStatementNode(expression: vExpr, cases: [caseElem]);
      expect(caseStmt.accept(visitor, ctx), equals('CaseStatementNode:test'));
      expect(caseStmt.children, equals([vExpr, caseElem]));
    });

    test('WhileStatementNode and RepeatStatementNode', () {
      const whileStmt = WhileStatementNode(condition: expr, statement: empty);
      expect(whileStmt.accept(visitor, ctx), equals('WhileStatementNode:test'));
      expect(whileStmt.children, equals([expr, empty]));

      const repeatStmt = RepeatStatementNode(
        statements: [empty],
        condition: expr,
      );
      expect(
        repeatStmt.accept(visitor, ctx),
        equals('RepeatStatementNode:test'),
      );
      expect(repeatStmt.children, equals([empty, expr]));
    });

    test('ForStatementNode (to and downto)', () {
      const forUp = ForStatementNode(
        variable: 'i',
        initialValue: LiteralExpressionNode(raw: '1', value: 1),
        isDownTo: false,
        finalValue: LiteralExpressionNode(raw: '10', value: 10),
        statement: empty,
      );
      expect(
        forUp.accept(visitor, ctx),
        equals('ForStatementNode:i:false:test'),
      );
      expect(forUp.children.length, equals(3));

      const forDown = ForStatementNode(
        variable: 'j',
        initialValue: LiteralExpressionNode(raw: '10', value: 10),
        isDownTo: true,
        finalValue: LiteralExpressionNode(raw: '1', value: 1),
        statement: empty,
      );
      expect(
        forDown.accept(visitor, ctx),
        equals('ForStatementNode:j:true:test'),
      );
    });

    test('WithStatementNode and GotoStatementNode', () {
      const withStmt = WithStatementNode(records: [vExpr], statement: empty);
      expect(withStmt.accept(visitor, ctx), equals('WithStatementNode:test'));
      expect(withStmt.children, equals([vExpr, empty]));

      const gotoStmt = GotoStatementNode(targetLabel: '100');
      expect(
        gotoStmt.accept(visitor, ctx),
        equals('GotoStatementNode:100:test'),
      );
      expect(gotoStmt.children, isEmpty);
    });
  });

  group('expression nodes', () {
    const left = LiteralExpressionNode(raw: '5', value: 5);
    const right = LiteralExpressionNode(raw: '3', value: 3);
    const vExpr = VariableExpressionNode('arr');

    test('BinaryExpressionNode and UnaryExpressionNode', () {
      const bin = BinaryExpressionNode(operator: '+', left: left, right: right);
      expect(bin.accept(visitor, ctx), equals('BinaryExpressionNode:+:test'));
      expect(bin.children, equals([left, right]));

      const un = UnaryExpressionNode(operator: '-', operand: left);
      expect(un.accept(visitor, ctx), equals('UnaryExpressionNode:-:test'));
      expect(un.children, equals([left]));
    });

    test('VariableExpressionNode and LiteralExpressionNode', () {
      expect(
        vExpr.accept(visitor, ctx),
        equals('VariableExpressionNode:arr:test'),
      );
      expect(vExpr.children, isEmpty);

      const lit = LiteralExpressionNode(raw: "'val'", value: 'val');
      expect(
        lit.accept(visitor, ctx),
        equals('LiteralExpressionNode:val:test'),
      );
      expect(lit.children, isEmpty);
    });

    test('ArrayAccessExpressionNode and FieldAccessExpressionNode', () {
      const arrAccess = ArrayAccessExpressionNode(
        array: vExpr,
        indices: [left],
      );
      expect(
        arrAccess.accept(visitor, ctx),
        equals('ArrayAccessExpressionNode:test'),
      );
      expect(arrAccess.children, equals([vExpr, left]));

      const fieldAccess = FieldAccessExpressionNode(
        record: vExpr,
        field: 'count',
      );
      expect(
        fieldAccess.accept(visitor, ctx),
        equals('FieldAccessExpressionNode:count:test'),
      );
      expect(fieldAccess.children, equals([vExpr]));
    });

    test('PointerDereferenceExpressionNode and FunctionCallExpressionNode', () {
      const ptrDeref = PointerDereferenceExpressionNode(vExpr);
      expect(
        ptrDeref.accept(visitor, ctx),
        equals('PointerDereferenceExpressionNode:test'),
      );
      expect(ptrDeref.children, equals([vExpr]));

      const fnCall = FunctionCallExpressionNode(
        name: 'Sqrt',
        arguments: [left],
      );
      expect(
        fnCall.accept(visitor, ctx),
        equals('FunctionCallExpressionNode:Sqrt:test'),
      );
      expect(fnCall.children, equals([left]));
    });

    test('SetExpressionNode and SetElementNode', () {
      const elem1 = SetElementNode(start: left);
      const elem2 = SetElementNode(start: left, end: right);

      expect(elem1.accept(visitor, ctx), equals('SetElementNode:test'));
      expect(elem1.children, equals([left]));

      expect(elem2.accept(visitor, ctx), equals('SetElementNode:test'));
      expect(elem2.children, equals([left, right]));

      const setExpr = SetExpressionNode([elem1, elem2]);
      expect(setExpr.accept(visitor, ctx), equals('SetExpressionNode:test'));
      expect(setExpr.children, equals([elem1, elem2]));
    });
  });
}

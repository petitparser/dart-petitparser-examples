import 'package:checks/checks.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:test/scaffolding.dart';

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

      check(program.accept(visitor, ctx)).equals('ProgramNode:MyProg:test');
      check(program.children).deepEquals([block]);
      check(program.parameters).deepEquals(['input', 'output']);

      check(block.accept(visitor, ctx)).equals('BlockNode:test');
      check(block.labels).deepEquals(['10', '20']);
      check(block.children).any((it) => it.isA<CompoundStatementNode>());
    });
  });

  group('declaration and subroutine nodes', () {
    const lit = LiteralExpressionNode(raw: '42', value: 42);
    const simple = SimpleTypeNode('integer');

    test('ConstantDefinitionNode', () {
      const constDef = ConstantDefinitionNode(name: 'MAX', value: lit);
      check(constDef.accept(visitor, ctx))
          .equals('ConstantDefinitionNode:MAX:test');
      check(constDef.children).deepEquals([lit]);
    });

    test('TypeDefinitionNode', () {
      const typeDef = TypeDefinitionNode(name: 'TInt', type: simple);
      check(typeDef.accept(visitor, ctx))
          .equals('TypeDefinitionNode:TInt:test');
      check(typeDef.children).deepEquals([simple]);
    });

    test('VariableDeclarationNode', () {
      const varDecl = VariableDeclarationNode(names: ['x', 'y'], type: simple);
      check(varDecl.accept(visitor, ctx))
          .equals('VariableDeclarationNode:x,y:test');
      check(varDecl.children).deepEquals([simple]);
    });

    test('FormalParameterNode', () {
      const param = FormalParameterNode(
        isVar: true,
        names: ['a', 'b'],
        type: simple,
      );
      check(param.accept(visitor, ctx)).equals('FormalParameterNode:a,b:test');
      check(param.children).deepEquals([simple]);
      check(param.isVar).isTrue();
      check(param.type).equals(simple);
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
      check(proc.accept(visitor, ctx)).equals('ProcedureNode:DoWork:test');
      check(proc.children).deepEquals([param, block]);

      const func = FunctionNode(
        name: 'GetVal',
        parameters: [param],
        returnType: SimpleTypeNode('real'),
        block: block,
      );
      check(func.accept(visitor, ctx)).equals('FunctionNode:GetVal:test');
      check(func.children)
          .deepEquals([param, const SimpleTypeNode('real'), block]);
      check(func.returnType).equals(const SimpleTypeNode('real'));
    });
  });

  group('type nodes', () {
    const simple = SimpleTypeNode('char');
    const lit1 = LiteralExpressionNode(raw: '1', value: 1);
    const lit10 = LiteralExpressionNode(raw: '10', value: 10);

    test('SimpleTypeNode and SubrangeTypeNode', () {
      check(simple.accept(visitor, ctx)).equals('SimpleTypeNode:char:test');
      check(simple.children).isEmpty();

      const subrange = SubrangeTypeNode(start: lit1, end: lit10);
      check(subrange.accept(visitor, ctx)).equals('SubrangeTypeNode:test');
      check(subrange.children).deepEquals([lit1, lit10]);
    });

    test('EnumeratedTypeNode and PointerTypeNode', () {
      const enumType = EnumeratedTypeNode(['red', 'green', 'blue']);
      check(enumType.accept(visitor, ctx))
          .equals('EnumeratedTypeNode:red,green,blue:test');
      check(enumType.children).isEmpty();

      const ptrType = PointerTypeNode(SimpleTypeNode('node'));
      check(ptrType.accept(visitor, ctx)).equals('PointerTypeNode:test');
      check(ptrType.children).deepEquals([const SimpleTypeNode('node')]);
    });

    test('ArrayTypeNode and RecordTypeNode', () {
      const subrange = SubrangeTypeNode(start: lit1, end: lit10);
      const arrayType = ArrayTypeNode(indices: [subrange], elementType: simple);
      check(arrayType.accept(visitor, ctx)).equals('ArrayTypeNode:test');
      check(arrayType.children).deepEquals([subrange, simple]);

      const field = VariableDeclarationNode(names: ['name'], type: simple);
      const recordType = RecordTypeNode(fields: [field]);
      check(recordType.accept(visitor, ctx)).equals('RecordTypeNode:test');
      check(recordType.children).deepEquals([field]);
    });

    test('SetTypeNode and FileTypeNode', () {
      const setType = SetTypeNode(simple);
      check(setType.accept(visitor, ctx)).equals('SetTypeNode:test');
      check(setType.children).deepEquals([simple]);

      const fileType = FileTypeNode(simple);
      check(fileType.accept(visitor, ctx)).equals('FileTypeNode:test');
      check(fileType.children).deepEquals([simple]);
    });
  });

  group('statement nodes', () {
    const expr = LiteralExpressionNode(raw: 'true', value: true);
    const vExpr = VariableExpressionNode('x');
    const empty = EmptyStatementNode();

    test('CompoundStatementNode and EmptyStatementNode', () {
      check(empty.accept(visitor, ctx)).equals('EmptyStatementNode:test');
      check(empty.children).isEmpty();

      const compound = CompoundStatementNode(statements: [empty, empty]);
      check(compound.accept(visitor, ctx)).equals('CompoundStatementNode:test');
      check(compound.children).deepEquals([empty, empty]);
    });

    test('AssignmentStatementNode and ProcedureStatementNode', () {
      const assign = AssignmentStatementNode(
        variable: vExpr,
        value: LiteralExpressionNode(raw: '10', value: 10),
      );
      check(assign.accept(visitor, ctx)).equals('AssignmentStatementNode:test');
      check(assign.children.length).equals(2);

      const procStmt = ProcedureStatementNode(
        name: 'WriteLn',
        arguments: [LiteralExpressionNode(raw: "'hello'", value: 'hello')],
      );
      check(procStmt.accept(visitor, ctx))
          .equals('ProcedureStatementNode:WriteLn:test');
      check(procStmt.children.length).equals(1);
    });

    test('IfStatementNode with and without else', () {
      const ifElse = IfStatementNode(
        condition: expr,
        thenStatement: empty,
        elseStatement: empty,
      );
      check(ifElse.accept(visitor, ctx)).equals('IfStatementNode:test');
      check(ifElse.children).deepEquals([expr, empty, empty]);

      const ifOnly = IfStatementNode(condition: expr, thenStatement: empty);
      check(ifOnly.children).deepEquals([expr, empty]);
    });

    test('CaseStatementNode and CaseElementNode', () {
      const caseElem = CaseElementNode(
        constants: [LiteralExpressionNode(raw: '1', value: 1)],
        statement: empty,
      );
      check(caseElem.accept(visitor, ctx)).equals('CaseElementNode:test');
      check(caseElem.children.length).equals(2);

      const caseStmt = CaseStatementNode(expression: vExpr, cases: [caseElem]);
      check(caseStmt.accept(visitor, ctx)).equals('CaseStatementNode:test');
      check(caseStmt.children).deepEquals([vExpr, caseElem]);
    });

    test('WhileStatementNode and RepeatStatementNode', () {
      const whileStmt = WhileStatementNode(condition: expr, statement: empty);
      check(whileStmt.accept(visitor, ctx)).equals('WhileStatementNode:test');
      check(whileStmt.children).deepEquals([expr, empty]);

      const repeatStmt = RepeatStatementNode(
        statements: [empty],
        condition: expr,
      );
      check(repeatStmt.accept(visitor, ctx)).equals('RepeatStatementNode:test');
      check(repeatStmt.children).deepEquals([empty, expr]);
    });

    test('ForStatementNode (to and downto)', () {
      const forUp = ForStatementNode(
        variable: 'i',
        initialValue: LiteralExpressionNode(raw: '1', value: 1),
        isDownTo: false,
        finalValue: LiteralExpressionNode(raw: '10', value: 10),
        statement: empty,
      );
      check(forUp.accept(visitor, ctx)).equals('ForStatementNode:i:false:test');
      check(forUp.children.length).equals(3);

      const forDown = ForStatementNode(
        variable: 'j',
        initialValue: LiteralExpressionNode(raw: '10', value: 10),
        isDownTo: true,
        finalValue: LiteralExpressionNode(raw: '1', value: 1),
        statement: empty,
      );
      check(forDown.accept(visitor, ctx))
          .equals('ForStatementNode:j:true:test');
    });

    test('WithStatementNode and GotoStatementNode', () {
      const withStmt = WithStatementNode(records: [vExpr], statement: empty);
      check(withStmt.accept(visitor, ctx)).equals('WithStatementNode:test');
      check(withStmt.children).deepEquals([vExpr, empty]);

      const gotoStmt = GotoStatementNode(targetLabel: '100');
      check(gotoStmt.accept(visitor, ctx)).equals('GotoStatementNode:100:test');
      check(gotoStmt.children).isEmpty();
    });
  });

  group('expression nodes', () {
    const left = LiteralExpressionNode(raw: '5', value: 5);
    const right = LiteralExpressionNode(raw: '3', value: 3);
    const vExpr = VariableExpressionNode('arr');

    test('BinaryExpressionNode and UnaryExpressionNode', () {
      const bin = BinaryExpressionNode(operator: '+', left: left, right: right);
      check(bin.accept(visitor, ctx)).equals('BinaryExpressionNode:+:test');
      check(bin.children).deepEquals([left, right]);

      const un = UnaryExpressionNode(operator: '-', operand: left);
      check(un.accept(visitor, ctx)).equals('UnaryExpressionNode:-:test');
      check(un.children).deepEquals([left]);
    });

    test('VariableExpressionNode and LiteralExpressionNode', () {
      check(vExpr.accept(visitor, ctx))
          .equals('VariableExpressionNode:arr:test');
      check(vExpr.children).isEmpty();

      const lit = LiteralExpressionNode(raw: "'val'", value: 'val');
      check(lit.accept(visitor, ctx)).equals('LiteralExpressionNode:val:test');
      check(lit.children).isEmpty();
    });

    test('ArrayAccessExpressionNode and FieldAccessExpressionNode', () {
      const arrAccess = ArrayAccessExpressionNode(
        array: vExpr,
        indices: [left],
      );
      check(arrAccess.accept(visitor, ctx))
          .equals('ArrayAccessExpressionNode:test');
      check(arrAccess.children).deepEquals([vExpr, left]);

      const fieldAccess = FieldAccessExpressionNode(
        record: vExpr,
        field: 'count',
      );
      check(fieldAccess.accept(visitor, ctx))
          .equals('FieldAccessExpressionNode:count:test');
      check(fieldAccess.children).deepEquals([vExpr]);
    });

    test('PointerDereferenceExpressionNode and FunctionCallExpressionNode', () {
      const ptrDeref = PointerDereferenceExpressionNode(vExpr);
      check(ptrDeref.accept(visitor, ctx))
          .equals('PointerDereferenceExpressionNode:test');
      check(ptrDeref.children).deepEquals([vExpr]);

      const fnCall = FunctionCallExpressionNode(
        name: 'Sqrt',
        arguments: [left],
      );
      check(fnCall.accept(visitor, ctx))
          .equals('FunctionCallExpressionNode:Sqrt:test');
      check(fnCall.children).deepEquals([left]);
    });

    test('SetExpressionNode and SetElementNode', () {
      const elem1 = SetElementNode(start: left);
      const elem2 = SetElementNode(start: left, end: right);

      check(elem1.accept(visitor, ctx)).equals('SetElementNode:test');
      check(elem1.children).deepEquals([left]);

      check(elem2.accept(visitor, ctx)).equals('SetElementNode:test');
      check(elem2.children).deepEquals([left, right]);

      const setExpr = SetExpressionNode([elem1, elem2]);
      check(setExpr.accept(visitor, ctx)).equals('SetExpressionNode:test');
      check(setExpr.children).deepEquals([elem1, elem2]);
    });
  });
}

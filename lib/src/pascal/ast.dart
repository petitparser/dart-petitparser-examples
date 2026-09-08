import 'package:meta/meta.dart';

/// Abstract base class for all Pascal AST nodes.
@immutable
sealed class PascalNode {
  const new();

  /// Accepts a visitor to traverse the AST.
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]);

  /// Direct child nodes of this node.
  List<PascalNode> get children => const [];
}

/// Visitor interface for [PascalNode] AST hierarchies.
abstract interface class PascalVisitor<R, C> {
  R visitProgram(ProgramNode node, C? context);
  R visitBlock(BlockNode node, C? context);
  R visitConstantDefinition(ConstantDefinitionNode node, C? context);
  R visitTypeDefinition(TypeDefinitionNode node, C? context);
  R visitVariableDeclaration(VariableDeclarationNode node, C? context);
  R visitFormalParameter(FormalParameterNode node, C? context);
  R visitProcedure(ProcedureNode node, C? context);
  R visitFunction(FunctionNode node, C? context);

  // Types
  R visitSimpleType(SimpleTypeNode node, C? context);
  R visitSubrangeType(SubrangeTypeNode node, C? context);
  R visitEnumeratedType(EnumeratedTypeNode node, C? context);
  R visitPointerType(PointerTypeNode node, C? context);
  R visitArrayType(ArrayTypeNode node, C? context);
  R visitRecordType(RecordTypeNode node, C? context);
  R visitSetType(SetTypeNode node, C? context);
  R visitFileType(FileTypeNode node, C? context);

  // Statements
  R visitCompoundStatement(CompoundStatementNode node, C? context);
  R visitAssignmentStatement(AssignmentStatementNode node, C? context);
  R visitProcedureStatement(ProcedureStatementNode node, C? context);
  R visitIfStatement(IfStatementNode node, C? context);
  R visitCaseStatement(CaseStatementNode node, C? context);
  R visitCaseElement(CaseElementNode node, C? context);
  R visitWhileStatement(WhileStatementNode node, C? context);
  R visitRepeatStatement(RepeatStatementNode node, C? context);
  R visitForStatement(ForStatementNode node, C? context);
  R visitWithStatement(WithStatementNode node, C? context);
  R visitGotoStatement(GotoStatementNode node, C? context);
  R visitEmptyStatement(EmptyStatementNode node, C? context);

  // Expressions
  R visitBinaryExpression(BinaryExpressionNode node, C? context);
  R visitUnaryExpression(UnaryExpressionNode node, C? context);
  R visitVariableExpression(VariableExpressionNode node, C? context);
  R visitArrayAccessExpression(ArrayAccessExpressionNode node, C? context);
  R visitFieldAccessExpression(FieldAccessExpressionNode node, C? context);
  R visitPointerDereferenceExpression(
    PointerDereferenceExpressionNode node,
    C? context,
  );
  R visitFunctionCallExpression(FunctionCallExpressionNode node, C? context);
  R visitLiteralExpression(LiteralExpressionNode node, C? context);
  R visitSetExpression(SetExpressionNode node, C? context);
  R visitSetElement(SetElementNode node, C? context);
}

/// A complete Pascal program.
class ProgramNode extends PascalNode {
  const new({
    required this.name,
    required this.parameters,
    required this.block,
  });

  final String name;
  final List<String> parameters;
  final BlockNode block;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitProgram(this, context);

  @override
  List<PascalNode> get children => [block];
}

/// A Pascal block containing declarations and a compound statement.
class BlockNode extends PascalNode {
  const new({
    this.labels = const [],
    this.constants = const [],
    this.types = const [],
    this.variables = const [],
    this.subroutines = const [],
    required this.statement,
  });

  final List<String> labels;
  final List<ConstantDefinitionNode> constants;
  final List<TypeDefinitionNode> types;
  final List<VariableDeclarationNode> variables;
  final List<PascalNode> subroutines; // ProcedureNode or FunctionNode
  final CompoundStatementNode statement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitBlock(this, context);

  @override
  List<PascalNode> get children => [
    ...constants,
    ...types,
    ...variables,
    ...subroutines,
    statement,
  ];
}

/// A constant definition: `name = value;`.
class ConstantDefinitionNode extends PascalNode {
  const new({required this.name, required this.value});

  final String name;
  final ExpressionNode value;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitConstantDefinition(this, context);

  @override
  List<PascalNode> get children => [value];
}

/// A type definition: `name = type;`.
class TypeDefinitionNode extends PascalNode {
  const new({required this.name, required this.type});

  final String name;
  final TypeNode type;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitTypeDefinition(this, context);

  @override
  List<PascalNode> get children => [type];
}

/// A variable declaration: `var x, y: Integer;`.
class VariableDeclarationNode extends PascalNode {
  const new({required this.names, required this.type});

  final List<String> names;
  final TypeNode type;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitVariableDeclaration(this, context);

  @override
  List<PascalNode> get children => [type];
}

/// A formal parameter in a procedure or function heading.
class FormalParameterNode extends PascalNode {
  const new({
    required this.names,
    this.type,
    this.isVar = false,
    this.isFunction = false,
    this.isProcedure = false,
  });

  final List<String> names;
  final TypeNode? type;
  final bool isVar;
  final bool isFunction;
  final bool isProcedure;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitFormalParameter(this, context);

  @override
  List<PascalNode> get children => type != null ? [type!] : const [];
}

/// A procedure declaration.
class ProcedureNode extends PascalNode {
  const new({
    required this.name,
    this.parameters = const [],
    required this.block,
  });

  final String name;
  final List<FormalParameterNode> parameters;
  final BlockNode block;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitProcedure(this, context);

  @override
  List<PascalNode> get children => [...parameters, block];
}

/// A function declaration.
class FunctionNode extends PascalNode {
  const new({
    required this.name,
    this.parameters = const [],
    required this.returnType,
    required this.block,
  });

  final String name;
  final List<FormalParameterNode> parameters;
  final TypeNode returnType;
  final BlockNode block;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitFunction(this, context);

  @override
  List<PascalNode> get children => [...parameters, returnType, block];
}

// ---------------------------------------------------------------------------
// Type AST
// ---------------------------------------------------------------------------

/// Abstract base class for Pascal types.
sealed class TypeNode extends PascalNode {
  const new();
}

/// A simple named type, e.g. `Integer`, `Real`, `Boolean`.
class SimpleTypeNode extends TypeNode {
  const new(this.name);

  final String name;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitSimpleType(this, context);
}

/// A subrange type, e.g. `1..100` or `'a'..'z'`.
class SubrangeTypeNode extends TypeNode {
  const new({required this.start, required this.end});

  final ExpressionNode start;
  final ExpressionNode end;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitSubrangeType(this, context);

  @override
  List<PascalNode> get children => [start, end];
}

/// An enumerated type, e.g. `(Red, Green, Blue)`.
class EnumeratedTypeNode extends TypeNode {
  const new(this.values);

  final List<String> values;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitEnumeratedType(this, context);
}

/// A pointer type, e.g. `^Integer` or `^Node`.
class PointerTypeNode extends TypeNode {
  const new(this.baseType);

  final TypeNode baseType;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitPointerType(this, context);

  @override
  List<PascalNode> get children => [baseType];
}

/// An array type, e.g. `array [1..10] of Integer`.
class ArrayTypeNode extends TypeNode {
  const new({required this.indices, required this.elementType});

  final List<TypeNode> indices;
  final TypeNode elementType;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitArrayType(this, context);

  @override
  List<PascalNode> get children => [...indices, elementType];
}

/// A record type, e.g. `record x, y: Real; end`.
class RecordTypeNode extends TypeNode {
  const new({required this.fields});

  final List<VariableDeclarationNode> fields;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitRecordType(this, context);

  @override
  List<PascalNode> get children => fields;
}

/// A set type, e.g. `set of Char`.
class SetTypeNode extends TypeNode {
  const new(this.baseType);

  final TypeNode baseType;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitSetType(this, context);

  @override
  List<PascalNode> get children => [baseType];
}

/// A file type, e.g. `file of Integer`.
class FileTypeNode extends TypeNode {
  const new(this.baseType);

  final TypeNode? baseType;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitFileType(this, context);

  @override
  List<PascalNode> get children => baseType != null ? [baseType!] : const [];
}

// ---------------------------------------------------------------------------
// Statement AST
// ---------------------------------------------------------------------------

/// Abstract base class for Pascal statements.
sealed class StatementNode extends PascalNode {
  const new({this.label});

  final String? label;
}

/// A compound statement: `begin s1; s2; end`.
class CompoundStatementNode extends StatementNode {
  const new({super.label, required this.statements});

  final List<StatementNode> statements;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitCompoundStatement(this, context);

  @override
  List<PascalNode> get children => statements;
}

/// An assignment statement: `variable := expression`.
class AssignmentStatementNode extends StatementNode {
  const new({super.label, required this.variable, required this.value});

  final ExpressionNode variable;
  final ExpressionNode value;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitAssignmentStatement(this, context);

  @override
  List<PascalNode> get children => [variable, value];
}

/// A procedure statement / invocation: `WriteLn('hello')`.
class ProcedureStatementNode extends StatementNode {
  const new({super.label, required this.name, this.arguments = const []});

  final String name;
  final List<ExpressionNode> arguments;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitProcedureStatement(this, context);

  @override
  List<PascalNode> get children => arguments;
}

/// An `if` statement: `if condition then thenStatement [else elseStatement]`.
class IfStatementNode extends StatementNode {
  const new({
    super.label,
    required this.condition,
    required this.thenStatement,
    this.elseStatement,
  });

  final ExpressionNode condition;
  final StatementNode thenStatement;
  final StatementNode? elseStatement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitIfStatement(this, context);

  @override
  List<PascalNode> get children => [condition, thenStatement, ?elseStatement];
}

/// A `case` statement: `case expr of const: stmt; ... end`.
class CaseStatementNode extends StatementNode {
  const new({super.label, required this.expression, required this.cases});

  final ExpressionNode expression;
  final List<CaseElementNode> cases;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitCaseStatement(this, context);

  @override
  List<PascalNode> get children => [expression, ...cases];
}

/// A single element in a case statement: `const1, const2: stmt`.
class CaseElementNode extends PascalNode {
  const new({required this.constants, required this.statement});

  final List<ExpressionNode> constants;
  final StatementNode statement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitCaseElement(this, context);

  @override
  List<PascalNode> get children => [...constants, statement];
}

/// A `while` loop: `while condition do statement`.
class WhileStatementNode extends StatementNode {
  const new({super.label, required this.condition, required this.statement});

  final ExpressionNode condition;
  final StatementNode statement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitWhileStatement(this, context);

  @override
  List<PascalNode> get children => [condition, statement];
}

/// A `repeat` loop: `repeat s1; s2 until condition`.
class RepeatStatementNode extends StatementNode {
  const new({super.label, required this.statements, required this.condition});

  final List<StatementNode> statements;
  final ExpressionNode condition;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitRepeatStatement(this, context);

  @override
  List<PascalNode> get children => [...statements, condition];
}

/// A `for` loop: `for variable := initial to/downto final do statement`.
class ForStatementNode extends StatementNode {
  const new({
    super.label,
    required this.variable,
    required this.initialValue,
    required this.isDownTo,
    required this.finalValue,
    required this.statement,
  });

  final String variable;
  final ExpressionNode initialValue;
  final bool isDownTo;
  final ExpressionNode finalValue;
  final StatementNode statement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitForStatement(this, context);

  @override
  List<PascalNode> get children => [initialValue, finalValue, statement];
}

/// A `with` statement: `with r1, r2 do statement`.
class WithStatementNode extends StatementNode {
  const new({super.label, required this.records, required this.statement});

  final List<ExpressionNode> records;
  final StatementNode statement;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitWithStatement(this, context);

  @override
  List<PascalNode> get children => [...records, statement];
}

/// A `goto` statement: `goto label`.
class GotoStatementNode extends StatementNode {
  const new({super.label, required this.targetLabel});

  final String targetLabel;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitGotoStatement(this, context);
}

/// An empty statement.
class EmptyStatementNode extends StatementNode {
  const new({super.label});

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitEmptyStatement(this, context);
}

// ---------------------------------------------------------------------------
// Expression AST
// ---------------------------------------------------------------------------

/// Abstract base class for Pascal expressions.
sealed class ExpressionNode extends PascalNode {
  const new();
}

/// A binary expression: `left operator right`.
class BinaryExpressionNode extends ExpressionNode {
  const new({required this.operator, required this.left, required this.right});

  final String operator;
  final ExpressionNode left;
  final ExpressionNode right;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitBinaryExpression(this, context);

  @override
  List<PascalNode> get children => [left, right];
}

/// A unary expression: `+x`, `-x`, `not b`.
class UnaryExpressionNode extends ExpressionNode {
  const new({required this.operator, required this.operand});

  final String operator;
  final ExpressionNode operand;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitUnaryExpression(this, context);

  @override
  List<PascalNode> get children => [operand];
}

/// A simple variable identifier: `x`.
class VariableExpressionNode extends ExpressionNode {
  const new(this.name);

  final String name;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitVariableExpression(this, context);
}

/// An array element access: `arr[i, j]`.
class ArrayAccessExpressionNode extends ExpressionNode {
  const new({required this.array, required this.indices});

  final ExpressionNode array;
  final List<ExpressionNode> indices;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitArrayAccessExpression(this, context);

  @override
  List<PascalNode> get children => [array, ...indices];
}

/// A record field access: `rec.field`.
class FieldAccessExpressionNode extends ExpressionNode {
  const new({required this.record, required this.field});

  final ExpressionNode record;
  final String field;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitFieldAccessExpression(this, context);

  @override
  List<PascalNode> get children => [record];
}

/// A pointer dereference: `ptr^`.
class PointerDereferenceExpressionNode extends ExpressionNode {
  const new(this.pointer);

  final ExpressionNode pointer;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitPointerDereferenceExpression(this, context);

  @override
  List<PascalNode> get children => [pointer];
}

/// A function invocation: `Sin(x)` or `Func(a, b)`.
class FunctionCallExpressionNode extends ExpressionNode {
  const new({required this.name, this.arguments = const []});

  final String name;
  final List<ExpressionNode> arguments;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitFunctionCallExpression(this, context);

  @override
  List<PascalNode> get children => arguments;
}

/// A literal value (number, string, char, nil, boolean).
class LiteralExpressionNode extends ExpressionNode {
  const new({required this.raw, required this.value});

  final String raw;
  final Object? value;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitLiteralExpression(this, context);
}

/// A set literal: `[1, 2..5, 8]`.
class SetExpressionNode extends ExpressionNode {
  const new(this.elements);

  final List<SetElementNode> elements;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitSetExpression(this, context);

  @override
  List<PascalNode> get children => elements;
}

/// A single element or range in a set literal: `e` or `e1..e2`.
class SetElementNode extends PascalNode {
  const new({required this.start, this.end});

  final ExpressionNode start;
  final ExpressionNode? end;

  @override
  R accept<R, C>(PascalVisitor<R, C> visitor, [C? context]) =>
      visitor.visitSetElement(this, context);

  @override
  List<PascalNode> get children => [start, ?end];
}

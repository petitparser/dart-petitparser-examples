import 'package:petitparser/petitparser.dart';

import 'visitor.dart';

/// Abstract base class for all Smalltalk Abstract Syntax Tree (AST) nodes.
abstract class Node {
  /// Dispatches execution to [visitor] based on concrete node type.
  void accept(Visitor visitor);
}

/// Mixin for AST nodes that contain a sequence of statements and separator periods.
mixin HasStatements implements Node {
  /// The statements contained within this node.
  final List<IsStatement> statements = [];

  /// The period tokens separating statements.
  final List<Token> periods = [];
}

/// Marker mixin for AST nodes that can appear as statements.
mixin IsStatement implements Node;

/// Mixin for AST nodes delimited by enclosing opening and closing tokens.
mixin IsSurrounded implements Node {
  /// Opening boundary tokens.
  final List<Token> beforeToken = [];

  /// Closing boundary tokens.
  final List<Token> afterToken = [];

  /// Records enclosing [before] and [after] tokens.
  void surroundWith(Token before, Token after) {
    beforeToken.add(before);
    afterToken.add(after);
  }
}

/// The dispatch type of a Smalltalk message selector.
enum SelectorType {
  /// A unary selector with zero arguments (e.g. `asString`).
  unary,

  /// A binary operator selector with one argument (e.g. `+ 2`).
  binary,

  /// A keyword selector with colon-separated arguments (e.g. `at:put:`).
  keyword,
}

/// Mixin for AST nodes that have a message or method selector.
mixin HasSelector implements Node {
  /// Tokens comprising the selector name.
  final List<Token> selectorToken = [];

  /// The arguments associated with this selector.
  List get arguments;

  /// The full selector string combined from [selectorToken].
  String get selector => selectorToken.map((token) => token.input).join();

  /// The dispatch category of this selector.
  SelectorType get selectorType => arguments.isEmpty
      ? SelectorType.unary
      : selectorToken.first.value.endsWith(':')
      ? SelectorType.keyword
      : SelectorType.binary;
}

/// An AST node representing a Smalltalk method declaration.
///
/// Contains method [arguments], compiler [pragmas], and executable [body].
///
/// For example:
///
/// ```dart
/// final parser = SmalltalkParserDefinition().build();
/// final method = parser.parse('factorial ^ self <= 1 ifTrue: [ 1 ] ifFalse: [ self * (self - 1) factorial ]').value;
/// print(method.selector); // 'factorial'
/// ```
class MethodNode extends Node with HasSelector {
  /// Creates a method node.
  new();

  @override
  final List<VariableNode> arguments = [];

  /// Compiler pragmas defined on the method.
  final List<PragmaNode> pragmas = [];

  /// The method body sequence.
  final SequenceNode body = SequenceNode();

  @override
  void accept(Visitor visitor) => visitor.visitMethodNode(this);
}

/// An AST node representing a method annotation or compiler pragma (`<primitive: 123>`).
class PragmaNode extends Node with HasSelector, IsSurrounded {
  /// Creates a pragma node.
  new();

  @override
  final List<LiteralNode> arguments = [];

  @override
  void accept(Visitor visitor) => visitor.visitPragmaNode(this);
}

/// An AST node representing a block or method body containing temporaries and statements.
class SequenceNode extends Node with HasStatements {
  /// Creates a sequence node.
  new();

  /// Local temporary variables declared in `| temp1 temp2 |`.
  final List<VariableNode> temporaries = [];

  @override
  void accept(Visitor visitor) => visitor.visitSequenceNode(this);
}

/// An AST node representing a method return statement (`^ value`).
class ReturnNode extends Node with IsStatement {
  /// Creates a return statement with caret token [caret] and returned [value].
  new(this.caret, this.value);

  /// The caret (`^`) token.
  final Token caret;

  /// The expression being returned.
  final ValueNode value;

  @override
  void accept(Visitor visitor) => visitor.visitReturnNode(this);
}

/// Abstract base class for AST expressions that produce a value.
abstract class ValueNode extends Node with IsStatement, IsSurrounded {
  /// Creates a value node.
  new();
}

/// An AST node representing a runtime dynamic array expression (`{ 1 + 2. 'hello' }`).
class ArrayNode extends ValueNode with HasStatements {
  /// Creates a dynamic array node.
  new();

  @override
  void accept(Visitor visitor) => visitor.visitArrayNode(this);
}

/// An AST node representing variable assignment (`variable := value`).
class AssignmentNode extends ValueNode {
  /// Creates an assignment of [value] to [variable] via [assignment] operator token.
  new(this.variable, this.assignment, this.value);

  /// The target variable node.
  final VariableNode variable;

  /// The assignment operator token (`:=` or `_`).
  final Token assignment;

  /// The expression evaluated and assigned.
  final ValueNode value;

  @override
  void accept(Visitor visitor) => visitor.visitAssignmentNode(this);
}

/// An AST node representing a Smalltalk block closure (`[ :arg | arg + 1 ]`).
class BlockNode extends ValueNode {
  /// Creates a block closure node with [body].
  new(this.body);

  /// Block parameter variables declared with leading colons (e.g. `:x`).
  final List<VariableNode> arguments = [];

  /// Vertical bar separators (`|`) following block arguments.
  final List<Token> separators = [];

  /// The statements sequence inside the block.
  final SequenceNode body;

  @override
  void accept(Visitor visitor) => visitor.visitBlockNode(this);
}

/// An AST node representing a message cascade (`receiver msg1; msg2`).
class CascadeNode extends ValueNode {
  /// Creates a cascade node.
  new();

  /// The cascaded messages sent to the receiver.
  final List<MessageNode> messages = [];

  /// Semicolon tokens separating cascaded messages.
  final List<Token> semicolons = [];

  /// The common receiver of all messages in the cascade.
  ValueNode get receiver => messages.first.receiver;

  @override
  void accept(Visitor visitor) => visitor.visitCascadeNode(this);
}

/// Base class for literal constants in Smalltalk.
abstract class LiteralNode<T> extends ValueNode {
  /// Creates a literal node holding [value].
  new(this.value);

  /// The literal value.
  final T value;
}

/// An AST node representing a literal array constant (`#(1 2 'three')` or `#[1 2 3]`).
class LiteralArrayNode<T> extends LiteralNode<List<T>> {
  /// Creates a literal array node with element [values].
  new(this.values) : super(values.map((value) => value.value).toList());

  /// The literal element nodes within this array.
  final List<LiteralNode<T>> values;

  @override
  void accept(Visitor visitor) => visitor.visitLiteralArrayNode(this);
}

/// An AST node representing an atomic literal value (numbers, strings, booleans, symbols, nil).
class LiteralValueNode<T> extends LiteralNode<T> {
  /// Creates a literal value node from [token] and parsed [value].
  new(this.token, T value) : super(value);

  /// The source token representing this literal.
  final Token token;

  @override
  void accept(Visitor visitor) => visitor.visitLiteralValueNode(this);
}

/// An AST node representing a message send to [receiver].
///
/// Supports unary (`receiver printString`), binary (`receiver + arg`), and
/// keyword (`receiver at: 1 put: 'value'`) message sends.
class MessageNode extends ValueNode with HasSelector {
  /// Creates a message send node with target [receiver].
  new(this.receiver);

  /// The recipient expression of the message send.
  final ValueNode receiver;

  @override
  final List<ValueNode> arguments = [];

  @override
  void accept(Visitor visitor) => visitor.visitMessageNode(this);
}

/// An AST node representing a variable reference.
class VariableNode extends ValueNode {
  /// Creates a variable node with identifier [token].
  new(this.token);

  /// The token representing the variable identifier.
  final Token token;

  /// The identifier name of the variable.
  String get name => token.input;

  @override
  void accept(Visitor visitor) => visitor.visitVariableNode(this);
}

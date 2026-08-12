import 'package:petitparser/petitparser.dart';

import 'visitor.dart';

abstract class Node {
  void accept(Visitor visitor);
}

mixin HasStatements implements Node {
  final List<IsStatement> statements = [];
  final List<Token> periods = [];
}

mixin IsStatement implements Node;

mixin IsSurrounded implements Node {
  final List<Token> beforeToken = [];
  final List<Token> afterToken = [];

  void surroundWith(Token before, Token after) {
    beforeToken.add(before);
    afterToken.add(after);
  }
}

enum SelectorType { unary, binary, keyword }

mixin HasSelector implements Node {
  final List<Token> selectorToken = [];

  List get arguments;

  String get selector => selectorToken.map((token) => token.input).join();

  SelectorType get selectorType => arguments.isEmpty
      ? SelectorType.unary
      : selectorToken.first.value.endsWith(':')
      ? SelectorType.keyword
      : SelectorType.binary;
}

class MethodNode extends Node with HasSelector {
  new();

  @override
  final List<VariableNode> arguments = [];
  final List<PragmaNode> pragmas = [];
  final SequenceNode body = SequenceNode();

  @override
  void accept(Visitor visitor) => visitor.visitMethodNode(this);
}

class PragmaNode extends Node with HasSelector, IsSurrounded {
  new();

  @override
  final List<LiteralNode> arguments = [];

  @override
  void accept(Visitor visitor) => visitor.visitPragmaNode(this);
}

class SequenceNode extends Node with HasStatements {
  new();

  final List<VariableNode> temporaries = [];

  @override
  void accept(Visitor visitor) => visitor.visitSequenceNode(this);
}

class ReturnNode extends Node with IsStatement {
  new(this.caret, this.value);

  final Token caret;
  final ValueNode value;

  @override
  void accept(Visitor visitor) => visitor.visitReturnNode(this);
}

abstract class ValueNode extends Node with IsStatement, IsSurrounded {
  new();
}

class ArrayNode extends ValueNode with HasStatements {
  new();

  @override
  void accept(Visitor visitor) => visitor.visitArrayNode(this);
}

class AssignmentNode extends ValueNode {
  new(this.variable, this.assignment, this.value);

  final VariableNode variable;
  final Token assignment;
  final ValueNode value;

  @override
  void accept(Visitor visitor) => visitor.visitAssignmentNode(this);
}

class BlockNode extends ValueNode {
  new(this.body);

  final List<VariableNode> arguments = [];
  final List<Token> separators = [];
  final SequenceNode body;

  @override
  void accept(Visitor visitor) => visitor.visitBlockNode(this);
}

class CascadeNode extends ValueNode {
  new();

  final List<MessageNode> messages = [];
  final List<Token> semicolons = [];

  ValueNode get receiver => messages.first.receiver;

  @override
  void accept(Visitor visitor) => visitor.visitCascadeNode(this);
}

abstract class LiteralNode<T> extends ValueNode {
  new(this.value);

  final T value;
}

class LiteralArrayNode<T> extends LiteralNode<List<T>> {
  new(this.values) : super(values.map((value) => value.value).toList());

  final List<LiteralNode<T>> values;

  @override
  void accept(Visitor visitor) => visitor.visitLiteralArrayNode(this);
}

class LiteralValueNode<T> extends LiteralNode<T> {
  new(this.token, T value) : super(value);

  final Token token;

  @override
  void accept(Visitor visitor) => visitor.visitLiteralValueNode(this);
}

class MessageNode extends ValueNode with HasSelector {
  new(this.receiver);

  final ValueNode receiver;
  @override
  final List<ValueNode> arguments = [];

  @override
  void accept(Visitor visitor) => visitor.visitMessageNode(this);
}

class VariableNode extends ValueNode {
  new(this.token);

  final Token token;

  String get name => token.input;

  @override
  void accept(Visitor visitor) => visitor.visitVariableNode(this);
}

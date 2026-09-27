import 'ast.dart';

/// Visitor interface for traversing and processing Smalltalk AST [Node] hierarchies.
///
/// Implements default recursive traversal across all AST nodes. Subclasses
/// can override specific `visit*` methods to perform custom analysis or transformations.
///
/// For example:
///
/// ```dart
/// class VariableCollector extends Visitor {
///   final names = <String>[];
///
///   @override
///   void visitVariableNode(VariableNode node) {
///     names.add(node.name);
///   }
/// }
/// ```
abstract class Visitor {
  /// Visits [node] by dispatching to its `accept` method.
  void visit(Node node) => node.accept(this);

  /// Visits a [MethodNode] and traverses its arguments, pragmas, and body.
  void visitMethodNode(MethodNode node) {
    node.arguments.forEach(visit);
    node.pragmas.forEach(visit);
    visit(node.body);
  }

  /// Visits a [PragmaNode] and traverses its arguments.
  void visitPragmaNode(PragmaNode node) {
    node.arguments.forEach(visit);
  }

  /// Visits a [ReturnNode] and traverses its value expression.
  void visitReturnNode(ReturnNode node) {
    visit(node.value);
  }

  /// Visits a [SequenceNode] and traverses its temporaries and statements.
  void visitSequenceNode(SequenceNode node) {
    node.temporaries.forEach(visit);
    node.statements.forEach(visit);
  }

  /// Visits an [ArrayNode] and traverses its statements.
  void visitArrayNode(ArrayNode node) {
    node.statements.forEach(visit);
  }

  /// Visits an [AssignmentNode] and traverses its variable and value expressions.
  void visitAssignmentNode(AssignmentNode node) {
    visit(node.variable);
    visit(node.value);
  }

  /// Visits a [BlockNode] and traverses its arguments and body.
  void visitBlockNode(BlockNode node) {
    node.arguments.forEach(visit);
    visit(node.body);
  }

  /// Visits a [CascadeNode] and traverses its cascaded messages.
  void visitCascadeNode(CascadeNode node) {
    node.messages.forEach(visit);
  }

  /// Visits a [LiteralArrayNode] and traverses its element values.
  void visitLiteralArrayNode(LiteralArrayNode node) {
    node.values.forEach(visit);
  }

  /// Visits a [LiteralValueNode].
  void visitLiteralValueNode(LiteralValueNode node) {}

  /// Visits a [MessageNode] and traverses its receiver and argument expressions.
  void visitMessageNode(MessageNode node) {
    visit(node.receiver);
    node.arguments.forEach(visit);
  }

  /// Visits a [VariableNode].
  void visitVariableNode(VariableNode node) {}
}

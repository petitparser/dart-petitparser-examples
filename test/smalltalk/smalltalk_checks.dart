import 'package:checks/checks.dart';
import 'package:petitparser_examples/smalltalk.dart';

/// Extension methods for asserting on Smalltalk [LiteralNode] instances.
extension LiteralNodeChecks on Subject<LiteralNode> {
  /// Accesses the literal value.
  Subject<dynamic> get value => has((node) => node.value, 'value');
}

/// Extension methods for asserting on Smalltalk [VariableNode] instances.
extension VariableNodeChecks on Subject<VariableNode> {
  /// Accesses the variable name.
  Subject<String> get name => has((node) => node.name, 'name');
}

/// Extension methods for asserting on Smalltalk [MessageNode] instances.
extension MessageNodeChecks on Subject<MessageNode> {
  /// Accesses the receiver node.
  Subject<Node> get receiver => has((node) => node.receiver, 'receiver');

  /// Accesses the message selector.
  Subject<String> get selector => has((node) => node.selector, 'selector');

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has((node) => node.selectorType, 'selectorType');

  /// Accesses the argument nodes.
  Subject<List<Node>> get arguments =>
      has((node) => node.arguments, 'arguments');
}

/// Extension methods for asserting on Smalltalk [CascadeNode] instances.
extension CascadeNodeChecks on Subject<CascadeNode> {
  /// Accesses the list of cascaded message nodes.
  Subject<List<MessageNode>> get messages =>
      has((node) => node.messages, 'messages');
}

/// Extension methods for asserting on Smalltalk [AssignmentNode] instances.
extension AssignmentNodeChecks on Subject<AssignmentNode> {
  /// Accesses the assigned variable.
  Subject<VariableNode> get variable =>
      has((node) => node.variable, 'variable');

  /// Accesses the assigned value expression.
  Subject<Node> get value => has((node) => node.value, 'value');
}

/// Extension methods for asserting on Smalltalk [ArrayNode] instances.
extension ArrayNodeChecks on Subject<ArrayNode> {
  /// Accesses the statement nodes inside the array.
  Subject<List<Node>> get statements =>
      has((node) => node.statements, 'statements');
}

/// Extension methods for asserting on Smalltalk [SequenceNode] instances.
extension SequenceNodeChecks on Subject<SequenceNode> {
  /// Accesses the temporary variable declarations.
  Subject<List<VariableNode>> get temporaries =>
      has((node) => node.temporaries, 'temporaries');

  /// Accesses the statements in the sequence.
  Subject<List<Node>> get statements =>
      has((node) => node.statements, 'statements');
}

/// Extension methods for asserting on Smalltalk [ReturnNode] instances.
extension ReturnNodeChecks on Subject<ReturnNode> {
  /// Accesses the returned value expression.
  Subject<Node> get value => has((node) => node.value, 'value');
}

/// Extension methods for asserting on Smalltalk [BlockNode] instances.
extension BlockNodeChecks on Subject<BlockNode> {
  /// Accesses the block arguments.
  Subject<List<VariableNode>> get arguments =>
      has((node) => node.arguments, 'arguments');

  /// Accesses the block body sequence.
  Subject<SequenceNode> get body => has((node) => node.body, 'body');
}

/// Extension methods for asserting on Smalltalk [PragmaNode] instances.
extension PragmaNodeChecks on Subject<PragmaNode> {
  /// Accesses the pragma selector.
  Subject<String> get selector => has((node) => node.selector, 'selector');

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has((node) => node.selectorType, 'selectorType');

  /// Accesses the argument nodes.
  Subject<List<Node>> get arguments =>
      has((node) => node.arguments, 'arguments');
}

/// Extension methods for asserting on Smalltalk [MethodNode] instances.
extension MethodNodeChecks on Subject<MethodNode> {
  /// Accesses the method selector.
  Subject<String> get selector => has((node) => node.selector, 'selector');

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has((node) => node.selectorType, 'selectorType');

  /// Accesses the argument variables.
  Subject<List<VariableNode>> get arguments =>
      has((node) => node.arguments, 'arguments');

  /// Accesses the method pragmas.
  Subject<List<PragmaNode>> get pragmas =>
      has((node) => node.pragmas, 'pragmas');

  /// Accesses the method body sequence.
  Subject<SequenceNode> get body => has((node) => node.body, 'body');
}

/// Expects that an object is a [LiteralNode] with [value].
Condition<Object?> isLiteralNode(dynamic value) => (Subject<Object?> it) {
  final valueSubject = it.isA<LiteralNode>().has((node) => node.value, 'value');
  if (value is Map) {
    valueSubject.isA<Map<dynamic, dynamic>>().deepEquals(value);
  } else if (value is Iterable) {
    valueSubject.isA<Iterable<dynamic>>().deepEquals(value);
  } else {
    valueSubject.equals(value);
  }
};

/// Expects that an object is a [VariableNode] with [name].
Condition<Object?> isVariableNode(String name) => (Subject<Object?> it) {
  it.isA<VariableNode>().has((node) => node.name, 'name').equals(name);
};

/// Expects that an object is a [MessageNode] with given structure.
Condition<Object?> isMessageNode(
  Condition<Object?> receiver,
  String selector,
  SelectorType selectorType, {
  List<Condition<Object?>> arguments = const [],
}) => (Subject<Object?> it) {
  final node = it.isA<MessageNode>();
  node.has((n) => n.receiver, 'receiver').which(receiver);
  node.has((n) => n.selector, 'selector').equals(selector);
  node.has((n) => n.selectorType, 'selectorType').equals(selectorType);
  node
      .has((n) => n.arguments, 'arguments')
      .pairwiseMatches(arguments, (c) => c, 'matches');
};

/// Expects that an object is a [CascadeNode] with given message conditions.
Condition<Object?> isCascadeNode(List<Condition<Object?>> messages) =>
    (Subject<Object?> it) {
      it
          .isA<CascadeNode>()
          .has((node) => node.messages, 'messages')
          .pairwiseMatches(messages, (c) => c, 'matches');
    };

/// Expects that an object is an [AssignmentNode] with variable [name] and [value].
Condition<Object?> isAssignmentNode(String name, Condition<Object?> value) =>
    (Subject<Object?> it) {
      final node = it.isA<AssignmentNode>();
      node.has((n) => n.variable, 'variable').which(isVariableNode(name));
      node.has((n) => n.value, 'value').which(value);
    };

/// Expects that an object is an [ArrayNode] with given statement conditions.
Condition<Object?> isArrayNode({
  List<Condition<Object?>> statements = const [],
}) => (Subject<Object?> it) {
  it
      .isA<ArrayNode>()
      .has((node) => node.statements, 'statements')
      .pairwiseMatches(statements, (c) => c, 'matches');
};

/// Expects that an object is a [SequenceNode] with [temporaries] and [statements].
Condition<Object?> isSequenceNode({
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) => (Subject<Object?> it) {
  final node = it.isA<SequenceNode>();
  node
      .has((n) => n.temporaries, 'temporaries')
      .pairwiseMatches(temporaries, (t) => isVariableNode(t), 'temporaries');
  node
      .has((n) => n.statements, 'statements')
      .pairwiseMatches(statements, (c) => c, 'matches');
};

/// Expects that an object is a [ReturnNode] with [value].
Condition<Object?> isReturnNode(Condition<Object?> value) =>
    (Subject<Object?> it) {
      it.isA<ReturnNode>().has((node) => node.value, 'value').which(value);
    };

/// Expects that an object is a [BlockNode] with arguments, temporaries and statements.
Condition<Object?> isBlockNode({
  List<String> arguments = const [],
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) => (Subject<Object?> it) {
  final node = it.isA<BlockNode>();
  node
      .has((n) => n.arguments, 'arguments')
      .pairwiseMatches(arguments, (a) => isVariableNode(a), 'arguments');
  node
      .has((n) => n.body, 'body')
      .which(isSequenceNode(temporaries: temporaries, statements: statements));
};

/// Expects that an object is a [PragmaNode] with given structure.
Condition<Object?> isPragmaNode(
  String selector,
  SelectorType selectorType, {
  List<Condition<Object?>> arguments = const [],
}) => (Subject<Object?> it) {
  final node = it.isA<PragmaNode>();
  node.has((n) => n.selector, 'selector').equals(selector);
  node.has((n) => n.selectorType, 'selectorType').equals(selectorType);
  node
      .has((n) => n.arguments, 'arguments')
      .pairwiseMatches(arguments, (c) => c, 'matches');
};

/// Expects that an object is a [MethodNode] with given structure.
Condition<Object?> isMethodNode(
  String selector,
  SelectorType selectorType, {
  List<String> arguments = const [],
  List<Condition<Object?>> pragmas = const [],
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) => (Subject<Object?> it) {
  final node = it.isA<MethodNode>();
  node.has((n) => n.selector, 'selector').equals(selector);
  node.has((n) => n.selectorType, 'selectorType').equals(selectorType);
  node
      .has((n) => n.arguments, 'arguments')
      .pairwiseMatches(arguments, (a) => isVariableNode(a), 'arguments');
  node
      .has((n) => n.pragmas, 'pragmas')
      .pairwiseMatches(pragmas, (p) => p, 'matches');
  node
      .has((n) => n.body, 'body')
      .which(isSequenceNode(temporaries: temporaries, statements: statements));
};

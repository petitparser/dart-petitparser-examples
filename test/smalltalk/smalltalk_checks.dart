import 'package:checks/checks.dart';
import 'package:petitparser_examples/smalltalk.dart';

/// Extension methods for asserting on Smalltalk [LiteralNode] instances.
extension LiteralNodeChecks on Subject<LiteralNode> {
  /// Accesses the literal value.
  Subject<dynamic> get value => has('value', (node) => node.value);
}

/// Extension methods for asserting on Smalltalk [VariableNode] instances.
extension VariableNodeChecks on Subject<VariableNode> {
  /// Accesses the variable name.
  Subject<String> get name => has('name', (node) => node.name);
}

/// Extension methods for asserting on Smalltalk [MessageNode] instances.
extension MessageNodeChecks on Subject<MessageNode> {
  /// Accesses the receiver node.
  Subject<Node> get receiver => has('receiver', (node) => node.receiver);

  /// Accesses the message selector.
  Subject<String> get selector => has('selector', (node) => node.selector);

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has('selectorType', (node) => node.selectorType);

  /// Accesses the argument nodes.
  Subject<List<Node>> get arguments =>
      has('arguments', (node) => node.arguments);
}

/// Extension methods for asserting on Smalltalk [CascadeNode] instances.
extension CascadeNodeChecks on Subject<CascadeNode> {
  /// Accesses the list of cascaded message nodes.
  Subject<List<MessageNode>> get messages =>
      has('messages', (node) => node.messages);
}

/// Extension methods for asserting on Smalltalk [AssignmentNode] instances.
extension AssignmentNodeChecks on Subject<AssignmentNode> {
  /// Accesses the assigned variable.
  Subject<VariableNode> get variable =>
      has('variable', (node) => node.variable);

  /// Accesses the assigned value expression.
  Subject<Node> get value => has('value', (node) => node.value);
}

/// Extension methods for asserting on Smalltalk [ArrayNode] instances.
extension ArrayNodeChecks on Subject<ArrayNode> {
  /// Accesses the statement nodes inside the array.
  Subject<List<Node>> get statements =>
      has('statements', (node) => node.statements);
}

/// Extension methods for asserting on Smalltalk [SequenceNode] instances.
extension SequenceNodeChecks on Subject<SequenceNode> {
  /// Accesses the temporary variable declarations.
  Subject<List<VariableNode>> get temporaries =>
      has('temporaries', (node) => node.temporaries);

  /// Accesses the statements in the sequence.
  Subject<List<Node>> get statements =>
      has('statements', (node) => node.statements);
}

/// Extension methods for asserting on Smalltalk [ReturnNode] instances.
extension ReturnNodeChecks on Subject<ReturnNode> {
  /// Accesses the returned value expression.
  Subject<Node> get value => has('value', (node) => node.value);
}

/// Extension methods for asserting on Smalltalk [BlockNode] instances.
extension BlockNodeChecks on Subject<BlockNode> {
  /// Accesses the block arguments.
  Subject<List<VariableNode>> get arguments =>
      has('arguments', (node) => node.arguments);

  /// Accesses the block body sequence.
  Subject<SequenceNode> get body => has('body', (node) => node.body);
}

/// Extension methods for asserting on Smalltalk [PragmaNode] instances.
extension PragmaNodeChecks on Subject<PragmaNode> {
  /// Accesses the pragma selector.
  Subject<String> get selector => has('selector', (node) => node.selector);

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has('selectorType', (node) => node.selectorType);

  /// Accesses the argument nodes.
  Subject<List<Node>> get arguments =>
      has('arguments', (node) => node.arguments);
}

/// Extension methods for asserting on Smalltalk [MethodNode] instances.
extension MethodNodeChecks on Subject<MethodNode> {
  /// Accesses the method selector.
  Subject<String> get selector => has('selector', (node) => node.selector);

  /// Accesses the selector type.
  Subject<SelectorType> get selectorType =>
      has('selectorType', (node) => node.selectorType);

  /// Accesses the argument variables.
  Subject<List<VariableNode>> get arguments =>
      has('arguments', (node) => node.arguments);

  /// Accesses the method pragmas.
  Subject<List<PragmaNode>> get pragmas =>
      has('pragmas', (node) => node.pragmas);

  /// Accesses the method body sequence.
  Subject<SequenceNode> get body => has('body', (node) => node.body);
}

/// Expects that an object is a [LiteralNode] with [value].
Condition<Object?> isLiteralNode(dynamic value) {
  final it = Condition.it<Object?>();
  final valueSubject = it.isA<LiteralNode>().has('value', (node) => node.value);
  if (value is Map) {
    valueSubject.isA<Map<dynamic, dynamic>>().deepEquals(value);
  } else if (value is Iterable) {
    valueSubject.isA<Iterable<dynamic>>().deepEquals(value);
  } else {
    valueSubject.equals(value);
  }
  return it;
}

/// Expects that an object is a [VariableNode] with [name].
Condition<Object?> isVariableNode(String name) {
  final it = Condition.it<Object?>();
  it.isA<VariableNode>().has('name', (node) => node.name).equals(name);
  return it;
}

/// Expects that an object is a [MessageNode] with given structure.
Condition<Object?> isMessageNode(
  Condition<Object?> receiver,
  String selector,
  SelectorType selectorType, {
  List<Condition<Object?>> arguments = const [],
}) {
  final it = Condition.it<Object?>();
  final node = it.isA<MessageNode>();
  node.has<Object?>('receiver', (n) => n.receiver).which(receiver);
  node.has('selector', (n) => n.selector).equals(selector);
  node.has('selectorType', (n) => n.selectorType).equals(selectorType);
  node
      .has<Iterable<Object?>>('arguments', (n) => n.arguments)
      .pairwiseMatches(arguments, (c) => c, 'matches');
  return it;
}

/// Expects that an object is a [CascadeNode] with given message conditions.
Condition<Object?> isCascadeNode(List<Condition<Object?>> messages) {
  final it = Condition.it<Object?>();
  it
      .isA<CascadeNode>()
      .has<Iterable<Object?>>('messages', (node) => node.messages)
      .pairwiseMatches(messages, (c) => c, 'matches');
  return it;
}

/// Expects that an object is an [AssignmentNode] with variable [name] and [value].
Condition<Object?> isAssignmentNode(String name, Condition<Object?> value) {
  final it = Condition.it<Object?>();
  final node = it.isA<AssignmentNode>();
  node.has<Object?>('variable', (n) => n.variable).which(isVariableNode(name));
  node.has<Object?>('value', (n) => n.value).which(value);
  return it;
}

/// Expects that an object is an [ArrayNode] with given statement conditions.
Condition<Object?> isArrayNode({
  List<Condition<Object?>> statements = const [],
}) {
  final it = Condition.it<Object?>();
  it
      .isA<ArrayNode>()
      .has<Iterable<Object?>>('statements', (node) => node.statements)
      .pairwiseMatches(statements, (c) => c, 'matches');
  return it;
}

/// Expects that an object is a [SequenceNode] with [temporaries] and [statements].
Condition<Object?> isSequenceNode({
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) {
  final it = Condition.it<Object?>();
  final node = it.isA<SequenceNode>();
  node
      .has<Iterable<Object?>>('temporaries', (n) => n.temporaries)
      .pairwiseMatches(temporaries, (t) => isVariableNode(t), 'temporaries');
  node
      .has<Iterable<Object?>>('statements', (n) => n.statements)
      .pairwiseMatches(statements, (c) => c, 'matches');
  return it;
}

/// Expects that an object is a [ReturnNode] with [value].
Condition<Object?> isReturnNode(Condition<Object?> value) {
  final it = Condition.it<Object?>();
  it.isA<ReturnNode>().has<Object?>('value', (node) => node.value).which(value);
  return it;
}

/// Expects that an object is a [BlockNode] with arguments, temporaries and statements.
Condition<Object?> isBlockNode({
  List<String> arguments = const [],
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) {
  final it = Condition.it<Object?>();
  final node = it.isA<BlockNode>();
  node
      .has<Iterable<Object?>>('arguments', (n) => n.arguments)
      .pairwiseMatches(arguments, (a) => isVariableNode(a), 'arguments');
  node
      .has<Object?>('body', (n) => n.body)
      .which(isSequenceNode(temporaries: temporaries, statements: statements));
  return it;
}

/// Expects that an object is a [PragmaNode] with given structure.
Condition<Object?> isPragmaNode(
  String selector,
  SelectorType selectorType, {
  List<Condition<Object?>> arguments = const [],
}) {
  final it = Condition.it<Object?>();
  final node = it.isA<PragmaNode>();
  node.has('selector', (n) => n.selector).equals(selector);
  node.has('selectorType', (n) => n.selectorType).equals(selectorType);
  node
      .has<Iterable<Object?>>('arguments', (n) => n.arguments)
      .pairwiseMatches(arguments, (c) => c, 'matches');
  return it;
}

/// Expects that an object is a [MethodNode] with given structure.
Condition<Object?> isMethodNode(
  String selector,
  SelectorType selectorType, {
  List<String> arguments = const [],
  List<Condition<Object?>> pragmas = const [],
  List<String> temporaries = const [],
  List<Condition<Object?>> statements = const [],
}) {
  final it = Condition.it<Object?>();
  final node = it.isA<MethodNode>();
  node.has('selector', (n) => n.selector).equals(selector);
  node.has('selectorType', (n) => n.selectorType).equals(selectorType);
  node
      .has<Iterable<Object?>>('arguments', (n) => n.arguments)
      .pairwiseMatches(arguments, (a) => isVariableNode(a), 'arguments');
  node
      .has<Iterable<Object?>>('pragmas', (n) => n.pragmas)
      .pairwiseMatches(pragmas, (p) => p, 'matches');
  node
      .has<Object?>('body', (n) => n.body)
      .which(isSequenceNode(temporaries: temporaries, statements: statements));
  return it;
}

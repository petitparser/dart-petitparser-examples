import 'package:collection/collection.dart';

import 'nfa.dart';
import 'parser.dart';

abstract class Node {
  static Node fromString(String regexp) => nodeParser.parse(regexp).value;

  Node star() => repeat(0, null);

  Node plus() => repeat(1, null);

  Node optional() => repeat(0, 1);

  Node repeat(int min, int? max) => RepeatNode(this, min, max);

  Node concat(Node other) {
    final self = this;
    return ConcatNode([
      if (self is ConcatNode) ...self.children else self,
      if (other is ConcatNode) ...other.children else other,
    ]);
  }

  Node or(Node other) {
    final self = this;
    return AlternateNode([
      if (self is AlternateNode) ...self.children else self,
      if (other is AlternateNode) ...other.children else other,
    ]);
  }

  StateRange toNFA();
}

class EmptyNode extends Node {
  @override
  StateRange toNFA() => StateRange.epsilon();

  @override
  String toString() => 'EmptyNode()';

  @override
  bool operator ==(Object other) => other is EmptyNode;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LiteralNode extends Node {
  LiteralNode(String literal) : codePoint = literal.runes.single;

  final int codePoint;

  @override
  StateRange toNFA() => StateRange.literal(codePoint);

  @override
  String toString() => 'LiteralNode(${String.fromCharCode(codePoint)})';

  @override
  bool operator ==(Object other) =>
      other is LiteralNode && other.codePoint == codePoint;

  @override
  int get hashCode => Object.hash(runtimeType, codePoint);
}

class ConcatNode extends Node {
  ConcatNode(this.children);

  final List<Node> children;

  @override
  StateRange toNFA() =>
      StateRange.concat(children.map((child) => child.toNFA()));

  @override
  String toString() => 'ConcatNode($children)';

  @override
  bool operator ==(Object other) =>
      other is ConcatNode && nodeListEquality.equals(other.children, children);

  @override
  int get hashCode => Object.hash(runtimeType, nodeListEquality.hash(children));
}

class AlternateNode extends Node {
  AlternateNode(this.children);

  final List<Node> children;

  @override
  StateRange toNFA() =>
      StateRange.union(children.map((child) => child.toNFA()));

  @override
  String toString() => 'AlternateNode($children)';

  @override
  bool operator ==(Object other) =>
      other is AlternateNode &&
      nodeListEquality.equals(other.children, children);

  @override
  int get hashCode => Object.hash(runtimeType, nodeListEquality.hash(children));
}

class RepeatNode extends Node {
  RepeatNode(this.child, this.min, this.max);

  final Node child;
  final int min;
  final int? max;

  @override
  StateRange toNFA() => StateRange.repeat(child.toNFA(), min, max);

  @override
  String toString() => 'RepeatNode($child, $min, $max)';

  @override
  bool operator ==(Object other) =>
      other is RepeatNode &&
      other.child == child &&
      other.min == min &&
      other.max == max;

  @override
  int get hashCode => Object.hash(runtimeType, child, min, max);
}

const nodeListEquality = ListEquality<Node>();

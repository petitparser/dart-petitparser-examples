import 'nfa.dart';
import 'parser.dart';

abstract class Node {
  static Node fromString(String regexp) => nodeParser.parse(regexp).value;

  Nfa toNfa();
}

class EmptyNode extends Node {
  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.epsilons.add(end);
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'EmptyNode()';

  @override
  bool operator ==(Object other) => other is EmptyNode;

  @override
  int get hashCode => runtimeType.hashCode;
}

class DotNode extends Node {
  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.dots.add(end);
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'DotNode()';

  @override
  bool operator ==(Object other) => other is DotNode;

  @override
  int get hashCode => runtimeType.hashCode;
}

class LiteralNode extends Node {
  LiteralNode(String literal) : codePoint = literal.runes.single;

  final int codePoint;

  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.transitions[codePoint] = end;
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'LiteralNode(${String.fromCharCode(codePoint)})';

  @override
  bool operator ==(Object other) =>
      other is LiteralNode && other.codePoint == codePoint;

  @override
  int get hashCode => Object.hash(runtimeType, codePoint);
}

class ConcatenationNode extends Node {
  ConcatenationNode(this.left, this.right);

  final Node left;
  final Node right;

  @override
  Nfa toNfa() {
    final leftNfa = left.toNfa();
    final rightNfa = right.toNfa();
    leftNfa.end.epsilons.add(rightNfa.start);
    leftNfa.end.isEnd = false;
    return Nfa(start: leftNfa.start, end: rightNfa.end);
  }

  @override
  String toString() => 'ConcatenationNode($left, $right)';

  @override
  bool operator ==(Object other) =>
      other is ConcatenationNode && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(runtimeType, left, right);
}

class AlternationNode extends Node {
  AlternationNode(this.left, this.right);

  final Node left;
  final Node right;

  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);

    final leftNfa = left.toNfa();
    start.epsilons.add(leftNfa.start);
    leftNfa.end.epsilons.add(end);
    leftNfa.end.isEnd = false;

    final rightNfa = right.toNfa();
    start.epsilons.add(rightNfa.start);
    rightNfa.end.epsilons.add(end);
    rightNfa.end.isEnd = false;

    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'AlternationNode($left, $right)';

  @override
  bool operator ==(Object other) =>
      other is AlternationNode && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(runtimeType, left, right);
}

class IntersectionNode extends Node {
  IntersectionNode(this.left, this.right);

  final Node left;
  final Node right;

  @override
  Nfa toNfa() => throw UnsupportedError(toString());

  @override
  String toString() => 'IntersectionNode($left, $right)';

  @override
  bool operator ==(Object other) =>
      other is IntersectionNode && other.left == left && other.right == right;

  @override
  int get hashCode => Object.hash(runtimeType, left, right);
}

class QuantificationNode extends Node {
  QuantificationNode(this.child, this.min, [this.max]) {
    RangeError.checkNotNegative(min, 'min', 'Minimum must be non-negative');
    if (max != null && max! < min) {
      throw RangeError.value(
        max!,
        'max',
        'Maximum must be greater than or equal to minimum ($min)',
      );
    }
  }

  final Node child;
  final int min;
  final int? max;

  @override
  Nfa toNfa() {
    if (min == 0 && max == null) {
      final start = NfaState(isEnd: false);
      final end = NfaState(isEnd: true);
      final childNfa = child.toNfa();
      start.epsilons.add(end);
      start.epsilons.add(childNfa.start);
      childNfa.end.epsilons.add(end);
      childNfa.end.epsilons.add(childNfa.start);
      childNfa.end.isEnd = false;
      return Nfa(start: start, end: end);
    } else if (min == 0 && max == 1) {
      final start = NfaState(isEnd: false);
      final end = NfaState(isEnd: true);
      final childNfa = child.toNfa();
      start.epsilons.add(end);
      start.epsilons.add(childNfa.start);
      childNfa.end.epsilons.add(end);
      childNfa.end.isEnd = false;
      return Nfa(start: start, end: end);
    }
    final nfas = <Nfa>[];
    for (var i = 0; i < min; i++) {
      nfas.add(child.toNfa());
    }
    if (max == null) {
      nfas.add(QuantificationNode(child, 0, null).toNfa());
    } else {
      for (var i = 0; i < max! - min; i++) {
        nfas.add(QuantificationNode(child, 0, 1).toNfa());
      }
    }
    if (nfas.isEmpty) {
      final start = NfaState(isEnd: false);
      final end = NfaState(isEnd: true);
      start.epsilons.add(end);
      return Nfa(start: start, end: end);
    }
    for (var i = 0; i < nfas.length - 1; i++) {
      final current = nfas[i];
      final next = nfas[i + 1];
      current.end.epsilons.add(next.start);
      current.end.isEnd = false;
    }
    return Nfa(start: nfas.first.start, end: nfas.last.end);
  }

  @override
  String toString() => 'QuantifierNode($child, $min, $max)';

  @override
  bool operator ==(Object other) =>
      other is QuantificationNode &&
      other.child == child &&
      other.min == min &&
      other.max == max;

  @override
  int get hashCode => Object.hash(runtimeType, child, min, max);
}

class ComplementNode extends Node {
  ComplementNode(this.child);

  final Node child;

  @override
  Nfa toNfa() => throw UnsupportedError(toString());

  @override
  String toString() => 'ComplementNode($child)';

  @override
  bool operator ==(Object other) =>
      other is ComplementNode && other.child == child;

  @override
  int get hashCode => Object.hash(runtimeType, child);
}

class StartAnchorNode extends Node {
  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.startAnchors.add(end);
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'StartAnchorNode()';

  @override
  bool operator ==(Object other) => other is StartAnchorNode;

  @override
  int get hashCode => runtimeType.hashCode;
}

class EndAnchorNode extends Node {
  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.endAnchors.add(end);
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'EndAnchorNode()';

  @override
  bool operator ==(Object other) => other is EndAnchorNode;

  @override
  int get hashCode => runtimeType.hashCode;
}

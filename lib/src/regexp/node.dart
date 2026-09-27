import 'nfa.dart';
import 'parser.dart';

/// Base class for all regular expression Abstract Syntax Tree (AST) nodes.
abstract class Node {
  /// Const constructor for subclasses.
  const new();

  /// Parses a regular expression string into a [Node] AST.
  ///
  /// For example:
  ///
  /// ```dart
  /// final node = Node.fromString('a*b+');
  /// print(node);
  /// ```
  static Node fromString(String regexp) => nodeParser.parse(regexp).value;

  /// Compiles this AST node into a nondeterministic finite automaton ([Nfa]).
  Nfa toNfa();
}

/// An AST node matching the empty string.
class EmptyNode extends Node {
  /// Creates an empty regular expression node.
  const new();

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

/// An AST node matching any single character (the `.` wildcard).
class DotNode extends Node {
  /// Creates a wildcard dot node.
  const new();

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

/// An AST node matching a single literal character by its Unicode code point.
class LiteralNode extends Node {
  /// Creates a literal node matching the single character [literal].
  new(String literal) : codePoint = literal.codeUnits.single;

  /// The Unicode code point to match.
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

/// An AST node matching any character within the inclusive range between [startCodePoint] and [endCodePoint].
class RangeNode extends Node {
  /// Creates a character range node from [start] to [end].
  ///
  /// Throws an [ArgumentError] if [start] has a higher code point than [end].
  new(String start, String end)
    : startCodePoint = start.codeUnits.single,
      endCodePoint = end.codeUnits.single {
    if (startCodePoint > endCodePoint) {
      throw ArgumentError.value(
        '$start-$end',
        'start-end',
        'Start must be less than or equal to end',
      );
    }
  }

  /// The inclusive lower-bound Unicode code point.
  final int startCodePoint;

  /// The inclusive upper-bound Unicode code point.
  final int endCodePoint;

  @override
  Nfa toNfa() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    for (var i = startCodePoint; i <= endCodePoint; i++) {
      start.transitions[i] = end;
    }
    return Nfa(start: start, end: end);
  }

  @override
  String toString() =>
      'RangeNode(${String.fromCharCode(startCodePoint)}-${String.fromCharCode(endCodePoint)})';

  @override
  bool operator ==(Object other) =>
      other is RangeNode &&
      other.startCodePoint == startCodePoint &&
      other.endCodePoint == endCodePoint;

  @override
  int get hashCode => Object.hash(runtimeType, startCodePoint, endCodePoint);
}

/// An AST node matching [left] followed immediately by [right].
class ConcatenationNode extends Node {
  /// Creates a concatenation of [left] and [right] nodes.
  new(this.left, this.right);

  /// The first node in the sequence.
  final Node left;

  /// The second node in the sequence.
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

/// An AST node matching either [left] or [right] (the `|` operator).
class AlternationNode extends Node {
  /// Creates an alternation between [left] and [right].
  new(this.left, this.right);

  /// The alternative branch on the left.
  final Node left;

  /// The alternative branch on the right.
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

/// An AST node matching the intersection of [left] and [right] (the `&` operator).
///
/// Note: Compilation to an [Nfa] is currently unsupported for intersection nodes.
class IntersectionNode extends Node {
  /// Creates an intersection of [left] and [right].
  new(this.left, this.right);

  /// The first intersecting expression.
  final Node left;

  /// The second intersecting expression.
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

/// An AST node repeating [child] between [min] and [max] times.
///
/// If [max] is `null`, the repetition is unbounded (such as `*` or `+`).
class QuantificationNode extends Node {
  /// Creates a quantification of [child] with [min] and optional [max] bounds.
  ///
  /// Throws a [RangeError] if [min] is negative or if [max] is less than [min].
  new(this.child, this.min, [this.max]) {
    RangeError.checkNotNegative(min, 'min', 'Minimum must be non-negative');
    final max = this.max;
    if (max != null && max < min) {
      throw RangeError.value(
        max,
        'max',
        'Maximum must be greater than or equal to minimum ($min)',
      );
    }
  }

  /// The child node being quantified.
  final Node child;

  /// The minimum number of repetitions.
  final int min;

  /// The optional maximum number of repetitions, or `null` if unbounded.
  final int? max;

  @override
  Nfa toNfa() {
    final max = this.max;
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
      for (var i = 0; i < max - min; i++) {
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

/// An AST node matching the complement of [child] (inverting matches).
class ComplementNode extends Node {
  /// Creates a complement node inverting matches of [child].
  new(this.child);

  /// The child node whose matches are complemented.
  final Node child;

  @override
  Nfa toNfa() {
    final childNfa = child.toNfa();
    final accepted = _collectAcceptedCodePoints(childNfa);

    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    for (var i = 0; i <= 0xffff; i++) {
      if (!accepted.contains(i)) {
        start.transitions[i] = end;
      }
    }
    return Nfa(start: start, end: end);
  }

  @override
  String toString() => 'ComplementNode($child)';

  @override
  bool operator ==(Object other) =>
      other is ComplementNode && other.child == child;

  @override
  int get hashCode => Object.hash(runtimeType, child);
}

/// An AST node matching the start of input (the `^` anchor).
class StartAnchorNode extends Node {
  /// Creates a start anchor node.
  const new();

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

/// An AST node matching the end of input (the `$` anchor).
class EndAnchorNode extends Node {
  /// Creates an end anchor node.
  const new();

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

Set<int> _collectAcceptedCodePoints(Nfa childNfa) {
  final accepted = <int>{};
  final fromStart = <NfaState>{};
  void traverseStart(NfaState state) {
    if (!fromStart.add(state)) return;
    for (final next in state.epsilons) {
      traverseStart(next);
    }
  }

  traverseStart(childNfa.start);
  final reached = <NfaState, bool>{};
  bool reachesEnd(NfaState state, Set<NfaState> visited) {
    if (state == childNfa.end || state.isEnd) return true;
    final cached = reached[state];
    if (cached != null) return cached;
    if (!visited.add(state)) return false;
    for (final next in state.epsilons) {
      if (reachesEnd(next, visited)) {
        reached[state] = true;
        return true;
      }
    }
    reached[state] = false;
    return false;
  }

  for (final s in fromStart) {
    s.transitions.forEach((c, nextState) {
      if (reachesEnd(nextState, {})) {
        accepted.add(c);
      }
    });
  }
  return accepted;
}

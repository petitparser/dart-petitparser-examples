import 'node.dart';
import 'pattern.dart';

/// A nondeterministic finite automaton (NFA) for executing regular expression patterns.
///
/// Implements [RegexpPattern] to match strings according to Thompson's construction.
///
/// For example:
///
/// ```dart
/// final nfa = Nfa.fromString('a*b+');
/// print(nfa.matchAsPrefix('aaabb')?.group(0)); // 'aaabb'
/// ```
class Nfa extends RegexpPattern {
  /// Creates an NFA with given [start] and [end] states.
  new({required this.start, required this.end});

  /// Compiles a regular expression string into an [Nfa].
  factory fromString(String regexp) => Node.fromString(regexp).toNfa();

  /// The entry state of the NFA.
  final NfaState start;

  /// The accepting terminal state of the NFA.
  final NfaState end;

  @override
  int tryMatch(String input, int start, int end) {
    var result = -1;
    var currentStates = <NfaState>{};
    var nextStates = <NfaState>{};
    _addStates(this.start, currentStates, start, end);
    if (currentStates.any((state) => state.isEnd)) {
      result = start;
    }
    for (var i = start; i < end; i++) {
      final value = input.codeUnitAt(i);
      nextStates.clear();
      for (final state in currentStates) {
        final nextState = state.transitions[value];
        if (nextState != null) {
          _addStates(nextState, nextStates, i + 1, end);
        }
        for (final nextState in state.dots) {
          _addStates(nextState, nextStates, i + 1, end);
        }
      }
      if (nextStates.isEmpty) {
        break;
      }
      (currentStates, nextStates) = (nextStates, currentStates);
      if (currentStates.any((state) => state.isEnd)) {
        result = i + 1;
      }
    }
    return result;
  }

  void _addStates(NfaState state, Set<NfaState> states, int index, int end) {
    if (!states.add(state)) return;
    for (final other in state.epsilons) {
      _addStates(other, states, index, end);
    }
    if (index == 0) {
      for (final other in state.startAnchors) {
        _addStates(other, states, index, end);
      }
    }
    if (index == end) {
      for (final other in state.endAnchors) {
        _addStates(other, states, index, end);
      }
    }
  }
}

/// A state within a nondeterministic finite automaton ([Nfa]).
class NfaState {
  /// Creates an NFA state, marked as accepting when [isEnd] is `true`.
  new({required this.isEnd});

  /// Whether this state is an accepting (terminal) state.
  bool isEnd;

  /// Map of character code points to subsequent transition states.
  final Map<int, NfaState> transitions = {};

  /// Epsilon (empty string) transition states.
  final List<NfaState> epsilons = [];

  /// Wildcard (any character) transition states.
  final List<NfaState> dots = [];

  /// Start-of-input anchor transition states.
  final List<NfaState> startAnchors = [];

  /// End-of-input anchor transition states.
  final List<NfaState> endAnchors = [];
}

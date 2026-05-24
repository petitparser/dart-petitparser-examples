import 'node.dart';
import 'pattern.dart';

/// Nondeterministic Finite Automaton
class Nfa extends RegexpPattern {
  Nfa({required this.start, required this.end});

  factory Nfa.fromString(String regexp) => Node.fromString(regexp).toNfa();

  final NfaState start;
  final NfaState end;

  @override
  int tryMatch(String input, int start, int end) {
    var result = -1;
    var currentStates = <NfaState>{};
    _addStates(this.start, currentStates);
    if (currentStates.any((state) => state.isEnd)) {
      result = start;
    }
    for (var i = start; i < end; i++) {
      final value = input.codeUnitAt(i);
      final nextStates = <NfaState>{};
      for (final state in currentStates) {
        final nextState = state.transitions[value];
        if (nextState != null) {
          _addStates(nextState, nextStates);
        }
        for (final nextState in state.dots) {
          _addStates(nextState, nextStates);
        }
      }
      if (nextStates.isEmpty) {
        break;
      }
      currentStates = nextStates;
      if (currentStates.any((state) => state.isEnd)) {
        result = i + 1;
      }
    }
    return result;
  }

  void _addStates(NfaState state, Set<NfaState> states) {
    if (!states.add(state)) return;
    for (final other in state.epsilons) {
      _addStates(other, states);
    }
  }
}

class NfaState {
  NfaState({required this.isEnd});

  bool isEnd;
  final Map<int, NfaState> transitions = {};
  final List<NfaState> epsilons = [];
  final List<NfaState> dots = [];
}

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

class NfaState {
  NfaState({required this.isEnd});

  bool isEnd;
  final Map<int, NfaState> transitions = {};
  final List<NfaState> epsilons = [];
  final List<NfaState> dots = [];
  final List<NfaState> startAnchors = [];
  final List<NfaState> endAnchors = [];
}

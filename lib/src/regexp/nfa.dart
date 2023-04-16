/// Nondeterministic Finite Automaton
class Nfa {
  Nfa({required this.start, required this.end});

  factory Nfa.epsilon() {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.epsilons.add(end);
    return Nfa(start: start, end: end);
  }

  factory Nfa.literal(int value) {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    start.transitions[value] = end;
    return Nfa(start: start, end: end);
  }

  factory Nfa.concat(Iterable<Nfa> ranges) {
    final sequence = ranges.toList();
    for (var i = 0; i < sequence.length - 1; i++) {
      final prev = sequence[i].end;
      final next = sequence[i + 1].start;
      prev.epsilons.add(next);
      prev.isEnd = false;
    }
    sequence.last.end.isEnd = true;
    return Nfa(start: sequence.first.start, end: sequence.last.end);
  }

  factory Nfa.union(Iterable<Nfa> ranges) {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    for (final range in ranges) {
      start.epsilons.add(range.start);
      range.end.epsilons.add(end);
      range.end.isEnd = false;
    }
    return Nfa(start: start, end: end);
  }

  factory Nfa.repeat(Nfa other, int min, int? max) {
    final start = NfaState(isEnd: false);
    final end = NfaState(isEnd: true);
    if (min == 0 && max == null) {
      start.epsilons.add(end);
      start.epsilons.add(other.start);
      other.end.epsilons.add(end);
      other.end.epsilons.add(other.start);
      other.end.isEnd = false;
    } else if (min == 0 && max == 1) {
      start.epsilons.add(end);
      start.epsilons.add(other.start);
      other.end.epsilons.add(end);
      other.end.isEnd = false;
    } else if (min == 1 && max == null) {
      start.epsilons.add(other.start);
      other.end.epsilons.add(end);
      other.end.epsilons.add(other.start);
      other.end.isEnd = false;
    } else {
      throw StateError('Unsupported repeat($min, $max)');
    }
    return Nfa(start: start, end: end);
  }

  final NfaState start;
  final NfaState end;

  bool match(String input) {
    var currentStates = <NfaState>{};
    _addStates(start, currentStates);
    for (final value in input.runes) {
      final nextStates = <NfaState>{};
      for (final state in currentStates) {
        final nextState = state.transitions[value];
        if (nextState != null) {
          _addStates(nextState, nextStates);
        }
      }
      if (nextStates.isEmpty) return false;
      currentStates = nextStates;
    }
    return currentStates.any((state) => state.isEnd);
  }

  void _addStates(NfaState state, Set<NfaState> states) {
    if (!states.add(state)) return;
    for (var other in state.epsilons) {
      _addStates(other, states);
    }
  }
}

class NfaState {
  NfaState({required this.isEnd});

  bool isEnd;

  final Map<int, NfaState> transitions = {};

  final List<NfaState> epsilons = [];
}

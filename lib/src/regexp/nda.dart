class State {
  State({required this.isEnd});

  bool isEnd;

  final Map<int, State> transitions = {};

  final List<State> epsilons = [];
}

class StateRange {
  StateRange({required this.start, required this.end});

  factory StateRange.epsilon() {
    final start = State(isEnd: false);
    final end = State(isEnd: true);
    start.epsilons.add(end);
    return StateRange(start: start, end: end);
  }

  factory StateRange.literal(int value) {
    final start = State(isEnd: false);
    final end = State(isEnd: true);
    start.transitions[value] = end;
    return StateRange(start: start, end: end);
  }

  factory StateRange.concat(Iterable<StateRange> ranges) {
    final sequence = ranges.toList();
    for (var i = 0; i < sequence.length - 1; i++) {
      final prev = sequence[i].end;
      final next = sequence[i + 1].start;
      prev.epsilons.add(next);
      next.isEnd = i < sequence.length - 2;
    }
    return StateRange(start: sequence.first.start, end: sequence.last.end);
  }

  factory StateRange.union(Iterable<StateRange> ranges) {
    final start = State(isEnd: false);
    final end = State(isEnd: true);
    for (final range in ranges) {
      start.epsilons.add(range.start);
      range.end.epsilons.add(end);
      range.end.isEnd = false;
    }
    return StateRange(start: start, end: end);
  }

  factory StateRange.repeat(StateRange other, int min, int? max) {
    final start = State(isEnd: false);
    final end = State(isEnd: true);
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
    return StateRange(start: start, end: end);
  }

  final State start;
  final State end;
}

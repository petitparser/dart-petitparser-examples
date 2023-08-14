import 'package:meta/meta.dart';

abstract class RegexpPattern implements Pattern {
  // TODO: make it correctly match sub-strings
  @override
  Match? matchAsPrefix(String input, [int start = 0]) =>
      tryMatch(input.substring(start))
          ? RegexpMatch(this, input, start, input.length)
          : null;

  @override
  Iterable<Match> allMatches(String input, [int start = 0]) sync* {
    for (var i = start; i < input.length; i++) {
      final match = matchAsPrefix(input, i);
      if (match != null) yield match;
    }
  }

  @internal
  bool tryMatch(String input);
}

class RegexpMatch implements Match {
  RegexpMatch(this.pattern, this.input, this.start, this.end);

  @override
  final Pattern pattern;

  @override
  final String input;

  @override
  final int start;

  @override
  final int end;

  @override
  int get groupCount => 0;

  @override
  String? group(int group) => this[group];

  @override
  String? operator [](int group) =>
      group == 0 ? input.substring(start, end) : null;

  @override
  List<String?> groups(List<int> groupIndices) =>
      groupIndices.map(group).toList(growable: false);
}

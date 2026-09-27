import 'package:meta/meta.dart';

/// A [Pattern] implementation powered by a regular expression engine.
///
/// Subclasses provide the matching logic through [tryMatch].
abstract class RegexpPattern implements Pattern {
  @override
  Iterable<Match> allMatches(String input, [int start = 0]) sync* {
    while (start <= input.length) {
      final match = matchAsPrefix(input, start);
      if (match == null) {
        start++;
      } else {
        yield match;
        start = match.start < match.end ? match.end : match.start + 1;
      }
    }
  }

  @override
  Match? matchAsPrefix(String input, [int start = 0]) {
    RangeError.checkValueInInterval(start, 0, input.length, 'start');
    final end = tryMatch(input, start, input.length);
    if (end >= start) {
      return RegexpMatch(this, input, start, end);
    }
    return null;
  }

  /// Returns the end index (exclusive) of the longest prefix of [input] matched
  /// by this pattern, or `-1` if no prefix of [input] matches.
  @internal
  int tryMatch(String input, int start, int end);
}

/// A [Match] produced by a [RegexpPattern].
class RegexpMatch implements Match {
  /// Creates a match for [pattern] against [input] spanning from [start] to [end].
  new(this.pattern, this.input, this.start, this.end);

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

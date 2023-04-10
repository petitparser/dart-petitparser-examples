import 'package:meta/meta.dart';

abstract class Matcher {
  /// Activate this matcher's *start* state.
  @internal
  bool start();

  /// Process a character from the string we're matching against.
  @internal
  bool push(int value);

  /// Test if a string matches.
  bool matches(String text) =>
      text.runes.fold(start(), (_, char) => push(char));
}

/// The empty regex.
class Empty extends Matcher {
  bool matched = false;

  @override
  bool start() => matched = true;

  @override
  bool push(int value) => matched = false;
}

/// Matches any one character.
class Dot extends Matcher {
  bool started = false;
  bool matched = false;

  @override
  bool start() {
    started = true;
    return matched;
  }

  @override
  bool push(int value) {
    matched = started;
    started = false;
    return matched;
  }
}

/// Matches a literal character.
class Literal extends Matcher {
  Literal(String literal) : codePoint = literal.runes.single;

  final int codePoint;

  bool started = false;
  bool matched = false;

  @override
  bool start() {
    started = true;
    return matched;
  }

  @override
  bool push(int value) {
    matched = started && codePoint == value;
    started = false;
    return matched;
  }
}

/// Matches zero or more repetitions.
class Star extends Matcher {
  Star(this.other);

  final Matcher other;

  @override
  bool start() => other.start() || true;

  @override
  bool push(int value) => other.push(value) && start();
}

/// Matches two patterns in a row.
class Concat extends Matcher {
  Concat(this.left, this.right);

  final Matcher left;
  final Matcher right;
  bool rightStarted = false;

  @override
  bool start() {
    if (left.start()) {
      rightStarted = true;
      return right.start();
    } else {
      return false;
    }
  }

  @override
  bool push(int value) {
    var result = false;
    if (rightStarted) {
      result |= right.push(value);
    }
    if (left.push(value)) {
      rightStarted = true;
      result |= right.start();
    }
    return result;
  }
}

/// Matches either of two patterns.
class Or extends Matcher {
  Or(this.one, this.two);

  final Matcher one;
  final Matcher two;

  @override
  bool start() => one.start() | two.start();

  @override
  bool push(int value) => one.push(value) | two.push(value);
}

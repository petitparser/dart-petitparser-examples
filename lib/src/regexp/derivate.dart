abstract class State {
  /// If a link does not match the contents of the matcher's input, answer
  /// false. Otherwise, let the next matcher in the chain match.
  bool match(String input, int position);

  /// Propagate this message along the chain of links. Point `next' reference
  /// of the last link to [link]. If the chain is already terminated, blow up.
  void pointTailTo(Link link);

  /// Propagate this message along the chain of links, and make [terminator]
  /// the `next' link of the last link in the chain. If the chain is already
  /// terminated with the same terminator, do not blow up.
  void terminateWith(Terminator terminator);
}

class Link implements State {
  State? next;

  @override
  bool match(String input, int position) => next!.match(input, position);

  @override
  void pointTailTo(Link link) {
    if (next == null) {
      next = link;
    } else {
      next!.pointTailTo(link);
    }
  }

  @override
  void terminateWith(Terminator terminator) {
    if (next == null) {
      next = terminator;
    } else {
      next!.terminateWith(terminator);
    }
  }
}

class Branch extends Link {
  Branch(this.loopback);

  Link? alternative;
  bool loopback;

  @override
  bool match(String input, int position) =>
      next!.match(input, position) ||
      (alternative != null && alternative!.match(input, position));

  @override
  void pointTailTo(Link link) {
    if (loopback) {
      if (alternative == null) {
        alternative = link;
      } else {
        alternative!.pointTailTo(link);
      }
    } else {
      super.pointTailTo(link);
    }
  }

  @override
  void terminateWith(Terminator terminator) {
    if (next == null) {
      next = terminator;
    } else {
      next!.terminateWith(terminator);
    }
  }
}

class Terminator implements State {
  @override
  bool match(String input, int position) => true;

  @override
  void pointTailTo(Link link) => throw StateError(
      'internal matcher build error - redirecting terminator tail');

  @override
  void terminateWith(Terminator terminator) {
    if (terminator != this) {
      throw StateError('internal matcher build error - wrong terminator');
    }
  }
}

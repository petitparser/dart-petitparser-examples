import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';

/// A stateful set of parsers to handle indentation-based grammars with support
/// for nested blocks, multi-level dedents, and blank/comment line skipping.
@experimental
class PythonIndent {
  new({Parser<String>? parser, Parser<void>? blankOrComment, String? message})
    : parser = parser ?? pattern(' \t'),
      blankOrComment =
          blankOrComment ??
          (pattern(' \t').star() &
                  (char('#') & pattern('^\r\n').star()).optional() &
                  Token.newlineParser())
              .flatten(),
      message = message ?? 'indentation expected';

  /// The parser used to read indentation characters (spaces/tabs).
  final Parser<String> parser;

  /// Parser for full lines that are empty or contain only comments.
  final Parser<void> blankOrComment;

  /// Error message when indentation fails.
  final String message;

  /// Stack of outer indentation strings.
  @internal
  final List<String> stack = [];

  /// The currently active indentation string.
  @internal
  String current = '';

  /// A parser that increases the indentation, pushes previous indentation to
  /// stack, but does not consume anything itself.
  late final Parser<String> increase = parser
      .plusString(message: message)
      .where(
        (value) => value.startsWith(current) && value.length > current.length,
      )
      .map((value) {
        stack.add(current);
        return current = value;
      }, hasSideEffects: true)
      .and();

  /// A parser that consumes and matches the current indentation level.
  late final Parser<String> same = parser
      .starString(message: message)
      .where((value) => value == current);

  /// A parser that decreases the indentation by one level.
  late final Parser<String> decrease = epsilon()
      .where((_) => stack.isNotEmpty)
      .map((_) => current = stack.removeLast(), hasSideEffects: true);

  /// Helper combinator to guard a nested indented scope:
  /// `increase & parser & decrease`.
  Parser<R> guard<R>(Parser<R> parser) =>
      seq3(increase, parser, decrease).map3((_, body, _) => body);
}

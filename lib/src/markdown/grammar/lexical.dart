import 'package:petitparser/petitparser.dart';

import '../ast.dart';

/// Lexical rules for whitespace, newlines, escapes, and entities.
mixin MarkdownLexicalGrammar on GrammarDefinition<DocumentNode> {
  /// Matches a single newline sequence (`\n`, `\r\n`, or `\r`).
  Parser<String> newlineSequence() =>
      [string('\r\n'), char('\n'), char('\r')].toChoiceParser();

  /// Matches zero to three spaces (non-indent space).
  Parser<String> nonIndentSpace() =>
      char(' ').repeat(0, 3).map((chars) => chars.join());

  /// Matches 4 spaces or a single horizontal tab representing an indentation.
  Parser<String> indent() => [string('    '), char('\t')].toChoiceParser();

  /// Matches optional horizontal whitespace (spaces and tabs).
  Parser<String> sp() => pattern(' \t').starString();

  /// Matches one or more horizontal whitespace characters (spaces and tabs).
  Parser<String> spPlus() => pattern(' \t').plusString();

  /// Matches an empty or blank line ending with a newline.
  Parser<String> blankLine() => seq2(
    ref0(sp),
    ref0(newlineSequence),
  ).flatten(message: 'blank line expected');

  /// Matches one or more consecutive blank lines.
  Parser<List<String>> blankLines() => ref0(blankLine).plus();

  /// Matches an escaped ASCII punctuation character, returning the unescaped character.
  Parser<String> escapedChar() => seq2(
    char(r'\'),
    pattern('!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~'),
  ).map2((_, c) => c);

  /// Matches an HTML entity reference or numeric character reference (e.g. `&amp;`, `&#160;`, `&#x20;`).
  Parser<String> htmlEntity() => seq3(
    char('&'),
    [
      seq2(
        char('#'),
        [
          seq2(pattern('xX'), pattern('0-9a-fA-F').plus()),
          digit().plus(),
        ].toChoiceParser(),
      ),
      pattern('a-zA-Z0-9').plus(),
    ].toChoiceParser(),
    char(';'),
  ).flatten(message: 'HTML entity expected');

  /// Matches any single ASCII punctuation character.
  Parser<String> asciiPunctuation() =>
      pattern('!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~');
}

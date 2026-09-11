import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import '../indent.dart';

/// Mixin for Python lexical syntax: comments, whitespace, numbers, strings,
/// keywords, identifiers, and token helpers.
mixin PythonLexicalGrammar on GrammarDefinition<ModuleNode> {
  /// The indentation manager instance.
  PythonIndent get indent;

  /// Abstract reference to expression parser needed for f-string interpolation.
  Parser<ExpressionNode> expression();

  /// Bracket nesting depth. When > 0, physical newlines are treated as
  /// whitespace so that multi-line expressions inside `()`, `[]`, `{}` work.
  int _bracketNesting = 0;

  // ---------------------------------------------------------------------------
  // Tokens and Whitespace
  // ---------------------------------------------------------------------------

  /// Helper to convert a string or parser into a trimmed token.
  Parser<Token<T>> token<T>(Object input) => switch (input) {
    final Parser<T> parser => parser.token().trim(ref0(hiddenStuffWhitespace)),
    final String string => token(string.toParser()),
    _ => throw ArgumentError.value(input, 'input', 'Invalid token parser'),
  };

  /// Helper for keywords that must not be followed by an identifier character.
  Parser<Token<String>> keyword(String name) => token(
    (string(name) & ref0(identifierPart).not()).flatten(
      message: '$name expected',
    ),
  );

  Parser<void> hiddenWhitespace() => ref0(hiddenStuffWhitespace).plus();

  Parser<void> hiddenStuffWhitespace() => [
    ref0(inlineWhitespace),
    ref0(comment),
    ref0(explicitLineContinuation),
    Token.newlineParser().where((_) => _bracketNesting > 0),
  ].toChoiceParser();

  Parser<String> inlineWhitespace() => pattern(' \t').plusString();

  Parser<String> comment() => (char('#') & pattern('^\r\n').star()).flatten();

  Parser<String> explicitLineContinuation() =>
      (char(r'\') & Token.newlineParser()).flatten();

  /// Physical newline token or semicolon separating statements.
  Parser<String> newlineToken() =>
      seq2(ref0(hiddenStuffWhitespace).star(), Token.newlineParser()).flatten();

  /// Suppresses newline sensitivity within [parser] by incrementing the
  /// bracket nesting depth, allowing physical newlines as whitespace.
  Parser<R> ignore<R>(Parser<R> parser) => seq3(
    epsilon().map((_) => _bracketNesting++, hasSideEffects: true),
    parser,
    epsilon().map((_) => _bracketNesting--, hasSideEffects: true),
  ).map3((_, body, _) => body);

  /// A parser that skips zero or more blank or comment-only lines.
  Parser<void> blankLines() => indent.blankOrComment.star();

  // ---------------------------------------------------------------------------
  // Keywords
  // ---------------------------------------------------------------------------

  /// Token for the assignment operator `=`, distinct from `==`, `:=`, `+=` etc.
  Parser<Token<String>> assignToken() =>
      token((char('=') & char('=').not()).flatten(message: '= expected'));

  Parser<Token<String>> andToken() => ref1(keyword, 'and');
  Parser<Token<String>> asToken() => ref1(keyword, 'as');
  Parser<Token<String>> assertToken() => ref1(keyword, 'assert');
  Parser<Token<String>> asyncToken() => ref1(keyword, 'async');
  Parser<Token<String>> awaitToken() => ref1(keyword, 'await');
  Parser<Token<String>> breakToken() => ref1(keyword, 'break');
  Parser<Token<String>> caseToken() => ref1(keyword, 'case');
  Parser<Token<String>> classToken() => ref1(keyword, 'class');
  Parser<Token<String>> continueToken() => ref1(keyword, 'continue');
  Parser<Token<String>> defToken() => ref1(keyword, 'def');
  Parser<Token<String>> delToken() => ref1(keyword, 'del');
  Parser<Token<String>> elifToken() => ref1(keyword, 'elif');
  Parser<Token<String>> elseToken() => ref1(keyword, 'else');
  Parser<Token<String>> exceptToken() => ref1(keyword, 'except');
  Parser<Token<String>> finallyToken() => ref1(keyword, 'finally');
  Parser<Token<String>> forToken() => ref1(keyword, 'for');
  Parser<Token<String>> fromToken() => ref1(keyword, 'from');
  Parser<Token<String>> globalToken() => ref1(keyword, 'global');
  Parser<Token<String>> ifToken() => ref1(keyword, 'if');
  Parser<Token<String>> importToken() => ref1(keyword, 'import');
  Parser<Token<String>> inToken() => ref1(keyword, 'in');
  Parser<Token<String>> isToken() => ref1(keyword, 'is');
  Parser<Token<String>> lambdaToken() => ref1(keyword, 'lambda');
  Parser<Token<String>> matchToken() => ref1(keyword, 'match');
  Parser<Token<String>> nonlocalToken() => ref1(keyword, 'nonlocal');
  Parser<Token<String>> notToken() => ref1(keyword, 'not');
  Parser<Token<String>> orToken() => ref1(keyword, 'or');
  Parser<Token<String>> passToken() => ref1(keyword, 'pass');
  Parser<Token<String>> raiseToken() => ref1(keyword, 'raise');
  Parser<Token<String>> returnToken() => ref1(keyword, 'return');
  Parser<Token<String>> tryToken() => ref1(keyword, 'try');
  Parser<Token<String>> typeToken() => ref1(keyword, 'type');
  Parser<Token<String>> whileToken() => ref1(keyword, 'while');
  Parser<Token<String>> withToken() => ref1(keyword, 'with');
  Parser<Token<String>> yieldToken() => ref1(keyword, 'yield');

  // Literals keywords
  Parser<Token<String>> trueToken() => ref1(keyword, 'True');
  Parser<Token<String>> falseToken() => ref1(keyword, 'False');
  Parser<Token<String>> noneToken() => ref1(keyword, 'None');

  // ---------------------------------------------------------------------------
  // Identifiers
  // ---------------------------------------------------------------------------

  Parser<String> identifier() => token(
    (ref0(identifierStart) & ref0(identifierPart).star())
        .flatten(message: 'identifier expected')
        .where((id) => !keywords.contains(id), message: 'identifier expected'),
  ).map((t) => t.value);

  Parser<String> identifierStart() => pattern('a-zA-Z_');

  Parser<String> identifierPart() => pattern('a-zA-Z0-9_');

  static const Set<String> keywords = {
    'False',
    'None',
    'True',
    'and',
    'as',
    'assert',
    'async',
    'await',
    'break',
    'class',
    'continue',
    'def',
    'del',
    'elif',
    'else',
    'except',
    'finally',
    'for',
    'from',
    'global',
    'if',
    'import',
    'in',
    'is',
    'lambda',
    'nonlocal',
    'not',
    'or',
    'pass',
    'raise',
    'return',
    'try',
    'while',
    'with',
    'yield',
  };

  // ---------------------------------------------------------------------------
  // Numbers
  // ---------------------------------------------------------------------------

  Parser<ConstantNode> numberLiteral() => token(
    [
      ref0(complexLiteral),
      ref0(floatLiteral),
      ref0(hexLiteral),
      ref0(octalLiteral),
      ref0(binaryLiteral),
      ref0(decimalLiteral),
    ].toChoiceParser(),
  ).map((t) => t.value);

  Parser<ConstantNode> decimalLiteral() =>
      (digit() & (digit() | char('_')).star()).flatten().map(
        (s) => ConstantNode(int.parse(s.replaceAll('_', ''))),
      );

  Parser<ConstantNode> hexLiteral() =>
      ((string('0x') | string('0X')) &
              (pattern('0-9a-fA-F') | char('_')).plus().flatten())
          .flatten()
          .map(
            (s) => ConstantNode(
              int.parse(s.substring(2).replaceAll('_', ''), radix: 16),
            ),
          );

  Parser<ConstantNode> octalLiteral() =>
      ((string('0o') | string('0O')) &
              (pattern('0-7') | char('_')).plus().flatten())
          .flatten()
          .map(
            (s) => ConstantNode(
              int.parse(s.substring(2).replaceAll('_', ''), radix: 8),
            ),
          );

  Parser<ConstantNode> binaryLiteral() =>
      ((string('0b') | string('0B')) &
              (pattern('01') | char('_')).plus().flatten())
          .flatten()
          .map(
            (s) => ConstantNode(
              int.parse(s.substring(2).replaceAll('_', ''), radix: 2),
            ),
          );

  Parser<ConstantNode> floatLiteral() =>
      [
        // Point followed by digits
        char('.') &
            (digit() | char('_')).plus() &
            ref0(exponentPart).optional(),
        // Digits with fraction and optional exponent
        (digit() | char('_')).plus() &
            ((char('.') &
                    (digit() | char('_')).star() &
                    ref0(exponentPart).optional()) |
                ref0(exponentPart)),
      ].toChoiceParser().flatten().map(
        (s) => ConstantNode(double.parse(s.replaceAll('_', ''))),
      );

  Parser<String> exponentPart() =>
      (pattern('eE') & pattern('+-').optional() & (digit() | char('_')).plus())
          .flatten();

  Parser<ConstantNode> complexLiteral() => [
    ref0(floatLiteral),
    ref0(decimalLiteral),
  ].toChoiceParser().seq(pattern('jJ')).flatten().map((s) => ConstantNode(s));

  // ---------------------------------------------------------------------------
  // Strings and F-Strings
  // ---------------------------------------------------------------------------

  Parser<ExpressionNode> stringLiteral() =>
      ref0(singleStringLiteral).plus().map((strings) {
        if (strings.length == 1) return strings.first;
        final hasInterpolations = strings.any(
          (s) => s is JoinedStrNode || s is FormattedValueNode,
        );
        if (hasInterpolations) {
          final parts = <ExpressionNode>[];
          for (final s in strings) {
            if (s is JoinedStrNode) {
              parts.addAll(s.values);
            } else {
              parts.add(s);
            }
          }
          return JoinedStrNode(parts);
        } else {
          final buffer = StringBuffer();
          for (final s in strings) {
            if (s is ConstantNode) {
              buffer.write(s.value);
            }
          }
          return ConstantNode(buffer.toString());
        }
      });

  Parser<ExpressionNode> singleStringLiteral() => token(
    [
      ref0(tripleQuotedString),
      ref0(fStringLiteral),
      ref0(standardStringLiteral),
    ].toChoiceParser(),
  ).map((t) => t.value);

  Parser<ConstantNode> standardStringLiteral() => seq2(
    ref0(stringPrefix).optional(),
    [ref1(delimitedString, "'"), ref1(delimitedString, '"')].toChoiceParser(),
  ).map2((prefix, content) => ConstantNode(content));

  Parser<ConstantNode> tripleQuotedString() => seq2(
    ref0(stringPrefix).optional(),
    [
      ref1(tripleDelimitedString, "'''"),
      ref1(tripleDelimitedString, '"""'),
    ].toChoiceParser(),
  ).map2((prefix, content) => ConstantNode(content));

  Parser<String> stringPrefix() => [
    'br',
    'BR',
    'Br',
    'bR',
    'rb',
    'RB',
    'Rb',
    'rB',
    'r',
    'R',
    'u',
    'U',
    'b',
    'B',
  ].map(string).toChoiceParser().flatten();

  Parser<String> delimitedString(String quote) => seq3(
    char(quote),
    (string(r'\' + quote) | char(r'\').seq(any()) | pattern('^$quote\r\n\\'))
        .star()
        .flatten(),
    char(quote),
  ).map3((_, content, _) => _unescape(content));

  Parser<String> tripleDelimitedString(String delimiter) => seq3(
    string(delimiter),
    (string(r'\' + delimiter) | char(r'\').seq(any()) | string(delimiter).neg())
        .star()
        .flatten(),
    string(delimiter),
  ).map3((_, content, _) => content);

  // ---------------------------------------------------------------------------
  // F-strings
  // ---------------------------------------------------------------------------

  Parser<ExpressionNode> fStringLiteral() =>
      seq2(
        [
          'f',
          'F',
          'fr',
          'FR',
          'rf',
          'RF',
        ].map(string).toChoiceParser().flatten(),
        [
          ref1(fStringDelimited, "'"),
          ref1(fStringDelimited, '"'),
        ].toChoiceParser(),
      ).map2((prefix, parts) {
        final flat = <ExpressionNode>[];
        for (final p in parts) {
          if (p is ConstantNode && (p.value as String).isEmpty) continue;
          flat.add(p);
        }
        return flat.length == 1 && flat.first is ConstantNode
            ? flat.first
            : JoinedStrNode(flat);
      });

  Parser<List<ExpressionNode>> fStringDelimited(String quote) => seq3(
    char(quote),
    [
      string('{{').map((_) => const ConstantNode('{')),
      string('}}').map((_) => const ConstantNode('}')),
      ref0(fStringReplacementField),
      (string(r'\' + quote) |
              char(r'\').seq(any()) |
              pattern('^$quote\r\n\\{}'))
          .plus()
          .flatten()
          .map((s) => ConstantNode(_unescape(s))),
    ].toChoiceParser().star(),
    char(quote),
  ).map3((_, parts, _) => parts);

  Parser<FormattedValueNode> fStringReplacementField() =>
      seq4(
        char('{'),
        ref0(expression),
        seq2(
          seq2(char('!'), pattern('sra')).map2((_, ch) => ch).optional(),
          seq2(
            char(':'),
            pattern('^}\r\n').starString(),
          ).map2((_, s) => s).optional(),
        ),
        char('}'),
      ).map4(
        (_, expr, formatSpec, _) => FormattedValueNode(
          value: expr,
          conversion: formatSpec.$1,
          formatSpec: formatSpec.$2,
        ),
      );

  String _unescape(String input) => input
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\r', '\r')
      .replaceAll(r'\t', '\t')
      .replaceAll(r'\\', r'\');
}

import 'package:petitparser/petitparser.dart';

import '../ast.dart';

/// Mixin for Dart lexical syntax: whitespace, comments, tokens, identifiers,
/// keywords, and literals.
mixin DartLexicalGrammar on GrammarDefinition<CompilationUnitNode> {
  /// Abstract expression reference needed for string interpolation.
  Parser<ExpressionNode> expression();

  // ---------------------------------------------------------------------------
  // Tokens and whitespace
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

  Parser<void> hiddenStuffWhitespace() =>
      ref0(visibleWhitespace) |
      ref0(singleLineComment) |
      ref0(multiLineComment);

  Parser<String> visibleWhitespace() => whitespace();

  Parser<String> singleLineComment() =>
      (string('//') & pattern('^\r\n').star() & pattern('\r\n').optional())
          .flatten();

  Parser<String> multiLineComment() =>
      (string('/*') &
              (ref0(multiLineComment) | string('*/').neg()).star() &
              string('*/'))
          .flatten();

  Parser<String> hashbang() =>
      (string('#!') & pattern('^\r\n').star() & pattern('\r\n').optional())
          .flatten();

  // ---------------------------------------------------------------------------
  // Keywords
  // ---------------------------------------------------------------------------

  Parser<Token<String>> assertToken() => ref1(keyword, 'assert');
  Parser<Token<String>> breakToken() => ref1(keyword, 'break');
  Parser<Token<String>> caseToken() => ref1(keyword, 'case');
  Parser<Token<String>> catchToken() => ref1(keyword, 'catch');
  Parser<Token<String>> classToken() => ref1(keyword, 'class');
  Parser<Token<String>> constToken() => ref1(keyword, 'const');
  Parser<Token<String>> continueToken() => ref1(keyword, 'continue');
  Parser<Token<String>> defaultToken() => ref1(keyword, 'default');
  Parser<Token<String>> doToken() => ref1(keyword, 'do');
  Parser<Token<String>> elseToken() => ref1(keyword, 'else');
  Parser<Token<String>> enumToken() => ref1(keyword, 'enum');
  Parser<Token<String>> extendsToken() => ref1(keyword, 'extends');
  Parser<Token<String>> falseToken() => ref1(keyword, 'false');
  Parser<Token<String>> finalToken() => ref1(keyword, 'final');
  Parser<Token<String>> finallyToken() => ref1(keyword, 'finally');
  Parser<Token<String>> forToken() => ref1(keyword, 'for');
  Parser<Token<String>> ifToken() => ref1(keyword, 'if');
  Parser<Token<String>> inToken() => ref1(keyword, 'in');
  Parser<Token<String>> isToken() => ref1(keyword, 'is');
  Parser<Token<String>> newToken() => ref1(keyword, 'new');
  Parser<Token<String>> nullToken() => ref1(keyword, 'null');
  Parser<Token<String>> rethrowToken() => ref1(keyword, 'rethrow');
  Parser<Token<String>> returnToken() => ref1(keyword, 'return');
  Parser<Token<String>> superToken() => ref1(keyword, 'super');
  Parser<Token<String>> switchToken() => ref1(keyword, 'switch');
  Parser<Token<String>> thisToken() => ref1(keyword, 'this');
  Parser<Token<String>> throwToken() => ref1(keyword, 'throw');
  Parser<Token<String>> trueToken() => ref1(keyword, 'true');
  Parser<Token<String>> tryToken() => ref1(keyword, 'try');
  Parser<Token<String>> varToken() => ref1(keyword, 'var');
  Parser<Token<String>> voidToken() => ref1(keyword, 'void');
  Parser<Token<String>> whileToken() => ref1(keyword, 'while');
  Parser<Token<String>> withToken() => ref1(keyword, 'with');

  // Contextual / built-in keywords
  Parser<Token<String>> abstractToken() => ref1(keyword, 'abstract');
  Parser<Token<String>> asToken() => ref1(keyword, 'as');
  Parser<Token<String>> asyncToken() => ref1(keyword, 'async');
  Parser<Token<String>> awaitToken() => ref1(keyword, 'await');
  Parser<Token<String>> baseToken() => ref1(keyword, 'base');
  Parser<Token<String>> covariantToken() => ref1(keyword, 'covariant');
  Parser<Token<String>> deferredToken() => ref1(keyword, 'deferred');
  Parser<Token<String>> dynamicToken() => ref1(keyword, 'dynamic');
  Parser<Token<String>> exportToken() => ref1(keyword, 'export');
  Parser<Token<String>> extensionToken() => ref1(keyword, 'extension');
  Parser<Token<String>> externalToken() => ref1(keyword, 'external');
  Parser<Token<String>> factoryToken() => ref1(keyword, 'factory');
  Parser<Token<String>> functionToken() => ref1(keyword, 'Function');
  Parser<Token<String>> getToken() => ref1(keyword, 'get');
  Parser<Token<String>> hideToken() => ref1(keyword, 'hide');
  Parser<Token<String>> implementsToken() => ref1(keyword, 'implements');
  Parser<Token<String>> importToken() => ref1(keyword, 'import');
  Parser<Token<String>> interfaceToken() => ref1(keyword, 'interface');
  Parser<Token<String>> lateToken() => ref1(keyword, 'late');
  Parser<Token<String>> libraryToken() => ref1(keyword, 'library');
  Parser<Token<String>> mixinToken() => ref1(keyword, 'mixin');
  Parser<Token<String>> ofToken() => ref1(keyword, 'of');
  Parser<Token<String>> onToken() => ref1(keyword, 'on');
  Parser<Token<String>> operatorToken() => ref1(keyword, 'operator');
  Parser<Token<String>> partToken() => ref1(keyword, 'part');
  Parser<Token<String>> requiredToken() => ref1(keyword, 'required');
  Parser<Token<String>> sealedToken() => ref1(keyword, 'sealed');
  Parser<Token<String>> setToken() => ref1(keyword, 'set');
  Parser<Token<String>> showToken() => ref1(keyword, 'show');
  Parser<Token<String>> staticToken() => ref1(keyword, 'static');
  Parser<Token<String>> syncToken() => ref1(keyword, 'sync');
  Parser<Token<String>> typeToken() => ref1(keyword, 'type');
  Parser<Token<String>> typedefToken() => ref1(keyword, 'typedef');
  Parser<Token<String>> whenToken() => ref1(keyword, 'when');
  Parser<Token<String>> yieldToken() => ref1(keyword, 'yield');

  // ---------------------------------------------------------------------------
  // Identifiers
  // ---------------------------------------------------------------------------

  Parser<String> identifierStart() =>
      [letter(), char('_'), char(r'$')].toChoiceParser().flatten();

  Parser<String> identifierPart() =>
      [letter(), digit(), char('_'), char(r'$')].toChoiceParser().flatten();

  static const Set<String> _reservedWords = {
    'assert',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'default',
    'do',
    'else',
    'enum',
    'extends',
    'false',
    'final',
    'finally',
    'for',
    'if',
    'in',
    'is',
    'new',
    'null',
    'rethrow',
    'return',
    'super',
    'switch',
    'this',
    'throw',
    'true',
    'try',
    'var',
    'void',
    'while',
    'with',
  };

  Parser<String> rawIdentifier() =>
      (ref0(identifierStart) & ref0(identifierPart).star())
          .flatten(message: 'identifier expected')
          .where(
            (id) => !_reservedWords.contains(id),
            message: 'identifier expected',
          );

  /// A standard Dart identifier.
  Parser<String> identifier() =>
      ref1(token, ref0(rawIdentifier)).map((token) => token.value);

  /// A qualified identifier (`a.b.c`).
  Parser<String> qualifiedIdentifier() =>
      ref0(identifier)
          .plusSeparated(ref1(token, '.'))
          .map((list) => list.elements.join('.'));

  // ---------------------------------------------------------------------------
  // Literals
  // ---------------------------------------------------------------------------

  Parser<ExpressionNode> literal() => [
    ref0(nullLiteral),
    ref0(booleanLiteral),
    ref0(numericLiteral),
    ref0(stringLiteral),
    ref0(symbolLiteral),
  ].toChoiceParser();

  Parser<NullLiteralNode> nullLiteral() =>
      ref0(nullToken).map((_) => const NullLiteralNode());

  Parser<BooleanLiteralNode> booleanLiteral() => [
    ref0(trueToken).map((_) => const BooleanLiteralNode(true)),
    ref0(falseToken).map((_) => const BooleanLiteralNode(false)),
  ].toChoiceParser();

  // Numeric literals
  Parser<String> decimalDigits() =>
      (digit() & (char('_').optional() & digit()).star()).flatten();

  Parser<String> hexDigits() =>
      (pattern('0-9a-fA-F') &
              (char('_').optional() & pattern('0-9a-fA-F')).star())
          .flatten();

  Parser<String> exponent() =>
      (pattern('eE') & pattern('+-').optional() & ref0(decimalDigits))
          .flatten();

  Parser<IntegerLiteralNode> hexNumber() => (string('0x') | string('0X'))
      .seq(ref0(hexDigits))
      .flatten()
      .map((str) => IntegerLiteralNode(int.parse(str.replaceAll('_', ''))));

  Parser<LiteralNode<num>>
  decimalOrDoubleNumber() => <Parser<LiteralNode<num>>>[
    // Number with fractional part and optional exponent: 1.2, 1.2e3
    (ref0(decimalDigits) &
            char('.') &
            ref0(decimalDigits) &
            ref0(exponent).optional())
        .flatten()
        .map((str) => DoubleLiteralNode(double.parse(str.replaceAll('_', '')))),
    // Number starting with dot: .5, .5e3
    (char('.') & ref0(decimalDigits) & ref0(exponent).optional()).flatten().map(
      (str) => DoubleLiteralNode(double.parse(str.replaceAll('_', ''))),
    ),
    // Integer with exponent: 1e3
    (ref0(decimalDigits) & ref0(exponent)).flatten().map(
      (str) => DoubleLiteralNode(double.parse(str.replaceAll('_', ''))),
    ),
    // Pure integer: 42
    ref0(decimalDigits)
        .map((str) => IntegerLiteralNode(int.parse(str.replaceAll('_', '')))),
  ].toChoiceParser();

  Parser<LiteralNode<num>> numericLiteral() => ref1(
    token,
    [ref0(hexNumber), ref0(decimalOrDoubleNumber)].toChoiceParser(),
  ).map((token) => token.value);

  // Symbol literals
  Parser<SymbolLiteralNode> symbolLiteral() => ref1(
    token,
    (char('#') &
            [
              ref0(rawIdentifier),
              string('=='),
              string('[]='),
              string('[]'),
              string('+'),
              string('-'),
              string('*'),
              string('/'),
              string('~/'),
              string('%'),
              string('<<'),
              string('>>>'),
              string('>>'),
              string('<='),
              string('>='),
              string('<'),
              string('>'),
              string('&'),
              string('^'),
              string('|'),
              string('~'),
            ].toChoiceParser())
        .flatten(),
  ).map((token) => SymbolLiteralNode(token.value.substring(1)));

  // String literals
  Parser<StringLiteralNode> rawStringLiteral() =>
      ref1(
        token,
        [
          // Triple-quoted raw strings
          string('r"""') & any().starLazy(string('"""')) & string('"""'),
          string("r'''") & any().starLazy(string("'''")) & string("'''"),
          // Single-quoted raw strings
          string('r"') & pattern('^"\r\n').star() & char('"'),
          string("r'") & pattern("^'\r\n").star() & char("'"),
        ].toChoiceParser().flatten(),
      ).map((token) {
        final val = token.value;
        if (val.startsWith('r"""') || val.startsWith("r'''")) {
          return StringLiteralNode(
            val.substring(4, val.length - 3),
            isRaw: true,
          );
        }
        return StringLiteralNode(val.substring(2, val.length - 1), isRaw: true);
      });

  Parser<ExpressionNode> singleStringLiteral() => [
    ref0(rawStringLiteral),
    ref0(interpolatedString),
    ref0(simpleStringLiteral),
  ].toChoiceParser();

  Parser<ExpressionNode> stringLiteral() =>
      ref0(singleStringLiteral).plus().map((list) {
        if (list.length == 1) return list.first;
        final allSimple = list.every((e) => e is StringLiteralNode);
        if (allSimple) {
          final buffer = StringBuffer();
          for (final node in list.cast<StringLiteralNode>()) {
            buffer.write(node.value);
          }
          return StringLiteralNode(buffer.toString());
        }
        final parts = <DartNode>[];
        for (final node in list) {
          if (node is StringLiteralNode) {
            parts.add(node);
          } else if (node is InterpolatedStringNode) {
            parts.addAll(node.parts);
          } else {
            parts.add(node);
          }
        }
        return InterpolatedStringNode(parts);
      });

  Parser<StringLiteralNode> simpleStringLiteral() =>
      ref1(
        token,
        [
          // Multi-line
          string('"""') &
              (string(r'\"') |
                      string(r'\\') |
                      string(r'\$') |
                      pattern('^"\$').plus() |
                      string('"""').neg())
                  .star() &
              string('"""'),
          string("'''") &
              (string(r"\'") |
                      string(r'\\') |
                      string(r'\$') |
                      pattern("^'\$").plus() |
                      string("'''").neg())
                  .star() &
              string("'''"),
          // Single-line
          char('"') &
              (string(r'\"') |
                      string(r'\\') |
                      string(r'\$') |
                      pattern('^"\$\r\n'))
                  .star() &
              char('"'),
          char("'") &
              (string(r"\'") |
                      string(r'\\') |
                      string(r'\$') |
                      pattern("^'\$\r\n"))
                  .star() &
              char("'"),
        ].toChoiceParser().flatten(),
      ).map((token) {
        final val = token.value;
        if (val.startsWith('"""') || val.startsWith("'''")) {
          return StringLiteralNode(val.substring(3, val.length - 3));
        }
        return StringLiteralNode(val.substring(1, val.length - 1));
      });

  /// String interpolation: simple `$foo` or `${expression}`.
  Parser<ExpressionNode> interpolatedString() =>
      ref1(
        token,
        [
          string('"""')
              .seq(ref0(stringInterpolationContentMultiDouble).plus())
              .seq(string('"""')),
          string("'''")
              .seq(ref0(stringInterpolationContentMultiSingle).plus())
              .seq(string("'''")),
          char('"')
              .seq(ref0(stringInterpolationContentDouble).plus())
              .seq(char('"')),
          char("'")
              .seq(ref0(stringInterpolationContentSingle).plus())
              .seq(char("'")),
        ].toChoiceParser(),
      ).map((token) {
        final parts = (token.value as List)[1] as List;
        final nodes = <DartNode>[];
        for (final p in parts) {
          if (p is DartNode) {
            nodes.add(p);
          } else if (p is String && p.isNotEmpty) {
            nodes.add(StringLiteralNode(p));
          }
        }
        if (nodes.length == 1 && nodes.first is ExpressionNode) {
          return nodes.first as ExpressionNode;
        }
        return InterpolatedStringNode(nodes);
      });

  Parser<String> interpolationIdentifier() => (letter() | char('_'))
      .seq((letter() | digit() | char('_')).star())
      .flatten(message: 'identifier expected')
      .where(
        (id) => !_reservedWords.contains(id),
        message: 'identifier expected',
      );

  Parser<DartNode> stringInterpolationContentMultiDouble() => [
    (string(r'${') & ref0(expression) & char('}')).map(
      (list) => list[1] as ExpressionNode,
    ),
    (char(r'$') & ref0(interpolationIdentifier)).map(
      (list) => IdentifierNode(list[1] as String),
    ),
    (string(r'\"') |
            string(r'\\') |
            string(r'\$') |
            (char(r'$') & (char('{') | ref0(interpolationIdentifier)).not()) |
            (string('"""').not() & pattern(r'^$')))
        .plus()
        .flatten()
        .map(StringLiteralNode.new),
  ].toChoiceParser();

  Parser<DartNode> stringInterpolationContentMultiSingle() => [
    (string(r'${') & ref0(expression) & char('}')).map(
      (list) => list[1] as ExpressionNode,
    ),
    (char(r'$') & ref0(interpolationIdentifier)).map(
      (list) => IdentifierNode(list[1] as String),
    ),
    (string(r"\'") |
            string(r'\\') |
            string(r'\$') |
            (char(r'$') & (char('{') | ref0(interpolationIdentifier)).not()) |
            (string("'''").not() & pattern(r'^$')))
        .plus()
        .flatten()
        .map(StringLiteralNode.new),
  ].toChoiceParser();

  Parser<DartNode> stringInterpolationContentDouble() => [
    (string(r'${') & ref0(expression) & char('}')).map(
      (list) => list[1] as ExpressionNode,
    ),
    (char(r'$') & ref0(interpolationIdentifier)).map(
      (list) => IdentifierNode(list[1] as String),
    ),
    (string(r'\"') |
            string(r'\\') |
            string(r'\$') |
            (char(r'$') & (char('{') | ref0(interpolationIdentifier)).not()) |
            pattern('^"\$\r\n'))
        .plus()
        .flatten()
        .map(StringLiteralNode.new),
  ].toChoiceParser();

  Parser<DartNode> stringInterpolationContentSingle() => [
    (string(r'${') & ref0(expression) & char('}')).map(
      (list) => list[1] as ExpressionNode,
    ),
    (char(r'$') & ref0(interpolationIdentifier)).map(
      (list) => IdentifierNode(list[1] as String),
    ),
    (string(r"\'") |
            string(r'\\') |
            string(r'\$') |
            (char(r'$') & (char('{') | ref0(interpolationIdentifier)).not()) |
            pattern("^'\$\r\n"))
        .plus()
        .flatten()
        .map(StringLiteralNode.new),
  ].toChoiceParser();
}

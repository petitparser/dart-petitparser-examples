import 'package:petitparser/petitparser.dart';

import 'ast.dart';

/// Smalltalk parser definition producing strongly typed [Node] AST nodes.
class SmalltalkParserDefinition extends GrammarDefinition<MethodNode> {
  @override
  Parser<MethodNode> start() => ref0(startMethod);

  Parser<MethodNode> startMethod() => ref0(method).end();

  // region token helpers
  Parser<Token<String>> token(
    Object source, [
    String? message,
  ]) => switch (source) {
    final String string =>
      string
          .toParser(message: 'Expected ${message ?? string}')
          .token()
          .trim(ref0(spacer)),
    final Parser<String> parser =>
      parser
          .flatten(
            message:
                'Expected ${message ?? (throw ArgumentError.notNull('message'))}',
          )
          .token()
          .trim(ref0(spacer)),
    final Parser parser =>
      parser
          .flatten(
            message:
                'Expected ${message ?? (throw ArgumentError.notNull('message'))}',
          )
          .token()
          .trim(ref0(spacer)),
    _ => throw ArgumentError.value(source, 'source', 'Unknown token type'),
  };

  Parser<void> spacer() => [whitespace(), ref0(comment)].toChoiceParser();
  Parser<void> comment() => seq3(char('"'), char('"').neg().star(), char('"'));
  // endregion

  // region number parsing
  Parser<String> number() => seq2(
    char('-').optional(),
    ref0(positiveNumber),
  ).flatten(message: 'number expected');
  Parser<void> positiveNumber() =>
      [ref0(scaledDecimal), ref0(float), ref0(integer)].toChoiceParser();
  Parser<void> integer() =>
      [ref0(radixInteger), ref0(decimalInteger)].toChoiceParser();
  Parser<void> decimalInteger() => ref0(digits);
  Parser<void> digits() => digit().plus();
  Parser<void> radixInteger() =>
      seq3(ref0(radixSpecifier), char('r'), ref0(radixDigits));
  Parser<void> radixSpecifier() => ref0(digits);
  Parser<void> radixDigits() => pattern('0-9A-Z').plus();
  Parser<void> float() => seq2(
    ref0(mantissa),
    seq2(ref0(exponentLetter), ref0(exponent)).optional(),
  );
  Parser<void> mantissa() => seq3(ref0(digits), char('.'), ref0(digits));
  Parser<void> exponent() => seq2(char('-').optional(), ref0(decimalInteger));
  Parser<void> exponentLetter() => pattern('edq');
  Parser<void> scaledDecimal() =>
      seq3(ref0(scaledMantissa), char('s'), ref0(fractionalDigits).optional());
  Parser<void> scaledMantissa() =>
      [ref0(decimalInteger), ref0(mantissa)].toChoiceParser();
  Parser<void> fractionalDigits() => ref0(decimalInteger);
  // endregion

  // region grammar productions
  Parser<ArrayNode> array() =>
      seq3(
        ref1(token, '{'),
        ref0(expression)
            .starSeparated(ref0(periodToken).plus())
            .skip(after: ref0(periodToken).star()),
        ref1(token, '}'),
      ).map3((open, list, close) {
        final result = ArrayNode()..surroundWith(open, close);
        result.statements.addAll(list.elements);
        for (final sep in list.separators) {
          result.periods.addAll(sep);
        }
        return result;
      });

  Parser<LiteralNode<dynamic>> arrayItem() => <Parser<LiteralNode>>[
    ref0(literal),
    ref0(symbolLiteralArray),
    ref0(arrayLiteralArray),
    ref0(byteLiteralArray),
  ].toChoiceParser();

  Parser<LiteralArrayNode<dynamic>> arrayLiteral() =>
      seq3(ref1(token, '#('), ref0(arrayItem).star(), ref1(token, ')')).map3(
        (open, items, close) =>
            LiteralArrayNode(items)..surroundWith(open, close),
      );

  Parser<LiteralArrayNode<dynamic>> arrayLiteralArray() =>
      seq3(ref1(token, '('), ref0(arrayItem).star(), ref1(token, ')')).map3(
        (open, items, close) =>
            LiteralArrayNode(items)..surroundWith(open, close),
      );

  Parser<(VariableNode, Token<String>)> assignment() =>
      seq2(ref0(variable), ref0(assignmentToken));

  Parser<Token<String>> assignmentToken() => ref1(token, ':=');

  Parser<String> binary() => anyOf(r'!%&*+,-/<=>?@\|~').plusString();

  Parser<ValueNode> binaryExpression() =>
      seq2(ref0(unaryExpression), ref0(binaryMessage).star()).map2((
        unary,
        messages,
      ) {
        var current = unary;
        for (final (tokens, args) in messages) {
          final msg = MessageNode(current);
          msg.selectorToken.addAll(tokens);
          msg.arguments.addAll(args);
          current = msg;
        }
        return current;
      });

  Parser<(List<Token<String>>, List<ValueNode>)> binaryMessage() => seq2(
    ref0(binaryToken),
    ref0(unaryExpression),
  ).map2((t, expr) => ([t], [expr]));

  Parser<(List<Token<String>>, List<VariableNode>)> binaryMethod() =>
      seq2(ref0(binaryToken), ref0(variable)).map2((t, v) => ([t], [v]));

  Parser<(List<Token<String>>, List<LiteralNode<dynamic>>)> binaryPragma() =>
      seq2(ref0(binaryToken), ref0(arrayItem)).map2((t, item) => ([t], [item]));

  Parser<Token<String>> binaryToken() =>
      ref2(token, ref0(binary), 'binary selector');

  Parser<BlockNode> block() =>
      seq3(ref1(token, '['), ref0(blockBody), ref1(token, ']')).map3((
        open,
        bodyInfo,
        close,
      ) {
        final (args, body) = bodyInfo;
        final (arguments, separator) = args;
        final result = BlockNode(body)..surroundWith(open, close);
        result.arguments.addAll(arguments);
        if (separator != null) {
          result.separators.add(separator);
        }
        return result;
      });

  Parser<VariableNode> blockArgument() =>
      seq2(ref1(token, ':'), ref0(variable)).map2((_, v) => v);

  Parser<(List<VariableNode>, Token<String>?)> blockArguments() =>
      [ref0(blockArgumentsWith), ref0(blockArgumentsWithout)].toChoiceParser();

  Parser<(List<VariableNode>, Token<String>?)> blockArgumentsWith() => seq2(
    ref0(blockArgument).plus(),
    [
      ref1(token, '|').map((t) => t as Token<String>?),
      ref1(token, ']').and().map((_) => null),
    ].toChoiceParser(),
  );

  Parser<(List<VariableNode>, Token<String>?)> blockArgumentsWithout() =>
      epsilonWith((const <VariableNode>[], null));

  Parser<((List<VariableNode>, Token<String>?), SequenceNode)> blockBody() =>
      seq2(ref0(blockArguments), ref0(sequence));

  Parser<LiteralArrayNode<num>> byteLiteral() =>
      seq3(
        ref1(token, '#['),
        ref0(numberLiteral).star(),
        ref1(token, ']'),
      ).map3(
        (open, items, close) =>
            LiteralArrayNode<num>(items)..surroundWith(open, close),
      );

  Parser<LiteralArrayNode<num>> byteLiteralArray() =>
      seq3(ref1(token, '['), ref0(numberLiteral).star(), ref1(token, ']')).map3(
        (open, items, close) =>
            LiteralArrayNode<num>(items)..surroundWith(open, close),
      );

  Parser<ValueNode> cascadeExpression() =>
      seq2(
        ref0(keywordExpression),
        seq2(ref1(token, ';'), ref0(message)).star(),
      ).map2((first, rest) {
        if (rest.isEmpty) return first;
        final cascade = CascadeNode();
        cascade.messages.add(first as MessageNode);
        final receiver = cascade.receiver;
        for (final (semicolon, (tokens, args)) in rest) {
          final msg = MessageNode(receiver);
          msg.selectorToken.addAll(tokens);
          msg.arguments.addAll(args);
          cascade.messages.add(msg);
          cascade.semicolons.add(semicolon);
        }
        return cascade;
      });

  Parser<(Token<String>, (List<Token<String>>, List<ValueNode>))>
  cascadeMessage() => seq2(ref1(token, ';'), ref0(message));

  Parser<String> character() => seq2(char(r'$'), any()).flatten();

  Parser<LiteralValueNode<String>> characterLiteral() =>
      ref0(characterToken)
          .map((t) => LiteralValueNode<String>(t, t.value.substring(1)));

  Parser<Token<String>> characterToken() =>
      ref2(token, ref0(character), 'character');

  Parser<ValueNode> expression() =>
      seq2(ref0(assignment).star(), ref0(cascadeExpression)).map2(
        (assignments, expr) => assignments.reversed.fold(
          expr,
          (result, assign) => AssignmentNode(assign.$1, assign.$2, result),
        ),
      );

  Parser<ReturnNode> expressionReturn() => seq2(
    ref1(token, '^'),
    ref0(expression),
  ).map2((caret, expr) => ReturnNode(caret, expr));

  Parser<LiteralValueNode<bool>> falseLiteral() =>
      ref0(falseToken).map((t) => LiteralValueNode<bool>(t, false));

  Parser<Token<String>> falseToken() =>
      ref2(token, seq2(string('false'), word().not()), 'false');

  Parser<String> identifier() =>
      seq2(pattern('a-zA-Z_'), word().star()).flatten();

  Parser<Token<String>> identifierToken() =>
      ref2(token, ref0(identifier), 'identifier');

  Parser<String> keyword() => seq2(ref0(identifier), char(':')).flatten();

  Parser<ValueNode> keywordExpression() =>
      seq2(ref0(binaryExpression), ref0(keywordMessage).optional()).map2((
        binary,
        kwMsg,
      ) {
        if (kwMsg == null) return binary;
        final msg = MessageNode(binary);
        msg.selectorToken.addAll(kwMsg.$1);
        msg.arguments.addAll(kwMsg.$2);
        return msg;
      });

  Parser<(List<Token<String>>, List<ValueNode>)> keywordMessage() =>
      seq2(ref0(keywordToken), ref0(binaryExpression)).plus().map(
        (pairs) =>
            (pairs.map((p) => p.$1).toList(), pairs.map((p) => p.$2).toList()),
      );

  Parser<(List<Token<String>>, List<VariableNode>)> keywordMethod() =>
      seq2(ref0(keywordToken), ref0(variable)).plus().map(
        (pairs) =>
            (pairs.map((p) => p.$1).toList(), pairs.map((p) => p.$2).toList()),
      );

  Parser<(List<Token<String>>, List<LiteralNode<dynamic>>)> keywordPragma() =>
      seq2(ref0(keywordToken), ref0(arrayItem)).plus().map(
        (pairs) =>
            (pairs.map((p) => p.$1).toList(), pairs.map((p) => p.$2).toList()),
      );

  Parser<Token<String>> keywordToken() =>
      ref2(token, ref0(keyword), 'keyword selector');

  Parser<LiteralNode<dynamic>> literal() => <Parser<LiteralNode>>[
    ref0(numberLiteral),
    ref0(stringLiteral),
    ref0(characterLiteral),
    ref0(arrayLiteral),
    ref0(byteLiteral),
    ref0(symbolLiteral),
    ref0(nilLiteral),
    ref0(trueLiteral),
    ref0(falseLiteral),
  ].toChoiceParser();

  Parser<(List<Token<String>>, List<ValueNode>)> message() => [
    ref0(keywordMessage),
    ref0(binaryMessage),
    ref0(unaryMessage),
  ].toChoiceParser();

  Parser<MethodNode> method() =>
      seq2(ref0(methodDeclaration), ref0(methodSequence)).map2((decl, seqInfo) {
        final (declTokens, declArgs) = decl;
        final (pragmas, temps, stmts, periods) = seqInfo;
        final result = MethodNode();
        result.selectorToken.addAll(declTokens);
        result.arguments.addAll(declArgs);
        result.pragmas.addAll(pragmas);
        result.body.temporaries.addAll(temps);
        result.body.statements.addAll(stmts);
        result.body.periods.addAll(periods);
        return result;
      });

  Parser<(List<Token<String>>, List<VariableNode>)> methodDeclaration() => [
    ref0(keywordMethod),
    ref0(unaryMethod),
    ref0(binaryMethod),
  ].toChoiceParser();

  Parser<
    (
      List<PragmaNode>,
      List<VariableNode>,
      List<IsStatement>,
      List<Token<String>>,
    )
  >
  methodSequence() =>
      seq8(
        ref0(periodToken).star(),
        ref0(pragmas),
        ref0(periodToken).star(),
        ref0(temporaries),
        ref0(periodToken).star(),
        ref0(pragmas),
        ref0(periodToken).star(),
        ref0(statements),
      ).map8(
        (p1, pragmas1, p2, temps, p3, pragmas2, p4, stmts) => (
          [...pragmas1, ...pragmas2],
          temps,
          stmts,
          [...p1, ...p2, ...p3, ...p4],
        ),
      );

  Parser<void> multiword() => ref0(keyword).plus();

  Parser<LiteralValueNode<void>> nilLiteral() =>
      ref0(nilToken).map((t) => LiteralValueNode<void>(t, null));

  Parser<Token<String>> nilToken() =>
      ref2(token, seq2(string('nil'), word().not()), 'nil');

  Parser<LiteralValueNode<num>> numberLiteral() =>
      ref0(numberToken)
          .map((t) => LiteralValueNode<num>(t, _buildNumber(t.value)));

  Parser<Token<String>> numberToken() => ref2(token, ref0(number), 'number');

  Parser<ValueNode> parens() => seq3(
    ref1(token, '('),
    ref0(expression),
    ref1(token, ')'),
  ).map3((open, expr, close) => expr..surroundWith(open, close));

  Parser<String> period() => char('.');

  Parser<Token<String>> periodToken() => ref2(token, ref0(period), 'period');

  Parser<PragmaNode> pragma() =>
      seq3(ref1(token, '<'), ref0(pragmaMessage), ref1(token, '>')).map3((
        open,
        msgInfo,
        close,
      ) {
        final (tokens, args) = msgInfo;
        final result = PragmaNode()..surroundWith(open, close);
        result.selectorToken.addAll(tokens);
        result.arguments.addAll(args);
        return result;
      });

  Parser<(List<Token<String>>, List<LiteralNode<dynamic>>)> pragmaMessage() => [
    ref0(keywordPragma),
    ref0(unaryPragma),
    ref0(binaryPragma),
  ].toChoiceParser();

  Parser<List<PragmaNode>> pragmas() => ref0(pragma).star();

  Parser<ValueNode> primary() => [
    ref0(literal),
    ref0(variable),
    ref0(block),
    ref0(parens),
    ref0(array),
  ].toChoiceParser();

  Parser<SequenceNode> sequence() =>
      seq3(ref0(temporaries), ref0(periodToken).star(), ref0(statements)).map3((
        temps,
        periods,
        stmts,
      ) {
        final result = SequenceNode();
        result.temporaries.addAll(temps);
        result.periods.addAll(periods);
        result.statements.addAll(stmts);
        return result;
      });

  Parser<List<IsStatement>> statements() =>
      [ref0(expressionReturn), ref0(expression)]
          .toChoiceParser()
          .starSeparated(ref0(periodToken).plus())
          .skip(after: ref0(periodToken).star())
          .map((list) => list.elements);

  Parser<String> _string() => seq3(
    char("'"),
    [string("''"), pattern("^'")].toChoiceParser().star(),
    char("'"),
  ).flatten();

  Parser<LiteralValueNode<String>> stringLiteral() =>
      ref0(stringToken)
          .map((t) => LiteralValueNode<String>(t, _buildString(t.value)));

  Parser<Token<String>> stringToken() => ref2(token, ref0(_string), 'string');

  Parser<void> symbol() => [
    ref0(unary),
    ref0(binary),
    ref0(multiword),
    ref0(_string),
  ].toChoiceParser();

  Parser<LiteralValueNode<String>> symbolLiteral() =>
      seq2(ref1(token, '#').plus(), ref2(token, ref0(symbol), 'symbol')).map2(
        (hashes, sym) => LiteralValueNode<String>(
          Token.join<dynamic>([...hashes, sym]),
          _buildString(sym.value),
        ),
      );

  Parser<LiteralValueNode<String>> symbolLiteralArray() => ref2(
    token,
    ref0(symbol),
    'symbol',
  ).map((sym) => LiteralValueNode<String>(sym, _buildString(sym.value)));

  Parser<List<VariableNode>> temporaries() => seq3(
    ref1(token, '|'),
    ref0(variable).star(),
    ref1(token, '|'),
  ).map3((_, vars, _) => vars).optionalWith(const <VariableNode>[]);

  Parser<LiteralValueNode<bool>> trueLiteral() =>
      ref0(trueToken).map((t) => LiteralValueNode<bool>(t, true));

  Parser<Token<String>> trueToken() =>
      ref2(token, seq2(string('true'), word().not()), 'true');

  Parser<String> unary() => seq2(ref0(identifier), char(':').not()).flatten();

  Parser<ValueNode> unaryExpression() =>
      seq2(ref0(primary), ref0(unaryMessage).star()).map2((primary, messages) {
        var current = primary;
        for (final (tokens, args) in messages) {
          final msg = MessageNode(current);
          msg.selectorToken.addAll(tokens);
          msg.arguments.addAll(args);
          current = msg;
        }
        return current;
      });

  Parser<(List<Token<String>>, List<ValueNode>)> unaryMessage() =>
      ref0(unaryToken).map((t) => ([t], const <ValueNode>[]));

  Parser<(List<Token<String>>, List<VariableNode>)> unaryMethod() =>
      ref0(identifierToken).map((t) => ([t], const <VariableNode>[]));

  Parser<(List<Token<String>>, List<LiteralNode<dynamic>>)> unaryPragma() =>
      ref0(identifierToken).map((t) => ([t], const <LiteralNode<dynamic>>[]));

  Parser<Token<String>> unaryToken() =>
      ref2(token, ref0(unary), 'unary selector');

  Parser<VariableNode> variable() =>
      ref0(identifierToken).map(VariableNode.new);
  // endregion
}

num _buildNumber(String input) {
  final values = input.split('r');
  return values.length == 1
      ? num.parse(values[0])
      : values.length == 2
      ? int.parse(values[1], radix: int.parse(values[0]))
      : throw ArgumentError.value(input, 'number', 'Unable to parse');
}

String _buildString(String input) =>
    input.isNotEmpty && input.startsWith("'") && input.endsWith("'")
    ? input.substring(1, input.length - 1).replaceAll("''", "'")
    : input;

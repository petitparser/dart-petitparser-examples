import 'package:petitparser/petitparser.dart';

/// Pascal grammar definition based on
/// http://www.danamania.com/print/Apple%20Pascal%20Poster/PascalPosterV3%20A1.pdf
class PascalGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(program).end();

  Parser program() => seq6(
    ref1(token, 'program'),
    ref0(identifier),
    seq3(
      ref1(token, '('),
      ref0(identifier).plusSeparated(ref1(token, ',')),
      ref1(token, ')'),
    ).optional(),
    ref1(token, ';'),
    ref0(block),
    ref1(token, '.'),
  );

  // region statement
  Parser statement() => seq2(
    ref0(statementLabel).optional(),
    [
      ref0(statementAssign),
      ref0(statementCall),
      ref0(statementBlock),
      ref0(statementIf),
      ref0(statementRepeat),
      ref0(statementWhile),
      ref0(statementFor),
      ref0(statementCase),
      ref0(statementWith),
      ref0(statementGoto),
      ref0(statementExit),
    ].toChoiceParser(),
  ).optional();

  Parser statementLabel() => seq2(ref0(unsignedInteger), ref1(token, ':'));

  Parser statementAssign() =>
      seq3(ref0(variable), ref1(token, ':='), ref0(expression));

  Parser statementCall() => seq2(
    ref0(identifier),
    seq3(
      ref1(token, '('),
      ref0(expression).plusSeparated(ref1(token, ',')),
      ref1(token, ')'),
    ).optional(),
  );

  Parser statementBlock() => seq3(
    ref1(token, 'begin'),
    ref0(statement).plusSeparated(ref1(token, ';')),
    ref1(token, 'end'),
  );

  Parser statementIf() => seq5(
    ref1(token, 'if'),
    ref0(expression),
    ref1(token, 'then'),
    ref0(statement),
    seq2(ref1(token, 'else'), ref0(statement)).optional(),
  );

  Parser statementRepeat() => seq4(
    ref1(token, 'repeat'),
    ref0(statement).plusSeparated(ref1(token, ';')),
    ref1(token, 'until'),
    ref0(expression),
  );

  Parser statementWhile() => seq4(
    ref1(token, 'while'),
    ref0(expression),
    ref1(token, 'do'),
    ref0(statement),
  );

  Parser statementFor() => seq8(
    ref1(token, 'for'),
    ref0(identifier),
    ref1(token, ':='),
    ref0(expression),
    [ref1(token, 'to'), ref1(token, 'downto')].toChoiceParser(),
    ref0(expression),
    ref1(token, 'do'),
    ref0(statement),
  );

  Parser statementCase() => seq5(
    ref1(token, 'case'),
    ref0(expression),
    ref1(token, 'of'),
    seq3(
      ref0(constant).plusSeparated(ref1(token, ',')),
      ref1(token, ':'),
      ref0(statement),
    ).plusSeparated(ref1(token, ';')),
    ref1(token, 'end'),
  );

  Parser statementWith() => seq4(
    ref1(token, 'with'),
    ref0(variable).plusSeparated(ref1(token, ',')),
    ref1(token, 'do'),
    ref0(statement),
  );

  Parser statementGoto() => seq2(ref1(token, 'goto'), ref0(unsignedInteger));

  Parser statementExit() => seq4(
    ref1(token, 'exit'),
    ref1(token, '('),
    [ref1(token, 'program'), ref0(identifier)].toChoiceParser(),
    ref1(token, ')'),
  );

  // endregion

  // region block

  Parser block() => seq6(
    ref0(blockLabel).optional(),
    ref0(blockConst).optional(),
    ref0(blockType).optional(),
    ref0(blockVar).optional(),
    [ref0(blockProcedure), ref0(blockFunction)].toChoiceParser().star(),
    ref0(blockStatement),
  );

  Parser blockLabel() => seq3(
    ref1(token, 'label'),
    ref0(unsignedInteger).plusSeparated(ref1(token, ',')),
    ref1(token, ';'),
  );

  Parser blockConst() => seq2(
    ref1(token, 'const'),
    seq4(
      ref0(identifier),
      ref1(token, '='),
      ref0(constant),
      ref1(token, ';'),
    ).plus(),
  );

  Parser blockType() => seq2(
    ref1(token, 'type'),
    seq4(
      ref0(identifier),
      ref1(token, '='),
      ref0(type),
      ref1(token, ';'),
    ).plus(),
  );

  Parser blockVar() => seq2(
    ref1(token, 'var'),
    seq4(
      ref0(identifier).plusSeparated(ref1(token, ',')),
      ref1(token, ':'),
      ref0(type),
      ref1(token, ';'),
    ).plus(),
  );

  Parser blockProcedure() => seq6(
    ref1(token, 'procedure'),
    ref0(identifier),
    ref0(parameterList),
    ref1(token, ';'),
    ref0(block),
    ref1(token, ';'),
  );

  Parser blockFunction() => seq8(
    ref1(token, 'function'),
    ref0(identifier),
    ref0(parameterList),
    ref1(token, ':'),
    ref0(identifier),
    ref1(token, ';'),
    ref0(block),
    ref1(token, ';'),
  );

  Parser blockStatement() => seq3(
    ref1(token, 'begin'),
    ref0(statement).plusSeparated(ref1(token, ';')),
    ref1(token, 'end'),
  );

  // endregion

  // region type

  Parser type() => [
    ref0(simpleType),
    ref0(typePointer),
    seq2(
      ref1(token, 'packed').optional(),
      [
        ref0(typeSet),
        ref0(typeArray),
        ref0(typeRecord),
        ref0(typeFile),
      ].toChoiceParser(),
    ),
  ].toChoiceParser();

  Parser typePointer() => seq2(ref1(token, '^'), ref0(identifier));

  Parser typeSet() =>
      seq3(ref1(token, 'set'), ref1(token, 'of'), ref0(simpleType));

  Parser typeArray() => seq6(
    ref1(token, 'array'),
    ref1(token, '['),
    ref0(simpleType).plusSeparated(ref1(token, ',')),
    ref1(token, ']'),
    ref1(token, 'of'),
    ref0(type),
  );

  Parser typeRecord() =>
      seq3(ref1(token, 'record'), ref0(fieldList), ref1(token, 'end'));

  Parser typeFile() =>
      seq2(ref1(token, 'file'), seq2(ref1(token, 'of'), ref0(type)).optional());

  // endregion

  Parser identifier() => ref1(
    token,
    seq2(letter(), word().star()).flatten(message: 'identifier expected'),
  ).where((each) => !_keywords.contains(each));

  Parser variable() => seq2(
    ref0(identifier),
    [
      seq3(
        ref1(token, '['),
        ref0(expression).plusSeparated(ref1(token, ',')),
        ref1(token, ']'),
      ),
      seq2(ref1(token, '.'), ref0(identifier)),
      ref1(token, '^'),
    ].toChoiceParser().star(),
  );

  Parser unsignedNumber() => ref1(
    token,
    seq3(
      digit().plus(),
      seq2(char('.'), digit().plus()).optional(),
      seq3(pattern('eE'), pattern('+-').optional(), digit().plus()).optional(),
    ).flatten(message: 'unsigned number expected').map(num.parse),
  );

  Parser stringLiteral() => ref1(
    token,
    seq3(
      char("'"),
      pattern("^'").star(),
      char("'"),
    ).flatten(message: 'string expected'),
  );

  Parser expression() => seq2(
    ref0(simpleExpression),
    seq2(
      [
        ref1(token, '<'),
        ref1(token, '<='),
        ref1(token, '='),
        ref1(token, '<>'),
        ref1(token, '>='),
        ref1(token, '>'),
        ref1(token, 'in'),
      ].toChoiceParser(),
      ref0(simpleExpression),
    ).optional(),
  );

  Parser simpleExpression() => seq2(
    [ref1(token, '+'), ref1(token, '-')].toChoiceParser().optional(),
    ref0(term).plusSeparated(ref1(token, 'or')),
  ).plus();

  Parser term() => ref0(factor).plusSeparated(
    [
      ref1(token, '*'),
      ref1(token, '/'),
      ref1(token, 'div'),
      ref1(token, 'mod'),
      ref1(token, 'and'),
    ].toChoiceParser(),
  );

  Parser factor() => [
    seq3(ref1(token, '('), ref0(expression), ref1(token, ')')),
    seq2(ref1(token, 'not'), ref0(factor)),
    seq3(
      ref1(token, '['),
      seq2(
        ref0(expression),
        seq2(ref1(token, '..'), ref0(expression)).optional(),
      ).starSeparated(ref1(token, ',')),
      ref1(token, ']'),
    ),
    seq2(
      ref0(identifier),
      seq3(
        ref1(token, '('),
        ref0(expression).plusSeparated(ref1(token, ',')),
        ref1(token, ')'),
      ).optional(),
    ),
    ref0(unsignedConstant),
    ref0(variable),
  ].toChoiceParser();

  Parser unsignedConstant() => [
    ref1(token, 'nil'),
    ref0(stringLiteral),
    ref0(unsignedNumber),
    ref0(identifier),
  ].toChoiceParser();

  Parser parameterList() => seq3(
    ref1(token, '('),
    seq4(
      ref1(token, 'var').optional(),
      ref0(identifier).plusSeparated(ref1(token, ',')),
      ref1(token, ':'),
      ref0(identifier),
    ).plusSeparated(ref1(token, ';')),
    ref1(token, ')'),
  ).optional();

  Parser unsignedInteger() => ref1(
    token,
    digit().plusString(message: 'unsigned integer expected').map(int.parse),
  );

  Parser constant() => [
    seq2(
      pattern('+-'),
      [ref0(identifier), ref0(unsignedNumber)].toChoiceParser(),
    ),
    ref0(unsignedConstant),
  ].toChoiceParser();

  Parser simpleType() => [
    seq3(
      ref1(token, '('),
      ref0(identifier).plusSeparated(ref1(token, ',')),
      ref1(token, ')'),
    ),
    seq3(ref0(constant), ref1(token, '..'), ref0(constant)),
    ref0(identifier),
  ].toChoiceParser();

  Parser fieldList() => [
    seq2(ref0(fieldListBase), ref0(fieldListCase).optional()),
    ref0(fieldListCase),
  ].toChoiceParser();

  Parser fieldListBase() => seq3(
    ref0(identifier).plusSeparated(ref1(token, ',')),
    ref1(token, ':'),
    ref0(type),
  ).plusSeparated(ref1(token, ';'));

  Parser fieldListCase() => seq5(
    ref1(token, 'case'),
    seq2(ref0(identifier), ref1(token, ':')).optional(),
    ref0(identifier),
    ref1(token, 'of'),
    seq5(
      ref0(constant).plusSeparated(ref1(token, ',')),
      ref1(token, ':'),
      ref1(token, '('),
      ref0(fieldList),
      ref1(token, ')'),
    ).plusSeparated(ref1(token, ';')),
  );

  // region custom helpers
  Parser spacer() => [whitespace(), comment()].toChoiceParser().plus();

  Parser comment() => seq3(
    string('(*'),
    [ref0(comment), any()].toChoiceParser().starLazy(string('*)')),
    string('*)'),
  );

  final _keywords = <String>{};

  Parser token(Object source) {
    if (source is String) {
      final message = '"$source" expected';
      if (_isKeyword.accept(source)) {
        _keywords.add(source);
        return token(
          source
              .toParser(message: message, ignoreCase: true)
              .skip(after: word().not()),
        );
      } else {
        return token(source.toParser(message: message));
      }
    } else if (source is Parser) {
      return source.trim(ref0(spacer));
    } else {
      throw ArgumentError('Unknown token type: $source.');
    }
  }
}

final _isKeyword = word().plusString().end();

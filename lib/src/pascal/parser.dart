import 'package:petitparser/petitparser.dart';

import 'ast.dart';

/// Pascal parser definition producing strongly typed [PascalNode] AST nodes.
///
/// Based on the Apple Pascal Standard:
/// http://www.danamania.com/print/Apple%20Pascal%20Poster/PascalPosterV3%20A1.pdf
class PascalParserDefinition extends GrammarDefinition<ProgramNode> {
  @override
  Parser<ProgramNode> start() => ref0(program).end();

  Parser<ProgramNode> program() =>
      seq6(
        ref1(token, 'program'),
        ref0(identifier),
        seq3(
          ref1(token, '('),
          ref0(identifier)
              .plusSeparated(ref1(token, ','))
              .map((sep) => sep.elements),
          ref1(token, ')'),
        ).map3((_, params, _) => params).optionalWith(const <String>[]),
        ref1(token, ';'),
        ref0(block),
        ref1(token, '.'),
      ).map6(
        (_, name, params, _, block, _) =>
            ProgramNode(name: name, parameters: params, block: block),
      );

  // region statement
  Parser<StatementNode> statement() =>
      seq2(
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
        ].toChoiceParser().optional(),
      ).optional().map((values) {
        if (values == null) return const EmptyStatementNode();
        final (label, stmt) = values;
        if (stmt == null) return EmptyStatementNode(label: label);
        if (label != null) {
          return switch (stmt) {
            final CompoundStatementNode cs => CompoundStatementNode(
              label: label,
              statements: cs.statements,
            ),
            final AssignmentStatementNode a => AssignmentStatementNode(
              label: label,
              variable: a.variable,
              value: a.value,
            ),
            final ProcedureStatementNode p => ProcedureStatementNode(
              label: label,
              name: p.name,
              arguments: p.arguments,
            ),
            final IfStatementNode i => IfStatementNode(
              label: label,
              condition: i.condition,
              thenStatement: i.thenStatement,
              elseStatement: i.elseStatement,
            ),
            final CaseStatementNode c => CaseStatementNode(
              label: label,
              expression: c.expression,
              cases: c.cases,
            ),
            final WhileStatementNode w => WhileStatementNode(
              label: label,
              condition: w.condition,
              statement: w.statement,
            ),
            final RepeatStatementNode r => RepeatStatementNode(
              label: label,
              statements: r.statements,
              condition: r.condition,
            ),
            final ForStatementNode f => ForStatementNode(
              label: label,
              variable: f.variable,
              initialValue: f.initialValue,
              isDownTo: f.isDownTo,
              finalValue: f.finalValue,
              statement: f.statement,
            ),
            final WithStatementNode wt => WithStatementNode(
              label: label,
              records: wt.records,
              statement: wt.statement,
            ),
            final GotoStatementNode g => GotoStatementNode(
              label: label,
              targetLabel: g.targetLabel,
            ),
            EmptyStatementNode _ => EmptyStatementNode(label: label),
          };
        }
        return stmt;
      });

  Parser<String> statementLabel() => seq2(
    ref0(unsignedInteger),
    ref1(token, ':'),
  ).map2((n, _) => n.toString());

  Parser<AssignmentStatementNode> statementAssign() =>
      seq3(ref0(variable), ref1(token, ':='), ref0(expression)).map3(
        (variable, _, value) =>
            AssignmentStatementNode(variable: variable, value: value),
      );

  Parser<ProcedureStatementNode> statementCall() => seq2(
    ref0(identifier),
    seq3(
      ref1(token, '('),
      ref0(expression)
          .plusSeparated(ref1(token, ','))
          .map((sep) => sep.elements),
      ref1(token, ')'),
    ).map3((_, args, _) => args).optionalWith(const <ExpressionNode>[]),
  ).map2((name, args) => ProcedureStatementNode(name: name, arguments: args));

  Parser<CompoundStatementNode> statementBlock() => seq3(
    ref1(token, 'begin'),
    ref0(statement).plusSeparated(ref1(token, ';')).map((sep) => sep.elements),
    ref1(token, 'end'),
  ).map3((_, stmts, _) => CompoundStatementNode(statements: stmts));

  Parser<IfStatementNode> statementIf() =>
      seq5(
        ref1(token, 'if'),
        ref0(expression),
        ref1(token, 'then'),
        ref0(statement),
        seq2(ref1(token, 'else'), ref0(statement)).map2((_, s) => s).optional(),
      ).map5(
        (_, cond, _, thenStmt, elseStmt) => IfStatementNode(
          condition: cond,
          thenStatement: thenStmt,
          elseStatement: elseStmt,
        ),
      );

  Parser<RepeatStatementNode> statementRepeat() =>
      seq4(
        ref1(token, 'repeat'),
        ref0(statement)
            .plusSeparated(ref1(token, ';'))
            .map((sep) => sep.elements),
        ref1(token, 'until'),
        ref0(expression),
      ).map4(
        (_, stmts, _, cond) =>
            RepeatStatementNode(statements: stmts, condition: cond),
      );

  Parser<WhileStatementNode> statementWhile() =>
      seq4(
        ref1(token, 'while'),
        ref0(expression),
        ref1(token, 'do'),
        ref0(statement),
      ).map4(
        (_, cond, _, stmt) =>
            WhileStatementNode(condition: cond, statement: stmt),
      );

  Parser<ForStatementNode> statementFor() =>
      seq8(
        ref1(token, 'for'),
        ref0(identifier),
        ref1(token, ':='),
        ref0(expression),
        [ref1(token, 'to'), ref1(token, 'downto')].toChoiceParser(),
        ref0(expression),
        ref1(token, 'do'),
        ref0(statement),
      ).map8(
        (_, variable, _, initVal, dir, finalVal, _, stmt) => ForStatementNode(
          variable: variable,
          initialValue: initVal,
          isDownTo: dir.toLowerCase() == 'downto',
          finalValue: finalVal,
          statement: stmt,
        ),
      );

  Parser<CaseStatementNode> statementCase() =>
      seq5(
        ref1(token, 'case'),
        ref0(expression),
        ref1(token, 'of'),
        seq3(
              ref0(constant)
                  .plusSeparated(ref1(token, ','))
                  .map((sep) => sep.elements),
              ref1(token, ':'),
              ref0(statement),
            )
            .map3(
              (consts, _, stmt) =>
                  CaseElementNode(constants: consts, statement: stmt),
            )
            .plusSeparated(ref1(token, ';'))
            .map((sep) => sep.elements),
        ref1(token, 'end'),
      ).map5(
        (_, expr, _, cases, _) =>
            CaseStatementNode(expression: expr, cases: cases),
      );

  Parser<WithStatementNode> statementWith() =>
      seq4(
        ref1(token, 'with'),
        ref0(variable)
            .plusSeparated(ref1(token, ','))
            .map((sep) => sep.elements),
        ref1(token, 'do'),
        ref0(statement),
      ).map4(
        (_, records, _, stmt) =>
            WithStatementNode(records: records, statement: stmt),
      );

  Parser<GotoStatementNode> statementGoto() => seq2(
    ref1(token, 'goto'),
    ref0(unsignedInteger),
  ).map2((_, target) => GotoStatementNode(targetLabel: target.toString()));

  Parser<ProcedureStatementNode> statementExit() =>
      seq4(
        ref1(token, 'exit'),
        ref1(token, '('),
        [ref1(token, 'program'), ref0(identifier)].toChoiceParser(),
        ref1(token, ')'),
      ).map4(
        (_, _, target, _) => ProcedureStatementNode(
          name: 'exit',
          arguments: [VariableExpressionNode(target)],
        ),
      );
  // endregion

  // region block
  Parser<BlockNode> block() =>
      seq6(
        ref0(blockLabel).optionalWith(const <String>[]),
        ref0(blockConst).optionalWith(const <ConstantDefinitionNode>[]),
        ref0(blockType).optionalWith(const <TypeDefinitionNode>[]),
        ref0(blockVar).optionalWith(const <VariableDeclarationNode>[]),
        [ref0(blockProcedure), ref0(blockFunction)].toChoiceParser().star(),
        ref0(blockStatement),
      ).map6(
        (labels, constants, types, variables, subroutines, statement) =>
            BlockNode(
              labels: labels,
              constants: constants,
              types: types,
              variables: variables,
              subroutines: subroutines,
              statement: statement,
            ),
      );

  Parser<List<String>> blockLabel() => seq3(
    ref1(token, 'label'),
    ref0(unsignedInteger).plusSeparated(ref1(token, ',')),
    ref1(token, ';'),
  ).map3((_, labels, _) => labels.elements.map((e) => e.toString()).toList());

  Parser<List<ConstantDefinitionNode>> blockConst() => seq2(
    ref1(token, 'const'),
    seq4(ref0(identifier), ref1(token, '='), ref0(constant), ref1(token, ';'))
        .map4(
          (name, _, value, _) =>
              ConstantDefinitionNode(name: name, value: value),
        )
        .plus(),
  ).map2((_, constants) => constants);

  Parser<List<TypeDefinitionNode>> blockType() => seq2(
    ref1(token, 'type'),
    seq4(ref0(identifier), ref1(token, '='), ref0(type), ref1(token, ';'))
        .map4((name, _, type, _) => TypeDefinitionNode(name: name, type: type))
        .plus(),
  ).map2((_, types) => types);

  Parser<List<VariableDeclarationNode>> blockVar() => seq2(
    ref1(token, 'var'),
    seq4(
          ref0(identifier)
              .plusSeparated(ref1(token, ','))
              .map((sep) => sep.elements),
          ref1(token, ':'),
          ref0(type),
          ref1(token, ';'),
        )
        .map4(
          (names, _, type, _) =>
              VariableDeclarationNode(names: names, type: type),
        )
        .plus(),
  ).map2((_, vars) => vars);

  Parser<ProcedureNode> blockProcedure() =>
      seq6(
        ref1(token, 'procedure'),
        ref0(identifier),
        ref0(parameterList).optionalWith(const <FormalParameterNode>[]),
        ref1(token, ';'),
        ref0(block),
        ref1(token, ';'),
      ).map6(
        (_, name, params, _, block, _) => ProcedureNode(
          name: name,
          parameters: params ?? const [],
          block: block,
        ),
      );

  Parser<FunctionNode> blockFunction() =>
      seq8(
        ref1(token, 'function'),
        ref0(identifier),
        ref0(parameterList).optionalWith(const <FormalParameterNode>[]),
        ref1(token, ':'),
        ref0(identifier),
        ref1(token, ';'),
        ref0(block),
        ref1(token, ';'),
      ).map8(
        (_, name, params, _, returnTypeName, _, block, _) => FunctionNode(
          name: name,
          parameters: params ?? const [],
          returnType: SimpleTypeNode(returnTypeName),
          block: block,
        ),
      );

  Parser<CompoundStatementNode> blockStatement() =>
      seq3(
        ref1(token, 'begin'),
        ref0(statement)
            .plusSeparated(ref1(token, ';'))
            .map((sep) => sep.elements),
        ref1(token, 'end'),
      ).map3((_, stmts, _) {
        final list = stmts.where((s) => s is! EmptyStatementNode).toList();
        return CompoundStatementNode(statements: list.isEmpty ? stmts : list);
      });
  // endregion

  // region type
  Parser<TypeNode> type() => [
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
    ).map2((_, type) => type),
  ].toChoiceParser();

  Parser<PointerTypeNode> typePointer() => seq2(
    ref1(token, '^'),
    ref0(identifier),
  ).map2((_, name) => PointerTypeNode(SimpleTypeNode(name)));

  Parser<SetTypeNode> typeSet() => seq3(
    ref1(token, 'set'),
    ref1(token, 'of'),
    ref0(simpleType),
  ).map3((_, _, base) => SetTypeNode(base));

  Parser<ArrayTypeNode> typeArray() =>
      seq6(
        ref1(token, 'array'),
        ref1(token, '['),
        ref0(simpleType)
            .plusSeparated(ref1(token, ','))
            .map((sep) => sep.elements),
        ref1(token, ']'),
        ref1(token, 'of'),
        ref0(type),
      ).map6(
        (_, _, indices, _, _, elementType) =>
            ArrayTypeNode(indices: indices, elementType: elementType),
      );

  Parser<RecordTypeNode> typeRecord() => seq3(
    ref1(token, 'record'),
    ref0(fieldList),
    ref1(token, 'end'),
  ).map3((_, fields, _) => RecordTypeNode(fields: fields));

  Parser<FileTypeNode> typeFile() => seq2(
    ref1(token, 'file'),
    seq2(ref1(token, 'of'), ref0(type)).map2((_, type) => type).optional(),
  ).map2((_, base) => FileTypeNode(base));

  Parser<TypeNode> simpleType() => [
    seq3(
      ref1(token, '('),
      ref0(identifier)
          .plusSeparated(ref1(token, ','))
          .map((sep) => sep.elements),
      ref1(token, ')'),
    ).map3((_, names, _) => EnumeratedTypeNode(names)),
    seq3(
      ref0(constant),
      ref1(token, '..'),
      ref0(constant),
    ).map3((start, _, end) => SubrangeTypeNode(start: start, end: end)),
    ref0(identifier).map(SimpleTypeNode.new),
  ].toChoiceParser();

  Parser<List<VariableDeclarationNode>> fieldList() => [
    seq2(
      ref0(fieldListBase),
      ref0(fieldListCase).optional(),
    ).map2((base, _) => base),
    ref0(fieldListCase).map((_) => const <VariableDeclarationNode>[]),
  ].toChoiceParser();

  Parser<List<VariableDeclarationNode>> fieldListBase() =>
      seq3(
            ref0(identifier)
                .plusSeparated(ref1(token, ','))
                .map((sep) => sep.elements),
            ref1(token, ':'),
            ref0(type),
          )
          .map3(
            (names, _, type) =>
                VariableDeclarationNode(names: names, type: type),
          )
          .plusSeparated(ref1(token, ';'))
          .skip(after: ref1(token, ';').optional())
          .map((sep) => sep.elements);

  Parser<void> fieldListCase() => seq5(
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
  // endregion

  Parser<String> identifier() => seq2(letter(), word().star())
      .flatten(message: 'identifier expected')
      .where((each) => !_keywords.contains(each))
      .trim(ref0(spacer));

  Parser<ExpressionNode> variable() =>
      seq2(
        ref0(identifier),
        [
          seq3(
            ref1(token, '['),
            ref0(expression)
                .plusSeparated(ref1(token, ','))
                .map((sep) => sep.elements),
            ref1(token, ']'),
          ).map3(
            (_, indices, _) => (indices: indices, field: null, isDeref: false),
          ),
          seq2(ref1(token, '.'), ref0(identifier)).map2(
            (_, field) => (
              indices: const <ExpressionNode>[],
              field: field,
              isDeref: false,
            ),
          ),
          ref1(token, '^').map(
            (_) =>
                (indices: const <ExpressionNode>[], field: null, isDeref: true),
          ),
        ].toChoiceParser().star(),
      ).map2((name, accessors) {
        ExpressionNode current = VariableExpressionNode(name);
        for (final acc in accessors) {
          if (acc.isDeref) {
            current = PointerDereferenceExpressionNode(current);
          } else if (acc.field != null) {
            current = FieldAccessExpressionNode(
              record: current,
              field: acc.field!,
            );
          } else {
            current = ArrayAccessExpressionNode(
              array: current,
              indices: acc.indices,
            );
          }
        }
        return current;
      });

  Parser<num> unsignedNumber() =>
      seq3(
            digit().plus(),
            seq2(char('.'), digit().plus()).optional(),
            seq3(
              pattern('eE'),
              pattern('+-').optional(),
              digit().plus(),
            ).optional(),
          )
          .flatten(message: 'unsigned number expected')
          .map(num.parse)
          .trim(ref0(spacer));

  Parser<String> stringLiteral() => seq3(
    char("'"),
    pattern("^'").starString(),
    char("'"),
  ).flatten(message: 'string expected').trim(ref0(spacer));

  Parser<ExpressionNode> expression() =>
      seq2(
        ref0(simpleExpression),
        seq2(
          [
            ref1(token, '<='),
            ref1(token, '<>'),
            ref1(token, '<'),
            ref1(token, '>='),
            ref1(token, '>'),
            ref1(token, '='),
            ref1(token, 'in'),
          ].toChoiceParser(),
          ref0(simpleExpression),
        ).optional(),
      ).map2((left, rightPart) {
        if (rightPart == null) return left;
        return BinaryExpressionNode(
          operator: rightPart.$1,
          left: left,
          right: rightPart.$2,
        );
      });

  Parser<ExpressionNode> simpleExpression() =>
      seq2(
        [ref1(token, '+'), ref1(token, '-')].toChoiceParser().optional(),
        ref0(term).plusSeparated(ref1(token, 'or')),
      ).plus().map((list) {
        ExpressionNode? result;
        for (final (prefix, termsSep) in list) {
          final terms = termsSep.elements;
          var termExpr = terms.first;
          for (var i = 1; i < terms.length; i++) {
            termExpr = BinaryExpressionNode(
              operator: 'or',
              left: termExpr,
              right: terms[i],
            );
          }
          if (prefix != null) {
            termExpr = UnaryExpressionNode(operator: prefix, operand: termExpr);
          }
          result = result == null
              ? termExpr
              : BinaryExpressionNode(
                  operator: '+',
                  left: result,
                  right: termExpr,
                );
        }
        return result!;
      });

  Parser<ExpressionNode> term() => ref0(factor)
      .plusSeparated(
        [
          ref1(token, '*'),
          ref1(token, '/'),
          ref1(token, 'div'),
          ref1(token, 'mod'),
          ref1(token, 'and'),
        ].toChoiceParser(),
      )
      .map((sep) {
        final factors = sep.elements;
        final operators = sep.separators;
        var result = factors.first;
        for (var i = 0; i < operators.length; i++) {
          result = BinaryExpressionNode(
            operator: operators[i],
            left: result,
            right: factors[i + 1],
          );
        }
        return result;
      });

  Parser<ExpressionNode> factor() => [
    seq3(
      ref1(token, '('),
      ref0(expression),
      ref1(token, ')'),
    ).map3((_, expr, _) => expr),
    seq2(
      ref1(token, 'not'),
      ref0(factor),
    ).map2((_, f) => UnaryExpressionNode(operator: 'not', operand: f)),
    seq3(
      ref1(token, '['),
      seq2(
            ref0(expression),
            seq2(
              ref1(token, '..'),
              ref0(expression),
            ).map2((_, e) => e).optional(),
          )
          .map2((start, end) => SetElementNode(start: start, end: end))
          .starSeparated(ref1(token, ','))
          .map((sep) => sep.elements),
      ref1(token, ']'),
    ).map3((_, elems, _) => SetExpressionNode(elems)),
    seq4(
      ref0(identifier),
      ref1(token, '('),
      ref0(expression)
          .plusSeparated(ref1(token, ','))
          .map((sep) => sep.elements),
      ref1(token, ')'),
    ).map4(
      (name, _, args, _) =>
          FunctionCallExpressionNode(name: name, arguments: args),
    ),
    ref0(variable),
    ref0(unsignedConstant),
  ].toChoiceParser();

  Parser<LiteralExpressionNode> unsignedConstant() => [
    ref1(
      token,
      'nil',
    ).map((_) => const LiteralExpressionNode(raw: 'nil', value: null)),
    ref0(stringLiteral).map((s) => LiteralExpressionNode(raw: s, value: s)),
    ref0(unsignedNumber)
        .map((n) => LiteralExpressionNode(raw: n.toString(), value: n)),
    ref0(identifier).map((id) => LiteralExpressionNode(raw: id, value: id)),
  ].toChoiceParser();

  Parser<List<FormalParameterNode>?> parameterList() => seq3(
    ref1(token, '('),
    seq4(
          ref1(token, 'var').optional(),
          ref0(identifier)
              .plusSeparated(ref1(token, ','))
              .map((sep) => sep.elements),
          ref1(token, ':'),
          ref0(identifier),
        )
        .map4(
          (varKeyword, names, _, type) => FormalParameterNode(
            names: names,
            type: SimpleTypeNode(type),
            isVar: varKeyword != null,
          ),
        )
        .plusSeparated(ref1(token, ';'))
        .map((sep) => sep.elements),
    ref1(token, ')'),
  ).map3((_, params, _) => params).optional();

  Parser<int> unsignedInteger() => digit()
      .plusString(message: 'unsigned integer expected')
      .map(int.parse)
      .trim(ref0(spacer));

  Parser<LiteralExpressionNode> constant() => [
    seq2(
      pattern('+-'),
      [
        ref0(identifier).map((s) => (s, null)),
        ref0(unsignedNumber).map((n) => (null, n)),
      ].toChoiceParser(),
    ).map2((sign, val) {
      final (id, numVal) = val;
      if (numVal != null) {
        final signedVal = sign == '-' ? -numVal : numVal;
        return LiteralExpressionNode(raw: '$sign$numVal', value: signedVal);
      }
      return LiteralExpressionNode(raw: '$sign$id', value: '$sign$id');
    }),
    ref0(unsignedConstant),
  ].toChoiceParser();

  // region custom helpers
  Parser<void> spacer() =>
      [whitespace(), ref0(comment)].toChoiceParser().plus();

  Parser<void> comment() => seq3(
    string('(*'),
    [ref0(comment), any()].toChoiceParser().starLazy(string('*)')),
    string('*)'),
  );

  final _keywords = <String>{};

  Parser<String> token(String string) {
    if (_isKeyword.accept(string)) {
      _keywords.add(string);
      return string
          .toParser(message: '"$string" expected', ignoreCase: true)
          .skip(after: word().not())
          .trim(ref0(spacer));
    }
    return string.toParser(message: '"$string" expected').trim(ref0(spacer));
  }
  // endregion
}

final _isKeyword = word().plusString().end();

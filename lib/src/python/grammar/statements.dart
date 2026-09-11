import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'declarations.dart';
import 'expressions.dart';
import 'lexical.dart';
import 'patterns.dart';

/// Mixin for Python statements and suites.
mixin PythonStatementGrammar
    on
        GrammarDefinition<ModuleNode>,
        PythonLexicalGrammar,
        PythonPatternGrammar,
        PythonExpressionGrammar,
        PythonDeclarationGrammar {
  /// Top-level module statements parser.
  Parser<List<StatementNode>> statements() =>
      seq2(ref0(blankLines), ref0(statementLine))
          .map2((_, stmts) => stmts)
          .plus()
          .map((lines) => lines.expand((l) => l).toList());

  /// A line of statements (simple or compound).
  Parser<List<StatementNode>> statementLine() => [
    ref0(compoundStatement).map((s) => [s]),
    ref0(simpleStatements),
  ].toChoiceParser();

  /// Suite / Block of statements: either a simple inline statement or an
  /// indented block of statements.
  @override
  Parser<List<StatementNode>> suite() =>
      [ref0(indentedBlock), ref0(simpleStatements)].toChoiceParser();

  /// Indented block of statements.
  Parser<List<StatementNode>> indentedBlock() => seq5(
    ref0(newlineToken),
    ref0(blankLines),
    indent.increase,
    ref0(indentedStatements),
    indent.decrease,
  ).map5((_, _, _, stmts, _) => stmts);

  Parser<List<StatementNode>> indentedStatements() =>
      ref0(indentedStatementLine)
          .plus()
          .map((lines) => lines.expand((l) => l).toList());

  Parser<List<StatementNode>> indentedStatementLine() => seq3(
    ref0(blankLines),
    indent.same,
    ref0(statementLine),
  ).map3((_, _, stmts) => stmts);

  // ---------------------------------------------------------------------------
  // Compound Statements
  // ---------------------------------------------------------------------------

  Parser<StatementNode> compoundStatement() => [
    ref0(ifStatement),
    ref0(whileStatement),
    ref0(forStatement),
    ref0(tryStatement),
    ref0(withStatement),
    ref0(matchStatement),
    ref0(functionDefinition),
    ref0(classDefinition),
  ].toChoiceParser();

  // If statement
  Parser<IfNode> ifStatement() =>
      seq5(
        ref0(ifToken),
        ref0(expression),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ref0(elifClause).star(),
        ref0(elseClause).optional(),
      ).map5((_, test, body, elifs, elseBody) {
        var currentElse = elseBody ?? const <StatementNode>[];
        for (var i = elifs.length - 1; i >= 0; i--) {
          final elif = elifs[i];
          currentElse = [
            IfNode(test: elif.test, body: elif.body, orelse: currentElse),
          ];
        }
        return IfNode(test: test, body: body, orelse: currentElse);
      });

  Parser<({ExpressionNode test, List<StatementNode> body})> elifClause() =>
      seq3(
        ref0(blankLines),
        indent.same,
        seq3(
          ref0(elifToken),
          ref0(expression),
          seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ),
      ).map3((_, _, clause) => (test: clause.$2, body: clause.$3));

  Parser<List<StatementNode>> elseClause() => seq3(
    ref0(blankLines),
    indent.same,
    seq2(
      ref0(elseToken),
      seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
    ),
  ).map3((_, _, clause) => clause.$2);

  // While statement
  Parser<WhileNode> whileStatement() =>
      seq4(
        ref0(whileToken),
        ref0(expression),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ref0(elseClause).optional(),
      ).map4(
        (_, test, body, orelse) =>
            WhileNode(test: test, body: body, orelse: orelse ?? const []),
      );

  // For statement
  Parser<StatementNode> forStatement() =>
      seq5(
        ref0(asyncToken).optional(),
        ref0(forToken),
        seq3(ref0(starTargets), ref0(inToken), ref0(expressionList)),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ref0(elseClause).optional(),
      ).map5((isAsync, _, inSeq, body, orelse) {
        if (isAsync != null) {
          return AsyncForNode(
            target: inSeq.$1,
            iter: inSeq.$3,
            body: body,
            orelse: orelse ?? const [],
          );
        }
        return ForNode(
          target: inSeq.$1,
          iter: inSeq.$3,
          body: body,
          orelse: orelse ?? const [],
        );
      });

  // With statement
  Parser<StatementNode> withStatement() =>
      seq4(
        ref0(asyncToken).optional(),
        ref0(withToken),
        [
          seq3(
            ref1(token, '('),
            ignore(ref0(withItems)),
            ref1(token, ')'),
          ).map3((_, items, _) => items),
          ref0(withItems),
        ].toChoiceParser(),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
      ).map4((isAsync, _, items, body) {
        if (isAsync != null) {
          return AsyncWithNode(items: items, body: body);
        }
        return WithNode(items: items, body: body);
      });

  Parser<List<WithItemNode>> withItems() => seq2(
    ref0(withItem).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => seq.elements);

  Parser<WithItemNode> withItem() => seq2(
    ref0(expression),
    seq2(ref0(asToken), ref0(expression)).map2((_, e) => e).optional(),
  ).map2((ctx, vars) => WithItemNode(contextExpr: ctx, optionalVars: vars));

  // Try statement
  Parser<StatementNode> tryStatement() =>
      seq5(
        ref0(tryToken),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        [
          ref0(exceptStarHandler).plus(),
          ref0(exceptHandler).star(),
        ].toChoiceParser(),
        ref0(elseClause).optional(),
        ref0(finallyClause).optional(),
      ).map5((_, body, handlers, orelse, finalbody) {
        final parsedHandlers = handlers;
        final isTryStar =
            parsedHandlers.isNotEmpty &&
            parsedHandlers.first.name?.startsWith('*') == true;
        if (isTryStar) {
          return TryStarNode(
            body: body,
            handlers: parsedHandlers,
            orelse: orelse ?? const [],
            finalbody: finalbody ?? const [],
          );
        }
        return TryNode(
          body: body,
          handlers: parsedHandlers,
          orelse: orelse ?? const [],
          finalbody: finalbody ?? const [],
        );
      });

  Parser<ExceptHandlerNode> exceptHandler() =>
      seq3(
        ref0(blankLines),
        indent.same,
        seq4(
          ref0(exceptToken),
          ref0(expression).optional(),
          seq2(ref0(asToken), ref0(identifier)).map2((_, id) => id).optional(),
          seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ),
      ).map3(
        (_, _, clause) => ExceptHandlerNode(
          type: clause.$2,
          name: clause.$3,
          body: clause.$4,
        ),
      );

  Parser<ExceptHandlerNode> exceptStarHandler() =>
      seq3(
        ref0(blankLines),
        indent.same,
        seq5(
          ref0(exceptToken),
          ref1(token, '*'),
          ref0(expression),
          seq2(ref0(asToken), ref0(identifier)).map2((_, id) => id).optional(),
          seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ),
      ).map3(
        (_, _, clause) => ExceptHandlerNode(
          type: clause.$3,
          name: '*${clause.$4 ?? ''}',
          body: clause.$5,
        ),
      );

  Parser<List<StatementNode>> finallyClause() => seq3(
    ref0(blankLines),
    indent.same,
    seq2(
      ref0(finallyToken),
      seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
    ),
  ).map3((_, _, clause) => clause.$2);

  // Match statement
  Parser<MatchNode> matchStatement() => seq4(
    ref0(matchToken),
    ref0(expression),
    seq2(ref1(token, ':'), ref0(newlineToken)).map2((_, _) => null),
    seq4(
      ref0(blankLines),
      indent.increase,
      ref0(caseBlock).plus(),
      indent.decrease,
    ).map4((_, _, cases, _) => cases),
  ).map4((_, subject, _, cases) => MatchNode(subject: subject, cases: cases));

  Parser<MatchCaseNode> caseBlock() =>
      seq3(
        ref0(blankLines),
        indent.same,
        seq4(
          ref0(caseToken),
          ref0(pythonPattern),
          seq2(ref0(ifToken), ref0(expression)).map2((_, e) => e).optional(),
          seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
        ),
      ).map3(
        (_, _, clause) => MatchCaseNode(
          pattern: clause.$2,
          guard: clause.$3,
          body: clause.$4,
        ),
      );

  // ---------------------------------------------------------------------------
  // Simple Statements
  // ---------------------------------------------------------------------------

  Parser<List<StatementNode>> simpleStatements() => seq3(
    ref0(simpleStatement).plusSeparated(ref1(token, ';')),
    ref1(token, ';').optional(),
    ref0(newlineToken).or(endOfInput()),
  ).map3((seq, _, _) => seq.elements);

  Parser<StatementNode> simpleStatement() => [
    ref0(assertStatement),
    ref0(assignmentStatement),
    ref0(typeAliasStatement),
    ref0(passStatement),
    ref0(delStatement),
    ref0(returnStatement),
    ref0(yieldStatement),
    ref0(raiseStatement),
    ref0(breakStatement),
    ref0(continueStatement),
    ref0(importStatement),
    ref0(globalStatement),
    ref0(nonlocalStatement),
    ref0(expressionStatement),
  ].toChoiceParser();

  Parser<AssertNode> assertStatement() => seq3(
    ref0(assertToken),
    ref0(expression),
    seq2(ref1(token, ','), ref0(expression)).map2((_, e) => e).optional(),
  ).map3((_, test, msg) => AssertNode(test: test, msg: msg));

  Parser<StatementNode> assignmentStatement() => [
    ref0(augAssignStatement),
    ref0(annAssignStatement),
    ref0(standardAssignStatement),
  ].toChoiceParser();

  Parser<AugAssignNode> augAssignStatement() =>
      seq3(
        ref0(expression),
        [
          ref1(token, '+='),
          ref1(token, '-='),
          ref1(token, '*='),
          ref1(token, '/='),
          ref1(token, '//='),
          ref1(token, '%='),
          ref1(token, '@='),
          ref1(token, '&='),
          ref1(token, '|='),
          ref1(token, '^='),
          ref1(token, '<<='),
          ref1(token, '>>='),
          ref1(token, '**='),
        ].toChoiceParser().map((t) => t.value),
        ref0(expression),
      ).map3(
        (target, op, val) =>
            AugAssignNode(target: target, operator: op, value: val),
      );

  Parser<AnnAssignNode> annAssignStatement() =>
      seq3(
        ref0(expression),
        seq2(ref1(token, ':'), ref0(expression)).map2((_, e) => e),
        seq2(ref0(assignToken), ref0(expression)).map2((_, e) => e).optional(),
      ).map3(
        (target, ann, val) =>
            AnnAssignNode(target: target, annotation: ann, value: val),
      );

  Parser<AssignNode> standardAssignStatement() => seq2(
    seq2(ref0(starTargets), ref0(assignToken)).map2((e, _) => e).plus(),
    ref0(expressionList),
  ).map2((targets, val) => AssignNode(targets: targets, value: val));

  Parser<TypeAliasNode> typeAliasStatement() =>
      seq5(
        ref0(typeToken),
        ref0(identifier).map(NameNode.new),
        ref0(typeParams).optional(),
        ref0(assignToken),
        ref0(expression),
      ).map5(
        (_, name, tParams, _, val) => TypeAliasNode(
          name: name,
          value: val,
          typeParams: tParams ?? const [],
        ),
      );

  Parser<PassNode> passStatement() =>
      ref0(passToken).map((_) => const PassNode());

  Parser<DeleteNode> delStatement() =>
      seq2(ref0(delToken), ref0(expressionList)).map2((_, expr) {
        if (expr is TupleNode) return DeleteNode(expr.elements);
        return DeleteNode([expr]);
      });

  Parser<ReturnNode> returnStatement() => seq2(
    ref0(returnToken),
    ref0(expressionList).optional(),
  ).map2((_, val) => ReturnNode(val));

  Parser<ExprStatementNode> yieldStatement() =>
      ref0(yieldExpression).map(ExprStatementNode.new);

  Parser<RaiseNode> raiseStatement() => seq3(
    ref0(raiseToken),
    ref0(expression).optional(),
    seq2(ref0(fromToken), ref0(expression)).map2((_, e) => e).optional(),
  ).map3((_, exc, cause) => RaiseNode(exc: exc, cause: cause));

  Parser<BreakNode> breakStatement() =>
      ref0(breakToken).map((_) => const BreakNode());

  Parser<ContinueNode> continueStatement() =>
      ref0(continueToken).map((_) => const ContinueNode());

  Parser<StatementNode> importStatement() =>
      [ref0(importName), ref0(importFrom)].toChoiceParser();

  Parser<ImportNode> importName() => seq2(
    ref0(importToken),
    ref0(dottedAsNames),
  ).map2((_, names) => ImportNode(names));

  Parser<List<AliasNode>> dottedAsNames() => seq2(
    ref0(dottedAsName).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => seq.elements);

  Parser<AliasNode> dottedAsName() => seq2(
    ref0(dottedName),
    seq2(ref0(asToken), ref0(identifier)).map2((_, id) => id).optional(),
  ).map2((name, asname) => AliasNode(name: name, asname: asname));

  Parser<ImportFromNode> importFrom() =>
      seq4(
        ref0(fromToken),
        seq2(
          ref1(token, '.').star().flatten().map((dots) => dots.length),
          ref0(dottedName).optional(),
        ),
        ref0(importToken),
        [
          ref1(token, '*').map((_) => [const AliasNode(name: '*')]),
          seq3(
            ref1(token, '('),
            ignore(ref0(dottedAsNames)),
            ref1(token, ')'),
          ).map3((_, names, _) => names),
          ref0(dottedAsNames),
        ].toChoiceParser(),
      ).map4(
        (_, moduleSpec, _, names) => ImportFromNode(
          module: moduleSpec.$2,
          level: moduleSpec.$1,
          names: names,
        ),
      );

  Parser<GlobalNode> globalStatement() => seq2(
    ref0(globalToken),
    ref0(identifier).plusSeparated(ref1(token, ',')).map((seq) => seq.elements),
  ).map2((_, ids) => GlobalNode(ids));

  Parser<NonlocalNode> nonlocalStatement() => seq2(
    ref0(nonlocalToken),
    ref0(identifier).plusSeparated(ref1(token, ',')).map((seq) => seq.elements),
  ).map2((_, ids) => NonlocalNode(ids));

  Parser<ExprStatementNode> expressionStatement() =>
      ref0(expressionList).map(ExprStatementNode.new);
}

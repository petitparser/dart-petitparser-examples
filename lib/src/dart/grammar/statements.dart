import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'expressions.dart';
import 'lexical.dart';
import 'patterns.dart';
import 'types.dart';

/// Mixin for Dart statement syntax.
mixin DartStatementGrammar
    on
        GrammarDefinition<CompilationUnitNode>,
        DartLexicalGrammar,
        DartTypeGrammar,
        DartPatternGrammar,
        DartExpressionGrammar {
  /// The main statement production.
  Parser<StatementNode> statement() => [
    ref0(emptyStatement),
    ref0(labeledStatement),
    ref0(block),
    ref0(functionDeclarationStatement),
    ref0(patternVariableDeclarationStatement),
    ref0(variableDeclarationStatement),
    ref0(ifStatement),
    ref0(forStatement),
    ref0(whileStatement),
    ref0(doWhileStatement),
    ref0(switchStatement),
    ref0(tryStatement),
    ref0(returnStatement),
    ref0(breakStatement),
    ref0(continueStatement),
    ref0(rethrowStatement),
    ref0(yieldStatement),
    ref0(assertStatement),
    ref0(expressionStatement),
  ].toChoiceParser();

  /// Abstract declaration for function declarations defined in DartDeclarationGrammar.
  Parser<FunctionDeclarationNode> functionDeclaration();

  /// A function declaration used as a statement.
  Parser<FunctionDeclarationStatementNode> functionDeclarationStatement() =>
      ref0(functionDeclaration).map(FunctionDeclarationStatementNode.new);

  // ---------------------------------------------------------------------------
  // Block & Expression Statement
  // ---------------------------------------------------------------------------

  @override
  Parser<BlockStatementNode> block() => seq3(
    ref1(token, '{'),
    ref0(statement).star(),
    ref1(token, '}'),
  ).map3((_, stmts, _) => BlockStatementNode(stmts));

  Parser<EmptyStatementNode> emptyStatement() =>
      ref1(token, ';').map((_) => const EmptyStatementNode());

  Parser<ExpressionStatementNode> expressionStatement() => seq2(
    ref0(expression),
    ref1(token, ';'),
  ).map2((expr, _) => ExpressionStatementNode(expr));

  Parser<LabeledStatementNode> labeledStatement() =>
      seq3(ref0(identifier), ref1(token, ':'), ref0(statement)).map3(
        (label, _, stmt) => LabeledStatementNode(label: label, statement: stmt),
      );

  // ---------------------------------------------------------------------------
  // Variable Declarations
  // ---------------------------------------------------------------------------

  Parser<PatternVariableDeclarationStatementNode>
  patternVariableDeclarationStatement() =>
      seq4(
        [ref0(varToken), ref0(finalToken)].toChoiceParser().map((t) => t.value),
        ref0(outerPattern),
        ref1(token, '='),
        seq2(ref0(expression), ref1(token, ';')),
      ).map4(
        (kw, p, _, exprAndSemi) => PatternVariableDeclarationStatementNode(
          keyword: kw,
          pattern: p,
          expression: exprAndSemi.$1,
        ),
      );

  Parser<VariableDeclarationStatementNode> variableDeclarationStatement() =>
      seq2(ref0(variableDeclaration), ref1(token, ';')).map2((decl, _) => decl);

  Parser<VariableDeclarationStatementNode> variableDeclaration() => [
    // 1. var x = 1, y = 2; (var cannot be accompanied by a type)
    seq3(
      ref0(lateToken).optional(),
      ref0(varToken),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
    ).map3(
      (lateKw, _, vars) => VariableDeclarationStatementNode(
        variables: vars,
        isLate: lateKw != null,
        isVar: true,
      ),
    ),
    // 2. final / const with explicit type: final int x = 1;
    seq4(
      ref0(lateToken).optional(),
      [ref0(finalToken), ref0(constToken)].toChoiceParser(),
      ref0(type),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
    ).map4(
      (lateKw, modifier, type, vars) => VariableDeclarationStatementNode(
        variables: vars,
        type: type,
        isLate: lateKw != null,
        isFinal: modifier.value == 'final',
        isConst: modifier.value == 'const',
      ),
    ),
    // 3. final / const without type: final x = 1;
    seq3(
      ref0(lateToken).optional(),
      [ref0(finalToken), ref0(constToken)].toChoiceParser(),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
    ).map3(
      (lateKw, modifier, vars) => VariableDeclarationStatementNode(
        variables: vars,
        isLate: lateKw != null,
        isFinal: modifier.value == 'final',
        isConst: modifier.value == 'const',
      ),
    ),
    // 4. With type only (no final/const/var): int x = 1;
    seq3(
      ref0(lateToken).optional(),
      ref0(type),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
    ).map3(
      (lateKw, type, vars) => VariableDeclarationStatementNode(
        variables: vars,
        type: type,
        isLate: lateKw != null,
      ),
    ),
  ].toChoiceParser();

  Parser<VariableDeclaratorNode> variableDeclarator() => seq2(
    ref0(identifier),
    (ref1(token, '=') & ref0(expression))
        .map((l) => l[1] as ExpressionNode)
        .optional(),
  ).map2((name, init) => VariableDeclaratorNode(name: name, initializer: init));

  // ---------------------------------------------------------------------------
  // If Statement
  // ---------------------------------------------------------------------------

  Parser<IfStatementNode> ifStatement() =>
      seq6(
        ref0(ifToken),
        ref1(token, '('),
        ref0(ifCondition),
        ref1(token, ')'),
        ref0(statement),
        (ref0(elseToken) & ref0(statement))
            .map((l) => l[1] as StatementNode)
            .optional(),
      ).map6(
        (_, _, cond, _, thenBranch, elseBranch) => IfStatementNode(
          condition: cond.$1,
          casePattern: cond.$2,
          whenGuard: cond.$3,
          thenBranch: thenBranch,
          elseBranch: elseBranch,
        ),
      );

  // ---------------------------------------------------------------------------
  // Switch Statement
  // ---------------------------------------------------------------------------

  Parser<SwitchStatementNode> switchStatement() =>
      seq5(
        ref0(switchToken),
        ref1(token, '('),
        ref0(expression),
        ref1(token, ')'),
        seq3(
          ref1(token, '{'),
          ref0(switchCase).star(),
          ref1(token, '}'),
        ).map3((_, cases, _) => cases),
      ).map5(
        (_, _, expr, _, cases) =>
            SwitchStatementNode(expression: expr, cases: cases),
      );

  Parser<SwitchPatternCaseNode> switchCase() => [
    // Standard case pattern [when guard]: statements
    seq3(
      (ref0(identifier) & ref1(token, ':')).map((l) => l[0] as String).star(),
      seq3(
        ref0(caseToken),
        ref0(dartPattern),
        seq2(ref0(patternGuard).optional(), ref1(token, ':')),
      ).map3((_, p, guardAndColon) => (p, guardAndColon.$1)).plus(),
      ref0(statement).star(),
    ).map3(
      (labels, patternsAndGuards, stmts) => SwitchPatternCaseNode(
        labels: labels,
        patterns: patternsAndGuards.map((e) => e.$1).toList(),
        whenGuard: patternsAndGuards.last.$2,
        statements: stmts,
      ),
    ),
    // Default: statements
    seq3(
      (ref0(identifier) & ref1(token, ':')).map((l) => l[0] as String).star(),
      seq2(ref0(defaultToken), ref1(token, ':')),
      ref0(statement).star(),
    ).map3(
      (labels, _, stmts) => SwitchPatternCaseNode(
        labels: labels,
        isDefault: true,
        statements: stmts,
      ),
    ),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Loops
  // ---------------------------------------------------------------------------

  Parser<StatementNode> forStatement() =>
      seq5(
        ref0(awaitToken).optional(),
        ref0(forToken),
        ref1(token, '('),
        ref0(forLoopParts),
        seq2(ref1(token, ')'), ref0(statement)),
      ).map5((awaitKw, _, _, parts, closeAndBody) {
        if (parts is ForPartsClassic) {
          return ForStatementNode(
            initialization: parts.init,
            condition: parts.condition,
            updates: parts.updates,
            body: closeAndBody.$2,
          );
        } else if (parts is ForPartsIn) {
          return ForInStatementNode(
            variable: parts.variable,
            pattern: parts.pattern,
            iterable: parts.iterable,
            body: closeAndBody.$2,
            isAsync: awaitKw != null,
          );
        }
        throw StateError('Invalid for loop parts');
      });

  Parser<Object> forLoopParts() => [
    // Pattern for-in: for (var (a, b) in iterable)
    seq3(
      (ref0(varToken) | ref0(finalToken)) & ref0(dartPattern),
      ref0(inToken),
      ref0(expression),
    ).map3(
      (p, _, iter) => ForPartsIn(pattern: p[1] as PatternNode, iterable: iter),
    ),
    // Variable for-in: for (var x in iterable)
    seq3(
      ref0(variableDeclaration),
      ref0(inToken),
      ref0(expression),
    ).map3((decl, _, iter) => ForPartsIn(variable: decl, iterable: iter)),
    // Identifier for-in: for (x in iterable)
    seq3(ref0(identifier), ref0(inToken), ref0(expression)).map3(
      (id, _, iter) => ForPartsIn(
        variable: VariableDeclarationStatementNode(
          variables: [VariableDeclaratorNode(name: id)],
        ),
        iterable: iter,
      ),
    ),
    // Traditional for: for (init; cond; updates)
    seq5(
      [
        ref0(variableDeclarationStatement),
        (ref0(expression).optional() & ref1(token, ';')).map(
          (l) => l[0] != null
              ? ExpressionStatementNode(l[0] as ExpressionNode)
              : null,
        ),
      ].toChoiceParser(),
      ref0(expression).optional(),
      ref1(token, ';'),
      ref0(expression)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements)
          .optionalWith(const <ExpressionNode>[]),
      epsilon(),
    ).map5(
      (init, cond, _, updates, _) =>
          ForPartsClassic(init: init, condition: cond, updates: updates),
    ),
  ].toChoiceParser();

  Parser<WhileStatementNode> whileStatement() =>
      seq5(
        ref0(whileToken),
        ref1(token, '('),
        ref0(expression),
        ref1(token, ')'),
        ref0(statement),
      ).map5(
        (_, _, cond, _, body) =>
            WhileStatementNode(condition: cond, body: body),
      );

  Parser<DoWhileStatementNode> doWhileStatement() =>
      seq6(
        ref0(doToken),
        ref0(statement),
        ref0(whileToken),
        ref1(token, '('),
        ref0(expression),
        seq2(ref1(token, ')'), ref1(token, ';')),
      ).map6(
        (_, body, _, _, cond, _) =>
            DoWhileStatementNode(body: body, condition: cond),
      );

  // ---------------------------------------------------------------------------
  // Try-Catch-Finally
  // ---------------------------------------------------------------------------

  Parser<TryStatementNode> tryStatement() =>
      seq3(
        ref0(tryToken),
        ref0(block),
        [
          seq2(
            ref0(catchClause).plus(),
            ref0(finallyClause).optional(),
          ).map2((catches, fin) => (catches, fin)),
          ref0(finallyClause).map((fin) => (const <CatchClauseNode>[], fin)),
        ].toChoiceParser(),
      ).map3(
        (_, body, catchesAndFin) => TryStatementNode(
          body: body,
          catchClauses: catchesAndFin.$1,
          finallyBlock: catchesAndFin.$2,
        ),
      );

  Parser<CatchClauseNode> catchClause() => seq2(
    [
      // on Type catch (e, s)
      seq4(
        ref0(onToken),
        ref0(type),
        ref0(catchParameters).optional(),
        ref0(block),
      ).map4(
        (_, type, params, b) => CatchClauseNode(
          exceptionType: type,
          exceptionParameter: params?.$1,
          stackTraceParameter: params?.$2,
          body: b,
        ),
      ),
      // catch (e, s)
      seq2(ref0(catchParameters), ref0(block)).map2(
        (params, b) => CatchClauseNode(
          exceptionParameter: params.$1,
          stackTraceParameter: params.$2,
          body: b,
        ),
      ),
    ].toChoiceParser(),
    epsilon(),
  ).map2((c, _) => c);

  Parser<(String, String?)> catchParameters() => seq5(
    ref0(catchToken),
    ref1(token, '('),
    ref0(identifier),
    (ref1(token, ',') & ref0(identifier)).map((l) => l[1] as String).optional(),
    ref1(token, ')'),
  ).map5((_, _, e, s, _) => (e, s));

  Parser<BlockStatementNode> finallyClause() =>
      (ref0(finallyToken) & ref0(block)).map((l) => l[1] as BlockStatementNode);

  // ---------------------------------------------------------------------------
  // Control Flow (return, break, continue, rethrow, yield, assert)
  // ---------------------------------------------------------------------------

  Parser<ReturnStatementNode> returnStatement() => seq3(
    ref0(returnToken),
    ref0(expression).optional(),
    ref1(token, ';'),
  ).map3((_, expr, _) => ReturnStatementNode(expr));

  Parser<BreakStatementNode> breakStatement() => seq3(
    ref0(breakToken),
    ref0(identifier).optional(),
    ref1(token, ';'),
  ).map3((_, label, _) => BreakStatementNode(label));

  Parser<ContinueStatementNode> continueStatement() => seq3(
    ref0(continueToken),
    ref0(identifier).optional(),
    ref1(token, ';'),
  ).map3((_, label, _) => ContinueStatementNode(label));

  Parser<RethrowStatementNode> rethrowStatement() =>
      (ref0(rethrowToken) & ref1(token, ';')).map(
        (_) => const RethrowStatementNode(),
      );

  Parser<YieldStatementNode> yieldStatement() => seq4(
    ref0(yieldToken),
    ref1(token, '*').optional(),
    ref0(expression),
    ref1(token, ';'),
  ).map4((_, star, expr, _) => YieldStatementNode(expr, isStar: star != null));

  Parser<AssertStatementNode> assertStatement() => seq6(
    ref0(assertToken),
    ref1(token, '('),
    ref0(expression),
    (ref1(token, ',') & ref0(expression))
        .map((l) => l[1] as ExpressionNode)
        .optional(),
    ref1(token, ',').optional(),
    seq2(ref1(token, ')'), ref1(token, ';')),
  ).map6((_, _, cond, msg, _, _) => AssertStatementNode(cond, msg));
}

class ForPartsClassic {
  new({this.init, this.condition, this.updates = const []});
  final StatementNode? init;
  final ExpressionNode? condition;
  final List<ExpressionNode> updates;
}

class ForPartsIn {
  new({this.variable, this.pattern, required this.iterable});
  final VariableDeclarationStatementNode? variable;
  final PatternNode? pattern;
  final ExpressionNode iterable;
}

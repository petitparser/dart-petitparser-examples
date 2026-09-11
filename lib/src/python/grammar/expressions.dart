import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';

/// Mixin for Python expressions syntax.
mixin PythonExpressionGrammar
    on GrammarDefinition<ModuleNode>, PythonLexicalGrammar {
  // Cross-mixin references: resolved by PythonDeclarationGrammar at runtime.
  Parser<ArgumentsNode> parameterList();

  /// Lambda parameters — like function params but without type annotations.
  /// Overridden by `PythonDeclarationGrammar` to support `*args`, `**kwargs`.
  Parser<ArgumentsNode> lambdaParameters();

  /// The main expression production.
  @override
  Parser<ExpressionNode> expression() => ref0(expressionList);

  Parser<ExpressionNode> singleExpression() => [
    ref0(namedExpression),
    ref0(conditionalExpression),
    ref0(lambdaExpression),
  ].toChoiceParser();

  /// Named walrus expression: `target := value`.
  Parser<ExpressionNode> namedExpression() => seq3(
    ref0(identifier).map(NameNode.new),
    ref1(token, ':='),
    ref0(singleExpression),
  ).map3((target, _, val) => NamedExprNode(target: target, value: val));

  /// Lambda expression: `lambda [args]: body`.
  Parser<ExpressionNode> lambdaExpression() =>
      seq3(
        ref0(lambdaToken),
        ref0(lambdaParameters).optional(),
        seq2(ref1(token, ':'), ref0(singleExpression)).map2((_, e) => e),
      ).map3(
        (_, params, body) =>
            LambdaNode(args: params ?? const ArgumentsNode(), body: body),
      );

  /// Conditional expression: `test_or_expr if test else expr`.
  Parser<ExpressionNode> conditionalExpression() =>
      seq2(
        ref0(disjunction),
        seq3(
          ref0(ifToken),
          ref0(disjunction),
          seq2(ref0(elseToken), ref0(singleExpression)).map2((_, e) => e),
        ).optional(),
      ).map2((body, orelsePart) {
        if (orelsePart == null) return body;
        final test = orelsePart.$2;
        final orelse = orelsePart.$3;
        return IfExpNode(test: test, body: body, orelse: orelse);
      });

  /// Logical `or`: `a or b or c`.
  Parser<ExpressionNode> disjunction() =>
      ref0(conjunction).plusSeparated(ref0(orToken)).map((seq) {
        if (seq.elements.length == 1) return seq.elements.first;
        return BoolOpNode(operator: 'or', values: seq.elements);
      });

  /// Logical `and`: `a and b and c`.
  Parser<ExpressionNode> conjunction() =>
      ref0(inversion).plusSeparated(ref0(andToken)).map((seq) {
        if (seq.elements.length == 1) return seq.elements.first;
        return BoolOpNode(operator: 'and', values: seq.elements);
      });

  /// Logical `not`: `not a`.
  Parser<ExpressionNode> inversion() => [
    seq2(
      ref0(notToken),
      ref0(inversion),
    ).map2((_, expr) => UnaryOpNode(operator: 'not', operand: expr)),
    ref0(comparison),
  ].toChoiceParser();

  /// Comparison expressions with chaining: `a < b <= c`.
  Parser<ExpressionNode> comparison() =>
      seq2(ref0(bitwiseOr), seq2(ref0(compOp), ref0(bitwiseOr)).star()).map2((
        left,
        rest,
      ) {
        if (rest.isEmpty) return left;
        final ops = <String>[];
        final comparators = <ExpressionNode>[];
        for (final pair in rest) {
          ops.add(pair.$1);
          comparators.add(pair.$2);
        }
        return CompareNode(
          left: left,
          operators: ops,
          comparators: comparators,
        );
      });

  Parser<String> compOp() => [
    ref1(token, '==').map((t) => t.value),
    ref1(token, '!=').map((t) => t.value),
    ref1(token, '<=').map((t) => t.value),
    ref1(token, '>=').map((t) => t.value),
    ref1(token, '<').map((t) => t.value),
    ref1(token, '>').map((t) => t.value),
    seq2(ref0(isToken), ref0(notToken)).map2((_, _) => 'is not'),
    ref0(isToken).map((_) => 'is'),
    seq2(ref0(notToken), ref0(inToken)).map2((_, _) => 'not in'),
    ref0(inToken).map((_) => 'in'),
  ].toChoiceParser().cast<String>();

  /// Bitwise OR `|`.
  Parser<ExpressionNode> bitwiseOr() => ref0(bitwiseXor)
      .plusSeparated(ref1(token, '|').map((t) => t.value))
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Bitwise XOR `^`.
  Parser<ExpressionNode> bitwiseXor() => ref0(bitwiseAnd)
      .plusSeparated(ref1(token, '^').map((t) => t.value))
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Bitwise AND `&`.
  Parser<ExpressionNode> bitwiseAnd() => ref0(shiftExpr)
      .plusSeparated(ref1(token, '&').map((t) => t.value))
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Shift expressions `<<`, `>>`.
  Parser<ExpressionNode> shiftExpr() => ref0(sumExpr)
      .plusSeparated(
        [
          ref1(token, '<<').map((t) => t.value),
          ref1(token, '>>').map((t) => t.value),
        ].toChoiceParser().cast<String>(),
      )
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Addition and subtraction `+`, `-`.
  Parser<ExpressionNode> sumExpr() => ref0(termExpr)
      .plusSeparated(
        [
          ref1(token, '+').map((t) => t.value),
          ref1(token, '-').map((t) => t.value),
        ].toChoiceParser().cast<String>(),
      )
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Multiplication, division, modulo, matrix multiplication `*`, `/`, `//`, `%`, `@`.
  Parser<ExpressionNode> termExpr() => ref0(factorExpr)
      .plusSeparated(
        [
          ref1(token, '//').map((t) => t.value),
          ref1(token, '*').map((t) => t.value),
          ref1(token, '/').map((t) => t.value),
          ref1(token, '%').map((t) => t.value),
          ref1(token, '@').map((t) => t.value),
        ].toChoiceParser().cast<String>(),
      )
      .map((seq) => _foldBinOps(seq.elements, seq.separators.cast<String>()));

  /// Unary operators `+x`, `-x`, `~x`.
  Parser<ExpressionNode> factorExpr() => [
    seq2(
      [ref1(token, '+'), ref1(token, '-'), ref1(token, '~')].toChoiceParser(),
      ref0(factorExpr),
    ).map2((op, expr) => UnaryOpNode(operator: op.value, operand: expr)),
    ref0(powerExpr),
  ].toChoiceParser();

  /// Exponentiation `**` (right associative).
  Parser<ExpressionNode> powerExpr() =>
      seq2(
        ref0(awaitExpr),
        seq2(ref1(token, '**'), ref0(factorExpr)).optional(),
      ).map2((left, exp) {
        if (exp == null) return left;
        return BinOpNode(left: left, operator: '**', right: exp.$2);
      });

  /// Await expression `await x`.
  Parser<ExpressionNode> awaitExpr() => [
    seq2(
      ref0(awaitToken),
      ref0(primaryExpr),
    ).map2((_, expr) => AwaitNode(expr)),
    ref0(primaryExpr),
  ].toChoiceParser();

  /// Primary expressions and postfix selectors (`()`, `[]`, `.attr`).
  Parser<ExpressionNode> primaryExpr() =>
      seq2(ref0(atom), ref0(selector).star()).map2((target, selectors) {
        var current = target;
        for (final sel in selectors) {
          current = sel(current);
        }
        return current;
      });

  Parser<ExpressionNode Function(ExpressionNode)> selector() => [
    ref0(callSelector),
    ref0(subscriptSelector),
    ref0(attributeSelector),
  ].toChoiceParser();

  Parser<ExpressionNode Function(ExpressionNode)> attributeSelector() =>
      seq2(ref1(token, '.'), ref0(identifier)).map2(
        (_, name) =>
            (target) => AttributeNode(value: target, attribute: name),
      );

  Parser<ExpressionNode Function(ExpressionNode)> subscriptSelector() =>
      seq3(
        ref1(token, '['),
        ignore(ref0(sliceOrExprList)),
        ref1(token, ']'),
      ).map3(
        (_, slice, _) =>
            (target) => SubscriptNode(value: target, slice: slice),
      );

  Parser<ExpressionNode> sliceOrExprList() =>
      seq2(
        ref0(sliceItem).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, trailing) {
        if (seq.elements.length == 1 && trailing == null) {
          return seq.elements.first;
        }
        return TupleNode(elements: seq.elements);
      });

  Parser<ExpressionNode> sliceItem() =>
      [ref0(sliceExpr), ref0(singleExpression)].toChoiceParser();

  Parser<SliceNode> sliceExpr() =>
      seq3(
        ref0(singleExpression).optional(),
        ref1(token, ':'),
        seq2(
          ref0(singleExpression).optional(),
          seq2(ref1(token, ':'), ref0(singleExpression).optional()).optional(),
        ),
      ).map3((lower, _, rest) {
        final upper = rest.$1;
        final step = rest.$2?.$2;
        return SliceNode(lower: lower, upper: upper, step: step);
      });

  Parser<ExpressionNode Function(ExpressionNode)> callSelector() =>
      seq3(
        ref1(token, '('),
        ignore(
          [
            ref0(generatorExpression),
            ref0(callArgumentList),
          ].toChoiceParser().optional(),
        ),
        ref1(token, ')'),
      ).map3(
        (_, args, _) => (target) {
          final parsedArgs =
              args ?? (args: <ExpressionNode>[], kw: <KeywordNode>[]);
          return CallNode(
            function: target,
            args: parsedArgs.args,
            keywords: parsedArgs.kw,
          );
        },
      );

  Parser<({List<ExpressionNode> args, List<KeywordNode> kw})>
  generatorExpression() => ref0(comprehensionClause).map(
    (comp) => (
      args: [
        GeneratorExpNode(element: comp.element, generators: comp.generators),
      ],
      kw: <KeywordNode>[],
    ),
  );

  Parser<({List<ExpressionNode> args, List<KeywordNode> kw})>
  callArgumentList() =>
      seq2(
        ref0(callArg).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final args = <ExpressionNode>[];
        final kw = <KeywordNode>[];
        for (final item in seq.elements) {
          if (item is KeywordNode) {
            kw.add(item);
          } else {
            args.add(item as ExpressionNode);
          }
        }
        return (args: args, kw: kw);
      });

  Parser<PythonNode> callArg() => [
    seq3(
      ref0(identifier),
      ref0(assignToken),
      ref0(singleExpression),
    ).map3((name, _, val) => KeywordNode(arg: name, value: val)),
    seq2(
      ref1(token, '**'),
      ref0(singleExpression),
    ).map2((_, val) => KeywordNode(value: val)),
    seq2(
      ref1(token, '*'),
      ref0(singleExpression),
    ).map2((_, val) => StarredNode(val)),
    ref0(singleExpression),
  ].toChoiceParser();

  /// Atoms: identifiers, literals, parenthesized expressions, tuples, lists, dicts, sets, comprehensions.
  Parser<ExpressionNode> atom() => [
    ref0(yieldExpression),
    ref0(numberLiteral),
    ref0(stringLiteral),
    ref1(token, '...').map((_) => const ConstantNode(null)), // Ellipsis
    ref0(noneToken).map((_) => const ConstantNode(null)),
    ref0(trueToken).map((_) => const ConstantNode(true)),
    ref0(falseToken).map((_) => const ConstantNode(false)),
    ref0(identifier).map(NameNode.new),
    ref0(enclosedInParen),
    ref0(enclosedInBrackets),
    ref0(enclosedInBraces),
  ].toChoiceParser();

  /// Yield and Yield From.
  Parser<ExpressionNode> yieldExpression() => seq2(
    ref0(yieldToken),
    [
      seq2(ref0(fromToken), ref0(expression)).map2((_, e) => YieldFromNode(e)),
      ref0(expressionList).optional().map((e) => YieldNode(e)),
    ].toChoiceParser(),
  ).map2((_, res) => res);

  Parser<ExpressionNode> expressionList() =>
      seq2(
        ref0(singleExpression).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, trailing) {
        if (seq.elements.length == 1 && trailing == null) {
          return seq.elements.first;
        }
        return TupleNode(elements: seq.elements);
      });

  Parser<ExpressionNode> enclosedInParen() => seq3(
    ref1(token, '('),
    ignore(
      [
        ref0(generatorExpr),
        ref0(tupleOrSingleExpr),
      ].toChoiceParser().optional(),
    ),
    ref1(token, ')'),
  ).map3((_, expr, _) => expr ?? const TupleNode(elements: []));

  Parser<ExpressionNode> tupleOrSingleExpr() =>
      seq2(
        ref0(starOrSingleExpr).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, trailing) {
        if (seq.elements.length == 1 && trailing == null) {
          return seq.elements.first;
        }
        return TupleNode(elements: seq.elements);
      });

  /// A star expression or a single expression, for use in tuple/list displays.
  Parser<ExpressionNode> starOrSingleExpr() => [
    seq2(
      ref1(token, '*'),
      ref0(singleExpression),
    ).map2((_, e) => StarredNode(e)),
    ref0(singleExpression),
  ].toChoiceParser();

  Parser<ExpressionNode> enclosedInBrackets() => seq3(
    ref1(token, '['),
    ignore([ref0(listComp), ref0(listItems)].toChoiceParser().optional()),
    ref1(token, ']'),
  ).map3((_, expr, _) => expr ?? const ListNode(elements: []));

  Parser<ExpressionNode> listItems() => seq2(
    ref0(starOrSingleExpr).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => ListNode(elements: seq.elements));

  Parser<ExpressionNode> enclosedInBraces() => seq3(
    ref1(token, '{'),
    ignore(
      [ref0(dictOrSetComp), ref0(dictOrSetItems)].toChoiceParser().optional(),
    ),
    ref1(token, '}'),
  ).map3((_, expr, _) => expr ?? const DictNode());

  Parser<ExpressionNode> dictOrSetItems() =>
      [ref0(dictItems), ref0(setItems)].toChoiceParser();

  Parser<DictNode> dictItems() =>
      seq2(
        ref0(dictPair).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final keys = <ExpressionNode?>[];
        final values = <ExpressionNode>[];
        for (final pair in seq.elements) {
          keys.add(pair.key);
          values.add(pair.val);
        }
        return DictNode(keys: keys, values: values);
      });

  Parser<({ExpressionNode? key, ExpressionNode val})> dictPair() => [
    seq3(
      ref0(singleExpression),
      ref1(token, ':'),
      ref0(singleExpression),
    ).map3((k, _, v) => (key: k, val: v)),
    seq2(
      ref1(token, '**'),
      ref0(singleExpression),
    ).map2((_, v) => (key: null, val: v)),
  ].toChoiceParser();

  Parser<SetNode> setItems() => seq2(
    ref0(singleExpression).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => SetNode(elements: seq.elements));

  // ---------------------------------------------------------------------------
  // Comprehensions
  // ---------------------------------------------------------------------------

  Parser<GeneratorExpNode> generatorExpr() => ref0(comprehensionClause).map(
    (comp) =>
        GeneratorExpNode(element: comp.element, generators: comp.generators),
  );

  Parser<ListCompNode> listComp() => ref0(comprehensionClause).map(
    (comp) => ListCompNode(element: comp.element, generators: comp.generators),
  );

  Parser<ExpressionNode> dictOrSetComp() => [
    seq2(
      seq3(ref0(singleExpression), ref1(token, ':'), ref0(singleExpression)),
      ref0(forIfClauses),
    ).map2(
      (pair, clauses) =>
          DictCompNode(key: pair.$1, value: pair.$3, generators: clauses),
    ),
    ref0(comprehensionClause).map(
      (comp) => SetCompNode(element: comp.element, generators: comp.generators),
    ),
  ].toChoiceParser();

  Parser<({ExpressionNode element, List<ComprehensionNode> generators})>
  comprehensionClause() => seq2(
    ref0(conditionalExpression),
    ref0(forIfClauses),
  ).map2((elt, clauses) => (element: elt, generators: clauses));

  Parser<List<ComprehensionNode>> forIfClauses() =>
      ref0(forIfClause).plus().map((list) => list);

  Parser<ExpressionNode> starTargets() =>
      seq2(
        ref0(starTarget).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, trailing) {
        if (seq.elements.length == 1 && trailing == null) {
          return seq.elements.first;
        }
        return TupleNode(elements: seq.elements);
      });

  Parser<ExpressionNode> starTarget() => [
    seq2(ref1(token, '*'), ref0(starTarget)).map2((_, e) => StarredNode(e)),
    ref0(bitwiseOr),
  ].toChoiceParser();

  Parser<ComprehensionNode> forIfClause() =>
      seq4(
        ref0(asyncToken).optional(),
        ref0(forToken),
        seq3(ref0(starTargets), ref0(inToken), ref0(disjunction)),
        ref0(ifClause).star(),
      ).map4(
        (asyncTok, _, inSeq, ifs) => ComprehensionNode(
          target: inSeq.$1,
          iter: inSeq.$3,
          ifs: ifs,
          isAsync: asyncTok != null,
        ),
      );

  Parser<ExpressionNode> ifClause() =>
      seq2(ref0(ifToken), ref0(disjunction)).map2((_, e) => e);

  ExpressionNode _foldBinOps(
    List<ExpressionNode> elements,
    List<String> operators,
  ) {
    var result = elements.first;
    for (var i = 0; i < operators.length; i++) {
      result = BinOpNode(
        left: result,
        operator: operators[i],
        right: elements[i + 1],
      );
    }
    return result;
  }
}

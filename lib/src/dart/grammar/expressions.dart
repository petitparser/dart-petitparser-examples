import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';
import 'patterns.dart';
import 'types.dart';

/// Mixin for Dart expression syntax using [ExpressionBuilder].
mixin DartExpressionGrammar
    on
        GrammarDefinition<CompilationUnitNode>,
        DartLexicalGrammar,
        DartTypeGrammar,
        DartPatternGrammar {
  /// Abstract block statement reference needed for function closures.
  Parser<BlockStatementNode> block();

  /// Abstract for-loop parts reference needed for collection for-elements.
  Parser<Object> forLoopParts();

  /// The main expression production.
  @override
  Parser<ExpressionNode> expression() => ref0(expressionBuilderParser);

  /// Expression builder setup.
  Parser<ExpressionNode> expressionBuilderParser() {
    final builder = ExpressionBuilder<ExpressionNode>();

    // Primitives
    builder.primitive(ref0(primary));

    // Group 1: Postfix selectors & operators
    builder.group()
      ..postfix(
        ref1(token, '++'),
        (val, _) =>
            UnaryExpressionNode(operator: '++', operand: val, isPrefix: false),
      )
      ..postfix(
        ref1(token, '--'),
        (val, _) =>
            UnaryExpressionNode(operator: '--', operand: val, isPrefix: false),
      )
      ..postfix(
        ref1(token, '!'),
        (val, _) =>
            UnaryExpressionNode(operator: '!', operand: val, isPrefix: false),
      )
      // Property access: .prop or ?.prop (including constructor tear-off .new)
      ..postfix(
        seq2(
          [ref1(token, '?.'), ref1(token, '.')].toChoiceParser(),
          [
            ref0(identifier),
            ref0(newToken).map((t) => t.value),
          ].toChoiceParser(),
        ),
        (target, access) => PropertyAccessNode(
          target: target,
          propertyName: access.$2,
          isNullAware: access.$1.value == '?.',
        ),
      )
      // Method / function invocation: (args) or <typeArgs>(args)
      ..postfix(
        seq2(
          ref0(typeArguments)
              .optional()
              .map((list) => list ?? const <TypeNode>[]),
          ref0(argumentList),
        ),
        (target, inv) => InvocationExpressionNode(
          target: target,
          typeArguments: inv.$1,
          arguments: inv.$2,
        ),
      )
      // Indexing: [index] or ?[index]
      ..postfix(
        seq3(
          [ref1(token, '?['), ref1(token, '[')].toChoiceParser(),
          builder.loopback,
          ref1(token, ']'),
        ),
        (target, index) => IndexExpressionNode(
          target: target,
          index: index.$2,
          isNullAware: index.$1.value == '?[',
        ),
      );

    // Group 2: Prefix operators
    builder.group()
      ..prefix(
        ref1(token, '-'),
        (op, val) => UnaryExpressionNode(operator: '-', operand: val),
      )
      ..prefix(
        ref1(token, '!'),
        (op, val) => UnaryExpressionNode(operator: '!', operand: val),
      )
      ..prefix(
        ref1(token, '~'),
        (op, val) => UnaryExpressionNode(operator: '~', operand: val),
      )
      ..prefix(
        ref1(token, '++'),
        (op, val) => UnaryExpressionNode(operator: '++', operand: val),
      )
      ..prefix(
        ref1(token, '--'),
        (op, val) => UnaryExpressionNode(operator: '--', operand: val),
      )
      ..prefix(ref0(awaitToken), (op, val) => AwaitExpressionNode(val))
      ..prefix(ref0(throwToken), (op, val) => ThrowExpressionNode(val));

    // Group 3: Multiplicative (*, /, ~/, %)
    builder.group()
      ..left(
        ref1(token, '*'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '*', right: right),
      )
      ..left(
        ref1(token, '/'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '/', right: right),
      )
      ..left(
        ref1(token, '~/'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '~/', right: right),
      )
      ..left(
        ref1(token, '%'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '%', right: right),
      );

    // Group 4: Additive (+, -)
    builder.group()
      ..left(
        ref1(token, '+'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '+', right: right),
      )
      ..left(
        ref1(token, '-'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '-', right: right),
      );

    // Group 5: Shift (<<, >>>, >>)
    builder.group()
      ..left(
        ref1(token, '<<'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '<<', right: right),
      )
      ..left(
        ref1(token, '>>>'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '>>>', right: right),
      )
      ..left(
        ref1(token, '>>'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '>>', right: right),
      );

    // Group 6: Relational (<, <=, >, >=, is, is!, as)
    builder.group()
      ..left(
        ref1(token, '<='),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '<=', right: right),
      )
      ..left(
        ref1(token, '>='),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '>=', right: right),
      )
      ..left(
        ref1(token, '<'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '<', right: right),
      )
      ..left(
        ref1(token, '>'),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '>', right: right),
      )
      ..postfix(
        seq2(
          [ref0(isToken) & ref1(token, '!'), ref0(isToken)].toChoiceParser(),
          ref0(typeTestType),
        ),
        (expr, isTest) {
          final isNegated = isTest.$1 is List;
          return TypeTestExpressionNode(
            expression: expr,
            type: isTest.$2,
            isNegated: isNegated,
          );
        },
      )
      ..postfix(
        seq2(ref0(asToken), ref0(typeTestType)),
        (expr, asCast) =>
            TypeCastExpressionNode(expression: expr, type: asCast.$2),
      );

    // Group 7: Equality (==, !=)
    builder.group()
      ..left(
        ref1(token, '=='),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '==', right: right),
      )
      ..left(
        ref1(token, '!='),
        (left, op, right) =>
            BinaryExpressionNode(left: left, operator: '!=', right: right),
      );

    // Group 8: Bitwise AND (&)
    builder.group().left(
      ref1(token, '&'),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: '&', right: right),
    );

    // Group 9: Bitwise XOR (^)
    builder.group().left(
      ref1(token, '^'),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: '^', right: right),
    );

    // Group 10: Bitwise OR (|)
    builder.group().left(
      ref1(token, '|'),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: '|', right: right),
    );

    // Group 11: Logical AND (&&)
    builder.group().left(
      ref1(token, '&&'),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: '&&', right: right),
    );

    // Group 12: Logical OR (||)
    builder.group().left(
      ref1(token, '||'),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: '||', right: right),
    );

    // Group 13: If-null (??)
    builder.group().right(
      ref1(token, '??'),
      (left, op, right) => IfNullExpressionNode(left: left, right: right),
    );

    // Group 14: Ternary conditional (c ? t : e)
    builder.group().postfix(
      seq4(
        ref1(token, '?'),
        builder.loopback,
        ref1(token, ':'),
        builder.loopback,
      ),
      (cond, ternary) => ConditionalExpressionNode(
        condition: cond,
        thenExpression: ternary.$2,
        elseExpression: ternary.$4,
      ),
    );

    // Group 15: Cascade (.. or ?..)
    builder.group().postfix(
      seq2(
        [ref1(token, '?..'), ref1(token, '..')].toChoiceParser(),
        ref0(cascadeSection).plus(),
      ),
      (target, cascade) => CascadeExpressionNode(
        target: target,
        cascadeSections: cascade.$2,
        isNullAware: cascade.$1.value == '?..',
      ),
    );

    // Group 16: Assignment & Compound Assignment (=, +=, -=, *=, /=, ~/=, %=, <<=, >>=, >>>=, &=, ^=, |=, ??=)
    builder.group().right(
      [
        ref1(token, '='),
        ref1(token, '+='),
        ref1(token, '-='),
        ref1(token, '*='),
        ref1(token, '/='),
        ref1(token, '~/='),
        ref1(token, '%='),
        ref1(token, '<<='),
        ref1(token, '>>>='),
        ref1(token, '>>='),
        ref1(token, '&='),
        ref1(token, '^='),
        ref1(token, '|='),
        ref1(token, '??='),
      ].toChoiceParser().map((t) => t.value),
      (left, op, right) =>
          BinaryExpressionNode(left: left, operator: op, right: right),
    );

    return builder.build();
  }

  // ---------------------------------------------------------------------------
  // Cascade section
  // ---------------------------------------------------------------------------

  Parser<ExpressionNode> cascadeSection() => [
    // Cascaded index: ..[i]
    seq3(ref1(token, '['), ref0(expression), ref1(token, ']')).map3(
      (_, idx, _) =>
          IndexExpressionNode(target: const ThisExpressionNode(), index: idx),
    ),
    // Cascaded method call or property access
    seq3(
      ref0(identifier),
      ref0(typeArguments).optionalWith(const <TypeNode>[]),
      ref0(argumentList).optional(),
    ).map3((name, typeArgs, args) {
      final prop = PropertyAccessNode(
        target: const ThisExpressionNode(),
        propertyName: name,
      );
      if (args != null) {
        return InvocationExpressionNode(
          target: prop,
          typeArguments: typeArgs,
          arguments: args,
        );
      }
      return prop;
    }),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Primary Expressions
  // ---------------------------------------------------------------------------

  Parser<ExpressionNode> primary() => [
    ref0(literal),
    ref0(thisExpression),
    ref0(superExpression),
    ref0(functionExpression),
    ref0(parenthesizedOrRecordLiteral),
    ref0(switchExpression),
    ref0(collectionLiteral),
    ref0(constructorInvocation),
    ref0(constructorInvocationWithTypeArguments),
    ref0(identifierExpression),
  ].toChoiceParser();

  Parser<ThisExpressionNode> thisExpression() =>
      ref0(thisToken).map((_) => const ThisExpressionNode());

  Parser<SuperExpressionNode> superExpression() =>
      ref0(superToken).map((_) => const SuperExpressionNode());

  Parser<IdentifierNode> identifierExpression() =>
      ref0(identifier).map(IdentifierNode.new);

  /// Constructor invocation (`new Foo(...)` or `const Foo(...)`).
  Parser<InvocationExpressionNode> constructorInvocation() =>
      seq4(
        [ref0(newToken), ref0(constToken)].toChoiceParser(),
        ref0(namedType),
        (ref1(token, '.') & ref0(identifier))
            .map((l) => l[1] as String)
            .optional(),
        ref0(argumentList),
      ).map4((_, type, ctorName, args) {
        ExpressionNode target = IdentifierNode(type.name);
        if (ctorName != null) {
          target = PropertyAccessNode(target: target, propertyName: ctorName);
        }
        return InvocationExpressionNode(
          target: target,
          typeArguments: type.typeArguments,
          arguments: args,
        );
      });

  /// Constructor invocation without `new` or `const` that has type arguments
  /// (`Foo<int>(...)` or `Foo<int>.named(...)`).
  Parser<InvocationExpressionNode> constructorInvocationWithTypeArguments() =>
      seq4(
        ref0(qualifiedIdentifier),
        ref0(typeArguments),
        (ref1(token, '.') & ref0(identifier))
            .map((l) => l[1] as String)
            .optional(),
        ref0(argumentList),
      ).map4((name, typeArgs, ctorName, args) {
        ExpressionNode target = IdentifierNode(name);
        if (ctorName != null) {
          target = PropertyAccessNode(target: target, propertyName: ctorName);
        }
        return InvocationExpressionNode(
          target: target,
          typeArguments: typeArgs,
          arguments: args,
        );
      });

  /// Parenthesized expression or record literal `(...)`.
  Parser<ExpressionNode> parenthesizedOrRecordLiteral() =>
      seq4(
        ref0(constToken).optional(),
        ref1(token, '('),
        ref0(recordLiteralField)
            .plusSeparated(ref1(token, ','))
            .map((l) => l.elements)
            .optionalWith(const <RecordLiteralFieldNode>[]),
        seq2(ref1(token, ',').optional(), ref1(token, ')')),
      ).map4((constKw, _, fields, commaAndClose) {
        // Plain (expr) parenthesized: 1 field, no name, no trailing comma, no const
        if (fields.length == 1 &&
            fields.first.name == null &&
            commaAndClose.$1 == null &&
            constKw == null) {
          return ParenthesizedExpressionNode(fields.first.value);
        }
        return RecordLiteralNode(fields: fields, isConst: constKw != null);
      });

  Parser<RecordLiteralFieldNode> recordLiteralField() => [
    seq3(
      ref0(identifier),
      ref1(token, ':'),
      ref0(expression),
    ).map3((name, _, val) => RecordLiteralFieldNode(name: name, value: val)),
    ref0(expression).map((val) => RecordLiteralFieldNode(value: val)),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Collections (List, Set, Map)
  // ---------------------------------------------------------------------------

  /// List, Set, or Map literal (`[1, 2]`, `{'a': 1}`, `<int>{1, 2}`).
  Parser<CollectionLiteralNode> collectionLiteral() =>
      seq3(
        ref0(constToken).optional(),
        ref0(typeArguments)
            .optional()
            .map((list) => list ?? const <TypeNode>[]),
        [
          // List literal [...]
          seq3(
            ref1(token, '['),
            ref0(collectionElement)
                .plusSeparated(ref1(token, ','))
                .map((l) => l.elements)
                .optionalWith(const <CollectionElementNode>[]),
            seq2(ref1(token, ',').optional(), ref1(token, ']')),
          ).map3((_, elems, _) => elems),
          // Set / Map literal {...}
          seq3(
            ref1(token, '{'),
            ref0(collectionElement)
                .plusSeparated(ref1(token, ','))
                .map((l) => l.elements)
                .optionalWith(const <CollectionElementNode>[]),
            seq2(ref1(token, ',').optional(), ref1(token, '}')),
          ).map3((_, elems, _) => elems),
        ].toChoiceParser(),
      ).map3(
        (constKw, typeArgs, elements) => CollectionLiteralNode(
          typeArguments: typeArgs,
          elements: elements,
          isConst: constKw != null,
        ),
      );

  Parser<CollectionElementNode> collectionElement() => [
    ref0(spreadElement),
    ref0(ifElement),
    ref0(forElement),
    ref0(mapEntryElement),
    ref0(expressionElement),
  ].toChoiceParser();

  Parser<ExpressionElementNode> expressionElement() => seq2(
    ref1(token, '?').optional(),
    ref0(expression),
  ).map2((q, expr) => ExpressionElementNode(expr, isNullAware: q != null));

  Parser<MapEntryElementNode> mapEntryElement() =>
      seq4(
        ref1(token, '?').optional(),
        ref0(expression),
        ref1(token, ':'),
        seq2(ref1(token, '?').optional(), ref0(expression)),
      ).map4(
        (qKey, k, _, valAndQ) => MapEntryElementNode(
          key: k,
          value: valAndQ.$2,
          isKeyNullAware: qKey != null,
          isValueNullAware: valAndQ.$1 != null,
        ),
      );

  Parser<SpreadElementNode> spreadElement() =>
      seq2(
        [ref1(token, '...?'), ref1(token, '...')].toChoiceParser(),
        ref0(expression),
      ).map2(
        (op, expr) => SpreadElementNode(
          expression: expr,
          isNullAware: op.value == '...?',
        ),
      );

  Parser<IfElementNode> ifElement() =>
      seq6(
        ref0(ifToken),
        ref1(token, '('),
        ref0(ifCondition),
        ref1(token, ')'),
        ref0(collectionElement),
        (ref0(elseToken) & ref0(collectionElement))
            .map((l) => l[1] as CollectionElementNode)
            .optional(),
      ).map6(
        (_, _, cond, _, thenElem, elseElem) => IfElementNode(
          condition: cond.$1,
          casePattern: cond.$2,
          whenGuard: cond.$3,
          thenElement: thenElem,
          elseElement: elseElem,
        ),
      );

  Parser<(ExpressionNode, PatternNode?, ExpressionNode?)> ifCondition() => [
    // Pattern if: expr case pattern [when guard]
    seq4(
      ref0(expression),
      ref0(caseToken),
      ref0(dartPattern),
      ref0(patternGuard).optional(),
    ).map4((expr, _, p, guard) => (expr, p as PatternNode?, guard)),
    // Normal if: expr
    ref0(expression)
        .map((expr) => (expr, null as PatternNode?, null as ExpressionNode?)),
  ].toChoiceParser();

  Parser<CollectionElementNode> forElement() =>
      seq5(
        ref0(awaitToken).optional(),
        ref0(forToken),
        ref1(token, '('),
        ref0(forLoopParts),
        seq2(ref1(token, ')'), ref0(collectionElement)),
      ).map5((awaitKw, _, _, parts, closeAndBody) {
        if (parts is ForPartsClassic) {
          return ForElementNode(
            initialization: parts.init,
            condition: parts.condition,
            updates: parts.updates,
            body: closeAndBody.$2,
          );
        } else if (parts is ForPartsIn) {
          return ForInElementNode(
            variable: parts.variable,
            pattern: parts.pattern,
            iterable: parts.iterable,
            body: closeAndBody.$2,
            isAsync: awaitKw != null,
          );
        }
        throw StateError('Invalid for loop parts');
      });

  // ---------------------------------------------------------------------------
  // Switch Expression (Dart 3)
  // ---------------------------------------------------------------------------

  Parser<SwitchExpressionNode> switchExpression() =>
      seq5(
        ref0(switchToken),
        ref1(token, '('),
        ref0(expression),
        ref1(token, ')'),
        seq3(
          ref1(token, '{'),
          ref0(switchExpressionCase)
              .plusSeparated(ref1(token, ','))
              .map((l) => l.elements)
              .optionalWith(const <SwitchExpressionCaseNode>[]),
          seq2(ref1(token, ',').optional(), ref1(token, '}')),
        ).map3((_, cases, _) => cases),
      ).map5(
        (_, _, expr, _, cases) =>
            SwitchExpressionNode(expression: expr, cases: cases),
      );

  Parser<SwitchExpressionCaseNode> switchExpressionCase() =>
      seq4(
        ref0(dartPattern),
        ref0(patternGuard).optional(),
        ref1(token, '=>'),
        ref0(expression),
      ).map4(
        (p, guard, _, body) =>
            SwitchExpressionCaseNode(pattern: p, whenGuard: guard, body: body),
      );

  // ---------------------------------------------------------------------------
  // Function Expression / Closures
  // ---------------------------------------------------------------------------

  Parser<FunctionExpressionNode> functionExpression() =>
      seq4(
        ref0(typeParameters)
            .optional()
            .map((list) => list ?? const <TypeParameterNode>[]),
        ref0(formalParameters),
        ref0(asyncOrSyncModifier).optional(),
        ref0(functionBody),
      ).map4(
        (typeParams, params, modifier, body) => FunctionExpressionNode(
          typeParameters: typeParams,
          parameters: params,
          body: body,
        ),
      );

  Parser<String> asyncOrSyncModifier() => [
    ref0(asyncToken) & ref1(token, '*'),
    ref0(asyncToken),
    ref0(syncToken) & ref1(token, '*'),
  ].toChoiceParser().flatten();

  Parser<FunctionBodyNode> functionBody() => [
    // Arrow body: => expr
    seq2(
      ref1(token, '=>'),
      ref0(expression),
    ).map2((_, expr) => ExpressionFunctionBodyNode(expr)),
    // Block body: { statements }
    ref0(block).map(BlockFunctionBodyNode.new),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Argument List
  // ---------------------------------------------------------------------------

  Parser<List<ArgumentNode>> argumentList() => seq3(
    ref1(token, '('),
    ref0(argument)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements)
        .optionalWith(const <ArgumentNode>[]),
    seq2(ref1(token, ',').optional(), ref1(token, ')')),
  ).map3((_, args, _) => args);

  Parser<ArgumentNode> argument() => [
    seq3(
      ref0(identifier),
      ref1(token, ':'),
      ref0(expression),
    ).map3((name, _, val) => ArgumentNode(name: name, value: val)),
    ref0(expression).map((val) => ArgumentNode(value: val)),
  ].toChoiceParser();
}

import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';
import 'types.dart';

/// Mixin for Dart 3 pattern syntax.
mixin DartPatternGrammar
    on
        GrammarDefinition<CompilationUnitNode>,
        DartLexicalGrammar,
        DartTypeGrammar {
  /// The main pattern production.
  Parser<PatternNode> dartPattern() => ref0(logicalOrPattern);

  /// Logical-OR pattern (`p1 || p2`).
  Parser<PatternNode> logicalOrPattern() =>
      ref0(logicalAndPattern)
          .plusSeparated(ref1(token, '||'))
          .map(
            (seq) => seq.elements.reduce(
              (left, right) =>
                  LogicalPatternNode(left: left, operator: '||', right: right),
            ),
          );

  /// Logical-AND pattern (`p1 && p2`).
  Parser<PatternNode> logicalAndPattern() =>
      ref0(relationalOrUnaryPattern)
          .plusSeparated(ref1(token, '&&'))
          .map(
            (seq) => seq.elements.reduce(
              (left, right) =>
                  LogicalPatternNode(left: left, operator: '&&', right: right),
            ),
          );

  Parser<PatternNode> relationalOrUnaryPattern() =>
      [ref0(unaryPattern), ref0(relationalPattern)].toChoiceParser();

  /// Relational pattern (`> 5`, `<= 10`, `== 0`, `!= null`).
  Parser<RelationalPatternNode> relationalPattern() => seq2(
    [
      ref1(token, '=='),
      ref1(token, '!='),
      ref1(token, '<='),
      ref1(token, '>='),
      ref1(token, '<'),
      ref1(token, '>'),
    ].toChoiceParser().map((t) => t.value),
    ref0(expression),
  ).map2((op, expr) => RelationalPatternNode(operator: op, operand: expr));

  /// Unary / postfix pattern (`p as T`, `p?`, `p!`).
  Parser<PatternNode> unaryPattern() =>
      seq2(
        ref0(primaryPattern),
        [
          (ref0(asToken) & ref0(type)).map(
            (l) => (op: 'as', type: l[1] as TypeNode),
          ),
          ref1(token, '?').map((_) => (op: '?', type: null)),
          ref1(token, '!').map((_) => (op: '!', type: null)),
        ].toChoiceParser().star(),
      ).map2((primary, suffixes) {
        var result = primary;
        for (final s in suffixes) {
          if (s.op == 'as') {
            result = CastPatternNode(result, s.type!);
          } else if (s.op == '?') {
            result = NullCheckPatternNode(result);
          } else if (s.op == '!') {
            result = NullAssertPatternNode(result);
          }
        }
        return result;
      });

  /// Outer pattern for pattern variable declarations: `(a, b)`, `[a, b]`, `{'k': v}`, `Foo(a: b)`.
  Parser<PatternNode> outerPattern() => [
    ref0(parenthesizedOrRecordPattern),
    ref0(listPattern),
    ref0(mapPattern),
    ref0(objectPattern),
  ].toChoiceParser();

  /// Primary patterns.
  Parser<PatternNode> primaryPattern() => [
    ref0(parenthesizedOrRecordPattern),
    ref0(listPattern),
    ref0(mapPattern),
    ref0(objectPattern),
    ref0(wildcardPattern),
    ref0(variablePattern),
    ref0(constantPattern),
  ].toChoiceParser();

  /// Parenthesized or record pattern `(...)`.
  Parser<PatternNode> parenthesizedOrRecordPattern() =>
      seq3(
        ref1(token, '('),
        ref0(patternField)
            .plusSeparated(ref1(token, ','))
            .map((l) => l.elements)
            .optionalWith(const <PatternFieldNode>[]),
        seq2(ref1(token, ',').optional(), ref1(token, ')')),
      ).map3((_, fields, commaAndClose) {
        if (fields.length == 1 &&
            fields.first.name == null &&
            commaAndClose.$1 == null) {
          return ParenthesizedPatternNode(fields.first.pattern);
        }
        return RecordPatternNode(fields: fields);
      });

  /// List pattern (`[a, b, ...rest]`).
  Parser<ListPatternNode> listPattern() =>
      seq5(
        ref0(typeArguments).optionalWith(const <TypeNode>[]),
        ref1(token, '['),
        ref0(listPatternElement)
            .plusSeparated(ref1(token, ','))
            .map((l) => l.elements)
            .optionalWith(const <PatternNode>[]),
        ref1(token, ',').optional(),
        ref1(token, ']'),
      ).map5(
        (typeArgs, _, elements, _, _) =>
            ListPatternNode(typeArguments: typeArgs, elements: elements),
      );

  Parser<PatternNode> listPatternElement() =>
      [ref0(restPattern), ref0(dartPattern)].toChoiceParser();

  Parser<RestPatternNode> restPattern() => seq2(
    ref1(token, '...'),
    ref0(dartPattern).optional(),
  ).map2((_, p) => RestPatternNode(p));

  /// Map pattern (`{'a': 1, 'b': var x}`).
  Parser<MapPatternNode> mapPattern() =>
      seq5(
        ref0(typeArguments).optionalWith(const <TypeNode>[]),
        ref1(token, '{'),
        ref0(mapPatternEntry)
            .plusSeparated(ref1(token, ','))
            .map((l) => l.elements)
            .optionalWith(const <MapPatternEntryNode>[]),
        ref1(token, ',').optional(),
        ref1(token, '}'),
      ).map5(
        (typeArgs, _, entries, _, _) =>
            MapPatternNode(typeArguments: typeArgs, entries: entries),
      );

  Parser<MapPatternEntryNode> mapPatternEntry() => seq3(
    ref0(expression),
    ref1(token, ':'),
    ref0(dartPattern),
  ).map3((key, _, val) => MapPatternEntryNode(key: key, value: val));

  /// Object pattern (`Point(x: var x, y: 0)`).
  Parser<ObjectPatternNode> objectPattern() => seq4(
    ref0(namedType),
    ref1(token, '('),
    ref0(patternField)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements)
        .optionalWith(const <PatternFieldNode>[]),
    seq2(ref1(token, ',').optional(), ref1(token, ')')),
  ).map4((type, _, fields, _) => ObjectPatternNode(type: type, fields: fields));

  /// A field inside an object or record pattern (`name: pattern` or `:pattern` or `pattern`).
  Parser<PatternFieldNode> patternField() => [
    // Explicit name: foo: pattern
    seq3(
      ref0(identifier),
      ref1(token, ':'),
      ref0(dartPattern),
    ).map3((name, _, p) => PatternFieldNode(name: name, pattern: p)),
    // Shorthand name: :var x or :final x
    (ref1(token, ':') & ref0(variablePattern)).map(
      (l) => PatternFieldNode(
        name: (l[1] as VariablePatternNode).name,
        pattern: l[1] as VariablePatternNode,
      ),
    ),
    // Shorthand name with just identifier: :x (equivalent to :var x)
    (ref1(token, ':') & ref0(identifier)).map(
      (l) => PatternFieldNode(
        name: l[1] as String,
        pattern: VariablePatternNode(name: l[1] as String, isVar: true),
      ),
    ),
    // Just pattern (in record)
    ref0(dartPattern).map((p) => PatternFieldNode(pattern: p)),
  ].toChoiceParser();

  /// Wildcard pattern (`_` or `Type _`).
  Parser<WildcardPatternNode> wildcardPattern() => [
    (ref0(type) & ref1(token, '_')).map(
      (l) => WildcardPatternNode(l[0] as TypeNode),
    ),
    ref1(token, '_').map((_) => const WildcardPatternNode()),
  ].toChoiceParser();

  /// Variable pattern (`var x`, `final x`, `final int x`, `int x`).
  Parser<VariablePatternNode> variablePattern() => [
    seq2(
      ref0(finalToken),
      [
        seq2(
          ref0(type),
          ref0(identifier),
        ).map2((type, name) => (type: type, name: name)),
        ref0(identifier).map((name) => (type: null, name: name)),
      ].toChoiceParser(),
    ).map2(
      (_, data) =>
          VariablePatternNode(name: data.name, type: data.type, isFinal: true),
    ),
    seq2(
      ref0(varToken),
      ref0(identifier),
    ).map2((_, name) => VariablePatternNode(name: name, isVar: true)),
    seq2(
      ref0(type),
      ref0(identifier),
    ).map2((type, name) => VariablePatternNode(name: name, type: type)),
  ].toChoiceParser();

  /// Constant pattern (literals, const expressions, identifier constants).
  Parser<ConstantPatternNode> constantPattern() => [
    seq2(ref1(token, '-'), ref0(numericLiteral)).map2(
      (_, n) =>
          ConstantPatternNode(UnaryExpressionNode(operator: '-', operand: n)),
    ),
    ref0(literal).map(ConstantPatternNode.new),
    (ref0(constToken) & ref0(expression)).map(
      (l) => ConstantPatternNode(l[1] as ExpressionNode),
    ),
    ref0(qualifiedIdentifier)
        .map((name) => ConstantPatternNode(IdentifierNode(name))),
  ].toChoiceParser();

  /// Pattern guard `when expression`.
  Parser<ExpressionNode> patternGuard() =>
      (ref0(whenToken) & ref0(expression)).map((l) => l[1] as ExpressionNode);
}

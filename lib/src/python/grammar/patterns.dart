import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';

/// Mixin for Python pattern syntax (PEP 634 match/case).
mixin PythonPatternGrammar
    on GrammarDefinition<ModuleNode>, PythonLexicalGrammar {
  /// Entry point for pattern matching.
  Parser<PatternNode> pythonPattern() => ref0(orPattern);

  /// Pattern alternative `p1 | p2`.
  Parser<PatternNode> orPattern() =>
      ref0(closedPattern).plusSeparated(ref1(token, '|')).map((seq) {
        if (seq.elements.length == 1) return seq.elements.first;
        return MatchOrNode(seq.elements);
      });

  /// Closed patterns or as-patterns.
  Parser<PatternNode> closedPattern() =>
      [ref0(asPattern), ref0(atomPattern)].toChoiceParser();

  /// As pattern `p as name`.
  Parser<PatternNode> asPattern() => seq3(
    ref0(atomPattern),
    ref0(asToken),
    ref0(identifier),
  ).map3((pat, _, name) => MatchAsNode(pattern: pat, name: name));

  /// Atomic patterns.
  Parser<PatternNode> atomPattern() => [
    ref0(wildcardPattern),
    ref0(literalPattern),
    ref0(classOrCapturePattern),
    ref0(sequencePattern),
    ref0(mappingPattern),
  ].toChoiceParser();

  /// Wildcard pattern `_`.
  Parser<PatternNode> wildcardPattern() =>
      ref1(token, '_').map((_) => const MatchStarNode());

  /// Literal pattern (numbers, strings, True, False, None).
  Parser<PatternNode> literalPattern() => [
    ref0(noneToken).map((_) => const MatchSingletonNode(null)),
    ref0(trueToken).map((_) => const MatchSingletonNode(true)),
    ref0(falseToken).map((_) => const MatchSingletonNode(false)),
    ref0(numberLiteral).map(MatchValueNode.new),
    ref0(stringLiteral).map(MatchValueNode.new),
  ].toChoiceParser();

  /// Class pattern `Point(x, y)` or simple capture `name`.
  Parser<PatternNode> classOrCapturePattern() =>
      seq2(
        ref0(dottedName),
        seq3(
          ref1(token, '('),
          ignore(ref0(patternArguments).optional()),
          ref1(token, ')'),
        ).map3((_, args, _) => args).optional(),
      ).map2((name, args) {
        if (args == null) {
          if (!name.contains('.')) {
            return MatchAsNode(name: name);
          }
          return MatchValueNode(NameNode(name));
        }
        final parsedArgs = args;
        return MatchClassNode(
          cls: NameNode(name),
          patterns: parsedArgs.pos,
          kwdAttrs: parsedArgs.kwdNames,
          kwdPatterns: parsedArgs.kwdPatterns,
        );
      });

  Parser<String> dottedName() =>
      ref0(identifier)
          .plusSeparated(ref1(token, '.'))
          .map((seq) => seq.elements.join('.'));

  /// Pattern arguments in class pattern.
  Parser<
    ({
      List<PatternNode> pos,
      List<String> kwdNames,
      List<PatternNode> kwdPatterns,
    })
  >
  patternArguments() =>
      seq2(
        [
          ref0(keywordPatternArg),
          ref0(pythonPattern).map((p) => (kwd: null, pat: p)),
        ].toChoiceParser().plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final pos = <PatternNode>[];
        final kwdNames = <String>[];
        final kwdPatterns = <PatternNode>[];
        for (final item in seq.elements) {
          if (item.kwd != null) {
            kwdNames.add(item.kwd!);
            kwdPatterns.add(item.pat);
          } else {
            pos.add(item.pat);
          }
        }
        return (pos: pos, kwdNames: kwdNames, kwdPatterns: kwdPatterns);
      });

  Parser<({String? kwd, PatternNode pat})> keywordPatternArg() => seq3(
    ref0(identifier),
    ref0(assignToken),
    ref0(pythonPattern),
  ).map3((id, _, pat) => (kwd: id, pat: pat));

  /// Sequence pattern `[p1, p2]` or `(p1, p2)`.
  Parser<PatternNode> sequencePattern() => [
    seq3(
      ref1(token, '['),
      ignore(ref0(patternItems).optional()),
      ref1(token, ']'),
    ).map3((_, items, _) => MatchSequenceNode(items ?? const [])),
    seq3(
      ref1(token, '('),
      ignore(ref0(patternItems).optional()),
      ref1(token, ')'),
    ).map3((_, items, _) => MatchSequenceNode(items ?? const [])),
  ].toChoiceParser();

  Parser<List<PatternNode>> patternItems() => seq2(
    ref0(patternItem).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => seq.elements);

  Parser<PatternNode> patternItem() => [
    seq2(
      ref1(token, '*'),
      ref0(identifier).optional(),
    ).map2((_, id) => MatchStarNode(id)),
    ref0(pythonPattern),
  ].toChoiceParser();

  /// Mapping pattern `{"key": val, **rest}`.
  Parser<PatternNode> mappingPattern() =>
      seq3(
        ref1(token, '{'),
        ignore(ref0(mappingItems).optional()),
        ref1(token, '}'),
      ).map3((_, items, _) {
        if (items == null) return const MatchMappingNode();
        return MatchMappingNode(
          keys: items.keys,
          patterns: items.patterns,
          rest: items.rest,
        );
      });

  Parser<
    ({List<ExpressionNode> keys, List<PatternNode> patterns, String? rest})
  >
  mappingItems() =>
      seq2(
        [
          ref0(mappingDoubleStarRest),
          ref0(keyValPattern),
        ].toChoiceParser().plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final keys = <ExpressionNode>[];
        final patterns = <PatternNode>[];
        String? rest;
        for (final item in seq.elements) {
          if (item.rest != null) {
            rest = item.rest;
          } else if (item.key != null && item.pat != null) {
            keys.add(item.key!);
            patterns.add(item.pat!);
          }
        }
        return (keys: keys, patterns: patterns, rest: rest);
      });

  Parser<({ExpressionNode? key, PatternNode? pat, String? rest})>
  mappingDoubleStarRest() => seq2(
    ref1(token, '**'),
    ref0(identifier),
  ).map2((_, id) => (key: null, pat: null, rest: id));

  Parser<({ExpressionNode? key, PatternNode? pat, String? rest})>
  keyValPattern() => seq3(
    ref0(expression),
    ref1(token, ':'),
    ref0(pythonPattern),
  ).map3((k, _, p) => (key: k, pat: p, rest: null));
}

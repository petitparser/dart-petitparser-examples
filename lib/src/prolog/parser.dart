import 'package:petitparser/petitparser.dart';

import 'evaluator.dart';

/// The standard prolog parser definition.
final _definition = PrologParserDefinition();

/// The standard prolog parser to read rules.
final Parser<List<Rule>> rulesParser = _definition
    .buildFrom(_definition.rules())
    .end();

/// The standard prolog parser to read queries.
final Parser<Term> termParser = _definition.buildFrom(_definition.term()).end();

/// Prolog parser definition that directly creates typed Prolog AST structures.
class PrologParserDefinition extends GrammarDefinition<List<Rule>> {
  final Map<String, Variable> scope = {};

  @override
  Parser<List<Rule>> start() => ref0(rules).end();

  Parser<List<Rule>> rules() => ref0(rule).star();

  Parser<Rule> rule() =>
      seq4(
        epsilon().map((_) => scope.clear(), hasSideEffects: true),
        ref0(term),
        seq2(
          ref1(token, ':-'),
          ref0(term)
              .plusSeparated(ref1(token, ','))
              .map((list) => list.elements),
        ).map2((_, body) => body).optional(),
        ref1(token, '.'),
      ).map4((_, head, body, _) {
        if (body == null || body.isEmpty) {
          return Rule(head, const True());
        } else if (body.length == 1) {
          return Rule(head, body.single);
        } else {
          return Rule(head, Conjunction(body));
        }
      }, hasSideEffects: true);

  Parser<Term> term() => seq2(
    ref0(atom),
    seq3(
      ref1(token, '('),
      ref0(parameter)
          .plusSeparated(ref1(token, ','))
          .map((list) => list.elements),
      ref1(token, ')'),
    ).map3((_, params, _) => params).optional(),
  ).map2((atom, params) => Term(atom.toString(), params ?? const []));

  Parser<Node> parameter() =>
      seq2(
        ref0(atom),
        seq3(
          ref1(token, '('),
          ref0(parameter)
              .plusSeparated(ref1(token, ','))
              .map((list) => list.elements),
          ref1(token, ')'),
        ).map3((_, params, _) => params).optional(),
      ).map2(
        (atom, params) => params == null ? atom : Term(atom.toString(), params),
      );

  Parser<Node> atom() => [ref0(variable), ref0(value)].toChoiceParser();

  Parser<Variable> variable() => ref0(variableToken).map((name) {
    if (name == '_') return Variable(name);
    return scope.putIfAbsent(name, () => Variable(name));
  }, hasSideEffects: true);

  Parser<Value> value() => ref0(valueToken).map(Value.new);

  Parser<void> space() =>
      [whitespace(), ref0(commentSingle), ref0(commentMulti)].toChoiceParser();

  Parser<void> commentSingle() =>
      seq2(char('%'), pattern('^\r\n').starString());

  Parser<void> commentMulti() =>
      seq3(string('/*'), any().starLazy(string('*/')), string('*/'));

  Parser<String> token(Object parser, [String? message]) => switch (parser) {
    final Parser parser =>
      parser.flatten(message: message ?? 'token expected').trim(ref0(space)),
    final String string =>
      string.toParser(message: message ?? '$string expected').trim(ref0(space)),
    _ => throw ArgumentError.value(parser, 'parser', 'Invalid parser type'),
  };

  Parser<String> variableToken() => ref2(
    token,
    seq2(pattern('A-Z_'), pattern('A-Za-z0-9_').starString()),
    'Variable expected',
  );

  Parser<String> valueToken() => ref2(
    token,
    seq2(pattern('a-z'), pattern('A-Za-z0-9_').starString()),
    'Value expected',
  );
}

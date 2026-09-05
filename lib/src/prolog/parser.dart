import 'package:petitparser/petitparser.dart';

import 'evaluator.dart';
import 'grammar.dart';

/// The standard prolog parser definition.
final _definition = PrologParserDefinition();

/// The standard prolog parser to read rules.
final Parser<List<Rule>> rulesParser = _definition
    .buildFrom(_definition.rules())
    .end();

/// The standard prolog parser to read queries.
final Parser<Term> termParser = _definition.buildFrom(_definition.term()).end();

/// Prolog parser definition.
class PrologParserDefinition extends PrologGrammarDefinition {
  final Map<String, Variable> scope = {};

  @override
  Parser<List<Rule>> rules() => super.rules().castList();

  @override
  Parser<Rule> rule() => super.rule().map((each) {
    scope.clear();
    final [head, rest, _] = each as List;
    if (rest == null) {
      return Rule(head, const True());
    }
    final terms = rest[1] as List;
    return switch (terms.length) {
      0 => Rule(head, const True()),
      1 => Rule(head, terms[0]),
      _ => Rule(head, Conjunction(terms.cast())),
    };
  });

  @override
  Parser<Term> term() => super.term().map((each) {
    final [name, rest] = each as List;
    if (rest == null) {
      return Term(name.toString(), const []);
    }
    final terms = rest[1] as List;
    return Term(name.toString(), terms.cast());
  });

  @override
  Parser<Node> parameter() => super.parameter().map((each) {
    final [name, rest] = each as List;
    if (rest == null) {
      return name;
    }
    final terms = rest[1] as List;
    return Term(name.toString(), terms.cast());
  });

  @override
  Parser<Variable> variable() => super.variable().map((name) {
    if (name == '_') return Variable(name);
    return scope.putIfAbsent(name, () => Variable(name));
  });

  @override
  Parser<Value> value() => super.value().map((name) => Value(name));
}

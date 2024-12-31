import 'package:petitparser/petitparser.dart';

import 'evaluator.dart';
import 'grammar.dart';

/// The standard prolog parser definition.
final _definition = PrologParserDefinition();

/// The standard prolog parser to read rules.
final Parser<List<Rule>> rulesParser =
    _definition.buildFrom(_definition.rules()).end();

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
        final head = each[0];
        final rest = each[1];
        if (rest == null) {
          return Rule(head, const True());
        }
        final List terms = rest[1];
        if (terms.isEmpty) {
          return Rule(head, const True());
        } else if (terms.length == 1) {
          return Rule(head, terms[0]);
        } else {
          return Rule(head, Conjunction(terms.cast()));
        }
      });

  @override
  Parser<Term> term() => super.term().map((each) {
        final name = each[0];
        final rest = each[1];
        if (rest == null) {
          return Term(name.toString(), const []);
        }
        final List terms = rest[1];
        return Term(name.toString(), terms.cast());
      });

  @override
  Parser<Node> parameter() => super.parameter().map((each) {
        final name = each[0];
        final rest = each[1];
        if (rest == null) {
          return name;
        }
        final List terms = rest[1];
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

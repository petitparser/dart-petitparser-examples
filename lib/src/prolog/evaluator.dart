import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:more/collection.dart';

import 'parser.dart';

const Equality<List<Node>> argumentEquality = ListEquality();

Map<Variable, Node> newBindings() => Map<Variable, Node>.identity();

Map<Variable, Node>? mergeBindings(
  Map<Variable, Node>? first,
  Map<Variable, Node>? second,
) {
  if (first == null || second == null) {
    return null;
  }
  final result = newBindings()..addAll(first);
  for (final key in second.keys) {
    final value = second[key]!;
    final other = result[key];
    if (other != null) {
      final subs = other.match(value);
      if (subs == null) {
        return null;
      } else {
        result.addAll(subs);
      }
    } else {
      result[key] = value;
    }
  }
  return result;
}

@immutable
final class Database {
  factory Database.parse(String rules) =>
      Database(rulesParser.parse(rules).value);

  Database(Iterable<Rule> rules) {
    for (final rule in rules) {
      this.rules.putIfAbsent(rule.head.name, () => []).add(rule);
    }
  }

  final Map<String, List<Rule>> rules = {};

  Iterable<Node> query(Term goal) {
    final candidates = rules[goal.name];
    if (candidates == null) return const [];
    return candidates.expand((rule) => rule.query(this, goal));
  }

  @override
  String toString() =>
      rules.values.map((rules) => rules.join('\n')).join('\n\n');
}

@immutable
final class Rule {
  const Rule(this.head, this.body);

  final Term head;
  final Term body;

  Iterable<Node> query(Database database, Term goal) {
    final match = head.match(goal);
    if (match == null) return const [];
    final newHead = head.substitute(match);
    final newBody = body.substitute(match);
    return newBody
        .query(database)
        .map((item) => newHead.substitute(newBody.match(item)));
  }

  @override
  String toString() => '$head :- $body.';
}

@immutable
abstract class Node {
  const Node();

  Map<Variable, Node>? match(Node other);

  Node substitute(Map<Variable, Node>? bindings);
}

@immutable
class Variable extends Node {
  const Variable(this.name);

  final String name;

  @override
  Map<Variable, Node>? match(Node other) {
    final bindings = newBindings();
    if (this != other) {
      bindings[this] = other;
    }
    return bindings;
  }

  @override
  Node substitute(Map<Variable, Node>? bindings) {
    if (bindings != null) {
      final value = bindings[this];
      if (value != null) {
        return value.substitute(bindings);
      }
    }
    return this;
  }

  @override
  bool operator ==(Object other) => other is Variable && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

@immutable
class Term extends Node {
  factory Term.parse(String rules) => termParser.parse(rules).value;

  factory Term(String name, Iterable<Node> list) =>
      Term._(name, list.toList(growable: false));

  const Term._(this.name, this.arguments);

  final String name;
  final List<Node> arguments;

  Iterable<Node> query(Database database) => database.query(this);

  @override
  Map<Variable, Node>? match(Node other) {
    if (other is Term) {
      if (name != other.name) {
        return null;
      }
      if (arguments.length != other.arguments.length) {
        return null;
      }
      return [arguments, other.arguments]
          .zip()
          .map((arg) => arg[0].match(arg[1]))
          .fold(newBindings(), mergeBindings);
    }
    return other.match(this);
  }

  @override
  Term substitute(Map<Variable, Node>? bindings) =>
      Term(name, arguments.map((arg) => arg.substitute(bindings)));

  @override
  bool operator ==(Object other) =>
      other is Term &&
      name == other.name &&
      argumentEquality.equals(arguments, other.arguments);

  @override
  int get hashCode => name.hashCode ^ argumentEquality.hash(arguments);

  @override
  String toString() =>
      arguments.isEmpty ? name : '$name(${arguments.join(', ')})';
}

@immutable
class True extends Term {
  const True() : super._('true', const []);

  @override
  Term substitute(Map<Variable, Node>? bindings) => this;

  @override
  Iterable<Node> query(Database database) => [this];
}

@immutable
class Value extends Term {
  const Value(String name) : super._(name, const []);

  @override
  Iterable<Node> query(Database database) => [this];

  @override
  Value substitute(Map<Variable, Node>? bindings) => this;

  @override
  bool operator ==(Object other) => other is Value && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

@immutable
class Conjunction extends Term {
  factory Conjunction(Iterable<Node> list) =>
      Conjunction._(list.toList(growable: false));

  const Conjunction._(List<Node> args) : super._(',', args);

  @override
  Iterable<Node> query(Database database) {
    Iterable<Node> solutions(int index, Map<Variable, Node> bindings) sync* {
      if (index < arguments.length) {
        final arg = arguments[index];
        final subs = arg.substitute(bindings) as Term;
        for (final item in database.query(subs)) {
          final unified = mergeBindings(arg.match(item), bindings);
          if (unified != null) {
            yield* solutions(index + 1, unified);
          }
        }
      } else {
        yield substitute(bindings);
      }
    }

    return solutions(0, newBindings());
  }

  @override
  Conjunction substitute(Map<Variable, Node>? bindings) =>
      Conjunction(arguments.map((arg) => arg.substitute(bindings)));

  @override
  bool operator ==(Object other) =>
      other is Conjunction &&
      argumentEquality.equals(arguments, other.arguments);

  @override
  int get hashCode => argumentEquality.hash(arguments);

  @override
  String toString() => arguments.join(', ');
}

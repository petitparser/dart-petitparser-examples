import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:more/collection.dart';

import 'parser.dart';

const Equality<List<Node>> _argumentEquality = ListEquality();

Map<Variable, Node> _newBindings() => Map<Variable, Node>.identity();

Map<Variable, Node>? _mergeBindings(
  Map<Variable, Node>? first,
  Map<Variable, Node>? second,
) {
  if (first == null || second == null) {
    return null;
  }
  final result = _newBindings()..addAll(first);
  for (final MapEntry(:key, :value) in second.entries) {
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

/// An indexed collection of Prolog [Rule] definitions that can be queried.
///
/// Rules are indexed by head functor name for fast candidate lookup during
/// goal resolution.
///
/// For example:
///
/// ```dart
/// final db = Database.parse('parent(tom, bob). parent(bob, ann).');
/// final goal = Term.parse('parent(tom, X)');
/// for (final result in db.query(goal)) {
///   print(result); // parent(tom, bob)
/// }
/// ```
@immutable
final class Database {
  /// Parses a string of Prolog rules into a [Database].
  factory parse(String rules) => Database(rulesParser.parse(rules).value);

  /// Creates a database populated with [rules].
  new(Iterable<Rule> rules) {
    for (final rule in rules) {
      this.rules.putIfAbsent(rule.head.name, () => []).add(rule);
    }
  }

  /// Map of rule head functor names to candidate rules.
  final Map<String, List<Rule>> rules = {};

  /// Queries the database with [goal], yielding unified solution terms.
  Iterable<Node> query(Term goal) {
    final candidates = rules[goal.name];
    if (candidates == null) return const [];
    return candidates.expand((rule) => rule.query(this, goal));
  }

  @override
  String toString() =>
      rules.values.map((rules) => rules.join('\n')).join('\n\n');
}

/// A Prolog Horn clause consisting of a [head] term and a [body] goal.
///
/// Unconditional facts are represented with a [body] of [True].
///
/// For example:
///
/// ```dart
/// final rule = Rule(
///   Term('mortal', [Variable('X')]),
///   Term('human', [Variable('X')]),
/// );
/// ```
@immutable
final class Rule {
  /// Creates a rule with the specified [head] and [body].
  const new(this.head, this.body);

  /// The head term of the clause.
  final Term head;

  /// The body term or conjunction to satisfy.
  final Term body;

  /// Evaluates this rule against [database] to satisfy [goal].
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

/// Base class for all Prolog AST terms and variables.
///
/// Supports unification via [match] and variable substitution via [substitute].
@immutable
abstract class Node {
  /// Const constructor for subclasses.
  const new();

  /// Attempts to unify this node with [other], returning variable bindings or `null`.
  Map<Variable, Node>? match(Node other);

  /// Substitutes variables in this node with their bound values in [bindings].
  Node substitute(Map<Variable, Node>? bindings);
}

/// A named Prolog variable capable of binding during unification.
///
/// Variable names begin with an uppercase letter or an underscore.
///
/// For example:
///
/// ```dart
/// final x = Variable('X');
/// ```
@immutable
class Variable extends Node {
  /// Creates a variable with the given [name].
  const new(this.name);

  /// The name of the variable.
  final String name;

  @override
  Map<Variable, Node>? match(Node other) {
    final bindings = _newBindings();
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

/// A compound Prolog term consisting of a functor [name] and argument [arguments].
///
/// When [arguments] is empty, represents an atomic term.
///
/// For example:
///
/// ```dart
/// final term = Term.parse('father(john, mary)');
/// print(term.name); // 'father'
/// print(term.arguments); // [john, mary]
/// ```
@immutable
class Term extends Node {
  /// Parses a string into a [Term].
  factory parse(String rules) => termParser.parse(rules).value;

  /// Creates a compound term with [name] and [list] of arguments.
  factory(String name, Iterable<Node> list) =>
      Term._(name, list.toList(growable: false));

  const new _(this.name, this.arguments);

  /// The functor name of the term.
  final String name;

  /// The argument nodes of the compound term.
  final List<Node> arguments;

  /// Evaluates this term as a goal against [database].
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
          .fold(_newBindings(), _mergeBindings);
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
      _argumentEquality.equals(arguments, other.arguments);

  @override
  int get hashCode => name.hashCode ^ _argumentEquality.hash(arguments);

  @override
  String toString() =>
      arguments.isEmpty ? name : '$name(${arguments.join(', ')})';
}

/// The Prolog `true` goal, which succeeds unconditionally with no substitutions.
@immutable
class True extends Term {
  /// Creates an unconditional `true` term.
  const new() : super._('true', const []);

  @override
  Term substitute(Map<Variable, Node>? bindings) => this;

  @override
  Iterable<Node> query(Database database) => [this];
}

/// A Prolog atomic constant (atom) with no arguments.
///
/// For example:
///
/// ```dart
/// const atom = Value('apple');
/// ```
@immutable
class Value extends Term {
  /// Creates an atomic constant with the given [name].
  const new(String name) : super._(name, const []);

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

/// A conjunction of goals (the `,` operator in Prolog) evaluated sequentially.
///
/// For example:
///
/// ```dart
/// final conj = Conjunction([
///   Term('parent', [Variable('X'), Variable('Y')]),
///   Term('parent', [Variable('Y'), Variable('Z')]),
/// ]);
/// ```
@immutable
class Conjunction extends Term {
  /// Creates a conjunction from an iterable [list] of goal nodes.
  factory(Iterable<Node> list) => Conjunction._(list.toList(growable: false));

  const new _(List<Node> args) : super._(',', args);

  @override
  Iterable<Node> query(Database database) {
    Iterable<Node> solutions(int index, Map<Variable, Node> bindings) sync* {
      if (index < arguments.length) {
        final arg = arguments[index];
        final subs = arg.substitute(bindings) as Term;
        for (final item in database.query(subs)) {
          final unified = _mergeBindings(arg.match(item), bindings);
          if (unified != null) {
            yield* solutions(index + 1, unified);
          }
        }
      } else {
        yield substitute(bindings);
      }
    }

    return solutions(0, _newBindings());
  }

  @override
  Conjunction substitute(Map<Variable, Node>? bindings) =>
      Conjunction(arguments.map((arg) => arg.substitute(bindings)));

  @override
  bool operator ==(Object other) =>
      other is Conjunction &&
      _argumentEquality.equals(arguments, other.arguments);

  @override
  int get hashCode => _argumentEquality.hash(arguments);

  @override
  String toString() => arguments.join(', ');
}

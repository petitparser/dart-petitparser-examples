/// Prolog grammar, AST definitions, and unification-based query evaluator.
///
/// Based on <https://curiosity-driven.org/prolog-interpreter>.
///
/// For example:
///
/// ```dart
/// final db = Database.parse('p(X) :- q(X). q(a).');
/// final goal = Term.parse('p(a)');
/// for (final result in db.query(goal)) {
///   print(result);
/// }
/// ```
library;

export 'src/prolog/evaluator.dart';
export 'src/prolog/parser.dart';

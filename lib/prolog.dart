/// This library contains a simple grammar and evaluator for Prolog based on
/// this blog post: https://curiosity-driven.org/prolog-interpreter.
///
/// The code is reasonably complete to run and evaluate reasonably complex
/// programs from the console or the web browser.
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
export 'src/prolog/grammar.dart';
export 'src/prolog/parser.dart';

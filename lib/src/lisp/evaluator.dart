import 'package:petitparser/petitparser.dart';

import 'cons.dart';
import 'environment.dart';
import 'name.dart';
import 'quote.dart';

/// The evaluation function.
dynamic eval(Environment env, dynamic expr) => switch (expr) {
  final Quote quote => quote.datum,
  final Cons cons => (eval(env, cons.head) as Function)(env, cons.tail),
  final Name name => env[name],
  _ => expr,
};

/// Evaluate a cons of instructions.
dynamic evalList(Environment env, dynamic expr) {
  dynamic result;
  while (expr is Cons) {
    result = eval(env, expr.head);
    expr = expr.tail;
  }
  return result;
}

/// The arguments evaluation function.
dynamic evalArguments(Environment env, dynamic args) => switch (args) {
  final Cons cons => Cons(eval(env, cons.head), evalArguments(env, cons.tail)),
  _ => null,
};

/// Reads and evaluates a [script].
dynamic evalString(Parser parser, Environment env, String script) {
  dynamic result;
  for (final cell in parser.parse(script).value) {
    result = eval(env, cell);
  }
  return result;
}

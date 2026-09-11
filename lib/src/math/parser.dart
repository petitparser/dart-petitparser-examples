import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common.dart';

final parser = () {
  final builder = ExpressionBuilder<Expression>();
  builder
    // Numbers
    ..primitive(
      seq3(
        digit().plus(),
        seq2(char('.'), digit().plus()).optional(),
        seq3(pattern('eE'), anyOf('+-').optional(), digit().plus()).optional(),
      ).flatten(message: 'number expected').trim().map(_createValue),
    )
    // Constant, variables, and functions
    ..primitive(
      seq2(
        seq2(
          letter(),
          word().starString(),
        ).flatten(message: 'name expected').trim(),
        builder.loopback
            .starSeparated(char(',').trim())
            .map((list) => list.elements)
            .skip(before: char('(').trim(), after: char(')').trim())
            .optionalWith(const <Expression>[]),
      ).map2((name, args) => _createBinding(name, args)),
    );
  // Parentheses (highest precedence wrapper)
  builder.group().wrapper(
    char('(').trim(),
    char(')').trim(),
    (left, value, right) => value,
  );
  // Unary prefix operators (+, -)
  builder.group()
    ..prefix(char('+').trim(), (op, a) => a)
    ..prefix(char('-').trim(), (op, a) => Application('-', [a], (x) => -x));
  // Exponentiation (right-associative)
  builder.group().right(
    char('^').trim(),
    (a, op, b) => Application('^', [a, b], math.pow),
  );
  // Multiplicative operators (*, /, left-associative)
  builder.group()
    ..left(
      char('*').trim(),
      (a, op, b) => Application('*', [a, b], (x, y) => x * y),
    )
    ..left(
      char('/').trim(),
      (a, op, b) => Application('/', [a, b], (x, y) => x / y),
    );
  // Additive operators (+, -, left-associative)
  builder.group()
    ..left(
      char('+').trim(),
      (a, op, b) => Application('+', [a, b], (x, y) => x + y),
    )
    ..left(
      char('-').trim(),
      (a, op, b) => Application('-', [a, b], (x, y) => x - y),
    );
  return resolve(builder.build()).end();
}();

Expression _createValue(String value) => Value(num.parse(value));

Expression _createBinding(String name, List<Expression> arguments) =>
    switch (arguments.length) {
      0 => switch (constants[name]) {
        final num value => Value(value),
        _ => Variable(name),
      },
      1 => Application(name, arguments, checkValue(name, functions1[name])),
      2 => Application(name, arguments, checkValue(name, functions2[name])),
      _ => throwUnknown(name),
    };

T checkValue<T>(String name, T? value) => value ?? throwUnknown(name);

Never throwUnknown(String name) =>
    throw ArgumentError.value(name, 'Unknown function');

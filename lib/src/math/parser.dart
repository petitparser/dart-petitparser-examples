import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common.dart';

final parser = () {
  final builder = ExpressionBuilder<Expression>();
  builder
    ..primitive((digit().plus() &
            (char('.') & digit().plus()).optional() &
            (pattern('eE') & pattern('+-').optional() & digit().plus())
                .optional())
        .flatten('number expected')
        .trim()
        .map(_createValue))
    ..primitive(seq2(
            seq2(letter(), word().star()).flatten('name expected').trim(),
            seq3(
              char('(').trim(),
              builder.loopback
                  .starSeparated(char(',').trim())
                  .map((list) => list.elements),
              char(')').trim(),
            ).map3((_, list, __) => list).optionalWith(const <Expression>[]))
        .map2((name, args) => _createBinding(name, args)));
  builder.group().wrapper(
      char('(').trim(), char(')').trim(), (left, value, right) => value);
  builder.group()
    ..prefix(char('+').trim(), (op, a) => a)
    ..prefix(char('-').trim(), (op, a) => Application('-', [a], (x) => -x));
  builder.group().right(
      char('^').trim(), (a, op, b) => Application('^', [a, b], math.pow));
  builder.group()
    ..left(char('*').trim(),
        (a, op, b) => Application('*', [a, b], (x, y) => x * y))
    ..left(char('/').trim(),
        (a, op, b) => Application('/', [a, b], (x, y) => x / y));
  builder.group()
    ..left(char('+').trim(),
        (a, op, b) => Application('+', [a, b], (x, y) => x + y))
    ..left(char('-').trim(),
        (a, op, b) => Application('-', [a, b], (x, y) => x - y));
  return resolve(builder.build()).end();
}();

Expression _createValue(String value) => Value(num.parse(value));

Expression _createBinding(String name, List<Expression> arguments) {
  switch (arguments.length) {
    case 0:
      final value = constants[name];
      return value == null ? Variable(name) : Value(value);
    case 1:
      final function = checkValue(name, functions1[name]);
      return Application(name, arguments, function);
    case 2:
      final function = checkValue(name, functions2[name]);
      return Application(name, arguments, function);
    default:
      throwUnknown(name);
  }
}

T checkValue<T>(String name, T? value) => value ?? throwUnknown(name);

Never throwUnknown(String name) =>
    throw ArgumentError.value(name, 'Unknown function');

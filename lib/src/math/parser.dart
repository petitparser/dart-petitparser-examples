import 'dart:math' as math;

import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'common.dart';

final parser = () {
  final builder = ExpressionBuilder<Expression>();
  builder.group()
    ..primitive((digit().plus() &
            (char('.') & digit().plus()).optional() &
            (pattern('eE') & pattern('+-').optional() & digit().plus())
                .optional())
        .flatten('number expected')
        .trim()
        .map(_createValue))
    ..primitive((letter() & word().star())
        .flatten('variable expected')
        .trim()
        .map(_createVariable))
    ..wrapper<List<String>, String>(
        [word().plus().flatten('function expected'), char('(')]
            .toSequenceParser()
            .trim(),
        char(')').trim(),
        (left, value, right) => Unary(left[0], value, functions[left[0]]!))
    ..wrapper(
        char('(').trim(), char(')').trim(), (left, value, right) => value);
  builder.group()
    ..prefix(char('+').trim(), (op, a) => a)
    ..prefix(char('-').trim(), (op, a) => Unary('-', a, (x) => -x));
  builder
      .group()
      .right(char('^').trim(), (a, op, b) => Binary('^', a, b, math.pow));
  builder.group()
    ..left(char('*').trim(), (a, op, b) => Binary('*', a, b, (x, y) => x * y))
    ..left(char('/').trim(), (a, op, b) => Binary('/', a, b, (x, y) => x / y));
  builder.group()
    ..left(char('+').trim(), (a, op, b) => Binary('+', a, b, (x, y) => x + y))
    ..left(char('-').trim(), (a, op, b) => Binary('-', a, b, (x, y) => x - y));
  return builder.build().end();
}();

Expression _createValue(String value) => Value(num.parse(value));

Expression _createVariable(String name) =>
    constants.containsKey(name) ? Value(constants[name]!) : Variable(name);

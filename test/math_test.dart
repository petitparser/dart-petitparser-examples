import 'dart:math';

import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/math.dart';
import 'package:test/scaffolding.dart';

import 'utils/checks.dart';

void verify(
  String input,
  num result, {
  Map<String, num> variables = const {},
  double epsilon = 0.00001,
}) {
  final ast = parser.parse(input).value;
  check(ast.eval(variables)).isCloseTo(result, epsilon);
  check(ast.toString()).isNotNull();
}

void main() {
  test('linter', () {
    check(linter(parser, excludedRules: {})).isEmpty();
  });
  test('number', () {
    verify('0', 0);
    verify('42', 42);
    verify('3.141', 3.141);
    verify('1.2e5', 1.2e5);
    verify('3.4e-1', 3.4e-1);
  });
  test('variable', () {
    verify('x', 42, variables: {'x': 42});
    verify('x / y', 0.5, variables: {'x': 1, 'y': 2});
    check(() => verify('x', double.nan, variables: {})).throws<ArgumentError>();
  });
  test('constants', () {
    verify('pi', pi);
    verify('e', e);
  });
  test('functions (1 arg)', () {
    verify('acos(0.5)', acos(0.5));
    verify('asin(0.5)', asin(0.5));
    verify('atan(0.5)', atan(0.5));
    verify('cos(7)', cos(7));
    verify('exp(7)', exp(7));
    verify('log(7)', log(7));
    verify('sin(7)', sin(7));
    verify('sqrt(2)', sqrt(2));
    verify('tan(7)', tan(7));
    verify('abs(-1)', 1);
    verify('ceil(1.2)', 2);
    verify('floor(1.2)', 1);
    verify('round(1.6)', 2);
    verify('sign(-2)', -1);
    verify('truncate(-1.2)', -1);
  });
  test('functions (2 args)', () {
    verify('atan2(2, 3)', atan2(2, 3));
    verify('max(2, 3)', max(2, 3));
    verify('min(2, 3)', min(2, 3));
    verify('pow(2, 3)', pow(2, 3));
  });
  test('unknown functions throw ArgumentError', () {
    check(() => parser.parse('unknown(1)')).throws<ArgumentError>();
    check(() => parser.parse('unknown(1, 2)')).throws<ArgumentError>();
    check(() => parser.parse('foo(1, 2, 3)')).throws<ArgumentError>();
  });
  test('prefix', () {
    verify('+2', 2);
    verify('-pi', -pi);
  });
  test('power', () {
    verify('2 ^ 3', 8);
    verify('2 ^ -3', 0.125);
    verify('-2 ^ 3', -8);
    verify('-2 ^ -3', -0.125);
  });
  test('multiply', () {
    verify('2 * 3', 6);
    verify('2 * 3 * 4', 24);
    verify('6 / 3', 2);
    verify('6 / 3 / 2', 1);
  });
  test('addition', () {
    verify('2 + 3', 5);
    verify('2 + 3 + 4', 9);
    verify('5 - 3', 2);
    verify('5 - 3 - 2', 0);
  });
  test('priority', () {
    verify('1 + 2 * 3', 7);
    verify('1 + (2 * 3)', 7);
    verify('(1 + 2) * 3', 9);
  });
  group('failures', () {
    test('empty', () {
      check(parser).isFailure('');
    });
    test('trailing operator', () {
      check(parser).isFailure('1 +');
      check(parser).isFailure('2 *');
      check(parser).isFailure('2 ^');
    });
    test('unbalanced parentheses', () {
      check(parser).isFailure('(');
      check(parser).isFailure('(1 + 2');
      check(parser).isFailure('1 + 2)');
      check(parser).isFailure('()');
    });
    test('invalid tokens', () {
      check(parser).isFailure('1.');
      check(parser).isFailure('@');
      check(parser).isFailure('1 & 2');
    });
  });
}

import 'package:petitparser/petitparser.dart';
import 'package:test/scaffolding.dart';

import 'checks.dart';

void main() {
  group('ParserChecks', () {
    final parser = char('a').token();
    final pairParser = char('a') & char('b');

    test('isSuccess matches token unwrapped value', () {
      check(parser).isSuccess('a', value: 'a');
    });

    test('isSuccess matches token directly', () {
      check(parser).isSuccess('a', value: const Token('a', 'a', 0, 1));
    });

    test('isSuccess with condition', () {
      check(parser).isSuccess(
        'a',
        value: (Subject<Object?> it) {
          it.isA<String>().equals('a');
        },
      );
    });

    test('isSuccess default consumes all', () {
      check(parser).isSuccess('a');
    });

    test('isSuccess explicit position', () {
      check(pairParser).isSuccess('ab', position: 2);
    });

    test('isSuccess deep collection', () {
      check(pairParser).isSuccess('ab', value: ['a', 'b']);
    });

    test('isFailure matches failure', () {
      check(parser).isFailure('b');
    });

    test('isFailure matches message and position', () {
      check(parser).isFailure('b', message: '"a" expected', position: 0);
    });

    test('isFailure matches pattern message', () {
      check(parser).isFailure('b', message: RegExp(r'expected'));
    });
  });

  group('ResultChecks', () {
    final parser = digit();

    test('isSuccess on Success result', () {
      final result = parser.parse('1');
      check(result).isSuccess(value: '1', position: 1);
    });

    test('isFailure on Failure result', () {
      final result = parser.parse('x');
      check(result).isFailure(position: 0);
    });
  });
}

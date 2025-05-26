import 'package:petitparser/petitparser.dart';
import 'package:test/expect.dart';

/// Expects a parse success.
TypeMatcher isSuccess(
  String input, {
  dynamic value = anything,
  dynamic position,
}) => isA<Parser>().having(
  (parser) => parser.parse(input),
  'parse',
  isA<Success>()
      .having(
        (result) => result.value is Token && value is! Token
            ? result.value.value
            : result.value,
        'result',
        value,
      )
      .having(
        (result) => result.position,
        'position',
        position ?? input.length,
      ),
);

/// Expects a parse failure.
TypeMatcher isFailure(
  String input, {
  dynamic message = anything,
  dynamic position = anything,
}) => isA<Parser>().having(
  (parser) => parser.parse(input),
  'parse',
  isA<Failure>()
      .having((result) => result.message, 'message', message)
      .having((result) => result.position, 'position', position),
);

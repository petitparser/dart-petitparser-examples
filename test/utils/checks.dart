import 'package:checks/checks.dart';
import 'package:checks/context.dart';
import 'package:petitparser/petitparser.dart';

export 'package:checks/checks.dart';

const Object _sentinel = Object();

/// Domain-specific checks on PetitParser [Parser] subjects.
extension ParserChecks<T> on Subject<Parser<T>> {
  /// Asserts that parsing [input] returns a [Result], returning its subject.
  Subject<Result<T>> parse(String input) =>
      has((parser) => parser.parse(input), 'parse "$input"');

  /// Asserts that parsing [input] succeeds, optionally checking [value] and
  /// [position]. Defaults to checking that all input was consumed.
  Subject<Success<T>> isSuccess(
    String input, {
    Object? value = _sentinel,
    int? position,
  }) =>
      parse(input).isSuccess(value: value, position: position ?? input.length);

  /// Asserts that parsing [input] fails, optionally checking [message] and
  /// [position].
  Subject<Failure> isFailure(
    String input, {
    Object? message = _sentinel,
    Object? position = _sentinel,
  }) => parse(input).isFailure(message: message, position: position);
}

/// Domain-specific checks on PetitParser [Result] subjects.
extension ResultChecks<T> on Subject<Result<T>> {
  /// Asserts that this result is a [Success], optionally checking [value] and
  /// [position].
  Subject<Success<T>> isSuccess({Object? value = _sentinel, int? position}) =>
      context.nest<Success<T>>(
        () => ['is a successful parse'],
        (actual) => actual is Success<T>
            ? Extracted.value(actual)
            : Extracted.rejection(
                which: [
                  'is a failure at position ${actual.position}: '
                      '"${actual.message}"',
                ],
              ),
      )..which((success) {
        if (position != null) {
          success.has((s) => s.position, 'position').equals(position);
        }
        if (!identical(value, _sentinel)) {
          final valueSubject = success.has<Object?>((s) {
            final v = s.value;
            if (v is Token && value is! Token) {
              return v.value;
            }
            return v;
          }, 'value');
          _checkValue(valueSubject, value);
        }
      });

  /// Asserts that this result is a [Failure], optionally checking [message] and
  /// [position].
  Subject<Failure> isFailure({
    Object? message = _sentinel,
    Object? position = _sentinel,
  }) =>
      context.nest<Failure>(
        () => ['is a failed parse'],
        (actual) => actual is Failure
            ? Extracted.value(actual)
            : Extracted.rejection(
                which: [
                  'is a success with value ${actual.value} at position '
                      '${actual.position}',
                ],
              ),
      )..which((failure) {
        if (!identical(position, _sentinel)) {
          final posSubject = failure.has((f) => f.position, 'position');
          if (position is Condition<int>) {
            posSubject.which(position);
          } else {
            posSubject.equals(position as int);
          }
        }
        if (!identical(message, _sentinel)) {
          final msgSubject = failure.has((f) => f.message, 'message');
          if (message is Condition<String>) {
            msgSubject.which(message);
          } else if (message is Pattern) {
            msgSubject.matchesPattern(message);
          } else {
            msgSubject.equals(message as String);
          }
        }
      });
}

void _checkValue(Subject<Object?> subject, Object? expected) {
  if (expected is Condition<Object?>) {
    subject.which(expected);
  } else if (expected is void Function(Subject<dynamic>)) {
    expected(subject);
  } else if (expected is Map) {
    subject.isA<Map<Object?, Object?>>().deepEquals(expected);
  } else if (expected is Iterable) {
    final hasCondition = expected.any(
      (e) => e is Condition<Object?> || e is void Function(Subject<dynamic>),
    );
    if (hasCondition) {
      subject.isA<Iterable<Object?>>().pairwiseMatches(
        expected.toList(),
        (exp) =>
            (item) => _checkValue(item, exp),
        'matches expected condition',
      );
    } else {
      subject.isA<Iterable<Object?>>().deepEquals(expected);
    }
  } else {
    subject.equals(expected);
  }
}

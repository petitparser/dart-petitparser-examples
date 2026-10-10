import 'package:checks/checks.dart';
import 'package:petitparser_examples/lisp.dart';

const Object _unspecified = Object();

/// A [Condition] verifying that a subject is null.
const Condition<Object?> isNullValue = _checkIsNull;
void _checkIsNull(Subject<Object?> it) => it.isNull();

/// Domain-specific checks for [Name].
extension NameChecks on Subject<Name> {
  /// Accesses the name string representation.
  Subject<String> get name => has((n) => n.toString(), 'name');
}

/// Domain-specific checks for [Cons].
extension ConsChecks on Subject<Cons> {
  /// Accesses the [Cons.car] value.
  Subject<dynamic> get car => has((c) => c.car, 'car');

  /// Accesses the [Cons.cdr] value.
  Subject<dynamic> get cdr => has((c) => c.cdr, 'cdr');

  /// Accesses the [Cons.head] value.
  Subject<dynamic> get head => has((c) => c.head, 'head');

  /// Accesses the [Cons.tail] value.
  Subject<Cons?> get tail => has((c) => c.tail, 'tail');
}

/// Convenience boolean checks for dynamic subjects (e.g. from eval).
extension DynamicBoolChecks on Subject<dynamic> {
  /// Expects the value to be true.
  void isTrue() => isA<bool>().isTrue();

  /// Expects the value to be false.
  void isFalse() => isA<bool>().isFalse();
}

/// Returns a [Condition] checking that an object is a [Name] with optional [expectedName].
Condition<Object?> isName([Object? expectedName = _unspecified]) =>
    (Subject<Object?> it) {
      final nameSubject = it.isA<Name>();
      if (!identical(expectedName, _unspecified)) {
        nameSubject
            .has((n) => n.toString(), 'name')
            .equals(expectedName.toString());
      }
    };

/// Returns a [Condition] checking that an object is a [Cons] with optional [head] and [tail].
Condition<Object?> isCons({
  Object? head = _unspecified,
  Object? tail = _unspecified,
}) => (Subject<Object?> it) {
  final consSubject = it.isA<Cons>();
  if (!identical(head, _unspecified)) {
    if (head is Condition<Object?>) {
      consSubject.has((c) => c.head, 'head').which(head);
    } else {
      consSubject.has<Object?>((c) => c.head, 'head').equals(head);
    }
  }
  if (!identical(tail, _unspecified)) {
    if (identical(tail, isNullValue)) {
      consSubject.has((c) => c.tail, 'tail').isNull();
    } else if (tail is Condition<Object?>) {
      consSubject.has((c) => c.tail, 'tail').which(tail);
    } else if (tail == null) {
      consSubject.has((c) => c.tail, 'tail').isNull();
    } else {
      consSubject.has<Object?>((c) => c.tail, 'tail').equals(tail);
    }
  }
};

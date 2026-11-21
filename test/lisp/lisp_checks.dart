import 'package:checks/checks.dart';
import 'package:petitparser_examples/lisp.dart';

const Object _unspecified = Object();

/// A [Condition] verifying that a subject is null.
final Condition<Object?> isNullValue = Condition.it<Object?>()..isNull;

/// Domain-specific checks for [Name].
extension NameChecks on Subject<Name> {
  /// Accesses the name string representation.
  Subject<String> get name => has('name', (n) => n.toString());
}

/// Domain-specific checks for [Cons].
extension ConsChecks on Subject<Cons> {
  /// Accesses the [Cons.car] value.
  Subject<dynamic> get car => has('car', (c) => c.car);

  /// Accesses the [Cons.cdr] value.
  Subject<dynamic> get cdr => has('cdr', (c) => c.cdr);

  /// Accesses the [Cons.head] value.
  Subject<dynamic> get head => has('head', (c) => c.head);

  /// Accesses the [Cons.tail] value.
  Subject<Cons?> get tail => has('tail', (c) => c.tail);
}

/// Convenience boolean checks for dynamic subjects (e.g. from eval).
extension DynamicBoolChecks on Subject<dynamic> {
  /// Expects the value to be true.
  void get isTrue => isA<bool>().isTrue;

  /// Expects the value to be false.
  void get isFalse => isA<bool>().isFalse;
}

/// Returns a [Condition] checking that an object is a [Name] with optional [expectedName].
Condition<Object?> isName([Object? expectedName = _unspecified]) {
  final it = Condition.it<Object?>();
  final nameSubject = it.isA<Name>();
  if (!identical(expectedName, _unspecified)) {
    nameSubject
        .has('name', (n) => n.toString())
        .equals(expectedName.toString());
  }
  return it;
}

/// Returns a [Condition] checking that an object is a [Cons] with optional [head] and [tail].
Condition<Object?> isCons({
  Object? head = _unspecified,
  Object? tail = _unspecified,
}) {
  final it = Condition.it<Object?>();
  final consSubject = it.isA<Cons>();
  if (!identical(head, _unspecified)) {
    if (head is Condition<Object?>) {
      consSubject.has('head', (c) => c.head).which(head);
    } else {
      consSubject.has<Object?>('head', (c) => c.head).equals(head);
    }
  }
  if (!identical(tail, _unspecified)) {
    if (identical(tail, isNullValue)) {
      consSubject.has('tail', (c) => c.tail).isNull;
    } else if (tail is Condition<Object?>) {
      consSubject.has<Object?>('tail', (c) => c.tail).which(tail);
    } else if (tail == null) {
      consSubject.has('tail', (c) => c.tail).isNull;
    } else {
      consSubject.has<Object?>('tail', (c) => c.tail).equals(tail);
    }
  }
  return it;
}

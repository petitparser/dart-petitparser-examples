import 'package:checks/checks.dart';
import 'package:petitparser_examples/bibtex.dart';

export 'package:checks/checks.dart';

/// Reusable domain-specific checks on [BibTeXEntry] subjects.
extension BibTeXEntryChecks on Subject<BibTeXEntry> {
  Subject<String> get type => has('type', (e) => e.type);
  Subject<String> get key => has('key', (e) => e.key);
  Subject<List<BibTeXField>> get fields => has('fields', (e) => e.fields);

  void matchesEntry({
    Object? type,
    Object? key,
    Iterable<BibTeXField>? fields,
  }) {
    if (type != null) this.type.equals(type as String);
    if (key != null) this.key.equals(key as String);
    if (fields != null) this.fields.deepEquals(fields);
  }
}

/// Reusable condition matching a [BibTeXEntry].
Condition<Object?> isBibTeXEntry({
  Object? type,
  Object? key,
  Iterable<BibTeXField>? fields,
}) {
  final it = Condition.it<Object?>();
  it.isA<BibTeXEntry>().matchesEntry(type: type, key: key, fields: fields);
  return it;
}

/// Reusable domain-specific checks on [BibTeXField] subjects.
extension BibTeXFieldChecks on Subject<BibTeXField> {
  Subject<String> get rawKey => has('rawKey', (f) => f.rawKey);
  Subject<String> get rawValue => has('rawValue', (f) => f.rawValue);
  Subject<String> get key => has('key', (f) => f.key);
  Subject<String> get value => has('value', (f) => f.value);
}

import 'package:checks/checks.dart';
import 'package:petitparser_examples/bibtex.dart';

export 'package:checks/checks.dart';

/// Reusable domain-specific checks on [BibTeXEntry] subjects.
extension BibTeXEntryChecks on Subject<BibTeXEntry> {
  Subject<String> get type => has((e) => e.type, 'type');
  Subject<String> get key => has((e) => e.key, 'key');
  Subject<List<BibTeXField>> get fields => has((e) => e.fields, 'fields');

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
}) => (subject) {
  subject.isA<BibTeXEntry>().matchesEntry(type: type, key: key, fields: fields);
};

/// Reusable domain-specific checks on [BibTeXField] subjects.
extension BibTeXFieldChecks on Subject<BibTeXField> {
  Subject<String> get rawKey => has((f) => f.rawKey, 'rawKey');
  Subject<String> get rawValue => has((f) => f.rawValue, 'rawValue');
  Subject<String> get key => has((f) => f.key, 'key');
  Subject<String> get value => has((f) => f.value, 'value');
}

import 'package:meta/meta.dart';

import 'normalize.dart';

/// Models a single BibTeX bibliographic entry.
///
/// Contains the entry [type] (e.g. `'article'`, `'book'`), citation [key],
/// and a map of [fields].
///
/// For example:
///
/// ```dart
/// final entry = BibTeXEntry(
///   type: 'article',
///   key: 'knuth1984',
///   fields: {'author': 'Donald E. Knuth', 'title': 'Literate Programming'},
/// );
/// print(entry.key); // 'knuth1984'
/// print(entry.normalized['Title']); // 'Literate Programming'
/// ```
@immutable
class BibTeXEntry {
  /// Creates a BibTeX entry with [type], citation [key], and raw [fields].
  new({required this.type, required this.key, required this.fields});

  /// The entry type (e.g. `'article'`, `'inproceedings'`, `'book'`).
  final String type;

  /// The unique citation key used to cite this entry.
  final String key;

  /// The raw key-value mapping of field names to values.
  final Map<String, String> fields;

  /// The normalized fields with standardized names and LaTeX accents converted.
  late final Map<String, String> normalized = fields.map(
    (key, value) => MapEntry(
      normalizeFieldName(key),
      normalizeFieldValue(value, fieldName: key),
    ),
  );

  @override
  String toString() {
    final buffer = StringBuffer('@$type{$key');
    for (final field in fields.entries) {
      buffer.write(',\n\t${field.key} = ${field.value}');
    }
    buffer.write('}');
    return buffer.toString();
  }
}

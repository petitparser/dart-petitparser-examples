import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import 'field.dart';

/// Models a single BibTeX bibliographic entry.
///
/// Contains the entry [type] (e.g. `'article'`, `'book'`), citation [key],
/// and a list of [fields].
///
/// For example:
///
/// ```dart
/// final entry = BibTeXEntry(
///   type: 'article',
///   key: 'knuth1984',
///   fields: [
///     BibTeXField('author', 'Donald E. Knuth'),
///     BibTeXField('title', 'Literate Programming'),
///   ],
/// );
/// print(entry.key); // 'knuth1984'
/// print(entry['title']); // 'Literate Programming'
/// print(entry.getField('author')?.rawValue); // 'Donald E. Knuth'
/// ```
@immutable
class BibTeXEntry {
  /// Creates a BibTeX entry with [type], citation [key], and [fields].
  const new({required this.type, required this.key, this.fields = const []});

  /// The entry type (e.g. `'article'`, `'inproceedings'`, `'book'`).
  final String type;

  /// The unique citation key used to cite this entry.
  final String key;

  /// The list of [BibTeXField] instances.
  final List<BibTeXField> fields;

  /// Convenience operator for looking up normalized field values by [name].
  String? operator [](String name) => getField(name)?.value;

  /// Returns the raw unnormalized value of the field matching [name],
  /// or `null` if not found.
  String? getRaw(String name) => getField(name)?.rawValue;

  /// Returns whether this entry contains a field matching [name].
  bool containsField(String name) => getField(name) != null;

  /// Finds the [BibTeXField] matching [name], case-insensitively.
  BibTeXField? getField(String name) {
    final lower = name.toLowerCase();
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (field.key == lower) return field;
    }
    return null;
  }

  @override
  String toString() {
    final buffer = StringBuffer('@$type{$key');
    for (final field in fields) {
      buffer.write(',\n\t$field');
    }
    buffer.write('}');
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibTeXEntry &&
          other.type == type &&
          other.key == key &&
          const ListEquality<BibTeXField>().equals(other.fields, fields);

  @override
  int get hashCode => Object.hash(type, key, Object.hashAll(fields));
}

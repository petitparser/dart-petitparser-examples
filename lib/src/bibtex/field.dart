import 'package:meta/meta.dart';

import 'normalize.dart';

/// Models a single field in a BibTeX entry.
///
/// Contains the raw key and raw value as written in the BibTeX source,
/// and lazily computed [key] and [value] with outer
/// delimiters stripped and LaTeX escapes converted.
///
/// For example:
///
/// ```dart
/// final field = BibTeXField('author', '{Donald E. Knuth}');
/// print(field.rawKey); // 'author'
/// print(field.rawValue); // '{Donald E. Knuth}'
/// print(field.key); // 'author'
/// print(field.value); // 'Donald E. Knuth'
/// print(field); // 'author = {Donald E. Knuth}'
/// ```
@immutable
class BibTeXField {
  /// Creates a BibTeX field with [rawKey] and [rawValue].
  new(this.rawKey, this.rawValue);

  /// The raw unnormalized field key as written in the BibTeX source.
  final String rawKey;

  /// The raw unnormalized field value as written in the BibTeX source.
  final String rawValue;

  /// The normalized field key in lowercase.
  late final String key = rawKey.toLowerCase();

  /// The normalized field value with outer delimiters removed and LaTeX escapes decoded.
  late final String value = normalizeFieldValue(rawValue, key: key);

  @override
  String toString() => '$rawKey = $rawValue';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BibTeXField &&
          other.rawKey == rawKey &&
          other.rawValue == rawValue;

  @override
  int get hashCode => Object.hash(rawKey, rawValue);
}

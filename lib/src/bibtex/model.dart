import 'package:meta/meta.dart';

import 'normalize.dart';

/// Models a single BibTeX entry.
@immutable
class BibTeXEntry {
  new({required this.type, required this.key, required this.fields});

  final String type;
  final String key;
  final Map<String, String> fields;

  /// Normalized fields for rendering and lookup.
  late final Map<String, String> normalized = fields.map(
    (key, value) =>
        MapEntry(normalizeFieldName(key), normalizeFieldValue(value)),
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

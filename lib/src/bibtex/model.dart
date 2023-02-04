import 'package:meta/meta.dart';

/// Models a single BibTeX entry.
@immutable
class BibTeXEntry {
  const BibTeXEntry({
    required this.type,
    required this.key,
    required this.fields,
  });

  final String type;
  final String key;
  final Map<String, String> fields;

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

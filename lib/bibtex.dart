/// A simple parser that reads a [BibTeX](https://en.wikipedia.org/wiki/BibTeX)
/// file into a list of BibTeX entries with a list of fields.
///
/// For example:
///
/// ```dart
/// for (final entry in parseEntries(content)) {
///   print(entry.key);
///   print(entry['title']);
/// }
/// ```
library;

export 'src/bibtex/definition.dart';
export 'src/bibtex/entry.dart';
export 'src/bibtex/field.dart';
export 'src/bibtex/normalize.dart';
export 'src/bibtex/parser.dart';

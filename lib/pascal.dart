/// This library contains the grammar and parser of Pascal.
///
/// For example:
///
/// ```dart
/// final parser = PascalParserDefinition().build();
/// final result = parser.parse('program test; begin end.');
/// print(result.value);
/// ```
library;

export 'src/pascal/ast.dart';
export 'src/pascal/parser.dart';

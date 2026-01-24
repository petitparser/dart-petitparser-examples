/// This library contains the grammar of Pascal.
///
/// For example:
///
/// ```dart
/// final parser = PascalGrammarDefinition().build();
/// final result = parser.parse('program test; begin end.');
/// print(result.value);
/// ```
library;

export 'src/pascal/grammar.dart';

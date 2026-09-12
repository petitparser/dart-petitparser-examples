/// This library contains the complete grammar of Smalltalk.
///
/// It was automatically exported from PetitParser for Smalltalk.
///
/// For example:
///
/// ```dart
/// final parser = SmalltalkParserDefinition().build();
/// final result = parser.parse('example ^ 1 + 2');
/// print(result.value);
/// ```
library;

export 'src/smalltalk/ast.dart';
export 'src/smalltalk/parser.dart';
export 'src/smalltalk/visitor.dart';

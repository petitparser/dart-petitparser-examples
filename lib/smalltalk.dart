/// Smalltalk grammar, strongly typed AST models, and visitor traversal.
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

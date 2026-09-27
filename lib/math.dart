/// Mathematical expression parser, AST models, and evaluation engine.
///
/// For example:
///
/// ```dart
/// final result = parser.parse('1 + 2 * 3');
/// final value = result.value.eval({});
/// print(value);  // 7.0
/// ```
library;

export 'src/math/ast.dart';
export 'src/math/common.dart';
export 'src/math/parser.dart';

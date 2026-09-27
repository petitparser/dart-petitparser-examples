/// Dart grammar, strongly typed AST models, and parser based on the
/// [Dart programming language specification](https://raw.githubusercontent.com/dart-lang/language/refs/heads/main/specification/dartLangSpec.tex).
///
/// Supports modern Dart 3.x features including records, patterns, switch expressions,
/// enhanced enums, extension types, class modifiers, and null safety.
///
/// For example:
///
/// ```dart
/// final unit = parseDart('void main() => print("Hello, Dart!");');
/// print(unit.declarations.first);
/// ```
library;

import 'src/dart/ast.dart';
import 'src/dart/grammar.dart';

export 'src/dart/ast.dart';
export 'src/dart/grammar.dart';

final _defaultParser = DartGrammarDefinition().build();

/// Parses the [input] Dart source code into a [CompilationUnitNode].
CompilationUnitNode parseDart(String input) =>
    _defaultParser.parse(input).value;

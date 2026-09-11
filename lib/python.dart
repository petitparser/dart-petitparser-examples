/// This library contains the grammar and AST parser for the Python programming language.
///
/// Supports modern Python 3.12+ features including match/case pattern matching,
/// PEP 695 type parameter syntax, walrus operator, f-strings, exception groups
/// (except*), async/await, and indentation-based suite parsing.
///
/// For example:
///
/// ```dart
/// final module = parsePython('def add(a: int, b: int) -> int:\n    return a + b\n');
/// print(module.body.first);
/// ```
library;

import 'src/python/ast.dart';
import 'src/python/grammar.dart';

export 'src/python/ast.dart';
export 'src/python/grammar.dart';
export 'src/python/indent.dart';

/// Parses the [input] Python source code into a [ModuleNode].
ModuleNode parsePython(String input) =>
    PythonGrammarDefinition().build().parse(input).value;

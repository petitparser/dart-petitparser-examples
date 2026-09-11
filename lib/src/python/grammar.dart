import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'grammar/declarations.dart';
import 'grammar/expressions.dart';
import 'grammar/lexical.dart';
import 'grammar/patterns.dart';
import 'grammar/statements.dart';
import 'indent.dart';

/// Complete grammar and parser definition for the Python programming language (3.12+).
class PythonGrammarDefinition extends GrammarDefinition<ModuleNode>
    with
        PythonLexicalGrammar,
        PythonPatternGrammar,
        PythonExpressionGrammar,
        PythonDeclarationGrammar,
        PythonStatementGrammar {
  @override
  final PythonIndent indent = PythonIndent();

  @override
  Parser<ModuleNode> start() => seq4(
    ref0(blankLines),
    ref0(statements).optional(),
    ref0(blankLines),
    endOfInput(),
  ).map4((_, stmts, _, _) => ModuleNode(body: stmts ?? const []));
}

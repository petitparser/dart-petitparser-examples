import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'grammar/declarations.dart';
import 'grammar/expressions.dart';
import 'grammar/lexical.dart';
import 'grammar/patterns.dart';
import 'grammar/statements.dart';
import 'grammar/types.dart';

/// Complete grammar and parser definition for the Dart programming language.
///
/// Built using modern modular PetitParser mixins and produces typed [DartNode]
/// AST representations.
class DartGrammarDefinition extends GrammarDefinition<CompilationUnitNode>
    with
        DartLexicalGrammar,
        DartTypeGrammar,
        DartPatternGrammar,
        DartExpressionGrammar,
        DartStatementGrammar,
        DartDeclarationGrammar {
  @override
  Parser<CompilationUnitNode> start() => ref0(compilationUnit).end();
}

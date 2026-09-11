import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'grammar/blocks.dart';
import 'grammar/inlines.dart';
import 'grammar/lexical.dart';

/// Complete grammar and parser definition for Markdown.
///
/// Built using modular PetitParser mixins and produces typed [MarkdownNode]
/// AST representations supporting CommonMark 0.31.2 and GFM extensions.
class MarkdownGrammarDefinition extends GrammarDefinition<DocumentNode>
    with MarkdownLexicalGrammar, MarkdownInlineGrammar, MarkdownBlockGrammar {
  /// Default compiled Markdown document parser.
  static final defaultParser = MarkdownGrammarDefinition().build();

  @override
  Parser<DocumentNode> start() => ref0(document).end();
}

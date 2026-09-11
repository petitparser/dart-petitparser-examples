/// This library contains the grammar, AST parser, HTML renderer, and syntax
/// highlighter for Markdown.
///
/// Supports CommonMark 0.31.2 standards with GitHub Flavored Markdown (GFM)
/// extensions (tables, strikethrough, task lists).
///
/// For example:
///
/// ```dart
/// final doc = parseMarkdown('# Hello\n\nThis is **bold** text.');
/// print(doc.blocks.first);
/// final html = markdownToHtml('# Hello\n\nThis is **bold** text.');
/// print(html);
/// final highlighted = highlightMarkdown('# Hello');
/// print(highlighted);
/// ```
library;

import 'src/markdown/ast.dart';
import 'src/markdown/grammar.dart';
import 'src/markdown/highlighter.dart';
import 'src/markdown/html_renderer.dart';

export 'src/markdown/ast.dart';
export 'src/markdown/grammar.dart';
export 'src/markdown/highlighter.dart';
export 'src/markdown/html_renderer.dart';

final _defaultParser = MarkdownGrammarDefinition().build();
const _defaultRenderer = MarkdownHtmlRenderer();
const _defaultHighlighter = MarkdownHighlighter();

/// Parses the [input] Markdown text into a strongly typed [DocumentNode].
DocumentNode parseMarkdown(String input) => _defaultParser.parse(input).value;

/// Parses [input] Markdown and renders it to an HTML string.
String markdownToHtml(String input) {
  final doc = parseMarkdown(input);
  return doc.accept(_defaultRenderer);
}

/// Highlights [input] Markdown source code with HTML syntax spans using PetitParser.
String highlightMarkdown(String input) => _defaultHighlighter.highlight(input);

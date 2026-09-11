import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLTextAreaElement;
final editorHighlight =
    document.querySelector('#editor-highlight') as HTMLElement;
final stats = document.querySelector('#stats') as HTMLElement;

final panelPreview = document.querySelector('#panel-preview') as HTMLElement;
final panelHighlight =
    document.querySelector('#panel-highlight') as HTMLElement;
final panelHtmlSource =
    document.querySelector('#panel-html-source') as HTMLElement;
final panelAst = document.querySelector('#panel-ast') as HTMLElement;

final btnCommonMark =
    document.querySelector('#btn-commonmark') as HTMLButtonElement;
final btnTables = document.querySelector('#btn-tables') as HTMLButtonElement;
final btnCode = document.querySelector('#btn-code') as HTMLButtonElement;
final btnInlines = document.querySelector('#btn-inlines') as HTMLButtonElement;

final parser = MarkdownGrammarDefinition.defaultParser;
const highlighter = MarkdownHighlighter();
const renderer = MarkdownHtmlRenderer();

const presets = {
  'commonmark': '''# CommonMark Showcase

Welcome to the **PetitParser** Markdown demonstration!

> "Markdown is intended to be as easy-to-read and easy-to-write as is feasible."
> — John Gruber

Here are the key features:
- Fast, scannerless combinator parsing
- Strongly typed AST representation
- High-fidelity CommonMark 0.31.2 compliance

Visit [PetitParser on GitHub](https://github.com/petitparser/dart-petitparser) for details.''',
  'tables': '''# GFM Tables and Task Lists

### Feature Comparison Matrix

| Feature | Standard Markdown | GitHub Flavored | PetitParser |
| :--- | :---: | ---: | :---: |
| ATX Headings | Yes | Yes | Yes |
| Blockquotes | Yes | Yes | Yes |
| Tables | No | Yes | Yes |
| Task Lists | No | Yes | Yes |
| Strikethrough | No | Yes | Yes |

### Project Roadmap

- [x] Design strongly typed AST hierarchy
- [x] Implement lexical and inline combinators
- [x] Implement block and table parsers
- [x] Verify with PetitParser grammar reflection linter
- [ ] Deploy interactive web application''',
  'code': '''# Code Blocks & Diagnostics

Fenced code blocks support language metadata strings:

```dart
import 'package:petitparser/petitparser.dart';

void main() {
  final greeting = string('Hello').trim();
  final target = string('World');
  final parser = seq2(greeting, target).map2((g, t) => '\$g, \$t!');

  print(parser.parse('Hello World').value);
}
```

---

Or simple indented code blocks:

    final result = parser.parse('input');
    print(result.value);

Both styles are fully supported.''',
  'inlines': '''# Complex Inline Combinators

Markdown supports rich inline typography:

- Strong emphasis: **bold text** or __bold text__
- Regular emphasis: *italic text* or _italic text_
- Combined nesting: **bold with *italic* inside**
- GFM strikethrough: ~~outdated statement~~
- Code spans: `final x = 42;` and multiple `` `nested backticks` ``
- Autolinks: <https://dart.dev> and <contact@example.com>
- Escaped punctuation: \\*not italic\\*, \\# not heading, \\[not link\\]
- Embedded images: ![Dart Logo](https://dart.dev/assets/img/logo/dart-64.png "Dart")''',
};

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String formatAst(Object? node, [int indent = 0]) {
  final pad = '  ' * indent;
  if (node == null) return '<span class="node-val">null</span>';
  if (node is num || node is bool) {
    return '<span class="node-val">$node</span>';
  }
  if (node is String) {
    return '<span class="node-str">"${_escape(node)}"</span>';
  }
  if (node is List) {
    if (node.isEmpty) return '[]';
    final items = node
        .map((e) {
          final childPad = '  ' * (indent + 1);
          final formatted = formatAst(e, indent + 1);
          return '$childPad$formatted';
        })
        .join(',\n');
    return '[\n$items\n$pad]';
  }
  if (node is MarkdownNode) {
    final typeName = _nodeName(node);
    final props = _nodeProperties(node);
    if (props.isEmpty) {
      return '<span class="node-type">$typeName</span>()';
    }
    final buffer = StringBuffer();
    buffer.write('<span class="node-type">$typeName</span>(\n');
    final propStrings = <String>[];
    for (final (name, value) in props) {
      final childPad = '  ' * (indent + 1);
      final formatted = formatAst(value, indent + 1);
      propStrings.add(
        '$childPad<span class="node-prop">$name:</span> $formatted',
      );
    }
    buffer.write(propStrings.join(',\n'));
    buffer.write('\n$pad)');
    return buffer.toString();
  }
  return _escape(node.toString());
}

String _nodeName(MarkdownNode node) => switch (node) {
  DocumentNode() => 'DocumentNode',
  HeadingNode() => 'HeadingNode',
  ParagraphNode() => 'ParagraphNode',
  BlockquoteNode() => 'BlockquoteNode',
  FencedCodeBlockNode() => 'FencedCodeBlockNode',
  IndentedCodeBlockNode() => 'IndentedCodeBlockNode',
  ThematicBreakNode() => 'ThematicBreakNode',
  BulletListNode() => 'BulletListNode',
  OrderedListNode() => 'OrderedListNode',
  ListItemNode() => 'ListItemNode',
  TableNode() => 'TableNode',
  TableRowNode() => 'TableRowNode',
  TableCellNode() => 'TableCellNode',
  HtmlBlockNode() => 'HtmlBlockNode',
  LinkReferenceDefinitionNode() => 'LinkReferenceDefinitionNode',
  TextNode() => 'TextNode',
  EmphasisNode() => 'EmphasisNode',
  StrongNode() => 'StrongNode',
  StrikethroughNode() => 'StrikethroughNode',
  CodeSpanNode() => 'CodeSpanNode',
  LinkNode() => 'LinkNode',
  ImageNode() => 'ImageNode',
  AutolinkNode() => 'AutolinkNode',
  LineBreakNode() => 'LineBreakNode',
  CompositeInlineNode() => 'CompositeInlineNode',
  RawHtmlInlineNode() => 'RawHtmlInlineNode',
};

List<(String, Object?)> _nodeProperties(MarkdownNode node) => switch (node) {
  final DocumentNode n => [('blocks', n.blocks)],
  final HeadingNode n => [('level', n.level), ('content', n.content)],
  final ParagraphNode n => [('content', n.content)],
  final BlockquoteNode n => [('children', n.children)],
  final FencedCodeBlockNode n => [
    if (n.info != null) ('info', n.info),
    ('code', n.code),
  ],
  final IndentedCodeBlockNode n => [('code', n.code)],
  final ThematicBreakNode _ => const [],
  final BulletListNode n => [('isTight', n.isTight), ('items', n.items)],
  final OrderedListNode n => [
    ('startNumber', n.startNumber),
    ('isTight', n.isTight),
    ('items', n.items),
  ],
  final ListItemNode n => [
    if (n.isTask != null) ('isTask', n.isTask),
    if (n.isChecked != null) ('isChecked', n.isChecked),
    ('children', n.children),
  ],
  final TableNode n => [
    ('alignments', n.alignments.map((a) => a.name).toList()),
    ('rows', n.rows),
  ],
  final TableRowNode n => [('isHeader', n.isHeader), ('cells', n.cells)],
  final TableCellNode n => [('content', n.content)],
  final HtmlBlockNode n => [('rawHtml', n.rawHtml)],
  final LinkReferenceDefinitionNode n => [
    ('label', n.label),
    ('url', n.url),
    if (n.title != null) ('title', n.title),
  ],
  final TextNode n => [('text', n.text)],
  final EmphasisNode n => [('child', n.child)],
  final StrongNode n => [('child', n.child)],
  final StrikethroughNode n => [('child', n.child)],
  final CodeSpanNode n => [('code', n.code)],
  final LinkNode n => [
    ('text', n.text),
    ('url', n.url),
    if (n.title != null) ('title', n.title),
  ],
  final ImageNode n => [
    ('alt', n.alt),
    ('url', n.url),
    if (n.title != null) ('title', n.title),
  ],
  final AutolinkNode n => [('url', n.url), ('isEmail', n.isEmail)],
  final LineBreakNode n => [('isHard', n.isHard)],
  final CompositeInlineNode n => [('children', n.children)],
  final RawHtmlInlineNode n => [('rawHtml', n.rawHtml)],
};

void updateEditorHighlight(String source, [MarkdownNode? astNode]) {
  var highlighted = astNode != null
      ? highlighter.highlightAst(astNode, source)
      : highlighter.highlight(source);
  if (source.endsWith('\n')) {
    highlighted += ' ';
  }
  editorHighlight.innerHTML = highlighted.toJS;
}

void parseAndRender() {
  final source = input.value;

  final watch = Stopwatch()..start();
  final result = parser.parse(source);
  final parseTime = watch.elapsedMicroseconds;

  if (result is Failure) {
    updateEditorHighlight(source);
    stats.innerHTML = 'Parse failed in <span>$parseTimeμs</span>'.toJS;
    final errorHtml =
        '<div class="error">ParserException: ${result.message}\nat line ${result.toPositionString()}</div>';
    panelPreview.innerHTML = errorHtml.toJS;
    panelHighlight.innerHTML = highlighter.highlight(source).toJS;
    panelHtmlSource.innerHTML = errorHtml.toJS;
    panelAst.innerHTML = errorHtml.toJS;
    return;
  }

  final astNode = result.value;
  updateEditorHighlight(source, astNode);

  watch.reset();
  final renderedHtml = astNode.accept(renderer);
  final renderTime = watch.elapsedMicroseconds;

  stats.innerHTML =
      'Parsed in <span>$parseTimeμs</span>, Rendered in <span>$renderTimeμs</span> (Input: <span>${source.length}</span> chars)'
          .toJS;

  // 1. Rendered HTML preview
  panelPreview.innerHTML = renderedHtml.toJS;

  // 2. Syntax highlighted markdown view
  panelHighlight.innerHTML = highlighter.highlightAst(astNode, source).toJS;

  // 3. Raw HTML source
  panelHtmlSource.innerText = renderedHtml;

  // 4. Abstract Syntax Tree
  panelAst.innerHTML = formatAst(astNode).toJS;
}

void setupTabs() {
  final tabButtons = document.querySelectorAll('.tab-btn');
  final panels = document.querySelectorAll('.output-panel');

  for (var i = 0; i < tabButtons.length; i++) {
    final btn = tabButtons.item(i) as HTMLButtonElement;
    btn.onClick.listen((_) {
      for (var j = 0; j < tabButtons.length; j++) {
        (tabButtons.item(j) as HTMLElement).classList.remove('active');
      }
      for (var j = 0; j < panels.length; j++) {
        (panels.item(j) as HTMLElement).classList.remove('active');
      }

      btn.classList.add('active');
      final tabId = btn.getAttribute('data-tab');
      final targetPanel =
          document.querySelector('#panel-$tabId') as HTMLElement?;
      targetPanel?.classList.add('active');
    });
  }
}

void loadPreset(String key) {
  input.value = presets[key] ?? '';
  parseAndRender();
}

void main() {
  setupTabs();

  // Synchronize scroll between transparent textarea and overlay highlight layer
  input.onScroll.listen((_) {
    editorHighlight.scrollTop = input.scrollTop;
    editorHighlight.scrollLeft = input.scrollLeft;
  });

  btnCommonMark.onClick.listen((_) => loadPreset('commonmark'));
  btnTables.onClick.listen((_) => loadPreset('tables'));
  btnCode.onClick.listen((_) => loadPreset('code'));
  btnInlines.onClick.listen((_) => loadPreset('inlines'));

  input.onInput.listen((_) => parseAndRender());

  // Default preset
  loadPreset('commonmark');
}

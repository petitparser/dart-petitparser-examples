import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'grammar.dart';

/// Represents a highlighted text range with an associated CSS class.
class HighlightSpan implements Comparable<HighlightSpan> {
  const new(this.start, this.stop, this.cssClass);

  /// Start offset in source code.
  final int start;

  /// Stop offset in source code.
  final int stop;

  /// CSS class for syntax coloring.
  final String cssClass;

  @override
  int compareTo(HighlightSpan other) {
    final cmp = start.compareTo(other.start);
    if (cmp != 0) return cmp;
    return stop.compareTo(other.stop);
  }

  @override
  String toString() => 'HighlightSpan($start, $stop, $cssClass)';
}

/// A syntax highlighter for Markdown source code that uses AST position tokens.
///
/// Traverses the [MarkdownNode] AST produced by [MarkdownGrammarDefinition] to
/// extract highlight spans without any regular expressions or duplicate grammars.
class MarkdownHighlighter {
  /// Creates a new [MarkdownHighlighter] instance.
  const new();

  /// Highlights [source] Markdown into HTML with syntax spans.
  ///
  /// Uses [MarkdownGrammarDefinition.defaultParser] to parse the AST and extracts
  /// start/stop positions from the nodes. If parsing fails, returns HTML-escaped [source].
  String highlight(String source) {
    if (source.isEmpty) return '';
    final result = MarkdownGrammarDefinition.defaultParser.parse(source);
    if (result is Success<DocumentNode>) {
      return highlightAst(result.value, source);
    }
    return _escape(source);
  }

  /// Highlights [source] using the already parsed [node] AST.
  String highlightAst(MarkdownNode node, String source) {
    if (source.isEmpty) return '';
    final collector = _SpanCollector(source);
    node.accept(collector);
    return _renderSpans(source, collector.spans);
  }

  static String _escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  static String _renderSpans(String source, List<HighlightSpan> rawSpans) {
    if (rawSpans.isEmpty) return _escape(source);

    // Filter valid spans within range and deduplicate
    final spans = <HighlightSpan>[];
    for (final s in rawSpans) {
      if (s.start >= 0 && s.stop <= source.length && s.start < s.stop) {
        spans.add(s);
      }
    }
    spans.sort();

    final buffer = StringBuffer();
    var currentIndex = 0;

    for (var i = 0; i < spans.length; i++) {
      final span = spans[i];

      // If span starts after current index, output intervening unhighlighted text
      if (span.start > currentIndex) {
        buffer.write(_escape(source.substring(currentIndex, span.start)));
        currentIndex = span.start;
      }

      // If span start is before current index (nested/overlapping span), skip or clamp
      if (span.start < currentIndex) {
        if (span.stop <= currentIndex) {
          continue;
        }
        // Clamped child span
        final text = source.substring(currentIndex, span.stop);
        buffer.write('<span class="${span.cssClass}">${_escape(text)}</span>');
        currentIndex = span.stop;
        continue;
      }

      // Check for nested spans within this span
      final innerSpans = <HighlightSpan>[];
      var nextIndex = i + 1;
      while (nextIndex < spans.length && spans[nextIndex].stop <= span.stop) {
        innerSpans.add(spans[nextIndex]);
        nextIndex++;
      }

      if (innerSpans.isEmpty) {
        final text = source.substring(span.start, span.stop);
        buffer.write('<span class="${span.cssClass}">${_escape(text)}</span>');
        currentIndex = span.stop;
      } else {
        // Render parent opening tag, inner spans, and closing tag
        buffer.write('<span class="${span.cssClass}">');
        var innerCurrent = span.start;
        for (final inner in innerSpans) {
          if (inner.start > innerCurrent) {
            buffer.write(_escape(source.substring(innerCurrent, inner.start)));
            innerCurrent = inner.start;
          }
          if (inner.start >= innerCurrent && inner.stop <= span.stop) {
            final innerText = source.substring(inner.start, inner.stop);
            buffer.write(
              '<span class="${inner.cssClass}">${_escape(innerText)}</span>',
            );
            innerCurrent = inner.stop;
          }
        }
        if (innerCurrent < span.stop) {
          buffer.write(_escape(source.substring(innerCurrent, span.stop)));
        }
        buffer.write('</span>');
        currentIndex = span.stop;
        i = nextIndex - 1; // Advance past processed inner spans
      }
    }

    if (currentIndex < source.length) {
      buffer.write(_escape(source.substring(currentIndex)));
    }

    return buffer.toString();
  }
}

class _SpanCollector implements MarkdownVisitor<void> {
  new(this.source);

  final String source;
  final List<HighlightSpan> spans = [];

  @override
  void visitDocument(DocumentNode node) {
    for (final block in node.blocks) {
      block.accept(this);
    }
  }

  @override
  void visitHeading(HeadingNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      // Find hashes prefix
      var hashEnd = start;
      while (hashEnd < stop &&
          (source[hashEnd] == '#' ||
              source[hashEnd] == ' ' ||
              source[hashEnd] == '\t')) {
        hashEnd++;
      }
      if (hashEnd > start) {
        spans.add(HighlightSpan(start, hashEnd, 'hl-punct'));
      }
      // Content span
      final contentStart = node.content.start ?? hashEnd;
      var contentStop = node.content.stop ?? stop;
      while (contentStop > contentStart &&
          (source[contentStop - 1] == '\n' ||
              source[contentStop - 1] == '\r' ||
              source[contentStop - 1] == ' ' ||
              source[contentStop - 1] == '\t' ||
              source[contentStop - 1] == '#')) {
        contentStop--;
      }
      if (contentStart < contentStop) {
        spans.add(HighlightSpan(contentStart, contentStop, 'hl-heading'));
      }
    }
    node.content.accept(this);
  }

  @override
  void visitParagraph(ParagraphNode node) {
    node.content.accept(this);
  }

  @override
  void visitBlockquote(BlockquoteNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      // Mark leading '>' on lines as hl-blockquote
      var lineStart = start;
      while (lineStart < stop) {
        var nextNewline = source.indexOf('\n', lineStart);
        if (nextNewline == -1 || nextNewline > stop) {
          nextNewline = stop;
        }
        // Find '>' on this line
        var markerIdx = lineStart;
        while (markerIdx < nextNewline &&
            (source[markerIdx] == ' ' || source[markerIdx] == '\t')) {
          markerIdx++;
        }
        if (markerIdx < nextNewline && source[markerIdx] == '>') {
          var markerEnd = markerIdx + 1;
          if (markerEnd < nextNewline && source[markerEnd] == ' ') {
            markerEnd++;
          }
          spans.add(HighlightSpan(markerIdx, markerEnd, 'hl-blockquote'));
        }
        lineStart = nextNewline + 1;
      }
    }
    for (final child in node.children) {
      child.accept(this);
    }
  }

  @override
  void visitFencedCodeBlock(FencedCodeBlockNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      // Opening fence: ``` or ~~~
      var fenceEnd = start;
      while (fenceEnd < stop &&
          (source[fenceEnd] == '`' || source[fenceEnd] == '~')) {
        fenceEnd++;
      }
      if (fenceEnd > start) {
        spans.add(HighlightSpan(start, fenceEnd, 'hl-punct'));
      }
      // Info string
      if (node.info != null && node.info!.isNotEmpty) {
        final infoStart = source.indexOf(node.info!, fenceEnd);
        if (infoStart != -1 && infoStart < stop) {
          spans.add(
            HighlightSpan(infoStart, infoStart + node.info!.length, 'hl-info'),
          );
        }
      }
      // Code content
      if (node.code.isNotEmpty) {
        final codeStart = source.indexOf(node.code, fenceEnd);
        if (codeStart != -1 && codeStart < stop) {
          spans.add(
            HighlightSpan(codeStart, codeStart + node.code.length, 'hl-code'),
          );
        }
      }
      // Closing fence
      var closeStart = stop - 1;
      while (closeStart > start &&
          (source[closeStart] == '\n' ||
              source[closeStart] == '\r' ||
              source[closeStart] == ' ' ||
              source[closeStart] == '\t')) {
        closeStart--;
      }
      var closeFenceStart = closeStart;
      while (closeFenceStart >= start &&
          (source[closeFenceStart] == '`' || source[closeFenceStart] == '~')) {
        closeFenceStart--;
      }
      closeFenceStart++;
      if (closeFenceStart <= closeStart) {
        spans.add(HighlightSpan(closeFenceStart, closeStart + 1, 'hl-punct'));
      }
    }
  }

  @override
  void visitIndentedCodeBlock(IndentedCodeBlockNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-code'));
    }
  }

  @override
  void visitThematicBreak(ThematicBreakNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-punct'));
    }
  }

  @override
  void visitBulletList(BulletListNode node) {
    for (final item in node.items) {
      item.accept(this);
    }
  }

  @override
  void visitOrderedList(OrderedListNode node) {
    for (final item in node.items) {
      item.accept(this);
    }
  }

  @override
  void visitListItem(ListItemNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      // Find list marker
      var mStart = start;
      while (mStart < stop &&
          (source[mStart] == ' ' || source[mStart] == '\t')) {
        mStart++;
      }
      var mEnd = mStart;
      while (mEnd < stop &&
          source[mEnd] != ' ' &&
          source[mEnd] != '\t' &&
          source[mEnd] != '\n') {
        mEnd++;
      }
      if (mEnd < stop && (source[mEnd] == ' ' || source[mEnd] == '\t')) {
        mEnd++;
      }
      if (mEnd > mStart) {
        spans.add(HighlightSpan(mStart, mEnd, 'hl-list'));
      }

      // Check for task checkbox [x] or [ ]
      if (node.isTask == true) {
        var boxStart = mEnd;
        while (boxStart < stop &&
            (source[boxStart] == ' ' || source[boxStart] == '\t')) {
          boxStart++;
        }
        if (boxStart + 3 <= stop && source[boxStart] == '[') {
          spans.add(HighlightSpan(boxStart, boxStart + 3, 'hl-task'));
        }
      }
    }
    for (final child in node.children) {
      child.accept(this);
    }
  }

  @override
  void visitTable(TableNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      // Highlight pipes '|' across table rows
      for (var i = start; i < stop; i++) {
        if (source[i] == '|') {
          spans.add(HighlightSpan(i, i + 1, 'hl-table'));
        }
      }
    }
    for (final row in node.rows) {
      row.accept(this);
    }
  }

  @override
  void visitTableRow(TableRowNode node) {
    for (final cell in node.cells) {
      cell.accept(this);
    }
  }

  @override
  void visitTableCell(TableCellNode node) {
    node.content.accept(this);
  }

  @override
  void visitHtmlBlock(HtmlBlockNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-code'));
    }
  }

  @override
  void visitLinkReferenceDefinition(LinkReferenceDefinitionNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-link'));
    }
  }

  @override
  void visitText(TextNode node) {}

  @override
  void visitEmphasis(EmphasisNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-italic'));
    }
    node.child.accept(this);
  }

  @override
  void visitStrong(StrongNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-bold'));
    }
    node.child.accept(this);
  }

  @override
  void visitStrikethrough(StrikethroughNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-strike'));
    }
    node.child.accept(this);
  }

  @override
  void visitCodeSpan(CodeSpanNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-code'));
    }
  }

  @override
  void visitLink(LinkNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      final textStart = node.text.start ?? start + 1;
      final textStop = node.text.stop ?? textStart;
      if (textStart > start) {
        spans.add(HighlightSpan(start, textStart, 'hl-punct'));
      }
      spans.add(HighlightSpan(textStart, textStop, 'hl-link'));

      final destStart = source.indexOf(node.url, textStop);
      if (destStart != -1 && destStart < stop) {
        spans.add(HighlightSpan(textStop, destStart, 'hl-punct'));
        spans.add(
          HighlightSpan(destStart, destStart + node.url.length, 'hl-url'),
        );
        spans.add(HighlightSpan(destStart + node.url.length, stop, 'hl-punct'));
      }
    }
    node.text.accept(this);
  }

  @override
  void visitImage(ImageNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      final textStart = node.alt.start ?? start + 2;
      final textStop = node.alt.stop ?? textStart;
      if (textStart > start) {
        spans.add(HighlightSpan(start, textStart, 'hl-punct'));
      }
      spans.add(HighlightSpan(textStart, textStop, 'hl-link'));

      final destStart = source.indexOf(node.url, textStop);
      if (destStart != -1 && destStart < stop) {
        spans.add(HighlightSpan(textStop, destStart, 'hl-punct'));
        spans.add(
          HighlightSpan(destStart, destStart + node.url.length, 'hl-url'),
        );
        spans.add(HighlightSpan(destStart + node.url.length, stop, 'hl-punct'));
      }
    }
    node.alt.accept(this);
  }

  @override
  void visitAutolink(AutolinkNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-link'));
    }
  }

  @override
  void visitLineBreak(LineBreakNode node) {}

  @override
  void visitCompositeInline(CompositeInlineNode node) {
    for (final child in node.children) {
      child.accept(this);
    }
  }

  @override
  void visitRawHtmlInline(RawHtmlInlineNode node) {
    final start = node.start;
    final stop = node.stop;
    if (start != null && stop != null && start < stop) {
      spans.add(HighlightSpan(start, stop, 'hl-code'));
    }
  }
}

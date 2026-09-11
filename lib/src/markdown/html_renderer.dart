import 'ast.dart';

/// Renders a [MarkdownNode] tree into an HTML string.
class MarkdownHtmlRenderer implements MarkdownVisitor<String> {
  const new();

  /// Escapes special HTML characters (`&`, `<`, `>`, `"`).
  static String escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;');

  /// Extracts unformatted plain text from an [InlineNode] (e.g. for img alt attributes).
  static String plainText(InlineNode node) => switch (node) {
    TextNode(:final text) => text,
    CodeSpanNode(:final code) => code,
    EmphasisNode(:final child) => plainText(child),
    StrongNode(:final child) => plainText(child),
    StrikethroughNode(:final child) => plainText(child),
    LinkNode(:final text) => plainText(text),
    ImageNode(:final alt) => plainText(alt),
    AutolinkNode(:final url) => url,
    LineBreakNode() => ' ',
    CompositeInlineNode(:final children) => children.map(plainText).join(),
    RawHtmlInlineNode() => '',
  };

  @override
  String visitDocument(DocumentNode node) => node.blocks
      .map((b) => b.accept(this))
      .where((s) => s.isNotEmpty)
      .join('\n');

  @override
  String visitHeading(HeadingNode node) {
    final body = node.content.accept(this);
    return '<h${node.level}>$body</h${node.level}>';
  }

  @override
  String visitParagraph(ParagraphNode node) {
    final body = node.content.accept(this);
    return '<p>$body</p>';
  }

  @override
  String visitBlockquote(BlockquoteNode node) {
    final inner = node.children
        .map((b) => b.accept(this))
        .where((s) => s.isNotEmpty)
        .join('\n');
    return '<blockquote>\n$inner\n</blockquote>';
  }

  @override
  String visitFencedCodeBlock(FencedCodeBlockNode node) {
    final escapedCode = escape(node.code);
    final info = node.info?.trim();
    if (info != null && info.isNotEmpty) {
      final language = escape(info.split(RegExp(r'\s+')).first);
      return '<pre><code class="language-$language">$escapedCode</code></pre>';
    }
    return '<pre><code>$escapedCode</code></pre>';
  }

  @override
  String visitIndentedCodeBlock(IndentedCodeBlockNode node) {
    final escapedCode = escape(node.code);
    return '<pre><code>$escapedCode</code></pre>';
  }

  @override
  String visitThematicBreak(ThematicBreakNode node) => '<hr />';

  @override
  String visitBulletList(BulletListNode node) {
    final items = node.items
        .map((item) => _renderListItem(item, node.isTight))
        .join('\n');
    return '<ul>\n$items\n</ul>';
  }

  @override
  String visitOrderedList(OrderedListNode node) {
    final items = node.items
        .map((item) => _renderListItem(item, node.isTight))
        .join('\n');
    final startAttr = node.startNumber != 1
        ? ' start="${node.startNumber}"'
        : '';
    return '<ol$startAttr>\n$items\n</ol>';
  }

  String _renderListItem(ListItemNode item, bool isTight) {
    final prefix = switch (item.isTask) {
      true =>
        item.isChecked == true
            ? '<input type="checkbox" checked="" disabled="" /> '
            : '<input type="checkbox" disabled="" /> ',
      _ => '',
    };

    if (item.children.isEmpty) {
      return '<li>$prefix</li>';
    }

    if (isTight) {
      // In tight lists, paragraphs are rendered without <p> wrapper
      final buffer = StringBuffer('<li>$prefix');
      for (var i = 0; i < item.children.length; i++) {
        final child = item.children[i];
        if (child is ParagraphNode) {
          buffer.write(child.content.accept(this));
        } else {
          buffer.write(child.accept(this));
        }
      }
      buffer.write('</li>');
      return buffer.toString();
    }

    final inner = item.children.map((b) => b.accept(this)).join('\n');
    return '<li>$prefix$inner</li>';
  }

  @override
  String visitListItem(ListItemNode node) => _renderListItem(node, true);

  @override
  String visitTable(TableNode node) {
    if (node.rows.isEmpty) return '<table></table>';

    final buffer = StringBuffer('<table>\n');
    final alignments = node.alignments;

    final headerRow = node.rows.first;
    buffer.write('<thead>\n<tr>\n');
    for (var i = 0; i < headerRow.cells.length; i++) {
      final cell = headerRow.cells[i];
      final alignAttr = _alignAttribute(
        i < alignments.length ? alignments[i] : TableAlignment.none,
      );
      buffer.write('  <th$alignAttr>${cell.content.accept(this)}</th>\n');
    }
    buffer.write('</tr>\n</thead>\n');

    if (node.rows.length > 1) {
      buffer.write('<tbody>\n');
      for (var r = 1; r < node.rows.length; r++) {
        final row = node.rows[r];
        buffer.write('<tr>\n');
        for (var c = 0; c < row.cells.length; c++) {
          final cell = row.cells[c];
          final alignAttr = _alignAttribute(
            c < alignments.length ? alignments[c] : TableAlignment.none,
          );
          buffer.write('  <td$alignAttr>${cell.content.accept(this)}</td>\n');
        }
        buffer.write('</tr>\n');
      }
      buffer.write('</tbody>\n');
    }

    buffer.write('</table>');
    return buffer.toString();
  }

  String _alignAttribute(TableAlignment alignment) => switch (alignment) {
    TableAlignment.left => ' align="left"',
    TableAlignment.center => ' align="center"',
    TableAlignment.right => ' align="right"',
    TableAlignment.none => '',
  };

  @override
  String visitTableRow(TableRowNode node) {
    final tag = node.isHeader ? 'th' : 'td';
    final cells = node.cells
        .map((c) => '<$tag>${c.content.accept(this)}</$tag>')
        .join();
    return '<tr>$cells</tr>';
  }

  @override
  String visitTableCell(TableCellNode node) => node.content.accept(this);

  @override
  String visitHtmlBlock(HtmlBlockNode node) => node.rawHtml;

  @override
  String visitLinkReferenceDefinition(LinkReferenceDefinitionNode node) => '';

  @override
  String visitText(TextNode node) => escape(node.text);

  @override
  String visitEmphasis(EmphasisNode node) =>
      '<em>${node.child.accept(this)}</em>';

  @override
  String visitStrong(StrongNode node) =>
      '<strong>${node.child.accept(this)}</strong>';

  @override
  String visitStrikethrough(StrikethroughNode node) =>
      '<del>${node.child.accept(this)}</del>';

  @override
  String visitCodeSpan(CodeSpanNode node) =>
      '<code>${escape(node.code)}</code>';

  @override
  String visitLink(LinkNode node) {
    final text = node.text.accept(this);
    final href = escape(node.url);
    final titleAttr = node.title != null
        ? ' title="${escape(node.title!)}"'
        : '';
    return '<a href="$href"$titleAttr>$text</a>';
  }

  @override
  String visitImage(ImageNode node) {
    final alt = escape(plainText(node.alt));
    final src = escape(node.url);
    final titleAttr = node.title != null
        ? ' title="${escape(node.title!)}"'
        : '';
    return '<img src="$src" alt="$alt"$titleAttr />';
  }

  @override
  String visitAutolink(AutolinkNode node) {
    final escapedUrl = escape(node.url);
    final href = node.isEmail ? 'mailto:$escapedUrl' : escapedUrl;
    return '<a href="$href">$escapedUrl</a>';
  }

  @override
  String visitLineBreak(LineBreakNode node) => node.isHard ? '<br />\n' : '\n';

  @override
  String visitCompositeInline(CompositeInlineNode node) =>
      node.children.map((c) => c.accept(this)).join();

  @override
  String visitRawHtmlInline(RawHtmlInlineNode node) => node.rawHtml;
}

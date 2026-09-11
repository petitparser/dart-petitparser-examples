import 'package:collection/collection.dart';

/// Base class for all Abstract Syntax Tree (AST) nodes in Markdown.
sealed class MarkdownNode {
  const new({this.start, this.stop});

  /// The character offset where this node starts in the source, if tracked.
  final int? start;

  /// The character offset where this node stops in the source, if tracked.
  final int? stop;

  /// Dispatches to [visitor] based on concrete node type.
  R accept<R>(MarkdownVisitor<R> visitor);
}

/// The root node of a Markdown document containing top-level [blocks].
class DocumentNode extends MarkdownNode {
  const new(this.blocks, {super.start, super.stop});

  /// The list of block-level elements in this document.
  final List<BlockNode> blocks;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitDocument(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentNode &&
          const ListEquality<BlockNode>().equals(blocks, other.blocks);

  @override
  int get hashCode => const ListEquality<BlockNode>().hash(blocks);

  @override
  String toString() => 'DocumentNode($blocks)';
}

/// Base class for all block-level Markdown elements.
sealed class BlockNode extends MarkdownNode {
  const new({super.start, super.stop});
}

/// An ATX or Setext heading with a [level] (1-6) and [content].
class HeadingNode extends BlockNode {
  const new(this.level, this.content, {super.start, super.stop});

  /// The heading depth, from 1 (`#`) to 6 (`######`).
  final int level;

  /// The inline content inside this heading.
  final InlineNode content;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitHeading(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeadingNode && level == other.level && content == other.content;

  @override
  int get hashCode => Object.hash(level, content);

  @override
  String toString() => 'HeadingNode(level: $level, content: $content)';
}

/// A standard text paragraph block containing inline [content].
class ParagraphNode extends BlockNode {
  const new(this.content, {super.start, super.stop});

  /// The inline content inside this paragraph.
  final InlineNode content;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitParagraph(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParagraphNode && content == other.content;

  @override
  int get hashCode => content.hashCode;

  @override
  String toString() => 'ParagraphNode($content)';
}

/// A blockquote (`>`) containing nested block-level [children].
class BlockquoteNode extends BlockNode {
  const new(this.children, {super.start, super.stop});

  /// The nested block nodes inside this blockquote.
  final List<BlockNode> children;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitBlockquote(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockquoteNode &&
          const ListEquality<BlockNode>().equals(children, other.children);

  @override
  int get hashCode => const ListEquality<BlockNode>().hash(children);

  @override
  String toString() => 'BlockquoteNode($children)';
}

/// A code block delimited by fences (``` or ~~~), with optional language [info].
class FencedCodeBlockNode extends BlockNode {
  const new(this.code, {this.info, super.start, super.stop});

  /// The raw code contents.
  final String code;

  /// Optional language or metadata info string.
  final String? info;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitFencedCodeBlock(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FencedCodeBlockNode && code == other.code && info == other.info;

  @override
  int get hashCode => Object.hash(code, info);

  @override
  String toString() => 'FencedCodeBlockNode(info: $info, code: $code)';
}

/// A code block indented by 4 spaces or 1 tab.
class IndentedCodeBlockNode extends BlockNode {
  const new(this.code, {super.start, super.stop});

  /// The raw code contents.
  final String code;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) =>
      visitor.visitIndentedCodeBlock(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IndentedCodeBlockNode && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'IndentedCodeBlockNode($code)';
}

/// A horizontal rule / thematic break (`---`, `***`, `___`).
class ThematicBreakNode extends BlockNode {
  const new({super.start, super.stop});

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitThematicBreak(this);

  @override
  bool operator ==(Object other) => other is ThematicBreakNode;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'ThematicBreakNode()';
}

/// An unordered bullet list (`-`, `*`, `+`).
class BulletListNode extends BlockNode {
  const new(this.items, {this.isTight = true, super.start, super.stop});

  /// The list items.
  final List<ListItemNode> items;

  /// Whether spacing between items is tight (no `<p>` tags).
  final bool isTight;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitBulletList(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BulletListNode &&
          isTight == other.isTight &&
          const ListEquality<ListItemNode>().equals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(isTight, const ListEquality<ListItemNode>().hash(items));

  @override
  String toString() => 'BulletListNode(isTight: $isTight, items: $items)';
}

/// An ordered enumerated list (`1.`, `2.`).
class OrderedListNode extends BlockNode {
  const new(
    this.items, {
    this.startNumber = 1,
    this.isTight = true,
    super.start,
    super.stop,
  });

  /// The list items.
  final List<ListItemNode> items;

  /// The starting integer number.
  final int startNumber;

  /// Whether spacing between items is tight.
  final bool isTight;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitOrderedList(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderedListNode &&
          startNumber == other.startNumber &&
          isTight == other.isTight &&
          const ListEquality<ListItemNode>().equals(items, other.items);

  @override
  int get hashCode => Object.hash(
    startNumber,
    isTight,
    const ListEquality<ListItemNode>().hash(items),
  );

  @override
  String toString() =>
      'OrderedListNode(start: $startNumber, isTight: $isTight, items: $items)';
}

/// An individual item inside an ordered or bullet list.
class ListItemNode extends BlockNode {
  const new(
    this.children, {
    this.isTask,
    this.isChecked,
    super.start,
    super.stop,
  });

  /// The block-level contents of this list item.
  final List<BlockNode> children;

  /// Whether this item is a GFM task list checkbox item.
  final bool? isTask;

  /// If this is a task item, whether it is checked (`[x]`).
  final bool? isChecked;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitListItem(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListItemNode &&
          isTask == other.isTask &&
          isChecked == other.isChecked &&
          const ListEquality<BlockNode>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    isTask,
    isChecked,
    const ListEquality<BlockNode>().hash(children),
  );

  @override
  String toString() =>
      'ListItemNode(task: $isTask, checked: $isChecked, children: $children)';
}

/// Column text alignment in a Markdown table.
enum TableAlignment { none, left, center, right }

/// A GFM table with rows and column alignments.
class TableNode extends BlockNode {
  const new(this.rows, this.alignments, {super.start, super.stop});

  /// All rows in the table, where the first row is typically the header.
  final List<TableRowNode> rows;

  /// The column alignments.
  final List<TableAlignment> alignments;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitTable(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableNode &&
          const ListEquality<TableRowNode>().equals(rows, other.rows) &&
          const ListEquality<TableAlignment>().equals(
            alignments,
            other.alignments,
          );

  @override
  int get hashCode => Object.hash(
    const ListEquality<TableRowNode>().hash(rows),
    const ListEquality<TableAlignment>().hash(alignments),
  );

  @override
  String toString() => 'TableNode(rows: $rows, alignments: $alignments)';
}

/// A row inside a [TableNode].
class TableRowNode extends BlockNode {
  const new(this.cells, {this.isHeader = false, super.start, super.stop});

  /// The cells in this row.
  final List<TableCellNode> cells;

  /// Whether this row represents the header row (`<th>`).
  final bool isHeader;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitTableRow(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableRowNode &&
          isHeader == other.isHeader &&
          const ListEquality<TableCellNode>().equals(cells, other.cells);

  @override
  int get hashCode =>
      Object.hash(isHeader, const ListEquality<TableCellNode>().hash(cells));

  @override
  String toString() => 'TableRowNode(isHeader: $isHeader, cells: $cells)';
}

/// An individual cell inside a [TableRowNode].
class TableCellNode extends BlockNode {
  const new(this.content, {super.start, super.stop});

  /// The inline content inside this cell.
  final InlineNode content;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitTableCell(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableCellNode && content == other.content;

  @override
  int get hashCode => content.hashCode;

  @override
  String toString() => 'TableCellNode($content)';
}

/// Raw block-level HTML.
class HtmlBlockNode extends BlockNode {
  const new(this.rawHtml, {super.start, super.stop});

  /// The raw HTML string.
  final String rawHtml;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitHtmlBlock(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HtmlBlockNode && rawHtml == other.rawHtml;

  @override
  int get hashCode => rawHtml.hashCode;

  @override
  String toString() => 'HtmlBlockNode($rawHtml)';
}

/// A link reference definition block (`[label]: url "title"`).
class LinkReferenceDefinitionNode extends BlockNode {
  const new(this.label, this.url, {this.title, super.start, super.stop});

  /// The reference label case-folded for matching.
  final String label;

  /// The target destination URL.
  final String url;

  /// Optional link title.
  final String? title;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) =>
      visitor.visitLinkReferenceDefinition(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkReferenceDefinitionNode &&
          label == other.label &&
          url == other.url &&
          title == other.title;

  @override
  int get hashCode => Object.hash(label, url, title);

  @override
  String toString() =>
      'LinkReferenceDefinitionNode(label: $label, url: $url, title: $title)';
}

/// Base class for all inline Markdown elements.
sealed class InlineNode extends MarkdownNode {
  const new({super.start, super.stop});
}

/// Plain literal text.
class TextNode extends InlineNode {
  const new(this.text, {super.start, super.stop});

  /// The text content.
  final String text;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitText(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TextNode && text == other.text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'TextNode("$text")';
}

/// Emphasis (`*text*` or `_text_`).
class EmphasisNode extends InlineNode {
  const new(this.child, {super.start, super.stop});

  /// The emphasized content.
  final InlineNode child;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitEmphasis(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EmphasisNode && child == other.child;

  @override
  int get hashCode => child.hashCode;

  @override
  String toString() => 'EmphasisNode($child)';
}

/// Strong emphasis (`**text**` or `__text__`).
class StrongNode extends InlineNode {
  const new(this.child, {super.start, super.stop});

  /// The strongly emphasized content.
  final InlineNode child;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitStrong(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StrongNode && child == other.child;

  @override
  int get hashCode => child.hashCode;

  @override
  String toString() => 'StrongNode($child)';
}

/// GFM strikethrough (`~~text~~`).
class StrikethroughNode extends InlineNode {
  const new(this.child, {super.start, super.stop});

  /// The struck-through content.
  final InlineNode child;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitStrikethrough(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrikethroughNode && child == other.child;

  @override
  int get hashCode => child.hashCode;

  @override
  String toString() => 'StrikethroughNode($child)';
}

/// Inline code span (`` `code` ``).
class CodeSpanNode extends InlineNode {
  const new(this.code, {super.start, super.stop});

  /// The literal code text inside the span.
  final String code;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitCodeSpan(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CodeSpanNode && code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => 'CodeSpanNode("$code")';
}

/// A hyperlink (`[text](url "title")`).
class LinkNode extends InlineNode {
  const new(this.text, this.url, {this.title, super.start, super.stop});

  /// The link text or nested inline nodes.
  final InlineNode text;

  /// The destination URL.
  final String url;

  /// Optional link title.
  final String? title;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitLink(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinkNode &&
          text == other.text &&
          url == other.url &&
          title == other.title;

  @override
  int get hashCode => Object.hash(text, url, title);

  @override
  String toString() => 'LinkNode(text: $text, url: $url, title: $title)';
}

/// An embedded image (`![alt](url "title")`).
class ImageNode extends InlineNode {
  const new(this.alt, this.url, {this.title, super.start, super.stop});

  /// The image alt text or nested inline nodes.
  final InlineNode alt;

  /// The image source URL.
  final String url;

  /// Optional image title.
  final String? title;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitImage(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageNode &&
          alt == other.alt &&
          url == other.url &&
          title == other.title;

  @override
  int get hashCode => Object.hash(alt, url, title);

  @override
  String toString() => 'ImageNode(alt: $alt, url: $url, title: $title)';
}

/// An automatic link (`<https://example.com>` or `<user@domain.com>`).
class AutolinkNode extends InlineNode {
  const new(this.url, {this.isEmail = false, super.start, super.stop});

  /// The linked URL or email address.
  final String url;

  /// Whether this is an email address autolink.
  final bool isEmail;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitAutolink(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AutolinkNode && url == other.url && isEmail == other.isEmail;

  @override
  int get hashCode => Object.hash(url, isEmail);

  @override
  String toString() => 'AutolinkNode(url: $url, isEmail: $isEmail)';
}

/// A line break, either a hard break (`<br />`) or soft break (`\n`).
class LineBreakNode extends InlineNode {
  const new({this.isHard = false, super.start, super.stop});

  /// Whether this is a hard line break (created with 2 trailing spaces or `\`).
  final bool isHard;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitLineBreak(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineBreakNode && isHard == other.isHard;

  @override
  int get hashCode => isHard.hashCode;

  @override
  String toString() => 'LineBreakNode(isHard: $isHard)';
}

/// A composite sequence of consecutive [children] inline nodes.
class CompositeInlineNode extends InlineNode {
  const new(this.children, {super.start, super.stop});

  /// The sequence of inline nodes.
  final List<InlineNode> children;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitCompositeInline(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompositeInlineNode &&
          const ListEquality<InlineNode>().equals(children, other.children);

  @override
  int get hashCode => const ListEquality<InlineNode>().hash(children);

  @override
  String toString() => 'CompositeInlineNode($children)';
}

/// Raw inline HTML element (`<span>`, `<code>`, etc.).
class RawHtmlInlineNode extends InlineNode {
  const new(this.rawHtml, {super.start, super.stop});

  /// The raw HTML string.
  final String rawHtml;

  @override
  R accept<R>(MarkdownVisitor<R> visitor) => visitor.visitRawHtmlInline(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RawHtmlInlineNode && rawHtml == other.rawHtml;

  @override
  int get hashCode => rawHtml.hashCode;

  @override
  String toString() => 'RawHtmlInlineNode("$rawHtml")';
}

/// Visitor interface for traversing [MarkdownNode] trees.
abstract interface class MarkdownVisitor<R> {
  R visitDocument(DocumentNode node);
  R visitHeading(HeadingNode node);
  R visitParagraph(ParagraphNode node);
  R visitBlockquote(BlockquoteNode node);
  R visitFencedCodeBlock(FencedCodeBlockNode node);
  R visitIndentedCodeBlock(IndentedCodeBlockNode node);
  R visitThematicBreak(ThematicBreakNode node);
  R visitBulletList(BulletListNode node);
  R visitOrderedList(OrderedListNode node);
  R visitListItem(ListItemNode node);
  R visitTable(TableNode node);
  R visitTableRow(TableRowNode node);
  R visitTableCell(TableCellNode node);
  R visitHtmlBlock(HtmlBlockNode node);
  R visitLinkReferenceDefinition(LinkReferenceDefinitionNode node);
  R visitText(TextNode node);
  R visitEmphasis(EmphasisNode node);
  R visitStrong(StrongNode node);
  R visitStrikethrough(StrikethroughNode node);
  R visitCodeSpan(CodeSpanNode node);
  R visitLink(LinkNode node);
  R visitImage(ImageNode node);
  R visitAutolink(AutolinkNode node);
  R visitLineBreak(LineBreakNode node);
  R visitCompositeInline(CompositeInlineNode node);
  R visitRawHtmlInline(RawHtmlInlineNode node);
}

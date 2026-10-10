import 'package:checks/checks.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('ast and visitor', () {
    test('AST equality and hashCode', () {
      const h1 = HeadingNode(1, TextNode('Title'));
      const h2 = HeadingNode(1, TextNode('Title'));
      const h3 = HeadingNode(2, TextNode('Title'));

      check(h1).equals(h2);
      check(h1.hashCode).equals(h2.hashCode);
      check(h1).not((it) => it.equals(h3));
    });

    test('DocumentNode equality', () {
      const doc1 = DocumentNode([
        HeadingNode(1, TextNode('Hello')),
        ParagraphNode(TextNode('World')),
      ]);
      const doc2 = DocumentNode([
        HeadingNode(1, TextNode('Hello')),
        ParagraphNode(TextNode('World')),
      ]);
      check(doc1).equals(doc2);
      check(doc1.hashCode).equals(doc2.hashCode);
    });

    test('MarkdownHtmlRenderer renders complete document', () {
      const doc = DocumentNode([
        HeadingNode(1, TextNode('My Heading')),
        ParagraphNode(
          CompositeInlineNode([
            TextNode('This is '),
            StrongNode(TextNode('bold')),
            TextNode(' and '),
            EmphasisNode(TextNode('italic')),
            TextNode(' and '),
            CodeSpanNode('code'),
            TextNode('.'),
          ]),
        ),
        ThematicBreakNode(),
        BulletListNode([
          ListItemNode([ParagraphNode(TextNode('First'))], isTask: false),
          ListItemNode(
            [ParagraphNode(TextNode('Done'))],
            isTask: true,
            isChecked: true,
          ),
        ]),
      ]);

      const renderer = MarkdownHtmlRenderer();
      final html = doc.accept(renderer);
      check(html).equals('''<h1>My Heading</h1>
<p>This is <strong>bold</strong> and <em>italic</em> and <code>code</code>.</p>
<hr />
<ul>
<li>First</li>
<li><input type="checkbox" checked="" disabled="" /> Done</li>
</ul>''');
    });

    test('MarkdownHtmlRenderer escapes HTML characters', () {
      const doc = DocumentNode([
        ParagraphNode(TextNode('Tom & Jerry <cartoon> "fun"')),
      ]);
      const renderer = MarkdownHtmlRenderer();
      check(doc.accept(renderer))
          .equals('<p>Tom &amp; Jerry &lt;cartoon&gt; &quot;fun&quot;</p>');
    });

    test('TableNode rendering with alignments', () {
      const table = TableNode(
        [
          TableRowNode([
            TableCellNode(TextNode('Left')),
            TableCellNode(TextNode('Center')),
          ], isHeader: true),
          TableRowNode([
            TableCellNode(TextNode('1')),
            TableCellNode(TextNode('2')),
          ], isHeader: false),
        ],
        [TableAlignment.left, TableAlignment.center],
      );

      const renderer = MarkdownHtmlRenderer();
      final html = table.accept(renderer);
      check(html).contains('<th align="left">Left</th>');
      check(html).contains('<th align="center">Center</th>');
      check(html).contains('<td align="left">1</td>');
      check(html).contains('<td align="center">2</td>');
    });

    group('Markdown AST equality, hashCode, and toString for block nodes', () {
      test('DocumentNode', () {
        const d1 = DocumentNode([ParagraphNode(TextNode('text'))]);
        const d2 = DocumentNode([ParagraphNode(TextNode('text'))]);
        const d3 = DocumentNode([]);

        check(d1).equals(d2);
        check(d1.hashCode).equals(d2.hashCode);
        check(d1).not((it) => it.equals(d3));
        check(d1.toString()).contains('DocumentNode');
      });

      test('HeadingNode', () {
        const h1 = HeadingNode(1, TextNode('Title'));
        const h2 = HeadingNode(1, TextNode('Title'));
        const h3 = HeadingNode(2, TextNode('Title'));

        check(h1).equals(h2);
        check(h1.hashCode).equals(h2.hashCode);
        check(h1).not((it) => it.equals(h3));
        check(h1.toString())
            .equals('HeadingNode(level: 1, content: TextNode("Title"))');
      });

      test('ParagraphNode', () {
        const p1 = ParagraphNode(TextNode('A'));
        const p2 = ParagraphNode(TextNode('A'));
        const p3 = ParagraphNode(TextNode('B'));

        check(p1).equals(p2);
        check(p1.hashCode).equals(p2.hashCode);
        check(p1).not((it) => it.equals(p3));
        check(p1.toString()).equals('ParagraphNode(TextNode("A"))');
      });

      test('BlockquoteNode', () {
        const b1 = BlockquoteNode([ParagraphNode(TextNode('quote'))]);
        const b2 = BlockquoteNode([ParagraphNode(TextNode('quote'))]);
        const b3 = BlockquoteNode([ParagraphNode(TextNode('other'))]);

        check(b1).equals(b2);
        check(b1.hashCode).equals(b2.hashCode);
        check(b1).not((it) => it.equals(b3));
        check(b1.toString()).contains('BlockquoteNode');
      });

      test('FencedCodeBlockNode', () {
        const f1 = FencedCodeBlockNode('print(1)', info: 'dart');
        const f2 = FencedCodeBlockNode('print(1)', info: 'dart');
        const f3 = FencedCodeBlockNode('print(1)', info: 'python');
        const f4 = FencedCodeBlockNode('print(2)', info: 'dart');

        check(f1).equals(f2);
        check(f1.hashCode).equals(f2.hashCode);
        check(f1).not((it) => it.equals(f3));
        check(f1).not((it) => it.equals(f4));
        check(f1.toString())
            .equals('FencedCodeBlockNode(info: dart, code: print(1))');
      });

      test('IndentedCodeBlockNode', () {
        const c1 = IndentedCodeBlockNode('code1');
        const c2 = IndentedCodeBlockNode('code1');
        const c3 = IndentedCodeBlockNode('code2');

        check(c1).equals(c2);
        check(c1.hashCode).equals(c2.hashCode);
        check(c1).not((it) => it.equals(c3));
        check(c1.toString()).equals('IndentedCodeBlockNode(code1)');
      });

      test('ThematicBreakNode', () {
        const t1 = ThematicBreakNode();
        const t2 = ThematicBreakNode();

        check(t1).equals(t2);
        check(t1.hashCode).equals(t2.hashCode);
        check(t1.toString()).equals('ThematicBreakNode()');
      });

      test('BulletListNode and ListItemNode', () {
        const item1 = ListItemNode([ParagraphNode(TextNode('1'))]);
        const item2 = ListItemNode([ParagraphNode(TextNode('1'))]);
        const item3 = ListItemNode(
          [ParagraphNode(TextNode('1'))],
          isTask: true,
          isChecked: true,
        );

        check(item1).equals(item2);
        check(item1.hashCode).equals(item2.hashCode);
        check(item1).not((it) => it.equals(item3));
        check(item1.toString()).contains('ListItemNode');

        const list1 = BulletListNode([item1], isTight: true);
        const list2 = BulletListNode([item2], isTight: true);
        const list3 = BulletListNode([item1], isTight: false);

        check(list1).equals(list2);
        check(list1.hashCode).equals(list2.hashCode);
        check(list1).not((it) => it.equals(list3));
        check(list1.toString()).contains('BulletListNode(isTight: true');
      });

      test('OrderedListNode', () {
        const o1 = OrderedListNode(
          [
            ListItemNode([ParagraphNode(TextNode('1'))]),
          ],
          startNumber: 1,
          isTight: true,
        );
        const o2 = OrderedListNode(
          [
            ListItemNode([ParagraphNode(TextNode('1'))]),
          ],
          startNumber: 1,
          isTight: true,
        );
        const o3 = OrderedListNode(
          [
            ListItemNode([ParagraphNode(TextNode('1'))]),
          ],
          startNumber: 2,
          isTight: true,
        );

        check(o1).equals(o2);
        check(o1.hashCode).equals(o2.hashCode);
        check(o1).not((it) => it.equals(o3));
        check(o1.toString())
            .contains('OrderedListNode(start: 1, isTight: true');
      });

      test('TableNode, TableRowNode, TableCellNode', () {
        const cell1 = TableCellNode(TextNode('A'));
        const cell2 = TableCellNode(TextNode('A'));
        const cell3 = TableCellNode(TextNode('B'));

        check(cell1).equals(cell2);
        check(cell1.hashCode).equals(cell2.hashCode);
        check(cell1).not((it) => it.equals(cell3));
        check(cell1.toString()).equals('TableCellNode(TextNode("A"))');

        const row1 = TableRowNode([cell1], isHeader: true);
        const row2 = TableRowNode([cell2], isHeader: true);
        const row3 = TableRowNode([cell1], isHeader: false);

        check(row1).equals(row2);
        check(row1.hashCode).equals(row2.hashCode);
        check(row1).not((it) => it.equals(row3));
        check(row1.toString()).contains('TableRowNode(isHeader: true');

        const table1 = TableNode([row1], [TableAlignment.center]);
        const table2 = TableNode([row2], [TableAlignment.center]);
        const table3 = TableNode([row1], [TableAlignment.left]);

        check(table1).equals(table2);
        check(table1.hashCode).equals(table2.hashCode);
        check(table1).not((it) => it.equals(table3));
        check(table1.toString()).contains('TableNode');
      });

      test('HtmlBlockNode', () {
        const h1 = HtmlBlockNode('<div>test</div>');
        const h2 = HtmlBlockNode('<div>test</div>');
        const h3 = HtmlBlockNode('<p>test</p>');

        check(h1).equals(h2);
        check(h1.hashCode).equals(h2.hashCode);
        check(h1).not((it) => it.equals(h3));
        check(h1.toString()).equals('HtmlBlockNode(<div>test</div>)');
      });

      test('LinkReferenceDefinitionNode', () {
        const l1 = LinkReferenceDefinitionNode(
          'ref',
          'https://example.com',
          title: 'Example',
        );
        const l2 = LinkReferenceDefinitionNode(
          'ref',
          'https://example.com',
          title: 'Example',
        );
        const l3 = LinkReferenceDefinitionNode(
          'ref',
          'https://example.com',
          title: 'Other',
        );
        const l4 = LinkReferenceDefinitionNode(
          'other',
          'https://example.com',
          title: 'Example',
        );

        check(l1).equals(l2);
        check(l1.hashCode).equals(l2.hashCode);
        check(l1).not((it) => it.equals(l3));
        check(l1).not((it) => it.equals(l4));
        check(l1.toString()).equals(
          'LinkReferenceDefinitionNode(label: ref, url: https://example.com, title: Example)',
        );
      });
    });

    group('Markdown AST equality, hashCode, and toString for inline nodes', () {
      test('TextNode, EmphasisNode, StrongNode', () {
        const t1 = TextNode('hello');
        const t2 = TextNode('hello');
        const t3 = TextNode('world');

        check(t1).equals(t2);
        check(t1.hashCode).equals(t2.hashCode);
        check(t1).not((it) => it.equals(t3));
        check(t1.toString()).equals('TextNode("hello")');

        const e1 = EmphasisNode(t1);
        const e2 = EmphasisNode(t2);
        const e3 = EmphasisNode(t3);

        check(e1).equals(e2);
        check(e1.hashCode).equals(e2.hashCode);
        check(e1).not((it) => it.equals(e3));
        check(e1.toString()).equals('EmphasisNode(TextNode("hello"))');

        const s1 = StrongNode(t1);
        const s2 = StrongNode(t2);
        const s3 = StrongNode(t3);

        check(s1).equals(s2);
        check(s1.hashCode).equals(s2.hashCode);
        check(s1).not((it) => it.equals(s3));
        check(s1.toString()).equals('StrongNode(TextNode("hello"))');
      });

      test('StrikethroughNode', () {
        const s1 = StrikethroughNode(TextNode('del'));
        const s2 = StrikethroughNode(TextNode('del'));
        const s3 = StrikethroughNode(TextNode('other'));

        check(s1).equals(s2);
        check(s1.hashCode).equals(s2.hashCode);
        check(s1).not((it) => it.equals(s3));
        check(s1.toString()).equals('StrikethroughNode(TextNode("del"))');
      });

      test('CodeSpanNode', () {
        const c1 = CodeSpanNode('x = 1');
        const c2 = CodeSpanNode('x = 1');
        const c3 = CodeSpanNode('y = 2');

        check(c1).equals(c2);
        check(c1.hashCode).equals(c2.hashCode);
        check(c1).not((it) => it.equals(c3));
        check(c1.toString()).equals('CodeSpanNode("x = 1")');
      });

      test('LinkNode & ImageNode', () {
        const link1 = LinkNode(
          TextNode('click'),
          'https://dart.dev',
          title: 'Dart',
        );
        const link2 = LinkNode(
          TextNode('click'),
          'https://dart.dev',
          title: 'Dart',
        );
        const link3 = LinkNode(
          TextNode('click'),
          'https://pub.dev',
          title: 'Dart',
        );

        check(link1).equals(link2);
        check(link1.hashCode).equals(link2.hashCode);
        check(link1).not((it) => it.equals(link3));
        check(link1.toString()).equals(
          'LinkNode(text: TextNode("click"), url: https://dart.dev, title: Dart)',
        );

        const img1 = ImageNode(TextNode('logo'), 'logo.png', title: 'Logo');
        const img2 = ImageNode(TextNode('logo'), 'logo.png', title: 'Logo');
        const img3 = ImageNode(TextNode('logo'), 'icon.png', title: 'Logo');

        check(img1).equals(img2);
        check(img1.hashCode).equals(img2.hashCode);
        check(img1).not((it) => it.equals(img3));
        check(img1.toString()).equals(
          'ImageNode(alt: TextNode("logo"), url: logo.png, title: Logo)',
        );
      });

      test('AutolinkNode', () {
        const a1 = AutolinkNode('https://dart.dev', isEmail: false);
        const a2 = AutolinkNode('https://dart.dev', isEmail: false);
        const a3 = AutolinkNode('support@dart.dev', isEmail: true);

        check(a1).equals(a2);
        check(a1.hashCode).equals(a2.hashCode);
        check(a1).not((it) => it.equals(a3));
        check(a1.toString())
            .equals('AutolinkNode(url: https://dart.dev, isEmail: false)');
      });

      test('LineBreakNode', () {
        const lb1 = LineBreakNode(isHard: true);
        const lb2 = LineBreakNode(isHard: true);
        const lb3 = LineBreakNode(isHard: false);

        check(lb1).equals(lb2);
        check(lb1.hashCode).equals(lb2.hashCode);
        check(lb1).not((it) => it.equals(lb3));
        check(lb1.toString()).equals('LineBreakNode(isHard: true)');
      });

      test('CompositeInlineNode', () {
        const ci1 = CompositeInlineNode([TextNode('a'), TextNode('b')]);
        const ci2 = CompositeInlineNode([TextNode('a'), TextNode('b')]);
        const ci3 = CompositeInlineNode([TextNode('c')]);

        check(ci1).equals(ci2);
        check(ci1.hashCode).equals(ci2.hashCode);
        check(ci1).not((it) => it.equals(ci3));
        check(ci1.toString()).contains('CompositeInlineNode');
      });

      test('RawHtmlInlineNode', () {
        const r1 = RawHtmlInlineNode('<span>hello</span>');
        const r2 = RawHtmlInlineNode('<span>hello</span>');
        const r3 = RawHtmlInlineNode('<b>hello</b>');

        check(r1).equals(r2);
        check(r1.hashCode).equals(r2.hashCode);
        check(r1).not((it) => it.equals(r3));
        check(r1.toString()).equals('RawHtmlInlineNode("<span>hello</span>")');
      });

      test('Node offset tracking start and stop', () {
        const node = TextNode('hello', start: 5, stop: 10);
        check(node.start).equals(5);
        check(node.stop).equals(10);
      });
    });

    group('MarkdownVisitor traversal across all 26 AST nodes', () {
      final visitor = FullTrackingVisitor();

      test('dispatches all block nodes correctly', () {
        check(const DocumentNode([]).accept(visitor)).equals('document:0');
        check(const HeadingNode(3, TextNode('H')).accept(visitor))
            .equals('heading:3');
        check(const ParagraphNode(TextNode('P')).accept(visitor))
            .equals('paragraph');
        check(const BlockquoteNode([]).accept(visitor)).equals('blockquote:0');
        check(const FencedCodeBlockNode('c', info: 'i').accept(visitor))
            .equals('fenced:i:c');
        check(const IndentedCodeBlockNode('c').accept(visitor))
            .equals('indented:c');
        check(const ThematicBreakNode().accept(visitor))
            .equals('thematic_break');
        check(const BulletListNode([]).accept(visitor)).equals('bullet_list:0');
        check(const OrderedListNode([], startNumber: 5).accept(visitor))
            .equals('ordered_list:5');
        check(
          const ListItemNode(
            [],
            isTask: true,
            isChecked: false,
          ).accept(visitor),
        ).equals('list_item:true:false');
        check(const TableNode([], []).accept(visitor)).equals('table:0');
        check(const TableRowNode([], isHeader: true).accept(visitor))
            .equals('table_row:0:true');
        check(const TableCellNode(TextNode('')).accept(visitor))
            .equals('table_cell');
        check(const HtmlBlockNode('<hr>').accept(visitor))
            .equals('html_block:<hr>');
        check(const LinkReferenceDefinitionNode('lbl', 'url').accept(visitor))
            .equals('link_ref:lbl:url');
      });

      test('dispatches all inline nodes correctly', () {
        check(const TextNode('t').accept(visitor)).equals('text:t');
        check(const EmphasisNode(TextNode('e')).accept(visitor))
            .equals('emphasis');
        check(const StrongNode(TextNode('s')).accept(visitor)).equals('strong');
        check(const StrikethroughNode(TextNode('d')).accept(visitor))
            .equals('strikethrough');
        check(const CodeSpanNode('x').accept(visitor)).equals('code_span:x');
        check(const LinkNode(TextNode('t'), 'u').accept(visitor))
            .equals('link:u');
        check(const ImageNode(TextNode('a'), 'src').accept(visitor))
            .equals('image:src');
        check(const AutolinkNode('u', isEmail: true).accept(visitor))
            .equals('autolink:u:true');
        check(const LineBreakNode(isHard: false).accept(visitor))
            .equals('line_break:false');
        check(const CompositeInlineNode([]).accept(visitor))
            .equals('composite_inline:0');
        check(const RawHtmlInlineNode('<i>').accept(visitor))
            .equals('raw_html:<i>');
      });
    });
  });
}

class FullTrackingVisitor implements MarkdownVisitor<String> {
  @override
  String visitDocument(DocumentNode node) => 'document:${node.blocks.length}';

  @override
  String visitHeading(HeadingNode node) => 'heading:${node.level}';

  @override
  String visitParagraph(ParagraphNode node) => 'paragraph';

  @override
  String visitBlockquote(BlockquoteNode node) =>
      'blockquote:${node.children.length}';

  @override
  String visitFencedCodeBlock(FencedCodeBlockNode node) =>
      'fenced:${node.info}:${node.code}';

  @override
  String visitIndentedCodeBlock(IndentedCodeBlockNode node) =>
      'indented:${node.code}';

  @override
  String visitThematicBreak(ThematicBreakNode node) => 'thematic_break';

  @override
  String visitBulletList(BulletListNode node) =>
      'bullet_list:${node.items.length}';

  @override
  String visitOrderedList(OrderedListNode node) =>
      'ordered_list:${node.startNumber}';

  @override
  String visitListItem(ListItemNode node) =>
      'list_item:${node.isTask}:${node.isChecked}';

  @override
  String visitTable(TableNode node) => 'table:${node.rows.length}';

  @override
  String visitTableRow(TableRowNode node) =>
      'table_row:${node.cells.length}:${node.isHeader}';

  @override
  String visitTableCell(TableCellNode node) => 'table_cell';

  @override
  String visitHtmlBlock(HtmlBlockNode node) => 'html_block:${node.rawHtml}';

  @override
  String visitLinkReferenceDefinition(LinkReferenceDefinitionNode node) =>
      'link_ref:${node.label}:${node.url}';

  @override
  String visitText(TextNode node) => 'text:${node.text}';

  @override
  String visitEmphasis(EmphasisNode node) => 'emphasis';

  @override
  String visitStrong(StrongNode node) => 'strong';

  @override
  String visitStrikethrough(StrikethroughNode node) => 'strikethrough';

  @override
  String visitCodeSpan(CodeSpanNode node) => 'code_span:${node.code}';

  @override
  String visitLink(LinkNode node) => 'link:${node.url}';

  @override
  String visitImage(ImageNode node) => 'image:${node.url}';

  @override
  String visitAutolink(AutolinkNode node) =>
      'autolink:${node.url}:${node.isEmail}';

  @override
  String visitLineBreak(LineBreakNode node) => 'line_break:${node.isHard}';

  @override
  String visitCompositeInline(CompositeInlineNode node) =>
      'composite_inline:${node.children.length}';

  @override
  String visitRawHtmlInline(RawHtmlInlineNode node) =>
      'raw_html:${node.rawHtml}';
}

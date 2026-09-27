import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

void main() {
  group('ast and visitor', () {
    test('AST equality and hashCode', () {
      const h1 = HeadingNode(1, TextNode('Title'));
      const h2 = HeadingNode(1, TextNode('Title'));
      const h3 = HeadingNode(2, TextNode('Title'));

      expect(h1, equals(h2));
      expect(h1.hashCode, equals(h2.hashCode));
      expect(h1, isNot(equals(h3)));
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
      expect(doc1, equals(doc2));
      expect(doc1.hashCode, equals(doc2.hashCode));
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
      expect(html, '''<h1>My Heading</h1>
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
      expect(
        doc.accept(renderer),
        '<p>Tom &amp; Jerry &lt;cartoon&gt; &quot;fun&quot;</p>',
      );
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
      expect(html, contains('<th align="left">Left</th>'));
      expect(html, contains('<th align="center">Center</th>'));
      expect(html, contains('<td align="left">1</td>'));
      expect(html, contains('<td align="center">2</td>'));
    });

    group('Markdown AST equality, hashCode, and toString for block nodes', () {
      test('DocumentNode', () {
        const d1 = DocumentNode([ParagraphNode(TextNode('text'))]);
        const d2 = DocumentNode([ParagraphNode(TextNode('text'))]);
        const d3 = DocumentNode([]);

        expect(d1, equals(d2));
        expect(d1.hashCode, equals(d2.hashCode));
        expect(d1, isNot(equals(d3)));
        expect(d1.toString(), contains('DocumentNode'));
      });

      test('HeadingNode', () {
        const h1 = HeadingNode(1, TextNode('Title'));
        const h2 = HeadingNode(1, TextNode('Title'));
        const h3 = HeadingNode(2, TextNode('Title'));

        expect(h1, equals(h2));
        expect(h1.hashCode, equals(h2.hashCode));
        expect(h1, isNot(equals(h3)));
        expect(
          h1.toString(),
          'HeadingNode(level: 1, content: TextNode("Title"))',
        );
      });

      test('ParagraphNode', () {
        const p1 = ParagraphNode(TextNode('A'));
        const p2 = ParagraphNode(TextNode('A'));
        const p3 = ParagraphNode(TextNode('B'));

        expect(p1, equals(p2));
        expect(p1.hashCode, equals(p2.hashCode));
        expect(p1, isNot(equals(p3)));
        expect(p1.toString(), 'ParagraphNode(TextNode("A"))');
      });

      test('BlockquoteNode', () {
        const b1 = BlockquoteNode([ParagraphNode(TextNode('quote'))]);
        const b2 = BlockquoteNode([ParagraphNode(TextNode('quote'))]);
        const b3 = BlockquoteNode([ParagraphNode(TextNode('other'))]);

        expect(b1, equals(b2));
        expect(b1.hashCode, equals(b2.hashCode));
        expect(b1, isNot(equals(b3)));
        expect(b1.toString(), contains('BlockquoteNode'));
      });

      test('FencedCodeBlockNode', () {
        const f1 = FencedCodeBlockNode('print(1)', info: 'dart');
        const f2 = FencedCodeBlockNode('print(1)', info: 'dart');
        const f3 = FencedCodeBlockNode('print(1)', info: 'python');
        const f4 = FencedCodeBlockNode('print(2)', info: 'dart');

        expect(f1, equals(f2));
        expect(f1.hashCode, equals(f2.hashCode));
        expect(f1, isNot(equals(f3)));
        expect(f1, isNot(equals(f4)));
        expect(
          f1.toString(),
          'FencedCodeBlockNode(info: dart, code: print(1))',
        );
      });

      test('IndentedCodeBlockNode', () {
        const c1 = IndentedCodeBlockNode('code1');
        const c2 = IndentedCodeBlockNode('code1');
        const c3 = IndentedCodeBlockNode('code2');

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
        expect(c1, isNot(equals(c3)));
        expect(c1.toString(), 'IndentedCodeBlockNode(code1)');
      });

      test('ThematicBreakNode', () {
        const t1 = ThematicBreakNode();
        const t2 = ThematicBreakNode();

        expect(t1, equals(t2));
        expect(t1.hashCode, equals(t2.hashCode));
        expect(t1.toString(), 'ThematicBreakNode()');
      });

      test('BulletListNode and ListItemNode', () {
        const item1 = ListItemNode([ParagraphNode(TextNode('1'))]);
        const item2 = ListItemNode([ParagraphNode(TextNode('1'))]);
        const item3 = ListItemNode(
          [ParagraphNode(TextNode('1'))],
          isTask: true,
          isChecked: true,
        );

        expect(item1, equals(item2));
        expect(item1.hashCode, equals(item2.hashCode));
        expect(item1, isNot(equals(item3)));
        expect(item1.toString(), contains('ListItemNode'));

        const list1 = BulletListNode([item1], isTight: true);
        const list2 = BulletListNode([item2], isTight: true);
        const list3 = BulletListNode([item1], isTight: false);

        expect(list1, equals(list2));
        expect(list1.hashCode, equals(list2.hashCode));
        expect(list1, isNot(equals(list3)));
        expect(list1.toString(), contains('BulletListNode(isTight: true'));
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

        expect(o1, equals(o2));
        expect(o1.hashCode, equals(o2.hashCode));
        expect(o1, isNot(equals(o3)));
        expect(
          o1.toString(),
          contains('OrderedListNode(start: 1, isTight: true'),
        );
      });

      test('TableNode, TableRowNode, TableCellNode', () {
        const cell1 = TableCellNode(TextNode('A'));
        const cell2 = TableCellNode(TextNode('A'));
        const cell3 = TableCellNode(TextNode('B'));

        expect(cell1, equals(cell2));
        expect(cell1.hashCode, equals(cell2.hashCode));
        expect(cell1, isNot(equals(cell3)));
        expect(cell1.toString(), 'TableCellNode(TextNode("A"))');

        const row1 = TableRowNode([cell1], isHeader: true);
        const row2 = TableRowNode([cell2], isHeader: true);
        const row3 = TableRowNode([cell1], isHeader: false);

        expect(row1, equals(row2));
        expect(row1.hashCode, equals(row2.hashCode));
        expect(row1, isNot(equals(row3)));
        expect(row1.toString(), contains('TableRowNode(isHeader: true'));

        const table1 = TableNode([row1], [TableAlignment.center]);
        const table2 = TableNode([row2], [TableAlignment.center]);
        const table3 = TableNode([row1], [TableAlignment.left]);

        expect(table1, equals(table2));
        expect(table1.hashCode, equals(table2.hashCode));
        expect(table1, isNot(equals(table3)));
        expect(table1.toString(), contains('TableNode'));
      });

      test('HtmlBlockNode', () {
        const h1 = HtmlBlockNode('<div>test</div>');
        const h2 = HtmlBlockNode('<div>test</div>');
        const h3 = HtmlBlockNode('<p>test</p>');

        expect(h1, equals(h2));
        expect(h1.hashCode, equals(h2.hashCode));
        expect(h1, isNot(equals(h3)));
        expect(h1.toString(), 'HtmlBlockNode(<div>test</div>)');
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

        expect(l1, equals(l2));
        expect(l1.hashCode, equals(l2.hashCode));
        expect(l1, isNot(equals(l3)));
        expect(l1, isNot(equals(l4)));
        expect(
          l1.toString(),
          'LinkReferenceDefinitionNode(label: ref, url: https://example.com, title: Example)',
        );
      });
    });

    group('Markdown AST equality, hashCode, and toString for inline nodes', () {
      test('TextNode, EmphasisNode, StrongNode', () {
        const t1 = TextNode('hello');
        const t2 = TextNode('hello');
        const t3 = TextNode('world');

        expect(t1, equals(t2));
        expect(t1.hashCode, equals(t2.hashCode));
        expect(t1, isNot(equals(t3)));
        expect(t1.toString(), 'TextNode("hello")');

        const e1 = EmphasisNode(t1);
        const e2 = EmphasisNode(t2);
        const e3 = EmphasisNode(t3);

        expect(e1, equals(e2));
        expect(e1.hashCode, equals(e2.hashCode));
        expect(e1, isNot(equals(e3)));
        expect(e1.toString(), 'EmphasisNode(TextNode("hello"))');

        const s1 = StrongNode(t1);
        const s2 = StrongNode(t2);
        const s3 = StrongNode(t3);

        expect(s1, equals(s2));
        expect(s1.hashCode, equals(s2.hashCode));
        expect(s1, isNot(equals(s3)));
        expect(s1.toString(), 'StrongNode(TextNode("hello"))');
      });

      test('StrikethroughNode', () {
        const s1 = StrikethroughNode(TextNode('del'));
        const s2 = StrikethroughNode(TextNode('del'));
        const s3 = StrikethroughNode(TextNode('other'));

        expect(s1, equals(s2));
        expect(s1.hashCode, equals(s2.hashCode));
        expect(s1, isNot(equals(s3)));
        expect(s1.toString(), 'StrikethroughNode(TextNode("del"))');
      });

      test('CodeSpanNode', () {
        const c1 = CodeSpanNode('x = 1');
        const c2 = CodeSpanNode('x = 1');
        const c3 = CodeSpanNode('y = 2');

        expect(c1, equals(c2));
        expect(c1.hashCode, equals(c2.hashCode));
        expect(c1, isNot(equals(c3)));
        expect(c1.toString(), 'CodeSpanNode("x = 1")');
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

        expect(link1, equals(link2));
        expect(link1.hashCode, equals(link2.hashCode));
        expect(link1, isNot(equals(link3)));
        expect(
          link1.toString(),
          'LinkNode(text: TextNode("click"), url: https://dart.dev, title: Dart)',
        );

        const img1 = ImageNode(TextNode('logo'), 'logo.png', title: 'Logo');
        const img2 = ImageNode(TextNode('logo'), 'logo.png', title: 'Logo');
        const img3 = ImageNode(TextNode('logo'), 'icon.png', title: 'Logo');

        expect(img1, equals(img2));
        expect(img1.hashCode, equals(img2.hashCode));
        expect(img1, isNot(equals(img3)));
        expect(
          img1.toString(),
          'ImageNode(alt: TextNode("logo"), url: logo.png, title: Logo)',
        );
      });

      test('AutolinkNode', () {
        const a1 = AutolinkNode('https://dart.dev', isEmail: false);
        const a2 = AutolinkNode('https://dart.dev', isEmail: false);
        const a3 = AutolinkNode('support@dart.dev', isEmail: true);

        expect(a1, equals(a2));
        expect(a1.hashCode, equals(a2.hashCode));
        expect(a1, isNot(equals(a3)));
        expect(
          a1.toString(),
          'AutolinkNode(url: https://dart.dev, isEmail: false)',
        );
      });

      test('LineBreakNode', () {
        const lb1 = LineBreakNode(isHard: true);
        const lb2 = LineBreakNode(isHard: true);
        const lb3 = LineBreakNode(isHard: false);

        expect(lb1, equals(lb2));
        expect(lb1.hashCode, equals(lb2.hashCode));
        expect(lb1, isNot(equals(lb3)));
        expect(lb1.toString(), 'LineBreakNode(isHard: true)');
      });

      test('CompositeInlineNode', () {
        const ci1 = CompositeInlineNode([TextNode('a'), TextNode('b')]);
        const ci2 = CompositeInlineNode([TextNode('a'), TextNode('b')]);
        const ci3 = CompositeInlineNode([TextNode('c')]);

        expect(ci1, equals(ci2));
        expect(ci1.hashCode, equals(ci2.hashCode));
        expect(ci1, isNot(equals(ci3)));
        expect(ci1.toString(), contains('CompositeInlineNode'));
      });

      test('RawHtmlInlineNode', () {
        const r1 = RawHtmlInlineNode('<span>hello</span>');
        const r2 = RawHtmlInlineNode('<span>hello</span>');
        const r3 = RawHtmlInlineNode('<b>hello</b>');

        expect(r1, equals(r2));
        expect(r1.hashCode, equals(r2.hashCode));
        expect(r1, isNot(equals(r3)));
        expect(r1.toString(), 'RawHtmlInlineNode("<span>hello</span>")');
      });

      test('Node offset tracking start and stop', () {
        const node = TextNode('hello', start: 5, stop: 10);
        expect(node.start, 5);
        expect(node.stop, 10);
      });
    });

    group('MarkdownVisitor traversal across all 26 AST nodes', () {
      final visitor = FullTrackingVisitor();

      test('dispatches all block nodes correctly', () {
        expect(const DocumentNode([]).accept(visitor), 'document:0');
        expect(
          const HeadingNode(3, TextNode('H')).accept(visitor),
          'heading:3',
        );
        expect(const ParagraphNode(TextNode('P')).accept(visitor), 'paragraph');
        expect(const BlockquoteNode([]).accept(visitor), 'blockquote:0');
        expect(
          const FencedCodeBlockNode('c', info: 'i').accept(visitor),
          'fenced:i:c',
        );
        expect(const IndentedCodeBlockNode('c').accept(visitor), 'indented:c');
        expect(const ThematicBreakNode().accept(visitor), 'thematic_break');
        expect(const BulletListNode([]).accept(visitor), 'bullet_list:0');
        expect(
          const OrderedListNode([], startNumber: 5).accept(visitor),
          'ordered_list:5',
        );
        expect(
          const ListItemNode(
            [],
            isTask: true,
            isChecked: false,
          ).accept(visitor),
          'list_item:true:false',
        );
        expect(const TableNode([], []).accept(visitor), 'table:0');
        expect(
          const TableRowNode([], isHeader: true).accept(visitor),
          'table_row:0:true',
        );
        expect(const TableCellNode(TextNode('')).accept(visitor), 'table_cell');
        expect(const HtmlBlockNode('<hr>').accept(visitor), 'html_block:<hr>');
        expect(
          const LinkReferenceDefinitionNode('lbl', 'url').accept(visitor),
          'link_ref:lbl:url',
        );
      });

      test('dispatches all inline nodes correctly', () {
        expect(const TextNode('t').accept(visitor), 'text:t');
        expect(const EmphasisNode(TextNode('e')).accept(visitor), 'emphasis');
        expect(const StrongNode(TextNode('s')).accept(visitor), 'strong');
        expect(
          const StrikethroughNode(TextNode('d')).accept(visitor),
          'strikethrough',
        );
        expect(const CodeSpanNode('x').accept(visitor), 'code_span:x');
        expect(const LinkNode(TextNode('t'), 'u').accept(visitor), 'link:u');
        expect(
          const ImageNode(TextNode('a'), 'src').accept(visitor),
          'image:src',
        );
        expect(
          const AutolinkNode('u', isEmail: true).accept(visitor),
          'autolink:u:true',
        );
        expect(
          const LineBreakNode(isHard: false).accept(visitor),
          'line_break:false',
        );
        expect(
          const CompositeInlineNode([]).accept(visitor),
          'composite_inline:0',
        );
        expect(const RawHtmlInlineNode('<i>').accept(visitor), 'raw_html:<i>');
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

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
  });
}

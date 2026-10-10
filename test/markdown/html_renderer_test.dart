import 'package:checks/checks.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

void main() {
  const renderer = MarkdownHtmlRenderer();

  group('MarkdownHtmlRenderer.escape', () {
    test('escapes HTML special characters', () {
      check(MarkdownHtmlRenderer.escape('foo & bar < baz > "qux"'))
          .equals('foo &amp; bar &lt; baz &gt; &quot;qux&quot;');
    });

    test('preserves strings without special characters', () {
      check(MarkdownHtmlRenderer.escape('hello world 123'))
          .equals('hello world 123');
    });
  });

  group('MarkdownHtmlRenderer.plainText', () {
    test('extracts text from all 11 inline node types', () {
      check(MarkdownHtmlRenderer.plainText(const TextNode('simple text')))
          .equals('simple text');
      check(MarkdownHtmlRenderer.plainText(const CodeSpanNode('code span')))
          .equals('code span');
      check(
        MarkdownHtmlRenderer.plainText(
          const EmphasisNode(TextNode('emphasis')),
        ),
      ).equals('emphasis');
      check(
        MarkdownHtmlRenderer.plainText(const StrongNode(TextNode('strong'))),
      ).equals('strong');
      check(
        MarkdownHtmlRenderer.plainText(
          const StrikethroughNode(TextNode('strike')),
        ),
      ).equals('strike');
      check(
        MarkdownHtmlRenderer.plainText(
          const LinkNode(TextNode('link text'), 'url'),
        ),
      ).equals('link text');
      check(
        MarkdownHtmlRenderer.plainText(
          const ImageNode(TextNode('image alt'), 'img.png'),
        ),
      ).equals('image alt');
      check(
        MarkdownHtmlRenderer.plainText(const AutolinkNode('https://dart.dev')),
      ).equals('https://dart.dev');
      check(MarkdownHtmlRenderer.plainText(const LineBreakNode(isHard: false)))
          .equals(' ');
      check(MarkdownHtmlRenderer.plainText(const LineBreakNode(isHard: true)))
          .equals(' ');
      check(
        MarkdownHtmlRenderer.plainText(
          const CompositeInlineNode([
            TextNode('hello '),
            CodeSpanNode('world'),
          ]),
        ),
      ).equals('hello world');
      check(
        MarkdownHtmlRenderer.plainText(
          const RawHtmlInlineNode('<span>html</span>'),
        ),
      ).equals('');
    });

    test('recursively unwraps nested formatting', () {
      const nested = StrongNode(EmphasisNode(TextNode('deep text')));
      check(MarkdownHtmlRenderer.plainText(nested)).equals('deep text');
    });
  });

  group('headings and paragraphs', () {
    test('renders headings for levels 1 through 6', () {
      for (var level = 1; level <= 6; level++) {
        final node = HeadingNode(level, TextNode('Heading $level'));
        check(node.accept(renderer))
            .equals('<h$level>Heading $level</h$level>');
      }
    });

    test('renders paragraphs with formatted inlines', () {
      const para = ParagraphNode(
        CompositeInlineNode([
          TextNode('Normal '),
          EmphasisNode(TextNode('italic')),
          TextNode(' and '),
          StrongNode(TextNode('bold')),
          TextNode(' and '),
          StrikethroughNode(TextNode('deleted')),
          TextNode('.'),
        ]),
      );
      check(para.accept(renderer)).equals(
        '<p>Normal <em>italic</em> and <strong>bold</strong> and <del>deleted</del>.</p>',
      );
    });
  });

  group('code blocks', () {
    test('renders fenced code block with language specifier', () {
      const block = FencedCodeBlockNode(
        'void main() => print("<hi>");',
        info: 'dart',
      );
      check(block.accept(renderer)).equals(
        '<pre><code class="language-dart">void main() =&gt; print(&quot;&lt;hi&gt;&quot;);</code></pre>',
      );
    });

    test('renders fenced code block without info', () {
      const block = FencedCodeBlockNode('simple code');
      check(block.accept(renderer))
          .equals('<pre><code>simple code</code></pre>');
    });

    test('renders fenced code block with extra info attributes', () {
      const block = FencedCodeBlockNode(
        'x = 1',
        info: 'python {class=runnable}',
      );
      check(block.accept(renderer))
          .equals('<pre><code class="language-python">x = 1</code></pre>');
    });

    test('renders indented code block with escaping', () {
      const block = IndentedCodeBlockNode('  code & text <tag>');
      check(block.accept(renderer))
          .equals('<pre><code>  code &amp; text &lt;tag&gt;</code></pre>');
    });
  });

  group('blockquotes and thematic breaks', () {
    test('renders thematic break', () {
      const breakNode = ThematicBreakNode();
      check(breakNode.accept(renderer)).equals('<hr />');
    });

    test('renders nested blockquote with multiple children', () {
      const quote = BlockquoteNode([
        HeadingNode(2, TextNode('Quote Header')),
        ParagraphNode(TextNode('Quote Body')),
      ]);
      check(quote.accept(renderer)).equals(
        '<blockquote>\n<h2>Quote Header</h2>\n<p>Quote Body</p>\n</blockquote>',
      );
    });
  });

  group('lists', () {
    test('renders tight and loose bullet lists', () {
      const tightList = BulletListNode([
        ListItemNode([ParagraphNode(TextNode('Item A'))]),
        ListItemNode([ParagraphNode(TextNode('Item B'))]),
      ], isTight: true);
      check(tightList.accept(renderer))
          .equals('<ul>\n<li>Item A</li>\n<li>Item B</li>\n</ul>');

      const looseList = BulletListNode([
        ListItemNode([ParagraphNode(TextNode('Item 1'))]),
      ], isTight: false);
      check(looseList.accept(renderer))
          .equals('<ul>\n<li><p>Item 1</p></li>\n</ul>');
    });

    test('renders task list items checked and unchecked', () {
      const taskList = BulletListNode([
        ListItemNode(
          [ParagraphNode(TextNode('Todo'))],
          isTask: true,
          isChecked: false,
        ),
        ListItemNode(
          [ParagraphNode(TextNode('Done'))],
          isTask: true,
          isChecked: true,
        ),
      ]);
      check(taskList.accept(renderer)).equals(
        '<ul>\n'
        '<li><input type="checkbox" disabled="" /> Todo</li>\n'
        '<li><input type="checkbox" checked="" disabled="" /> Done</li>\n'
        '</ul>',
      );
    });

    test('renders empty list item and direct visitListItem', () {
      const emptyItem = ListItemNode([]);
      check(renderer.visitListItem(emptyItem)).equals('<li></li>');
    });

    test('renders ordered list with default and custom start number', () {
      const defaultOl = OrderedListNode([
        ListItemNode([ParagraphNode(TextNode('First'))]),
      ], startNumber: 1);
      check(defaultOl.accept(renderer)).equals('<ol>\n<li>First</li>\n</ol>');

      const customOl = OrderedListNode([
        ListItemNode([ParagraphNode(TextNode('Fifth'))]),
      ], startNumber: 5);
      check(customOl.accept(renderer))
          .equals('<ol start="5">\n<li>Fifth</li>\n</ol>');
    });
  });

  group('tables', () {
    test('renders empty table', () {
      const emptyTable = TableNode([], []);
      check(emptyTable.accept(renderer)).equals('<table></table>');
    });

    test('renders table with header, body, and varied alignments', () {
      const table = TableNode(
        [
          TableRowNode([
            TableCellNode(TextNode('Left')),
            TableCellNode(TextNode('Center')),
            TableCellNode(TextNode('Right')),
            TableCellNode(TextNode('Default')),
            TableCellNode(TextNode('Overflow')),
          ], isHeader: true),
          TableRowNode([
            TableCellNode(TextNode('L1')),
            TableCellNode(TextNode('C1')),
            TableCellNode(TextNode('R1')),
            TableCellNode(TextNode('D1')),
            TableCellNode(TextNode('O1')),
          ]),
        ],
        [
          TableAlignment.left,
          TableAlignment.center,
          TableAlignment.right,
          TableAlignment.none,
        ],
      );

      const expected =
          '<table>\n'
          '<thead>\n'
          '<tr>\n'
          '  <th align="left">Left</th>\n'
          '  <th align="center">Center</th>\n'
          '  <th align="right">Right</th>\n'
          '  <th>Default</th>\n'
          '  <th>Overflow</th>\n'
          '</tr>\n'
          '</thead>\n'
          '<tbody>\n'
          '<tr>\n'
          '  <td align="left">L1</td>\n'
          '  <td align="center">C1</td>\n'
          '  <td align="right">R1</td>\n'
          '  <td>D1</td>\n'
          '  <td>O1</td>\n'
          '</tr>\n'
          '</tbody>\n'
          '</table>';

      check(table.accept(renderer)).equals(expected);
    });

    test('visitTableRow and visitTableCell direct calls', () {
      const headerRow = TableRowNode([
        TableCellNode(TextNode('H1')),
        TableCellNode(TextNode('H2')),
      ], isHeader: true);
      check(renderer.visitTableRow(headerRow))
          .equals('<tr><th>H1</th><th>H2</th></tr>');

      const dataRow = TableRowNode([
        TableCellNode(TextNode('D1')),
        TableCellNode(TextNode('D2')),
      ], isHeader: false);
      check(renderer.visitTableRow(dataRow))
          .equals('<tr><td>D1</td><td>D2</td></tr>');

      const cell = TableCellNode(TextNode('cell content'));
      check(renderer.visitTableCell(cell)).equals('cell content');
    });
  });

  group('html and references', () {
    test('renders html block verbatim', () {
      const htmlBlock = HtmlBlockNode('<div class="note"><p>raw</p></div>');
      check(htmlBlock.accept(renderer))
          .equals('<div class="note"><p>raw</p></div>');
    });

    test('renders raw html inline verbatim', () {
      const rawHtml = RawHtmlInlineNode('<span>badge</span>');
      check(rawHtml.accept(renderer)).equals('<span>badge</span>');
    });

    test('renders link reference definition as empty string', () {
      const linkRef = LinkReferenceDefinitionNode(
        'ref',
        'https://example.com',
        title: 'Title',
      );
      check(linkRef.accept(renderer)).equals('');
    });
  });

  group('links, images and autolinks', () {
    test('renders link with and without title', () {
      const linkNoTitle = LinkNode(TextNode('Dart'), 'https://dart.dev');
      check(linkNoTitle.accept(renderer))
          .equals('<a href="https://dart.dev">Dart</a>');

      const linkWithTitle = LinkNode(
        TextNode('Dart & Flutter'),
        'https://dart.dev?a=1&b=2',
        title: 'The "Official" Site',
      );
      check(linkWithTitle.accept(renderer)).equals(
        '<a href="https://dart.dev?a=1&amp;b=2" title="The &quot;Official&quot; Site">Dart &amp; Flutter</a>',
      );
    });

    test('renders image with and without title', () {
      const imgNoTitle = ImageNode(TextNode('A logo'), 'logo.png');
      check(imgNoTitle.accept(renderer))
          .equals('<img src="logo.png" alt="A logo" />');

      const imgWithTitle = ImageNode(
        CompositeInlineNode([TextNode('Image '), CodeSpanNode('tag')]),
        'pic.png',
        title: 'Hover "Text"',
      );
      check(imgWithTitle.accept(renderer)).equals(
        '<img src="pic.png" alt="Image tag" title="Hover &quot;Text&quot;" />',
      );
    });

    test('renders autolink for url and email', () {
      const webUrl = AutolinkNode('https://dart.dev', isEmail: false);
      check(webUrl.accept(renderer))
          .equals('<a href="https://dart.dev">https://dart.dev</a>');

      const emailUrl = AutolinkNode('support@example.com', isEmail: true);
      check(
        emailUrl.accept(renderer),
      ).equals('<a href="mailto:support@example.com">support@example.com</a>');
    });

    test('renders soft and hard line breaks', () {
      const soft = LineBreakNode(isHard: false);
      check(soft.accept(renderer)).equals('\n');

      const hard = LineBreakNode(isHard: true);
      check(hard.accept(renderer)).equals('<br />\n');
    });
  });

  group('complete document rendering', () {
    test('renders full markdown document joining non-empty blocks', () {
      const doc = DocumentNode([
        HeadingNode(1, TextNode('Title')),
        LinkReferenceDefinitionNode('ref', 'https://example.com'),
        ParagraphNode(TextNode('Hello world.')),
        ThematicBreakNode(),
      ]);
      check(doc.accept(renderer))
          .equals('<h1>Title</h1>\n<p>Hello world.</p>\n<hr />');
    });
  });
}

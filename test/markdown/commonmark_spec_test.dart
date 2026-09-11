import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

void main() {
  group('CommonMark & GFM spec integration tests', () {
    test('ATX headings', () {
      expect(markdownToHtml('# foo'), equals('<h1>foo</h1>'));
      expect(markdownToHtml('## foo'), equals('<h2>foo</h2>'));
      expect(markdownToHtml('### foo'), equals('<h3>foo</h3>'));
      expect(markdownToHtml('#### foo'), equals('<h4>foo</h4>'));
      expect(markdownToHtml('##### foo'), equals('<h5>foo</h5>'));
      expect(markdownToHtml('###### foo'), equals('<h6>foo</h6>'));
      expect(markdownToHtml('# foo #######'), equals('<h1>foo</h1>'));
    });

    test('Thematic breaks', () {
      expect(markdownToHtml('***'), equals('<hr />'));
      expect(markdownToHtml('---'), equals('<hr />'));
      expect(markdownToHtml('___'), equals('<hr />'));
      expect(markdownToHtml('   ***'), equals('<hr />'));
    });

    test('Fenced code blocks', () {
      expect(
        markdownToHtml('```\n<\n >\n```'),
        equals('<pre><code>&lt;\n &gt;\n</code></pre>'),
      );
      expect(
        markdownToHtml('```dart\nprint("hi");\n```'),
        equals(
          '<pre><code class="language-dart">print(&quot;hi&quot;);\n</code></pre>',
        ),
      );
    });

    test('Blockquotes', () {
      expect(
        markdownToHtml('> # Foo\n> bar\n'),
        equals('<blockquote>\n<h1>Foo</h1>\n<p>bar</p>\n</blockquote>'),
      );
    });

    test('Lists', () {
      expect(
        markdownToHtml('- foo\n- bar\n'),
        equals('<ul>\n<li>foo</li>\n<li>bar</li>\n</ul>'),
      );
      expect(
        markdownToHtml('1. foo\n2. bar\n'),
        equals('<ol>\n<li>foo</li>\n<li>bar</li>\n</ol>'),
      );
      expect(
        markdownToHtml('3. foo\n4. bar\n'),
        equals('<ol start="3">\n<li>foo</li>\n<li>bar</li>\n</ol>'),
      );
    });

    test('Code spans', () {
      expect(markdownToHtml('`foo`'), equals('<p><code>foo</code></p>'));
      expect(
        markdownToHtml('`` `foo` ``'),
        equals('<p><code>`foo`</code></p>'),
      );
    });

    test('Emphasis and strong', () {
      expect(markdownToHtml('*foo bar*'), equals('<p><em>foo bar</em></p>'));
      expect(markdownToHtml('_foo bar_'), equals('<p><em>foo bar</em></p>'));
      expect(
        markdownToHtml('**foo bar**'),
        equals('<p><strong>foo bar</strong></p>'),
      );
      expect(
        markdownToHtml('__foo bar__'),
        equals('<p><strong>foo bar</strong></p>'),
      );
      expect(
        markdownToHtml('**foo *bar* baz**'),
        equals('<p><strong>foo <em>bar</em> baz</strong></p>'),
      );
    });

    test('Links and Images', () {
      expect(
        markdownToHtml('[link](/uri "title")'),
        equals('<p><a href="/uri" title="title">link</a></p>'),
      );
      expect(
        markdownToHtml('![foo](/url "title")'),
        equals('<p><img src="/url" alt="foo" title="title" /></p>'),
      );
      expect(
        markdownToHtml('<https://example.com>'),
        equals('<p><a href="https://example.com">https://example.com</a></p>'),
      );
      expect(
        markdownToHtml('<foo@example.com>'),
        equals('<p><a href="mailto:foo@example.com">foo@example.com</a></p>'),
      );
    });

    test('GFM Tables', () {
      const input = '''| foo | bar |
| --- | --- |
| baz | bim |''';
      final html = markdownToHtml(input);
      expect(html, contains('<table>'));
      expect(html, contains('<th>foo</th>'));
      expect(html, contains('<td>baz</td>'));
    });

    test('GFM Strikethrough', () {
      expect(
        markdownToHtml('~~deleted~~'),
        equals('<p><del>deleted</del></p>'),
      );
    });

    test('GFM Task Lists', () {
      const input = '''- [ ] unchecked
- [x] checked''';
      final html = markdownToHtml(input);
      expect(html, contains('<input type="checkbox" disabled="" /> unchecked'));
      expect(
        html,
        contains('<input type="checkbox" checked="" disabled="" /> checked'),
      );
    });
  });
}

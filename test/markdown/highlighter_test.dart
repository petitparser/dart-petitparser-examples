import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

void main() {
  const highlighter = MarkdownHighlighter();

  group('MarkdownHighlighter', () {
    test('highlights ATX headings', () {
      final html = highlighter.highlight('# Heading 1\n## Heading 2');
      expect(
        html,
        contains(
          '<span class="hl-punct"># </span><span class="hl-heading">Heading 1</span>',
        ),
      );
      expect(
        html,
        contains(
          '<span class="hl-punct">## </span><span class="hl-heading">Heading 2</span>',
        ),
      );
    });

    test('highlights fenced code blocks', () {
      final html = highlighter.highlight('```dart\nfinal x = 42;\n```');
      expect(html, contains('<span class="hl-punct">```</span>'));
      expect(html, contains('<span class="hl-info">dart</span>'));
      expect(html, contains('<span class="hl-code">final x = 42;\n</span>'));
    });

    test('highlights inline code spans', () {
      final html = highlighter.highlight('Use `code` here.');
      expect(html, contains('<span class="hl-code">`code`</span>'));
    });

    test('highlights bold, italic, and strikethrough', () {
      final html = highlighter.highlight('**bold** *italic* ~~deleted~~');
      expect(html, contains('<span class="hl-bold">**bold**</span>'));
      expect(html, contains('<span class="hl-italic">*italic*</span>'));
      expect(html, contains('<span class="hl-strike">~~deleted~~</span>'));
    });

    test('highlights links and images', () {
      final html = highlighter.highlight(
        'Visit [Google](https://google.com) and ![logo](logo.png)',
      );
      expect(html, contains('<span class="hl-link">Google</span>'));
      expect(html, contains('<span class="hl-url">https://google.com</span>'));
      expect(html, contains('<span class="hl-link">logo</span>'));
      expect(html, contains('<span class="hl-url">logo.png</span>'));
    });

    test('highlights autolinks', () {
      final html = highlighter.highlight('Check <https://dart.dev>');
      expect(
        html,
        contains('<span class="hl-link">&lt;https://dart.dev&gt;</span>'),
      );
    });

    test('highlights blockquotes', () {
      final html = highlighter.highlight('> quoted text');
      expect(
        html,
        contains('<span class="hl-blockquote">&gt; </span>quoted text'),
      );
    });

    test('highlights bullet lists and task checkboxes', () {
      final html = highlighter.highlight(
        '- [x] completed task\n- [ ] pending task',
      );
      expect(html, contains('<span class="hl-list">- </span>'));
      expect(html, contains('<span class="hl-task">[x]</span>'));
      expect(html, contains('<span class="hl-task">[ ]</span>'));
    });

    test('highlights tables', () {
      final html = highlighter.highlight('| A | B |\n|---|---|');
      expect(html, contains('<span class="hl-table">|</span>'));
    });

    test('escapes HTML special characters', () {
      final html = highlighter.highlight('1 < 2 & 3 > 0');
      expect(html, contains('1 &lt; 2 &amp; 3 &gt; 0'));
    });
  });
}

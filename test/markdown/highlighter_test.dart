import 'package:checks/checks.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

void main() {
  const highlighter = MarkdownHighlighter();

  group('MarkdownHighlighter', () {
    test('highlights ATX headings', () {
      final html = highlighter.highlight('# Heading 1\n## Heading 2');
      check(html).contains(
        '<span class="hl-punct"># </span><span class="hl-heading">Heading 1</span>',
      );
      check(html).contains(
        '<span class="hl-punct">## </span><span class="hl-heading">Heading 2</span>',
      );
    });

    test('highlights fenced code blocks', () {
      final html = highlighter.highlight('```dart\nfinal x = 42;\n```');
      check(html).contains('<span class="hl-punct">```</span>');
      check(html).contains('<span class="hl-info">dart</span>');
      check(html).contains('<span class="hl-code">final x = 42;\n</span>');
    });

    test('highlights inline code spans', () {
      final html = highlighter.highlight('Use `code` here.');
      check(html).contains('<span class="hl-code">`code`</span>');
    });

    test('highlights bold, italic, and strikethrough', () {
      final html = highlighter.highlight('**bold** *italic* ~~deleted~~');
      check(html).contains('<span class="hl-bold">**bold**</span>');
      check(html).contains('<span class="hl-italic">*italic*</span>');
      check(html).contains('<span class="hl-strike">~~deleted~~</span>');
    });

    test('highlights links and images', () {
      final html = highlighter.highlight(
        'Visit [Google](https://google.com) and ![logo](logo.png)',
      );
      check(html).contains('<span class="hl-link">Google</span>');
      check(html).contains('<span class="hl-url">https://google.com</span>');
      check(html).contains('<span class="hl-link">logo</span>');
      check(html).contains('<span class="hl-url">logo.png</span>');
    });

    test(
      'highlights linked badge images with underscores without emphasis',
      () {
        final html = highlighter.highlight(
          '[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)\n'
          '[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)',
        );
        check(html).not((it) => it.contains('hl-italic'));
        check(html)
            .contains('https://img.shields.io/pub/v/petitparser_examples.svg');
        check(html).contains('https://pub.dev/packages/petitparser_examples');
      },
    );

    test('highlights autolinks', () {
      final html = highlighter.highlight('Check <https://dart.dev>');
      check(html)
          .contains('<span class="hl-link">&lt;https://dart.dev&gt;</span>');
    });

    test('highlights blockquotes', () {
      final html = highlighter.highlight('> quoted text');
      check(html)
          .contains('<span class="hl-blockquote">&gt; </span>quoted text');
    });

    test('highlights bullet lists and task checkboxes', () {
      final html = highlighter.highlight(
        '- [x] completed task\n- [ ] pending task',
      );
      check(html).contains('<span class="hl-list">- </span>');
      check(html).contains('<span class="hl-task">[x]</span>');
      check(html).contains('<span class="hl-task">[ ]</span>');
    });

    test('highlights tables', () {
      final html = highlighter.highlight('| A | B |\n|---|---|');
      check(html).contains('<span class="hl-table">|</span>');
    });

    test('escapes HTML special characters', () {
      final html = highlighter.highlight('1 < 2 & 3 > 0');
      check(html).contains('1 &lt; 2 &amp; 3 &gt; 0');
    });
  });
}

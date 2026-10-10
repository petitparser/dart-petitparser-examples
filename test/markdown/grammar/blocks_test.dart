import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  group('block grammar', () {
    test('atxHeading', () {
      final p = grammar.buildFrom(grammar.atxHeading()).end();
      check(p).isSuccess(
        '# Heading 1',
        value: const HeadingNode(1, TextNode('Heading 1')),
      );
      check(p).isSuccess(
        '### Level 3 Heading',
        value: const HeadingNode(3, TextNode('Level 3 Heading')),
      );
      check(p).isSuccess(
        '## Heading with **bold** ##',
        value: const HeadingNode(
          2,
          CompositeInlineNode([
            TextNode('Heading with '),
            StrongNode(TextNode('bold')),
          ]),
        ),
      );
    });

    test('thematicBreak', () {
      final p = grammar.buildFrom(grammar.thematicBreak()).end();
      check(p).isSuccess('---', value: const ThematicBreakNode());
      check(p).isSuccess('***', value: const ThematicBreakNode());
      check(p).isSuccess('___', value: const ThematicBreakNode());
      check(p).isSuccess('- - -', value: const ThematicBreakNode());
      check(p).isSuccess('* * * *', value: const ThematicBreakNode());
      check(p).isFailure('--');
    });

    test('fencedCodeBlock', () {
      final p = grammar.buildFrom(grammar.fencedCodeBlock()).end();
      check(p).isSuccess(
        '```dart\nvoid main() {}\n```',
        value: const FencedCodeBlockNode('void main() {}\n', info: 'dart'),
      );
      check(p).isSuccess(
        '~~~\nraw text\n~~~',
        value: const FencedCodeBlockNode('raw text\n'),
      );
    });

    test('indentedCodeBlock', () {
      final p = grammar.buildFrom(grammar.indentedCodeBlock()).end();
      check(p).isSuccess(
        '    line 1\n    line 2\n',
        value: const IndentedCodeBlockNode('line 1\nline 2\n'),
      );
    });

    test('blockquote', () {
      final p = grammar.buildFrom(grammar.blockquote()).end();
      check(p).isSuccess(
        '> Hello quote\n',
        value: const BlockquoteNode([ParagraphNode(TextNode('Hello quote'))]),
      );
    });

    test('bulletList', () {
      final p = grammar.buildFrom(grammar.bulletList()).end();
      check(p).isSuccess(
        '- Item 1\n- Item 2\n',
        value: const BulletListNode([
          ListItemNode([ParagraphNode(TextNode('Item 1'))], isTask: false),
          ListItemNode([ParagraphNode(TextNode('Item 2'))], isTask: false),
        ]),
      );
      check(p).isSuccess(
        '- [ ] Task 1\n- [x] Task 2\n',
        value: const BulletListNode([
          ListItemNode(
            [ParagraphNode(TextNode('Task 1'))],
            isTask: true,
            isChecked: false,
          ),
          ListItemNode(
            [ParagraphNode(TextNode('Task 2'))],
            isTask: true,
            isChecked: true,
          ),
        ]),
      );
    });

    test('orderedList', () {
      final p = grammar.buildFrom(grammar.orderedList()).end();
      check(p).isSuccess(
        '1. First\n2. Second\n',
        value: const OrderedListNode([
          ListItemNode([ParagraphNode(TextNode('First'))], isTask: false),
          ListItemNode([ParagraphNode(TextNode('Second'))], isTask: false),
        ], startNumber: 1),
      );
    });

    test('table', () {
      final p = grammar.buildFrom(grammar.table()).end();
      const markdown = '''| A | B |
| :--- | ---: |
| 1 | 2 |''';
      check(p).isSuccess(
        markdown,
        value: const TableNode(
          [
            TableRowNode([
              TableCellNode(TextNode('A')),
              TableCellNode(TextNode('B')),
            ], isHeader: true),
            TableRowNode([
              TableCellNode(TextNode('1')),
              TableCellNode(TextNode('2')),
            ], isHeader: false),
          ],
          [TableAlignment.left, TableAlignment.right],
        ),
      );
    });

    test('linkReferenceDefinition', () {
      final p = grammar.buildFrom(grammar.linkReferenceDefinition()).end();
      check(p).isSuccess(
        '[id]: https://example.com "title"',
        value: const LinkReferenceDefinitionNode(
          'id',
          'https://example.com',
          title: 'title',
        ),
      );
    });

    test('paragraph', () {
      final p = grammar.buildFrom(grammar.paragraph()).end();
      check(p).isSuccess(
        'Simple paragraph text.',
        value: const ParagraphNode(TextNode('Simple paragraph text.')),
      );
      check(p).isSuccess(
        'Line 1\nLine 2\nLine 3',
        value: const ParagraphNode(
          CompositeInlineNode([
            TextNode('Line 1'),
            LineBreakNode(isHard: false),
            TextNode('Line 2'),
            LineBreakNode(isHard: false),
            TextNode('Line 3'),
          ]),
        ),
      );
    });
  });
}

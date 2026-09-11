import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  group('block grammar', () {
    test('atxHeading', () {
      final p = grammar.buildFrom(grammar.atxHeading()).end();
      expect(
        p,
        isSuccess(
          '# Heading 1',
          value: const HeadingNode(1, TextNode('Heading 1')),
        ),
      );
      expect(
        p,
        isSuccess(
          '### Level 3 Heading',
          value: const HeadingNode(3, TextNode('Level 3 Heading')),
        ),
      );
      expect(
        p,
        isSuccess(
          '## Heading with **bold** ##',
          value: const HeadingNode(
            2,
            CompositeInlineNode([
              TextNode('Heading with '),
              StrongNode(TextNode('bold')),
            ]),
          ),
        ),
      );
    });

    test('thematicBreak', () {
      final p = grammar.buildFrom(grammar.thematicBreak()).end();
      expect(p, isSuccess('---', value: const ThematicBreakNode()));
      expect(p, isSuccess('***', value: const ThematicBreakNode()));
      expect(p, isSuccess('___', value: const ThematicBreakNode()));
      expect(p, isSuccess('- - -', value: const ThematicBreakNode()));
      expect(p, isSuccess('* * * *', value: const ThematicBreakNode()));
      expect(p, isFailure('--'));
    });

    test('fencedCodeBlock', () {
      final p = grammar.buildFrom(grammar.fencedCodeBlock()).end();
      expect(
        p,
        isSuccess(
          '```dart\nvoid main() {}\n```',
          value: const FencedCodeBlockNode('void main() {}\n', info: 'dart'),
        ),
      );
      expect(
        p,
        isSuccess(
          '~~~\nraw text\n~~~',
          value: const FencedCodeBlockNode('raw text\n'),
        ),
      );
    });

    test('indentedCodeBlock', () {
      final p = grammar.buildFrom(grammar.indentedCodeBlock()).end();
      expect(
        p,
        isSuccess(
          '    line 1\n    line 2\n',
          value: const IndentedCodeBlockNode('line 1\nline 2\n'),
        ),
      );
    });

    test('blockquote', () {
      final p = grammar.buildFrom(grammar.blockquote()).end();
      expect(
        p,
        isSuccess(
          '> Hello quote\n',
          value: const BlockquoteNode([ParagraphNode(TextNode('Hello quote'))]),
        ),
      );
    });

    test('bulletList', () {
      final p = grammar.buildFrom(grammar.bulletList()).end();
      expect(
        p,
        isSuccess(
          '- Item 1\n- Item 2\n',
          value: const BulletListNode([
            ListItemNode([ParagraphNode(TextNode('Item 1'))], isTask: false),
            ListItemNode([ParagraphNode(TextNode('Item 2'))], isTask: false),
          ]),
        ),
      );
      expect(
        p,
        isSuccess(
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
        ),
      );
    });

    test('orderedList', () {
      final p = grammar.buildFrom(grammar.orderedList()).end();
      expect(
        p,
        isSuccess(
          '1. First\n2. Second\n',
          value: const OrderedListNode([
            ListItemNode([ParagraphNode(TextNode('First'))], isTask: false),
            ListItemNode([ParagraphNode(TextNode('Second'))], isTask: false),
          ], startNumber: 1),
        ),
      );
    });

    test('table', () {
      final p = grammar.buildFrom(grammar.table()).end();
      const markdown = '''| A | B |
| :--- | ---: |
| 1 | 2 |''';
      expect(
        p,
        isSuccess(
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
        ),
      );
    });

    test('linkReferenceDefinition', () {
      final p = grammar.buildFrom(grammar.linkReferenceDefinition()).end();
      expect(
        p,
        isSuccess(
          '[id]: https://example.com "title"',
          value: const LinkReferenceDefinitionNode(
            'id',
            'https://example.com',
            title: 'title',
          ),
        ),
      );
    });

    test('paragraph', () {
      final p = grammar.buildFrom(grammar.paragraph()).end();
      expect(
        p,
        isSuccess(
          'Simple paragraph text.',
          value: const ParagraphNode(TextNode('Simple paragraph text.')),
        ),
      );
      expect(
        p,
        isSuccess(
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
        ),
      );
    });
  });
}

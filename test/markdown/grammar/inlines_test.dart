import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  group('inline grammar', () {
    test('codeSpan', () {
      final p = grammar.buildFrom(grammar.codeSpan()).end();
      expect(p, isSuccess('`foo`', value: const CodeSpanNode('foo')));
      expect(
        p,
        isSuccess('``foo ` bar``', value: const CodeSpanNode('foo ` bar')),
      );
      expect(p, isSuccess('` foo `', value: const CodeSpanNode('foo')));
      expect(p, isFailure('`foo'));
    });

    test('autolink', () {
      final p = grammar.buildFrom(grammar.autolink()).end();
      expect(
        p,
        isSuccess(
          '<https://example.com/test>',
          value: const AutolinkNode('https://example.com/test', isEmail: false),
        ),
      );
      expect(
        p,
        isSuccess(
          '<user@example.com>',
          value: const AutolinkNode('user@example.com', isEmail: true),
        ),
      );
      expect(p, isFailure('<not a link>'));
    });

    test('directLink', () {
      final p = grammar.buildFrom(grammar.directLink()).end();
      expect(
        p,
        isSuccess(
          '[example](https://example.com)',
          value: const LinkNode(TextNode('example'), 'https://example.com'),
        ),
      );
      expect(
        p,
        isSuccess(
          '[example](https://example.com "My Title")',
          value: const LinkNode(
            TextNode('example'),
            'https://example.com',
            title: 'My Title',
          ),
        ),
      );
      expect(
        p,
        isSuccess(
          '[**bold**](https://example.com)',
          value: const LinkNode(
            StrongNode(TextNode('bold')),
            'https://example.com',
          ),
        ),
      );
      expect(
        p,
        isSuccess(
          '[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)',
          value: const LinkNode(
            ImageNode(
              TextNode('Pub Package'),
              'https://img.shields.io/pub/v/petitparser_examples.svg',
            ),
            'https://pub.dev/packages/petitparser_examples',
          ),
        ),
      );
    });

    test('directImage', () {
      final p = grammar.buildFrom(grammar.directImage()).end();
      expect(
        p,
        isSuccess(
          '![alt text](/img.png)',
          value: const ImageNode(TextNode('alt text'), '/img.png'),
        ),
      );
      expect(
        p,
        isSuccess(
          '![alt text](/img.png "Image Title")',
          value: const ImageNode(
            TextNode('alt text'),
            '/img.png',
            title: 'Image Title',
          ),
        ),
      );
    });

    test('strong', () {
      final p = grammar.buildFrom(grammar.strong()).end();
      expect(
        p,
        isSuccess(
          '**bold text**',
          value: const StrongNode(TextNode('bold text')),
        ),
      );
      expect(
        p,
        isSuccess(
          '__bold text__',
          value: const StrongNode(TextNode('bold text')),
        ),
      );
      expect(
        p,
        isSuccess(
          '**bold *and italic***',
          value: const StrongNode(
            CompositeInlineNode([
              TextNode('bold '),
              EmphasisNode(TextNode('and italic')),
            ]),
          ),
        ),
      );
    });

    test('emphasis', () {
      final p = grammar.buildFrom(grammar.emphasis()).end();
      expect(
        p,
        isSuccess('*italic*', value: const EmphasisNode(TextNode('italic'))),
      );
      expect(
        p,
        isSuccess('_italic_', value: const EmphasisNode(TextNode('italic'))),
      );
    });

    test('strikethrough', () {
      final p = grammar.buildFrom(grammar.strikethrough()).end();
      expect(
        p,
        isSuccess(
          '~~deleted~~',
          value: const StrikethroughNode(TextNode('deleted')),
        ),
      );
    });

    test('inlines composite sequence', () {
      final p = grammar.buildFrom(grammar.inlines()).end();
      expect(
        p,
        isSuccess(
          'Hello **world**!',
          value: const CompositeInlineNode([
            TextNode('Hello '),
            StrongNode(TextNode('world')),
            TextNode('!'),
          ]),
        ),
      );
      expect(
        p,
        isSuccess(
          'See `code` and *italic*',
          value: const CompositeInlineNode([
            TextNode('See '),
            CodeSpanNode('code'),
            TextNode(' and '),
            EmphasisNode(TextNode('italic')),
          ]),
        ),
      );
    });
  });
}

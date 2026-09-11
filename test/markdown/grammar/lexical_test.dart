import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  group('lexical grammar', () {
    test('newlineSequence', () {
      final p = grammar.buildFrom(grammar.newlineSequence()).end();
      expect(p, isSuccess('\n', value: '\n'));
      expect(p, isSuccess('\r\n', value: '\r\n'));
      expect(p, isSuccess('\r', value: '\r'));
      expect(p, isFailure(' '));
    });

    test('nonIndentSpace', () {
      final p = grammar.buildFrom(grammar.nonIndentSpace()).end();
      expect(p, isSuccess('', value: ''));
      expect(p, isSuccess(' ', value: ' '));
      expect(p, isSuccess('  ', value: '  '));
      expect(p, isSuccess('   ', value: '   '));
      expect(p, isFailure('    '));
    });

    test('indent', () {
      final p = grammar.buildFrom(grammar.indent()).end();
      expect(p, isSuccess('    ', value: '    '));
      expect(p, isSuccess('\t', value: '\t'));
      expect(p, isFailure('   '));
    });

    test('escapedChar', () {
      final p = grammar.buildFrom(grammar.escapedChar()).end();
      expect(p, isSuccess(r'\*', value: '*'));
      expect(p, isSuccess(r'\_', value: '_'));
      expect(p, isSuccess(r'\[', value: '['));
      expect(p, isSuccess(r'\]', value: ']'));
      expect(p, isSuccess(r'\`', value: '`'));
      expect(p, isSuccess(r'\\', value: r'\'));
      expect(p, isFailure(r'\a'));
    });

    test('blankLine', () {
      final p = grammar.buildFrom(grammar.blankLine()).end();
      expect(p, isSuccess('\n'));
      expect(p, isSuccess('   \n'));
      expect(p, isSuccess('\t\r\n'));
      expect(p, isFailure('foo\n'));
    });

    test('htmlEntity', () {
      final p = grammar.buildFrom(grammar.htmlEntity()).end();
      expect(p, isSuccess('&amp;', value: '&amp;'));
      expect(p, isSuccess('&lt;', value: '&lt;'));
      expect(p, isSuccess('&gt;', value: '&gt;'));
      expect(p, isSuccess('&#160;', value: '&#160;'));
      expect(p, isSuccess('&#xA0;', value: '&#xA0;'));
      expect(p, isFailure('&amp'));
    });
  });
}

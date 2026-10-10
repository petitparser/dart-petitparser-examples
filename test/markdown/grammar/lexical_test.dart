import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  group('lexical grammar', () {
    test('newlineSequence', () {
      final p = grammar.buildFrom(grammar.newlineSequence()).end();
      check(p).isSuccess('\n', value: '\n');
      check(p).isSuccess('\r\n', value: '\r\n');
      check(p).isSuccess('\r', value: '\r');
      check(p).isFailure(' ');
    });

    test('nonIndentSpace', () {
      final p = grammar.buildFrom(grammar.nonIndentSpace()).end();
      check(p).isSuccess('', value: '');
      check(p).isSuccess(' ', value: ' ');
      check(p).isSuccess('  ', value: '  ');
      check(p).isSuccess('   ', value: '   ');
      check(p).isFailure('    ');
    });

    test('indent', () {
      final p = grammar.buildFrom(grammar.indent()).end();
      check(p).isSuccess('    ', value: '    ');
      check(p).isSuccess('\t', value: '\t');
      check(p).isFailure('   ');
    });

    test('escapedChar', () {
      final p = grammar.buildFrom(grammar.escapedChar()).end();
      check(p).isSuccess(r'\*', value: '*');
      check(p).isSuccess(r'\_', value: '_');
      check(p).isSuccess(r'\[', value: '[');
      check(p).isSuccess(r'\]', value: ']');
      check(p).isSuccess(r'\`', value: '`');
      check(p).isSuccess(r'\\', value: r'\');
      check(p).isFailure(r'\a');
    });

    test('blankLine', () {
      final p = grammar.buildFrom(grammar.blankLine()).end();
      check(p).isSuccess('\n');
      check(p).isSuccess('   \n');
      check(p).isSuccess('\t\r\n');
      check(p).isFailure('foo\n');
    });

    test('htmlEntity', () {
      final p = grammar.buildFrom(grammar.htmlEntity()).end();
      check(p).isSuccess('&amp;', value: '&amp;');
      check(p).isSuccess('&lt;', value: '&lt;');
      check(p).isSuccess('&gt;', value: '&gt;');
      check(p).isSuccess('&#160;', value: '&#160;');
      check(p).isSuccess('&#xA0;', value: '&#xA0;');
      check(p).isFailure('&amp');
    });
  });
}

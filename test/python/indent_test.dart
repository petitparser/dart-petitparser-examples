import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/src/python/indent.dart';
import 'package:test/test.dart';

import '../utils/expect.dart';

class SimpleIndentTestGrammar extends GrammarDefinition {
  final indent = PythonIndent();

  @override
  Parser start() => ref0(block).end();

  Parser block() => seq3(
    string('header:'),
    ref0(newline),
    indent.guard(ref0(items)),
  ).map3((_, _, items) => items);

  Parser items() => ref0(item).plus();

  Parser item() => seq3(
    ref0(blankLines),
    indent.same,
    seq2(string('item'), ref0(newline).optional()),
  ).map3((_, _, val) => val.$1);

  Parser blankLines() => indent.blankOrComment.star();

  Parser newline() => Token.newlineParser();
}

void main() {
  group('PythonIndent', () {
    final grammar = SimpleIndentTestGrammar();
    final parser = grammar.build();

    tearDown(() {
      grammar.indent.stack.clear();
      grammar.indent.current = '';
    });

    test('simple indentation', () {
      expect(
        parser,
        isSuccess('header:\n  item\n  item\n', value: ['item', 'item']),
      );
    });

    test('blank lines and comment lines within indentation', () {
      expect(
        parser,
        isSuccess(
          'header:\n  item\n\n  # comment\n  item\n',
          value: ['item', 'item'],
        ),
      );
    });

    test('different indentation levels fail', () {
      expect(parser, isFailure('header:\n  item\n    item\n'));
    });
  });
}

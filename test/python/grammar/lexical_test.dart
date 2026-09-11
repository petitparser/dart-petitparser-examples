import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = PythonGrammarDefinition();

  group('whitespace and comments', () {
    final whitespaceParser = grammar
        .buildFrom(grammar.hiddenWhitespace())
        .end();

    test('inline whitespace', () {
      expect(whitespaceParser, isSuccess(' '));
      expect(whitespaceParser, isSuccess('\t'));
      expect(whitespaceParser, isSuccess('   \t  '));
    });

    test('comment', () {
      expect(whitespaceParser, isSuccess('# simple comment'));
      expect(whitespaceParser, isSuccess('#'));
      expect(whitespaceParser, isSuccess('   # spaced comment'));
    });

    test('explicit line continuation', () {
      expect(whitespaceParser, isSuccess('\\\n'));
      expect(whitespaceParser, isSuccess('\\\r\n'));
    });

    test('blank lines', () {
      final blankLinesParser = grammar.buildFrom(grammar.blankLines()).end();
      expect(blankLinesParser, isSuccess(''));
      expect(blankLinesParser, isSuccess('\n'));
      expect(blankLinesParser, isSuccess('  \n\n  # comment\n'));
    });

    test('ignore tracks bracket nesting', () {
      final whitespaceWithIgnore = grammar.buildFrom(
        grammar.ignore(grammar.hiddenWhitespace()),
      );
      // Newlines are accepted as hidden whitespace inside ignore:
      expect(whitespaceWithIgnore, isSuccess('\n'));
      expect(whitespaceWithIgnore, isSuccess('  \n\t  '));
    });
  });

  group('identifiers', () {
    final idParser = grammar.buildFrom(grammar.identifier()).end();

    test('valid identifiers', () {
      expect(idParser, isSuccess('a'));
      expect(idParser, isSuccess('z'));
      expect(idParser, isSuccess('A'));
      expect(idParser, isSuccess('Z'));
      expect(idParser, isSuccess('_'));
      expect(idParser, isSuccess('__'));
      expect(idParser, isSuccess('__init__'));
      expect(idParser, isSuccess('foo_bar'));
      expect(idParser, isSuccess('var123'));
    });

    test('identifiers with keyword prefixes', () {
      expect(idParser, isSuccess('is_active'));
      expect(idParser, isSuccess('if_condition'));
      expect(idParser, isSuccess('for_loop'));
      expect(idParser, isSuccess('class_name'));
      expect(idParser, isSuccess('def_val'));
    });

    test('reserved keywords rejected as identifiers', () {
      expect(idParser, isFailure('def'));
      expect(idParser, isFailure('class'));
      expect(idParser, isFailure('return'));
      expect(idParser, isFailure('if'));
      expect(idParser, isFailure('elif'));
      expect(idParser, isFailure('else'));
      expect(idParser, isFailure('True'));
      expect(idParser, isFailure('False'));
      expect(idParser, isFailure('None'));
    });

    test('soft keywords allowed as identifiers', () {
      expect(idParser, isSuccess('match'));
      expect(idParser, isSuccess('case'));
      expect(idParser, isSuccess('type'));
    });
  });

  group('numbers', () {
    final numParser = grammar.buildFrom(grammar.numberLiteral()).end();

    test('integers', () {
      expect(numParser, isSuccess('0'));
      expect(numParser, isSuccess('42'));
      expect(numParser, isSuccess('1_000_000'));
    });

    test('hex, octal, binary', () {
      expect(numParser, isSuccess('0x1f'));
      expect(numParser, isSuccess('0XFF_AA'));
      expect(numParser, isSuccess('0o777'));
      expect(numParser, isSuccess('0O755'));
      expect(numParser, isSuccess('0b1010'));
      expect(numParser, isSuccess('0B11_00'));
    });

    test('floats', () {
      expect(numParser, isSuccess('3.14'));
      expect(numParser, isSuccess('.5'));
      expect(numParser, isSuccess('1e-5'));
      expect(numParser, isSuccess('2.5e+3'));
      expect(numParser, isSuccess('1_000.500_1'));
    });

    test('complex numbers', () {
      expect(numParser, isSuccess('3j'));
      expect(numParser, isSuccess('4.5J'));
    });
  });

  group('strings', () {
    final strParser = grammar.buildFrom(grammar.stringLiteral()).end();

    test('single and double quotes', () {
      expect(strParser, isSuccess("'hello'"));
      expect(strParser, isSuccess('"world"'));
      expect(strParser, isSuccess(r"'hello\nworld'"));
    });

    test('triple quotes', () {
      expect(strParser, isSuccess("'''hello\nworld'''"));
      expect(strParser, isSuccess('"""multi\nline"""'));
    });

    test('raw and byte string prefixes', () {
      expect(strParser, isSuccess(r"r'hello\n'"));
      expect(strParser, isSuccess(r"b'bytes'"));
      expect(strParser, isSuccess(r'u"unicode"'));
      expect(strParser, isSuccess(r'R"raw"'));
      expect(strParser, isSuccess(r'B"BYTES"'));
      expect(strParser, isSuccess(r'U"unicode"'));
    });

    test('raw byte string two-char prefixes', () {
      expect(strParser, isSuccess(r"rb'raw bytes'"));
      expect(strParser, isSuccess(r'rb"raw bytes"'));
      expect(strParser, isSuccess(r"br'raw bytes'"));
      expect(strParser, isSuccess(r'br"raw bytes"'));
      expect(strParser, isSuccess(r'RB"RAW BYTES"'));
      expect(strParser, isSuccess(r'BR"RAW BYTES"'));
      expect(strParser, isSuccess(r'Rb"mixed case"'));
      expect(strParser, isSuccess(r'bR"mixed case"'));
      expect(strParser, isSuccess(r'rB"mixed case"'));
      expect(strParser, isSuccess(r'Br"mixed case"'));
    });

    test('string concatenation', () {
      expect(strParser, isSuccess("'hello ' 'world'"));
    });
  });

  group('f-strings', () {
    final fStrParser = grammar.buildFrom(grammar.stringLiteral()).end();

    test('simple f-string', () {
      expect(fStrParser, isSuccess('f"hello {name}"'));
      expect(fStrParser, isSuccess("f'count: {1 + 2}'"));
    });

    test('f-string with format specifier', () {
      expect(fStrParser, isSuccess('f"{pi:.2f}"'));
    });

    test('f-string with conversion', () {
      expect(fStrParser, isSuccess('f"{val!r}"'));
      expect(fStrParser, isSuccess('f"{val!s}"'));
      expect(fStrParser, isSuccess('f"{val!a}"'));
    });

    test('f-string escaped braces', () {
      expect(fStrParser, isSuccess('f"{{literal}}"'));
    });
  });
}

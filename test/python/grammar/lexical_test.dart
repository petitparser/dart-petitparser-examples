import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = PythonGrammarDefinition();

  group('whitespace and comments', () {
    final whitespaceParser = grammar
        .buildFrom(grammar.hiddenWhitespace())
        .end();

    test('inline whitespace', () {
      check(whitespaceParser).isSuccess(' ');
      check(whitespaceParser).isSuccess('\t');
      check(whitespaceParser).isSuccess('   \t  ');
    });

    test('comment', () {
      check(whitespaceParser).isSuccess('# simple comment');
      check(whitespaceParser).isSuccess('#');
      check(whitespaceParser).isSuccess('   # spaced comment');
    });

    test('explicit line continuation', () {
      check(whitespaceParser).isSuccess('\\\n');
      check(whitespaceParser).isSuccess('\\\r\n');
    });

    test('blank lines', () {
      final blankLinesParser = grammar.buildFrom(grammar.blankLines()).end();
      check(blankLinesParser).isSuccess('');
      check(blankLinesParser).isSuccess('\n');
      check(blankLinesParser).isSuccess('  \n\n  # comment\n');
    });

    test('ignore tracks bracket nesting', () {
      final whitespaceWithIgnore = grammar.buildFrom(
        grammar.ignore(grammar.hiddenWhitespace()),
      );
      // Newlines are accepted as hidden whitespace inside ignore:
      check(whitespaceWithIgnore).isSuccess('\n');
      check(whitespaceWithIgnore).isSuccess('  \n\t  ');
    });
  });

  group('identifiers', () {
    final idParser = grammar.buildFrom(grammar.identifier()).end();

    test('valid identifiers', () {
      check(idParser).isSuccess('a');
      check(idParser).isSuccess('z');
      check(idParser).isSuccess('A');
      check(idParser).isSuccess('Z');
      check(idParser).isSuccess('_');
      check(idParser).isSuccess('__');
      check(idParser).isSuccess('__init__');
      check(idParser).isSuccess('foo_bar');
      check(idParser).isSuccess('var123');
    });

    test('identifiers with keyword prefixes', () {
      check(idParser).isSuccess('is_active');
      check(idParser).isSuccess('if_condition');
      check(idParser).isSuccess('for_loop');
      check(idParser).isSuccess('class_name');
      check(idParser).isSuccess('def_val');
    });

    test('reserved keywords rejected as identifiers', () {
      check(idParser).isFailure('def');
      check(idParser).isFailure('class');
      check(idParser).isFailure('return');
      check(idParser).isFailure('if');
      check(idParser).isFailure('elif');
      check(idParser).isFailure('else');
      check(idParser).isFailure('True');
      check(idParser).isFailure('False');
      check(idParser).isFailure('None');
    });

    test('soft keywords allowed as identifiers', () {
      check(idParser).isSuccess('match');
      check(idParser).isSuccess('case');
      check(idParser).isSuccess('type');
    });
  });

  group('numbers', () {
    final numParser = grammar.buildFrom(grammar.numberLiteral()).end();

    test('integers', () {
      check(numParser).isSuccess('0');
      check(numParser).isSuccess('42');
      check(numParser).isSuccess('1_000_000');
    });

    test('hex, octal, binary', () {
      check(numParser).isSuccess('0x1f');
      check(numParser).isSuccess('0XFF_AA');
      check(numParser).isSuccess('0o777');
      check(numParser).isSuccess('0O755');
      check(numParser).isSuccess('0b1010');
      check(numParser).isSuccess('0B11_00');
    });

    test('floats', () {
      check(numParser).isSuccess('3.14');
      check(numParser).isSuccess('.5');
      check(numParser).isSuccess('1e-5');
      check(numParser).isSuccess('2.5e+3');
      check(numParser).isSuccess('1_000.500_1');
    });

    test('complex numbers', () {
      check(numParser).isSuccess('3j');
      check(numParser).isSuccess('4.5J');
    });
  });

  group('strings', () {
    final strParser = grammar.buildFrom(grammar.stringLiteral()).end();

    test('single and double quotes', () {
      check(strParser).isSuccess("'hello'");
      check(strParser).isSuccess('"world"');
      check(strParser).isSuccess(r"'hello\nworld'");
    });

    test('triple quotes', () {
      check(strParser).isSuccess("'''hello\nworld'''");
      check(strParser).isSuccess('"""multi\nline"""');
    });

    test('raw and byte string prefixes', () {
      check(strParser).isSuccess(r"r'hello\n'");
      check(strParser).isSuccess(r"b'bytes'");
      check(strParser).isSuccess(r'u"unicode"');
      check(strParser).isSuccess(r'R"raw"');
      check(strParser).isSuccess(r'B"BYTES"');
      check(strParser).isSuccess(r'U"unicode"');
    });

    test('raw byte string two-char prefixes', () {
      check(strParser).isSuccess(r"rb'raw bytes'");
      check(strParser).isSuccess(r'rb"raw bytes"');
      check(strParser).isSuccess(r"br'raw bytes'");
      check(strParser).isSuccess(r'br"raw bytes"');
      check(strParser).isSuccess(r'RB"RAW BYTES"');
      check(strParser).isSuccess(r'BR"RAW BYTES"');
      check(strParser).isSuccess(r'Rb"mixed case"');
      check(strParser).isSuccess(r'bR"mixed case"');
      check(strParser).isSuccess(r'rB"mixed case"');
      check(strParser).isSuccess(r'Br"mixed case"');
    });

    test('string concatenation', () {
      check(strParser).isSuccess("'hello ' 'world'");
    });

    test('f-string concatenation with strings', () {
      check(strParser).isSuccess(
        '"hello " f"{name}"',
        value: (Subject it) {
          it
              .isA<JoinedStrNode>()
              .has((node) => node.values, 'values')
              .length
              .equals(2);
        },
      );
      check(strParser).isSuccess(
        'f"{a} " "middle " f"{b}"',
        value: (Subject it) {
          it
              .isA<JoinedStrNode>()
              .has((node) => node.values, 'values')
              .length
              .equals(4);
        },
      );
    });
  });

  group('f-strings', () {
    final fStrParser = grammar.buildFrom(grammar.stringLiteral()).end();

    test('simple f-string', () {
      check(fStrParser).isSuccess('f"hello {name}"');
      check(fStrParser).isSuccess("f'count: {1 + 2}'");
    });

    test('constant-only f-string produces ConstantNode', () {
      check(fStrParser).isSuccess(
        'f"simple text"',
        value: (Subject it) {
          it
              .isA<ConstantNode>()
              .has((node) => node.value, 'value')
              .equals('simple text');
        },
      );
    });

    test('f-string with format specifier', () {
      check(fStrParser).isSuccess('f"{pi:.2f}"');
    });

    test('f-string with conversion', () {
      check(fStrParser).isSuccess('f"{val!r}"');
      check(fStrParser).isSuccess('f"{val!s}"');
      check(fStrParser).isSuccess('f"{val!a}"');
    });

    test('f-string escaped braces', () {
      check(fStrParser).isSuccess('f"{{literal}}"');
    });
  });
}

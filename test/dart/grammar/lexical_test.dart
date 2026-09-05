import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();

  group('whitespace and comments', () {
    final whitespaceParser = grammar
        .buildFrom(grammar.hiddenWhitespace())
        .end();

    test('simple whitespace', () {
      expect(whitespaceParser, isSuccess(' '));
      expect(whitespaceParser, isSuccess('\t'));
      expect(whitespaceParser, isSuccess('\n'));
      expect(whitespaceParser, isSuccess('\r\n'));
      expect(whitespaceParser, isSuccess('   \t\r\n  '));
    });

    test('single line comment', () {
      expect(whitespaceParser, isSuccess('// simple\n'));
      expect(whitespaceParser, isSuccess('/// doc comment\n'));
      expect(whitespaceParser, isSuccess('//\n'));
    });

    test('multi line comment', () {
      expect(whitespaceParser, isSuccess('/* simple */'));
      expect(whitespaceParser, isSuccess('/** doc */'));
      expect(whitespaceParser, isSuccess('/* multi\nline */'));
      expect(whitespaceParser, isSuccess('/* outer /* inner */ */'));
      expect(
        whitespaceParser,
        isSuccess('/* outer /* middle /* inner */ */ end */'),
      );
    });

    test('mixed whitespace and comments', () {
      expect(whitespaceParser, isSuccess('  // comment\n  /* block */ \t\n'));
    });

    test('invalid comment', () {
      expect(whitespaceParser, isFailure('/* unclosed'));
      expect(whitespaceParser, isFailure('/* unclosed /* inner */'));
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
      expect(idParser, isSuccess(r'$'));
      expect(idParser, isSuccess(r'$foo'));
      expect(idParser, isSuccess(r'foo$bar'));
      expect(idParser, isSuccess('camelCase'));
      expect(idParser, isSuccess('PascalCase'));
      expect(idParser, isSuccess('snake_case'));
      expect(idParser, isSuccess('_private'));
      expect(idParser, isSuccess('ident123'));
    });

    test('identifiers starting with keyword prefixes', () {
      expect(idParser, isSuccess('nullLiteral'));
      expect(idParser, isSuccess('variable'));
      expect(idParser, isSuccess('finallyDone'));
      expect(idParser, isSuccess('classNames'));
      expect(idParser, isSuccess('assertValid'));
      expect(idParser, isSuccess('defaultSettings'));
      expect(idParser, isSuccess('importPath'));
      expect(idParser, isSuccess('isDone'));
      expect(idParser, isSuccess('asString'));
    });

    test('reserved keywords rejected as identifiers', () {
      expect(idParser, isFailure('class'));
      expect(idParser, isFailure('var'));
      expect(idParser, isFailure('final'));
      expect(idParser, isFailure('void'));
      expect(idParser, isFailure('null'));
      expect(idParser, isFailure('true'));
      expect(idParser, isFailure('false'));
      expect(idParser, isFailure('if'));
      expect(idParser, isFailure('else'));
      expect(idParser, isFailure('return'));
    });

    test('invalid identifier starts', () {
      expect(idParser, isFailure('123'));
      expect(idParser, isFailure('1abc'));
      expect(idParser, isFailure('@foo'));
      expect(idParser, isFailure('#foo'));
    });
  });

  group('numeric literals', () {
    final numParser = grammar.buildFrom(grammar.numericLiteral()).end();

    test('integer decimals', () {
      expect(numParser, isSuccess('0'));
      expect(numParser, isSuccess('1'));
      expect(numParser, isSuccess('42'));
      expect(numParser, isSuccess('1000000'));
      expect(numParser, isSuccess('1_000_000'));
      expect(numParser, isSuccess('12_34_56'));
    });

    test('hexadecimal integers', () {
      expect(numParser, isSuccess('0x0'));
      expect(numParser, isSuccess('0x123'));
      expect(numParser, isSuccess('0xCAFE'));
      expect(numParser, isSuccess('0xcafe'));
      expect(numParser, isSuccess('0XDEAD_BEEF'));
      expect(numParser, isFailure('0x'));
      expect(numParser, isFailure('0xGHI'));
    });

    test('doubles', () {
      expect(numParser, isSuccess('0.0'));
      expect(numParser, isSuccess('3.14159'));
      expect(numParser, isSuccess('1_000.50_001'));
      expect(numParser, isSuccess('.5'));
      expect(numParser, isSuccess('.1234'));
      expect(numParser, isSuccess('1e5'));
      expect(numParser, isSuccess('1E5'));
      expect(numParser, isSuccess('1.2e3'));
      expect(numParser, isSuccess('1.2E-3'));
      expect(numParser, isSuccess('.5e+2'));
    });
  });

  group('boolean and null literals', () {
    final lit = grammar.buildFrom(grammar.literal()).end();

    test('boolean', () {
      expect(lit, isSuccess('true'));
      expect(lit, isSuccess('false'));
    });

    test('null', () {
      expect(lit, isSuccess('null'));
    });
  });

  group('symbol literals', () {
    final sym = grammar.buildFrom(grammar.symbolLiteral()).end();

    test('identifier symbols', () {
      expect(sym, isSuccess('#foo'));
      expect(sym, isSuccess('#_bar'));
      expect(sym, isSuccess(r'#$baz'));
      expect(sym, isSuccess('#camelCase'));
    });

    test('operator symbols', () {
      expect(sym, isSuccess('#+'));
      expect(sym, isSuccess('#-'));
      expect(sym, isSuccess('#*'));
      expect(sym, isSuccess('#/'));
      expect(sym, isSuccess('#~/'));
      expect(sym, isSuccess('#%'));
      expect(sym, isSuccess('#=='));
      expect(sym, isSuccess('#[]'));
      expect(sym, isSuccess('#[]='));
      expect(sym, isSuccess('#<'));
      expect(sym, isSuccess('#<='));
      expect(sym, isSuccess('#>'));
      expect(sym, isSuccess('#>='));
      expect(sym, isSuccess('#&'));
      expect(sym, isSuccess('#|'));
      expect(sym, isSuccess('#^'));
      expect(sym, isSuccess('#~'));
      expect(sym, isSuccess('#<<'));
      expect(sym, isSuccess('#>>'));
      expect(sym, isSuccess('#>>>'));
    });

    test('invalid symbols', () {
      expect(sym, isFailure('#'));
      expect(sym, isFailure('#123'));
    });
  });

  group('string literals', () {
    final str = grammar.buildFrom(grammar.stringLiteral()).end();

    test('single-line single-quoted', () {
      expect(str, isSuccess("''"));
      expect(str, isSuccess("'hello'"));
      expect(str, isSuccess("'hello world'"));
      expect(str, isSuccess(r"'escaped \' quote'"));
      expect(str, isSuccess(r"'newline \n test'"));
      expect(str, isSuccess(r"'\\'"));
      expect(str, isSuccess(r"'a\\b'"));
    });

    test('single-line double-quoted', () {
      expect(str, isSuccess('""'));
      expect(str, isSuccess('"hello"'));
      expect(str, isSuccess('"hello world"'));
      expect(str, isSuccess(r'"escaped \" quote"'));
      expect(str, isSuccess(r'"\\"'));
      expect(str, isSuccess(r'"a\\b"'));
    });

    test('multi-line strings', () {
      expect(str, isSuccess("''''''"));
      expect(str, isSuccess('""""""'));
      expect(str, isSuccess("'''first line\nsecond line'''"));
      expect(str, isSuccess('"""multi\r\nline\r\nstring"""'));
    });

    test('raw strings', () {
      expect(str, isSuccess("r'raw'"));
      expect(str, isSuccess('r"raw"'));
      expect(str, isSuccess(r"r'no \n escape'"));
      expect(str, isSuccess(r'r"no \t escape"'));
      expect(str, isSuccess(r"r'no $interp'"));
      expect(str, isSuccess("r'''raw multi'''"));
      expect(str, isSuccess('r"""raw multi"""'));
    });

    test('string interpolation', () {
      expect(str, isSuccess(r'"$name"'));
      expect(str, isSuccess(r'"hello $name"'));
      expect(str, isSuccess(r'"${1 + 2}"'));
      expect(str, isSuccess(r'"prefix ${user.name} suffix"'));
      expect(str, isSuccess(r"'$a and $b'"));
      expect(str, isSuccess(r"'nested ${1 + int.parse('2')}'"));
      expect(str, isSuccess(r'"price is $50"'));
      expect(str, isSuccess("'''\n\${1 + 2}\n'''"));
      expect(str, isSuccess('"""\n\${foo.bar}\n"""'));
      expect(str, isSuccess("'''cost is \$50 and \${count} items'''"));
      expect(str, isSuccess('"""he said "hi" and \$name answered"""'));
      expect(str, isSuccess("'''it's working and \$name answered'''"));
      expect(
        str,
        isSuccess("'''\n\${list.map((e) => '''<tr>\${e}</tr>''').join()}\n'''"),
      );
    });

    test('adjacent strings', () {
      expect(str, isSuccess("'hello ' 'world'"));
      expect(str, isSuccess('"a" "b" "c"'));
      expect(str, isSuccess(r"'hello ' '$name'"));
    });
  });
}

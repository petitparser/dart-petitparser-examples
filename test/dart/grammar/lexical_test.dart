import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();

  group('whitespace and comments', () {
    final whitespaceParser = grammar
        .buildFrom(grammar.hiddenWhitespace())
        .end();

    test('simple whitespace', () {
      check(whitespaceParser).isSuccess(' ');
      check(whitespaceParser).isSuccess('\t');
      check(whitespaceParser).isSuccess('\n');
      check(whitespaceParser).isSuccess('\r\n');
      check(whitespaceParser).isSuccess('   \t\r\n  ');
    });

    test('single line comment', () {
      check(whitespaceParser).isSuccess('// simple\n');
      check(whitespaceParser).isSuccess('/// doc comment\n');
      check(whitespaceParser).isSuccess('//\n');
    });

    test('multi line comment', () {
      check(whitespaceParser).isSuccess('/* simple */');
      check(whitespaceParser).isSuccess('/** doc */');
      check(whitespaceParser).isSuccess('/* multi\nline */');
      check(whitespaceParser).isSuccess('/* outer /* inner */ */');
      check(whitespaceParser)
          .isSuccess('/* outer /* middle /* inner */ */ end */');
    });

    test('mixed whitespace and comments', () {
      check(whitespaceParser).isSuccess('  // comment\n  /* block */ \t\n');
    });

    test('invalid comment', () {
      check(whitespaceParser).isFailure('/* unclosed');
      check(whitespaceParser).isFailure('/* unclosed /* inner */');
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
      check(idParser).isSuccess(r'$');
      check(idParser).isSuccess(r'$foo');
      check(idParser).isSuccess(r'foo$bar');
      check(idParser).isSuccess('camelCase');
      check(idParser).isSuccess('PascalCase');
      check(idParser).isSuccess('snake_case');
      check(idParser).isSuccess('_private');
      check(idParser).isSuccess('ident123');
    });

    test('identifiers starting with keyword prefixes', () {
      check(idParser).isSuccess('nullLiteral');
      check(idParser).isSuccess('variable');
      check(idParser).isSuccess('finallyDone');
      check(idParser).isSuccess('classNames');
      check(idParser).isSuccess('assertValid');
      check(idParser).isSuccess('defaultSettings');
      check(idParser).isSuccess('importPath');
      check(idParser).isSuccess('isDone');
      check(idParser).isSuccess('asString');
    });

    test('reserved keywords rejected as identifiers', () {
      check(idParser).isFailure('class');
      check(idParser).isFailure('var');
      check(idParser).isFailure('final');
      check(idParser).isFailure('void');
      check(idParser).isFailure('null');
      check(idParser).isFailure('true');
      check(idParser).isFailure('false');
      check(idParser).isFailure('if');
      check(idParser).isFailure('else');
      check(idParser).isFailure('return');
    });

    test('invalid identifier starts', () {
      check(idParser).isFailure('123');
      check(idParser).isFailure('1abc');
      check(idParser).isFailure('@foo');
      check(idParser).isFailure('#foo');
    });
  });

  group('numeric literals', () {
    final numParser = grammar.buildFrom(grammar.numericLiteral()).end();

    test('integer decimals', () {
      check(numParser).isSuccess('0');
      check(numParser).isSuccess('1');
      check(numParser).isSuccess('42');
      check(numParser).isSuccess('1000000');
      check(numParser).isSuccess('1_000_000');
      check(numParser).isSuccess('12_34_56');
    });

    test('hexadecimal integers', () {
      check(numParser).isSuccess('0x0');
      check(numParser).isSuccess('0x123');
      check(numParser).isSuccess('0xCAFE');
      check(numParser).isSuccess('0xcafe');
      check(numParser).isSuccess('0XDEAD_BEEF');
      check(numParser).isFailure('0x');
      check(numParser).isFailure('0xGHI');
    });

    test('doubles', () {
      check(numParser).isSuccess('0.0');
      check(numParser).isSuccess('3.14159');
      check(numParser).isSuccess('1_000.50_001');
      check(numParser).isSuccess('.5');
      check(numParser).isSuccess('.1234');
      check(numParser).isSuccess('1e5');
      check(numParser).isSuccess('1E5');
      check(numParser).isSuccess('1.2e3');
      check(numParser).isSuccess('1.2E-3');
      check(numParser).isSuccess('.5e+2');
    });
  });

  group('boolean and null literals', () {
    final lit = grammar.buildFrom(grammar.literal()).end();

    test('boolean', () {
      check(lit).isSuccess('true');
      check(lit).isSuccess('false');
    });

    test('null', () {
      check(lit).isSuccess('null');
    });
  });

  group('symbol literals', () {
    final sym = grammar.buildFrom(grammar.symbolLiteral()).end();

    test('identifier symbols', () {
      check(sym).isSuccess('#foo');
      check(sym).isSuccess('#_bar');
      check(sym).isSuccess(r'#$baz');
      check(sym).isSuccess('#camelCase');
    });

    test('operator symbols', () {
      check(sym).isSuccess('#+');
      check(sym).isSuccess('#-');
      check(sym).isSuccess('#*');
      check(sym).isSuccess('#/');
      check(sym).isSuccess('#~/');
      check(sym).isSuccess('#%');
      check(sym).isSuccess('#==');
      check(sym).isSuccess('#[]');
      check(sym).isSuccess('#[]=');
      check(sym).isSuccess('#<');
      check(sym).isSuccess('#<=');
      check(sym).isSuccess('#>');
      check(sym).isSuccess('#>=');
      check(sym).isSuccess('#&');
      check(sym).isSuccess('#|');
      check(sym).isSuccess('#^');
      check(sym).isSuccess('#~');
      check(sym).isSuccess('#<<');
      check(sym).isSuccess('#>>');
      check(sym).isSuccess('#>>>');
    });

    test('invalid symbols', () {
      check(sym).isFailure('#');
      check(sym).isFailure('#123');
    });
  });

  group('string literals', () {
    final str = grammar.buildFrom(grammar.stringLiteral()).end();

    test('single-line single-quoted', () {
      check(str).isSuccess("''");
      check(str).isSuccess("'hello'");
      check(str).isSuccess("'hello world'");
      check(str).isSuccess(r"'escaped \' quote'");
      check(str).isSuccess(r"'newline \n test'");
      check(str).isSuccess(r"'\\'");
      check(str).isSuccess(r"'a\\b'");
    });

    test('single-line double-quoted', () {
      check(str).isSuccess('""');
      check(str).isSuccess('"hello"');
      check(str).isSuccess('"hello world"');
      check(str).isSuccess(r'"escaped \" quote"');
      check(str).isSuccess(r'"\\"');
      check(str).isSuccess(r'"a\\b"');
    });

    test('multi-line strings', () {
      check(str).isSuccess("''''''");
      check(str).isSuccess('""""""');
      check(str).isSuccess("'''first line\nsecond line'''");
      check(str).isSuccess('"""multi\r\nline\r\nstring"""');
    });

    test('raw strings', () {
      check(str).isSuccess("r'raw'");
      check(str).isSuccess('r"raw"');
      check(str).isSuccess(r"r'no \n escape'");
      check(str).isSuccess(r'r"no \t escape"');
      check(str).isSuccess(r"r'no $interp'");
      check(str).isSuccess("r'''raw multi'''");
      check(str).isSuccess('r"""raw multi"""');
    });

    test('string interpolation', () {
      check(str).isSuccess(r'"$name"');
      check(str).isSuccess(r'"hello $name"');
      check(str).isSuccess(r'"${1 + 2}"');
      check(str).isSuccess(r'"prefix ${user.name} suffix"');
      check(str).isSuccess(r"'$a and $b'");
      check(str).isSuccess(r"'nested ${1 + int.parse('2')}'");
      check(str).isSuccess(r'"price is $50"');
      check(str).isSuccess("'''\n\${1 + 2}\n'''");
      check(str).isSuccess('"""\n\${foo.bar}\n"""');
      check(str).isSuccess("'''cost is \$50 and \${count} items'''");
      check(str).isSuccess('"""he said "hi" and \$name answered"""');
      check(str).isSuccess("'''it's working and \$name answered'''");
      check(
        str,
      ).isSuccess("'''\n\${list.map((e) => '''<tr>\${e}</tr>''').join()}\n'''");
    });

    test('adjacent strings', () {
      check(str).isSuccess("'hello ' 'world'");
      check(str).isSuccess('"a" "b" "c"');
      check(str).isSuccess(r"'hello ' '$name'");
    });
  });
}

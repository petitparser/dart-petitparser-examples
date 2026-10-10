import 'package:petitparser_examples/bibtex.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:petitparser_examples/json.dart';
import 'package:petitparser_examples/lisp.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:petitparser_examples/math.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:petitparser_examples/prolog.dart';
import 'package:petitparser_examples/python.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:petitparser_examples/smalltalk.dart' hide ReturnNode;
import 'package:petitparser_examples/tabular.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:test/scaffolding.dart';

import 'utils/checks.dart';

void main() {
  group('README examples', () {
    test('BibTeX', () {
      final parser = BibTeXDefinition().build();
      check(parser).isSuccess(
        r'''
@inproceedings{Reng10c,
  title = "Practical Dynamic Grammars for Dynamic Languages",
  author = "Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz",
  year = 2010
}''',
        value: (Subject<dynamic> it) {
          final entry = it.isA<List<BibTeXEntry>>().single;
          entry.has((e) => e.key, 'key').equals('Reng10c');
          entry.has((e) => e.type, 'type').equals('inproceedings');
          entry
              .has((e) => e['title'], "['title']")
              .equals('Practical Dynamic Grammars for Dynamic Languages');
          entry
              .has((e) => e['author'], "['author']")
              .equals(
                'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
              );
          entry.has((e) => e['year'], "['year']").equals('2010');
          entry.has((e) => e.fields, 'fields').deepEquals([
            BibTeXField(
              'title',
              '"Practical Dynamic Grammars for Dynamic Languages"',
            ),
            BibTeXField(
              'author',
              '"Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz"',
            ),
            BibTeXField('year', '2010'),
          ]);
        },
      );
    });

    test('Dart', () {
      final parser = DartGrammarDefinition().build();
      check(parser).isSuccess('void main() => print("Hello, Dart!");');
    });

    test('JSON', () {
      final data = parseJson(
        '{"name": "PetitParser", "tags": ["dart", "parser"], "active": true}',
      );
      check(data).isA<Map<String, Object?>>().deepEquals({
        'name': 'PetitParser',
        'tags': ['dart', 'parser'],
        'active': true,
      });
    });

    test('Lisp', () {
      final environment = NativeEnvironment();
      final result = evalString(lispParser, environment, '(+ 1 (* 2 3))');
      check(result).equals(7);
    });

    test('Markdown', () {
      final document = parseMarkdown('# Hello World\n\nThis is **bold** text.');
      check(document.blocks).length.equals(2);
      final heading = check(document.blocks.first).isA<HeadingNode>();
      heading.has((h) => h.level, 'level').equals(1);
      heading
          .has((h) => h.content, 'content')
          .equals(const TextNode('Hello World'));

      final html = markdownToHtml('# Hello World\n\nThis is **bold** text.');
      check(html).equals(
        '<h1>Hello World</h1>\n<p>This is <strong>bold</strong> text.</p>',
      );
    });

    test('Math', () {
      final expression = parser.parse('sqrt(16) + 2 ^ 3').value;
      check(expression.eval({})).equals(12.0);
    });

    test('Pascal', () {
      final parser = PascalParserDefinition().build();
      check(parser).isSuccess('''
program HelloWorld;
begin
  writeln('Hello, World!');
end.
''');
    });

    test('Prolog', () {
      final db = Database.parse('''
parent(bob, ann).
parent(bob, pat).
sibling(X, Y) :- parent(Z, X), parent(Z, Y).
''');
      final query = Term.parse('sibling(ann, S)');
      final solutions = db.query(query).map((term) => term.toString()).toList();
      check(solutions).deepEquals(['sibling(ann, ann)', 'sibling(ann, pat)']);
    });

    test('Python', () {
      final module = parsePython(
        'def add(a: int, b: int) -> int:\n    return a + b\n',
      );
      check(module.body).length.equals(1);
      final fn = module.body.first as FunctionDefNode;
      check(fn.name).equals('add');
      check(fn.args.args).length.equals(2);
      check(fn.args.args[0].arg).equals('a');
      check(fn.args.args[1].arg).equals('b');
      check(fn.body).length.equals(1);
      check(fn.body.first).isA<ReturnNode>();
    });

    test('RegExp', () {
      final nfa = Nfa.fromString(r'a*b+');
      check(nfa.matchAsPrefix('aaab')).isNotNull();
      check(nfa.matchAsPrefix('b')).isNotNull();
      check(nfa.matchAsPrefix('a')).isNull();
    });

    test('Smalltalk', () {
      final parser = SmalltalkParserDefinition().build();
      check(parser).isSuccess('''
example
  1 to: 10 do: [ :i | Transcript show: i printString ]
''');
    });

    test('Tabular', () {
      final csv = TabularDefinition.csv().build();
      check(csv).isSuccess(
        'language,paradigm\nDart,multi-paradigm\nSmalltalk,object-oriented',
        value: [
          ['language', 'paradigm'],
          ['Dart', 'multi-paradigm'],
          ['Smalltalk', 'object-oriented'],
        ],
      );
    });

    test('URI', () {
      check(uri).isSuccess(
        'https://user:pass@example.com:8080/path/to/page?lang=en#heading',
        value: (Subject<dynamic> it) {
          final val = it
              .isA<
                ({
                  String? authority,
                  String? fragment,
                  String? hostname,
                  List<(String, String?)> params,
                  String? password,
                  String path,
                  String? port,
                  String? query,
                  String? scheme,
                  String? username,
                })
              >();
          val.has((v) => v.scheme, 'scheme').equals('https');
          val.has((v) => v.hostname, 'hostname').equals('example.com');
          val.has((v) => v.port, 'port').equals('8080');
          val.has((v) => v.path, 'path').equals('/path/to/page');
          val.has((v) => v.query, 'query').equals('lang=en');
          val.has((v) => v.fragment, 'fragment').equals('heading');
        },
      );
    });
  });
}

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:petitparser_examples/json.dart';
import 'package:petitparser_examples/lisp.dart';
import 'package:petitparser_examples/math.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:petitparser_examples/prolog.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:petitparser_examples/smalltalk.dart';
import 'package:petitparser_examples/tabular.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:test/test.dart';

void main() {
  group('README examples', () {
    test('BibTeX', () {
      final parser = BibTeXDefinition().build();
      final result = parser.parse(r'''
@inproceedings{Reng10c,
  title = "Practical Dynamic Grammars for Dynamic Languages",
  author = "Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz",
  year = 2010
}''');
      expect(result is Success, isTrue);
      final entry = result.value.single;
      expect(entry.key, 'Reng10c');
      expect(entry.type, 'inproceedings');
      expect(entry.fields, {
        'title': '"Practical Dynamic Grammars for Dynamic Languages"',
        'author': '"Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz"',
        'year': '2010',
      });
      expect(entry.normalized, {
        'Title': 'Practical Dynamic Grammars for Dynamic Languages',
        'Author': 'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
        'Year': '2010',
      });
    });

    test('Dart', () {
      final parser = DartGrammarDefinition().build();
      final result = parser.parse('void main() => print("Hello, Dart!");');
      expect(result is Success, isTrue);
    });

    test('JSON', () {
      final data = parseJson(
        '{"name": "PetitParser", "tags": ["dart", "parser"], "active": true}',
      );
      expect(data, {
        'name': 'PetitParser',
        'tags': ['dart', 'parser'],
        'active': true,
      });
    });

    test('Lisp', () {
      final environment = NativeEnvironment();
      final result = evalString(lispParser, environment, '(+ 1 (* 2 3))');
      expect(result, 7);
    });

    test('Math', () {
      final expression = parser.parse('sqrt(16) + 2 ^ 3').value;
      expect(expression.eval({}), 12.0);
    });

    test('Pascal', () {
      final parser = PascalGrammarDefinition().build();
      final result = parser.parse('''
program HelloWorld;
begin
  writeln('Hello, World!');
end.
''');
      expect(result is Success, isTrue);
    });

    test('Prolog', () {
      final db = Database.parse('''
parent(bob, ann).
parent(bob, pat).
sibling(X, Y) :- parent(Z, X), parent(Z, Y).
''');
      final query = Term.parse('sibling(ann, S)');
      final solutions = db.query(query).map((term) => term.toString()).toList();
      expect(solutions, ['sibling(ann, ann)', 'sibling(ann, pat)']);
    });

    test('RegExp', () {
      final nfa = Nfa.fromString(r'a*b+');
      expect(nfa.matchAsPrefix('aaab') != null, isTrue);
      expect(nfa.matchAsPrefix('b') != null, isTrue);
      expect(nfa.matchAsPrefix('a') != null, isFalse);
    });

    test('Smalltalk', () {
      final parser = SmalltalkParserDefinition().build();
      final result = parser.parse('''
example
  1 to: 10 do: [ :i | Transcript show: i printString ]
''');
      expect(result is Success, isTrue);
    });

    test('Tabular', () {
      final csv = TabularDefinition.csv().build();
      final result = csv.parse(
        'language,paradigm\nDart,multi-paradigm\nSmalltalk,object-oriented',
      );
      expect(result.value, [
        ['language', 'paradigm'],
        ['Dart', 'multi-paradigm'],
        ['Smalltalk', 'object-oriented'],
      ]);
    });

    test('URI', () {
      final result = uri.parse(
        'https://user:pass@example.com:8080/path/to/page?lang=en#heading',
      );
      expect(result is Success, isTrue);
      expect(result.value.scheme, 'https');
      expect(result.value.hostname, 'example.com');
      expect(result.value.port, '8080');
      expect(result.value.path, '/path/to/page');
      expect(result.value.query, 'lang=en');
      expect(result.value.fragment, 'heading');
    });
  });
}

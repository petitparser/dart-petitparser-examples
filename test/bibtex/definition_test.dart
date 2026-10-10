import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/scaffolding.dart';

import '../utils/checks.dart';
import 'bibtex_checks.dart';

void main() {
  final parser = BibTeXDefinition().build();

  test('linter', () {
    check(
      linter(parser, excludedRules: {'Duplicate parser'}, excludedTypes: {}),
    ).isEmpty();
  });

  group('grammar', () {
    const input =
        '@inproceedings{Reng10c,\n'
        '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
        '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
        '\tMonth = jun,\n'
        '\tYear = 2010,\n'
        '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}}';

    test('raw preserves original values', () {
      final entry = parser.parse(input).value.single;
      check(entry).which(
        isBibTeXEntry(
          type: 'inproceedings',
          key: 'Reng10c',
          fields: [
            BibTeXField(
              'Title',
              '"Practical Dynamic Grammars for Dynamic Languages"',
            ),
            BibTeXField(
              'Author',
              '{Lukas Renggli and St\\\'ephane Ducasse and '
                  'Tudor G\\^irba and Oscar Nierstrasz}',
            ),
            BibTeXField('Month', 'jun'),
            BibTeXField('Year', '2010'),
            BibTeXField(
              'Url',
              '{http://scg.unibe.ch/archive/papers/'
                  'Reng10cDynamicGrammars.pdf}',
            ),
          ],
        ),
      );
    });

    test('toString round-trips via raw', () {
      final entry = parser.parse(input).value.single;
      check(entry.toString()).equals(input);
    });

    test('README example', () {
      final result = parser.parse(r'''
@inproceedings{Reng10c,
  title = "Practical Dynamic Grammars for Dynamic Languages",
  author = "Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz",
  year = 2010
}''');
      check(result).isA<Success>();
      final entry = result.value.single;
      check(entry.key).equals('Reng10c');
      check(entry.type).equals('inproceedings');
      check(entry.fields).deepEquals([
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
      check(entry['title'])
          .equals('Practical Dynamic Grammars for Dynamic Languages');
      check(entry['author']).equals(
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      check(entry['year']).equals('2010');
      check(entry.getField('title')?.value)
          .equals('Practical Dynamic Grammars for Dynamic Languages');
      check(entry.getField('author')?.value).equals(
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      check(entry.getField('year')?.value).equals('2010');
    });

    test('entry type supports uppercase and mixed case', () {
      final entry = parser.parse('@ARTICLE{k1, title = "A"}').value.single;
      check(entry.type).equals('ARTICLE');
      check(entry.key).equals('k1');
      check(entry['title']).equals('A');
    });
  });

  group('dashes in grammar', () {
    test('raw preserves --', () {
      final entry = parser
          .parse('@article{foo, pages = {10--20}}')
          .value
          .single;
      check(entry.getField('pages')).equals(BibTeXField('pages', '{10--20}'));
      check(entry.getField('pages')?.rawKey).equals('pages');
      check(entry.getField('pages')?.rawValue).equals('{10--20}');
    });

    test('raw preserves ---', () {
      final entry = parser.parse('@article{foo, title = {A---B}}').value.single;
      check(entry.getField('title')).equals(BibTeXField('title', '{A---B}'));
      check(entry.getField('title')?.rawKey).equals('title');
      check(entry.getField('title')?.rawValue).equals('{A---B}');
    });

    test('single hyphens are preserved', () {
      final entry = parser
          .parse('@article{foo, note = {well-known}}')
          .value
          .single;
      check(entry.getField('note')).equals(BibTeXField('note', '{well-known}'));
      check(entry.getField('note')?.rawKey).equals('note');
      check(entry.getField('note')?.rawValue).equals('{well-known}');
    });
  });

  group('comments and interstitial content', () {
    test('TeX-style percent comments before, between, and after entries', () {
      const input = '''
%%%%% File Header Comment %%%%%
% Another line of comment
@article{a1,
  title = "Paper 1"
}
% Comment between entries
%%%%% Section 2 %%%%%
@book{b1,
  title = "Book 1",
}
% Trailing comment at EOF
''';
      final entries = parser.parse(input).value;
      check(entries).length.equals(2);
      check(entries[0].key).equals('a1');
      check(entries[1].key).equals('b1');
    });

    test('freeform @comment blocks are skipped', () {
      const input = '''
@comment{This is an unstructured freeform comment without key}
@article{k1, title = "Title 1"}
@comment(Another comment enclosed in parentheses)
@COMMENT{Uppercase comment}
@book{k2, title = "Title 2"}
''';
      final entries = parser.parse(input).value;
      check(entries).length.equals(2);
      check(entries.map((e) => e.key)).deepEquals(['k1', 'k2']);
    });

    test('empty input and comment-only input yields empty list', () {
      check(parser.parse('').value).isEmpty();
      check(parser.parse('   \n\t  \r\n  ').value).isEmpty();
      check(parser.parse('% only comments\n% another line\n').value).isEmpty();
      check(parser.parse('@comment{just a comment}').value).isEmpty();
      check(parser.parse('@comment(parenthesized)').value).isEmpty();
    });

    test('entries with trailing commas in fields', () {
      const input = '''
@article{trailing1,
  author = "Someone",
  title = "Something",
  year = 2024,
}
''';
      final entry = parser.parse(input).value.single;
      check(entry.key).equals('trailing1');
      check(entry.fields).length.equals(3);
      check(entry['year']).equals('2024');
      check(entry.getField('year')?.value).equals('2024');
    });

    test('entries with no fields', () {
      check(parser.parse('@misc{empty1,}').value.single.key).equals('empty1');
      check(parser.parse('@misc{empty2}').value.single.key).equals('empty2');
      check(parser.parse('@misc{empty1,}').value.single.fields).isEmpty();
      check(parser.parse('@misc{empty2}').value.single.fields).isEmpty();
    });

    test('arbitrary preamble text outside entries', () {
      const input = '''
This is some arbitrary preamble text written at the top of the file.
BibTeX ignores all text outside entries.

@misc{k1, title = "First"}

And here is some text between entries explaining things.

@misc{k2, title = "Second"}

End of bibliography notes.
''';
      final entries = parser.parse(input).value;
      check(entries).length.equals(2);
      check(entries[0].key).equals('k1');
      check(entries[1].key).equals('k2');
    });
  });

  group('failures', () {
    test('incomplete entry', () {
      check(parser).isFailure('@');
      check(parser).isFailure('@article');
      check(parser).isFailure('@article{');
      check(parser).isFailure('@article{foo,');
    });

    test('missing closing brace', () {
      check(parser).isFailure('@article{foo, bar = "baz"');
    });

    test('invalid type or key', () {
      check(parser).isFailure('@123{foo,}');
      check(parser).isFailure('@article{, bar = "baz"}');
    });

    test('unterminated string', () {
      check(parser).isFailure('@article{foo, bar = "baz}');
      check(parser).isFailure('@article{foo, bar = {baz}');
    });
  });
}

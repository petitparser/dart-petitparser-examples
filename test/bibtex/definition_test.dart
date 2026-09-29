import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

import '../utils/expect.dart';

Matcher isBibTeXEntry({
  dynamic type = anything,
  dynamic key = anything,
  dynamic fields = anything,
}) => const TypeMatcher<BibTeXEntry>()
    .having((e) => e.type, 'type', type)
    .having((e) => e.key, 'key', key)
    .having((e) => e.fields, 'fields', fields);

void main() {
  final parser = BibTeXDefinition().build();

  test('linter', () {
    expect(
      linter(parser, excludedRules: {'Duplicate parser'}, excludedTypes: {}),
      isEmpty,
    );
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
      expect(
        entry,
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
      expect(entry.toString(), input);
    });

    test('README example', () {
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
      expect(entry.fields, [
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
      expect(
        entry['title'],
        'Practical Dynamic Grammars for Dynamic Languages',
      );
      expect(
        entry['author'],
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      expect(entry['year'], '2010');
      expect(
        entry.getField('title')?.value,
        'Practical Dynamic Grammars for Dynamic Languages',
      );
      expect(
        entry.getField('author')?.value,
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      expect(entry.getField('year')?.value, '2010');
    });

    test('entry type supports uppercase and mixed case', () {
      final entry = parser.parse('@ARTICLE{k1, title = "A"}').value.single;
      expect(entry.type, 'ARTICLE');
      expect(entry.key, 'k1');
      expect(entry['title'], 'A');
    });
  });

  group('dashes in grammar', () {
    test('raw preserves --', () {
      final entry = parser
          .parse('@article{foo, pages = {10--20}}')
          .value
          .single;
      expect(entry.getField('pages'), BibTeXField('pages', '{10--20}'));
      expect(entry.getField('pages')?.rawKey, 'pages');
      expect(entry.getField('pages')?.rawValue, '{10--20}');
    });

    test('raw preserves ---', () {
      final entry = parser.parse('@article{foo, title = {A---B}}').value.single;
      expect(entry.getField('title'), BibTeXField('title', '{A---B}'));
      expect(entry.getField('title')?.rawKey, 'title');
      expect(entry.getField('title')?.rawValue, '{A---B}');
    });

    test('single hyphens are preserved', () {
      final entry = parser
          .parse('@article{foo, note = {well-known}}')
          .value
          .single;
      expect(entry.getField('note'), BibTeXField('note', '{well-known}'));
      expect(entry.getField('note')?.rawKey, 'note');
      expect(entry.getField('note')?.rawValue, '{well-known}');
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
      expect(entries.length, 2);
      expect(entries[0].key, 'a1');
      expect(entries[1].key, 'b1');
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
      expect(entries.length, 2);
      expect(entries.map((e) => e.key), ['k1', 'k2']);
    });

    test('empty input and comment-only input yields empty list', () {
      expect(parser.parse('').value, isEmpty);
      expect(parser.parse('   \n\t  \r\n  ').value, isEmpty);
      expect(parser.parse('% only comments\n% another line\n').value, isEmpty);
      expect(parser.parse('@comment{just a comment}').value, isEmpty);
      expect(parser.parse('@comment(parenthesized)').value, isEmpty);
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
      expect(entry.key, 'trailing1');
      expect(entry.fields.length, 3);
      expect(entry['year'], '2024');
      expect(entry.getField('year')?.value, '2024');
    });

    test('entries with no fields', () {
      expect(parser.parse('@misc{empty1,}').value.single.key, 'empty1');
      expect(parser.parse('@misc{empty2}').value.single.key, 'empty2');
      expect(parser.parse('@misc{empty1,}').value.single.fields, isEmpty);
      expect(parser.parse('@misc{empty2}').value.single.fields, isEmpty);
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
      expect(entries.length, 2);
      expect(entries[0].key, 'k1');
      expect(entries[1].key, 'k2');
    });
  });

  group('failures', () {
    test('incomplete entry', () {
      expect(parser, isFailure('@'));
      expect(parser, isFailure('@article'));
      expect(parser, isFailure('@article{'));
      expect(parser, isFailure('@article{foo,'));
    });

    test('missing closing brace', () {
      expect(parser, isFailure('@article{foo, bar = "baz"'));
    });

    test('invalid type or key', () {
      expect(parser, isFailure('@123{foo,}'));
      expect(parser, isFailure('@article{, bar = "baz"}'));
    });

    test('unterminated string', () {
      expect(parser, isFailure('@article{foo, bar = "baz}'));
      expect(parser, isFailure('@article{foo, bar = {baz}'));
    });
  });
}

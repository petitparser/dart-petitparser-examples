import 'package:checks/checks.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/scaffolding.dart';

void main() {
  final parser = BibTeXDefinition().build();

  group('construction', () {
    test('basic properties', () {
      final entry = BibTeXEntry(
        type: 'article',
        key: 'knuth1984',
        fields: [BibTeXField('title', '{Literate Programming}')],
      );
      check(entry.type).equals('article');
      check(entry.key).equals('knuth1984');
      check(entry.fields).length.equals(1);
      check(entry.fields.first.key).equals('title');
    });

    test('default empty fields', () {
      const entry = BibTeXEntry(type: 'misc', key: 'empty');
      check(entry.type).equals('misc');
      check(entry.key).equals('empty');
      check(entry.fields).isEmpty();
    });
  });

  group('lookup', () {
    test('lookup methods on parsed entry', () {
      final entry = parser
          .parse('@article{k, Title = {My Title}, author = "Me"}')
          .value
          .single;
      check(entry['Title']).equals('My Title');
      check(entry['title']).equals('My Title');
      check(entry['AUTHOR']).equals('Me');
      check(entry.getField('title')?.rawKey).equals('Title');
      check(entry.getField('title')?.rawValue).equals('{My Title}');
      check(entry.getField('title')?.key).equals('title');
      check(entry.getField('title')?.value).equals('My Title');
      check(entry.getField('Author')?.value).equals('Me');
      check(entry.getField('unknown')).isNull();
      check(entry.getRaw('title')).equals('{My Title}');
      check(entry.getRaw('unknown')).isNull();
      check(entry.containsField('title')).isTrue();
      check(entry.containsField('author')).isTrue();
      check(entry.containsField('unknown')).isFalse();
    });

    test('normalized fields from parsed entry', () {
      const input =
          '@inproceedings{Reng10c,\n'
          '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
          '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
          '\tMonth = jun,\n'
          '\tYear = 2010,\n'
          '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}}';
      final entry = parser.parse(input).value.single;
      check(entry['title'])
          .equals('Practical Dynamic Grammars for Dynamic Languages');
      check(entry['author']).equals(
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      check(entry['month']).equals('jun');
      check(entry['year']).equals('2010');
      check(
        entry['url'],
      ).equals('http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf');
      check(entry.getField('title')?.value)
          .equals('Practical Dynamic Grammars for Dynamic Languages');
      check(entry.getField('title')?.key).equals('title');
    });
  });

  group('formatting', () {
    test('toString formatting', () {
      final entry = BibTeXEntry(
        type: 'misc',
        key: 'k1',
        fields: [
          BibTeXField('author', 'John Doe'),
          BibTeXField('year', '2024'),
        ],
      );
      check(entry.toString())
          .equals('@misc{k1,\n\tauthor = John Doe,\n\tyear = 2024}');
    });
  });

  group('equality', () {
    test('equality and hashCode', () {
      final e1 = BibTeXEntry(
        type: 'article',
        key: 'k1',
        fields: [BibTeXField('title', 'T1')],
      );
      final e2 = BibTeXEntry(
        type: 'article',
        key: 'k1',
        fields: [BibTeXField('title', 'T1')],
      );
      final e3 = BibTeXEntry(
        type: 'book',
        key: 'k1',
        fields: [BibTeXField('title', 'T1')],
      );
      final e4 = BibTeXEntry(
        type: 'article',
        key: 'k2',
        fields: [BibTeXField('title', 'T1')],
      );
      final e5 = BibTeXEntry(
        type: 'article',
        key: 'k1',
        fields: [BibTeXField('title', 'T2')],
      );
      check(e1).equals(e2);
      check(e1.hashCode).equals(e2.hashCode);
      check(e1).not((it) => it.equals(e3));
      check(e1).not((it) => it.equals(e4));
      check(e1).not((it) => it.equals(e5));
    });
  });
}

import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

void main() {
  final parser = BibTeXDefinition().build();

  group('construction', () {
    test('basic properties', () {
      final entry = BibTeXEntry(
        type: 'article',
        key: 'knuth1984',
        fields: [BibTeXField('title', '{Literate Programming}')],
      );
      expect(entry.type, 'article');
      expect(entry.key, 'knuth1984');
      expect(entry.fields, hasLength(1));
      expect(entry.fields.first.key, 'title');
    });

    test('default empty fields', () {
      const entry = BibTeXEntry(type: 'misc', key: 'empty');
      expect(entry.type, 'misc');
      expect(entry.key, 'empty');
      expect(entry.fields, isEmpty);
    });
  });

  group('lookup', () {
    test('lookup methods on parsed entry', () {
      final entry = parser
          .parse('@article{k, Title = {My Title}, author = "Me"}')
          .value
          .single;
      expect(entry['Title'], 'My Title');
      expect(entry['title'], 'My Title');
      expect(entry['AUTHOR'], 'Me');
      expect(entry.getField('title')?.rawKey, 'Title');
      expect(entry.getField('title')?.rawValue, '{My Title}');
      expect(entry.getField('title')?.key, 'title');
      expect(entry.getField('title')?.value, 'My Title');
      expect(entry.getField('Author')?.value, 'Me');
      expect(entry.getField('unknown'), isNull);
      expect(entry.getRaw('title'), '{My Title}');
      expect(entry.getRaw('unknown'), isNull);
      expect(entry.containsField('title'), isTrue);
      expect(entry.containsField('author'), isTrue);
      expect(entry.containsField('unknown'), isFalse);
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
      expect(
        entry['title'],
        'Practical Dynamic Grammars for Dynamic Languages',
      );
      expect(
        entry['author'],
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      expect(entry['month'], 'jun');
      expect(entry['year'], '2010');
      expect(
        entry['url'],
        'http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf',
      );
      expect(
        entry.getField('title')?.value,
        'Practical Dynamic Grammars for Dynamic Languages',
      );
      expect(entry.getField('title')?.key, 'title');
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
      expect(
        entry.toString(),
        '@misc{k1,\n\tauthor = John Doe,\n\tyear = 2024}',
      );
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
      expect(e1, equals(e2));
      expect(e1.hashCode, equals(e2.hashCode));
      expect(e1, isNot(equals(e3)));
      expect(e1, isNot(equals(e4)));
      expect(e1, isNot(equals(e5)));
    });
  });
}

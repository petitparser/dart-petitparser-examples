import 'package:http/http.dart' as http;
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

Matcher isBibTextEntry({
  dynamic type = anything,
  dynamic key = anything,
  dynamic fields = anything,
  dynamic normalized = anything,
}) => const TypeMatcher<BibTeXEntry>()
    .having((e) => e.type, 'type', type)
    .having((e) => e.key, 'key', key)
    .having((e) => e.fields, 'fields', fields)
    .having((e) => e.normalized, 'normalized', normalized);

void main() {
  final parser = BibTeXDefinition().build();
  test('linter', () {
    expect(
      linter(parser, excludedRules: {'Duplicate parser'}, excludedTypes: {}),
      isEmpty,
    );
  });

  group('basic', () {
    const input =
        '@inproceedings{Reng10c,\n'
        '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
        '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
        '\tMonth = jun,\n'
        '\tYear = 2010,\n'
        '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}}';
    final entry = parser.parse(input).value.single;
    test('raw preserves original values', () {
      expect(
        entry,
        isBibTextEntry(
          type: 'inproceedings',
          key: 'Reng10c',
          fields: {
            'Title': '"Practical Dynamic Grammars for Dynamic Languages"',
            'Author':
                '{Lukas Renggli and St\\\'ephane Ducasse and '
                'Tudor G\\^irba and Oscar Nierstrasz}',
            'Month': 'jun',
            'Year': '2010',
            'Url':
                '{http://scg.unibe.ch/archive/papers/'
                'Reng10cDynamicGrammars.pdf}',
          },
        ),
      );
    });
    test('fields are normalized', () {
      expect(
        entry,
        isBibTextEntry(
          type: 'inproceedings',
          key: 'Reng10c',
          normalized: {
            'Title': 'Practical Dynamic Grammars for Dynamic Languages',
            'Author': 'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
            'Month': 'jun',
            'Year': '2010',
            'Url':
                'http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf',
          },
        ),
      );
    });
    test('toString round-trips via raw', () {
      expect(entry.toString(), input);
    });
  });

  group('dashes', () {
    test('raw preserves --, fields shows en dash', () {
      final entry = parser
          .parse('@article{foo, pages = {10--20}}')
          .value
          .single;
      expect(entry.fields['pages'], '{10--20}');
      expect(entry.normalized['Pages'], '10\u201320');
    });
    test('raw preserves ---, fields shows em dash', () {
      final entry = parser.parse('@article{foo, title = {A---B}}').value.single;
      expect(entry.fields['title'], '{A---B}');
      expect(entry.normalized['Title'], 'A\u2014B');
    });
    test('single hyphens are preserved', () {
      final entry = parser
          .parse('@article{foo, note = {well-known}}')
          .value
          .single;
      expect(entry.fields['note'], '{well-known}');
      expect(entry.normalized['Note'], 'well-known');
    });
  });

  group('normalizeFieldName', () {
    test('capitalizes first letter', () {
      expect(normalizeFieldName('title'), 'Title');
      expect(normalizeFieldName('author'), 'Author');
    });
    test('lowercases and capitalizes from all-caps', () {
      expect(normalizeFieldName('TITLE'), 'Title');
      expect(normalizeFieldName('URL'), 'Url');
      expect(normalizeFieldName('AUTHOR'), 'Author');
    });
    test('capitalizes letter after hyphen', () {
      expect(normalizeFieldName('cross-ref'), 'Cross-Ref');
      expect(normalizeFieldName('CROSS-REF'), 'Cross-Ref');
    });
    test('is idempotent', () {
      expect(normalizeFieldName(normalizeFieldName('TITLE')), 'Title');
    });
  });

  group('normalizeFieldValue', () {
    test('strips outer braces', () {
      expect(normalizeFieldValue('{hello}'), 'hello');
    });
    test('strips outer quotes', () {
      expect(normalizeFieldValue('"hello"'), 'hello');
    });
    test('replaces --- with em dash', () {
      expect(normalizeFieldValue('{A---B}'), 'A\u2014B');
    });
    test('replaces -- with en dash', () {
      expect(normalizeFieldValue('{10--20}'), '10\u201320');
    });
    test('does not affect single hyphens', () {
      expect(normalizeFieldValue('{well-known}'), 'well-known');
    });
    test('expands LaTeX accents', () {
      expect(normalizeFieldValue(r"{\'e}"), 'é');
      expect(normalizeFieldValue(r'{\`e}'), 'è');
    });
    test('removes remaining braces', () {
      expect(normalizeFieldValue(r'{{\em foo}}'), 'foo');
    });
  });

  group(
    'scg.bib',
    () {
      late final List<BibTeXEntry> entries;
      setUpAll(() async {
        final body = await http.read(
          Uri.parse(
            'https://raw.githubusercontent.com/scgbern/scgbib/main/scg.bib',
          ),
        );
        entries = parser.parse(body).value;
      });
      test('size', () {
        expect(entries.length, greaterThan(9600));
        expect(
          entries
              .where(
                (entry) => entry.fields['Author']?.contains('Renggli') ?? false,
              )
              .length,
          greaterThan(35),
        );
      });
      test('round-trip via raw', () {
        for (final entry in entries) {
          expect(
            parser.parse(entry.toString()).value.single,
            isBibTextEntry(
              type: entry.type,
              key: entry.key,
              fields: entry.fields,
            ),
          );
        }
      });
    },
    onPlatform: const {
      'js': [Skip('http.get is unsupported in JavaScript')],
    },
  );
}

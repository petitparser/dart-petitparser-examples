import 'package:http/http.dart' as http;
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

Matcher isBibTextEntry({
  dynamic type = anything,
  dynamic key = anything,
  dynamic fields = anything,
}) => const TypeMatcher<BibTeXEntry>()
    .having((entry) => entry.type, 'type', type)
    .having((entry) => entry.key, 'key', key)
    .having((entry) => entry.fields, 'fields', fields);

void main() {
  final parser = BibTeXDefinition().build();
  test('linter', () {
    expect(linter(parser, excludedTypes: {}), isEmpty);
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
    test('parsing', () {
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
    test('serializing', () {
      expect(entry.toString(), input);
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
      test('round-trip', () {
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

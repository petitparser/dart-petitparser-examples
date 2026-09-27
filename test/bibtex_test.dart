import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

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

/// Synthetic hermetic BibTeX fixture containing diverse entry types, field
/// formats, LaTeX escapes, and nested braces.
const syntheticBibTeX = r'''
@article{Knuth1984,
	author = {Donald E. Knuth},
	title = {Literate Programming},
	journal = {The Computer Journal},
	volume = {27},
	number = {2},
	pages = {97--111},
	year = 1984,
	month = may,
	url = {https://doi.org/10.1093/comjnl/27.2.97}
}

@book{Abelson1996,
	author = "Harold Abelson and Gerald Jay Sussman",
	title = "Structure and Interpretation of Computer Programs",
	publisher = "MIT Press",
	year = "1996",
	address = "Cambridge, MA",
	isbn = "0-262-01153-0"
}

@inproceedings{Reng10c,
	title = "Practical Dynamic Grammars for Dynamic Languages",
	author = {Lukas Renggli and St\'ephane Ducasse and Tudor G\^irba and Oscar Nierstrasz},
	booktitle = "Proceedings of the 9th International Conference on Dynamic Languages",
	series = {ICDL '10},
	pages = {1---10},
	year = 2010,
	publisher = {ACM}
}

@misc{Renggli2024,
	author = {Lukas Renggli},
	title = {PetitParser: Dynamic Grammars for Dart},
	howpublished = {https://github.com/petitparser/dart-petitparser},
	year = 2024,
	note = {well-known}
}

@techreport{Steele1980,
	author = {Guy L. {Steele} Jr.},
	title = {The Definition and Implementation of a Computer Programming Language Based on Constraints},
	institution = {MIT AI Lab},
	number = {AI-TR-595},
	year = 1980
}

@phdthesis{Fielding2000,
	author = {Roy Thomas Fielding},
	title = {Architectural Styles and the Design of Network-based Software Architectures},
	school = {University of California, Irvine},
	year = 2000
}

@mastersthesis{Shannon1938,
	author = {Claude E. Shannon},
	title = {A Symbolic Analysis of Relay and Switching Circuits},
	school = {Massachusetts Institute of Technology},
	year = 1938
}

@proceedings{PLDI1990,
	title = {Proceedings of the ACM SIGPLAN Conference on Programming Language Design and Implementation},
	editor = {John Backus},
	year = 1990,
	publisher = {ACM}
}

@manual{DartSpec2023,
	title = {Dart Programming Language Specification},
	organization = {Google Inc.},
	edition = {7th},
	year = 2023
}

@comment{Cmt2026,
	note = "Synthetic comment entry for hermetic test verification",
	timestamp = "2026-09-27"
}

@string{StrACM,
	name = "ACM",
	value = {Association for Computing Machinery}
}

@preamble{Pre2026,
	text = "Maintained hermetically for PetitParserExamples test suite"
}
''';

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
    test('handles edge case strings without error', () {
      expect(normalizeFieldName(''), '');
      expect(normalizeFieldName('-'), '-');
      expect(normalizeFieldName('-a'), '-A');
      expect(normalizeFieldName('a-'), 'A-');
      expect(normalizeFieldName('123'), '123');
      expect(normalizeFieldName('--'), '--');
    });
    test('is idempotent', () {
      expect(normalizeFieldName(normalizeFieldName('TITLE')), 'Title');
    });
  });

  group('normalizeFieldValue', () {
    test('handles empty and blank values', () {
      expect(normalizeFieldValue(''), '');
      expect(normalizeFieldValue('{}'), '');
      expect(normalizeFieldValue('""'), '');
    });
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

  group('hermetic synthetic bibtex', () {
    late final List<BibTeXEntry> entries;
    setUpAll(() {
      entries = parser.parse(syntheticBibTeX).value;
    });

    test('parses all entry types', () {
      expect(entries.length, equals(12));
      final types = entries.map((e) => e.type).toSet();
      expect(
        types,
        containsAll([
          'article',
          'book',
          'inproceedings',
          'misc',
          'techreport',
          'phdthesis',
          'mastersthesis',
          'proceedings',
          'manual',
          'comment',
          'string',
          'preamble',
        ]),
      );
    });

    test('author filtering matches expected count', () {
      final renggliEntries = entries.where(
        (entry) => entry.fields['author']?.contains('Renggli') ?? false,
      );
      expect(renggliEntries.length, equals(2));
    });

    test('field normalization across entries', () {
      final reng10c = entries.firstWhere((e) => e.key == 'Reng10c');
      expect(
        reng10c.normalized['Author'],
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      expect(reng10c.normalized['Pages'], '1\u201410');

      final knuth = entries.firstWhere((e) => e.key == 'Knuth1984');
      expect(knuth.normalized['Pages'], '97\u2013111');
      expect(knuth.normalized['Author'], 'Donald E. Knuth');

      final misc = entries.firstWhere((e) => e.key == 'Renggli2024');
      expect(misc.normalized['Note'], 'well-known');
    });

    test('round-trip via raw toString()', () {
      for (final entry in entries) {
        final parsed = parser.parse(entry.toString()).value.single;
        expect(
          parsed,
          isBibTextEntry(
            type: entry.type,
            key: entry.key,
            fields: entry.fields,
          ),
        );
      }
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

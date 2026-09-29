import 'dart:async';
import 'dart:io';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

Matcher isBibTeXEntry({
  dynamic type = anything,
  dynamic key = anything,
  dynamic fields = anything,
}) => const TypeMatcher<BibTeXEntry>()
    .having((e) => e.type, 'type', type)
    .having((e) => e.key, 'key', key)
    .having((e) => e.fields, 'fields', fields);

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

const realWorldFixture = r'''
%%%%% Actual bibliography entries.
% See README.md before adding entries.
@Misc{abadi-et-al-misc2015,
  author =       "Mart{\'i}n Abadi and Ashish Agarwal and Jeffrey Dean",
  title =        "{TensorFlow}: Large-Scale Machine Learning on Heterogeneous Systems",
  howpublished = "\url{https://tensorflow.org/}",
  year =         "2015"
}

@InProceedings{abbe-et-al-neurips2024,
  author =       "Emmanuel Abbe and Samy Bengio",
  title =        "How Far Can Transformers Reason?",
  crossref =     "neurips2024",
  pages =        "27850--27895"
}

@Article{aljazzar-leue-aij2011,
  author =       "Husain Aljazzar and Stefan Leue",
  title =        "K*: A Heuristic Search Algorithm for Finding the K Shortest Paths",
  journal =      aij,
  year =         "2011",
  volume =       "175",
  number =       "18",
  pages =        "2129--2154",
}
''';

void main() {
  group('entryParser', () {
    test('parses a single entry', () {
      final result = entryParser.parse('@article{k1, title = "Hello"}');
      expect(result is Success, isTrue);
      final entry = result.value;
      expect(entry.key, 'k1');
      expect(entry['title'], 'Hello');
    });
  });

  group('streaming and progressive iteration', () {
    const input = '''
% Header
@article{e1, title = "First"}
% Middle
@book{e2, title = "Second"}
% Tail
@misc{e3, title = "Third"}
''';

    test('parseStream emits all entries progressively', () async {
      final entries = <BibTeXEntry>[];
      await for (final entry in parseStream(input)) {
        entries.add(entry);
      }
      expect(entries.length, 3);
      expect(entries.map((e) => e.key), ['e1', 'e2', 'e3']);
    });

    test('parseEntries provides synchronous lazy iterable', () {
      final entries = parseEntries(input).toList();
      expect(entries.length, 3);
      expect(entries.map((e) => e.key), ['e1', 'e2', 'e3']);
    });

    test(
      'parseStreamChunks processes chunked stream across boundaries',
      () async {
        final chunks = Stream.fromIterable([
          '% Header comment\n@art',
          'icle{c1, tit',
          'le = "Chunked',
          ' Entry"}\n\n% Mid\n@book',
          '{c2, title = "Second Chunked"}\n',
        ]);
        final entries = await parseStreamChunks(chunks).toList();
        expect(entries.length, 2);
        expect(entries[0].key, 'c1');
        expect(entries[0]['title'], 'Chunked Entry');
        expect(entries[1].key, 'c2');
        expect(entries[1]['title'], 'Second Chunked');
      },
    );

    test('parseStreamChunks emits entries progressively despite non-entry @ and comments', () async {
      final chunks = Stream.fromIterable([
        '% Note: author@example.com\n@article{c1, title = {First}}\n',
        '@comment{Tool comment with no entry fields}\n',
        '@book{c2, title = {Second}}\n',
      ]);
      final entries = await parseStreamChunks(chunks).toList();
      expect(entries.length, 2);
      expect(entries[0].key, 'c1');
      expect(entries[0]['title'], 'First');
      expect(entries[1].key, 'c2');
      expect(entries[1]['title'], 'Second');
    });

    test(
      'parseStreamChunks emits entries progressively before stream close',
      () async {
        final controller = StreamController<String>();
        final emitted = <BibTeXEntry>[];
        final subscription = parseStreamChunks(controller.stream)
            .listen(emitted.add);

        controller.add(
          '% Header with email contact@example.com\n@article{c1, title = {First}}\n',
        );
        await pumpEventQueue();
        expect(emitted.length, 1);
        expect(emitted[0].key, 'c1');

        controller.add('@article{c2, title = {Second}}\n');
        await pumpEventQueue();
        expect(emitted.length, 2);
        expect(emitted[1].key, 'c2');

        await controller.close();
        await subscription.cancel();
      },
    );

    test('parseStreamChunks handles empty stream', () async {
      final entries = await parseStreamChunks(const Stream.empty()).toList();
      expect(entries, isEmpty);
    });
  });

  group('hermetic synthetic bibtex', () {
    late final List<BibTeXEntry> entries;
    setUpAll(() {
      entries = parseEntries(syntheticBibTeX).toList();
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
        (entry) =>
            entry.getField('author')?.rawValue.contains('Renggli') ?? false,
      );
      expect(renggliEntries.length, equals(2));
    });

    test('field normalization across entries', () {
      final reng10c = entries.firstWhere((e) => e.key == 'Reng10c');
      expect(
        reng10c['author'],
        'Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz',
      );
      expect(reng10c['pages'], '1\u201410');

      final knuth = entries.firstWhere((e) => e.key == 'Knuth1984');
      expect(knuth['pages'], '97\u2013111');
      expect(knuth['author'], 'Donald E. Knuth');

      final misc = entries.firstWhere((e) => e.key == 'Renggli2024');
      expect(misc['note'], 'well-known');
    });

    test('round-trip via raw toString()', () {
      for (final entry in entries) {
        final parsed = entryParser.parse(entry.toString()).value;
        expect(
          parsed,
          isBibTeXEntry(type: entry.type, key: entry.key, fields: entry.fields),
        );
      }
    });
  });

  group('real-world literatur.bib pattern', () {
    test('parses full fixture with comments and trailing commas', () {
      final entries = parseEntries(realWorldFixture).toList();
      expect(entries.length, 3);
      expect(entries[0].key, 'abadi-et-al-misc2015');
      expect(
        entries[0]['author'],
        'Martín Abadi and Ashish Agarwal and Jeffrey Dean',
      );
      expect(
        entries[0].getField('author')?.value,
        'Martín Abadi and Ashish Agarwal and Jeffrey Dean',
      );
      expect(
        entries[0]['title'],
        'TensorFlow: Large-Scale Machine Learning on Heterogeneous Systems',
      );
      expect(
        entries[0].getField('title')?.value,
        'TensorFlow: Large-Scale Machine Learning on Heterogeneous Systems',
      );

      expect(entries[1].key, 'abbe-et-al-neurips2024');
      expect(entries[1]['pages'], '27850\u201327895');
      expect(entries[1].getField('pages')?.value, '27850\u201327895');

      expect(entries[2].key, 'aljazzar-leue-aij2011');
      expect(entries[2].getField('pages')?.value, '2129\u20132154');
      expect(entries[2].getField('journal')?.rawValue, 'aij');
      expect(entries[2]['pages'], '2129\u20132154');
      expect(entries[2].getRaw('journal'), 'aij');
    });

    test('streams real-world fixture', () async {
      final streamed = await parseStream(realWorldFixture).toList();
      expect(streamed.length, 3);
      expect(streamed[2].key, 'aljazzar-leue-aij2011');
    });

    test('parses full /tmp/literatur.bib if present', () {
      final file = File('/tmp/literatur.bib');
      if (!file.existsSync()) return;
      final entries = parseEntries(file.readAsStringSync()).toList();
      expect(entries.length, 2304);
    }, testOn: 'vm');
  });

  group('web application examples configuration', () {
    test('web/bibtex/bibtex.html declares valid example buttons', () {
      final file = File('web/bibtex/bibtex.html');
      if (!file.existsSync()) return;
      final html = file.readAsStringSync();
      expect(html, contains('class="examples-bar"'));
      expect(
        html,
        contains(
          'data-url="https://raw.githubusercontent.com/scgbern/scgbib/main/scg.bib"',
        ),
      );
      expect(
        html,
        contains(
          'data-url="https://raw.githubusercontent.com/aibasel/bib/refs/heads/main/literatur.bib"',
        ),
      );
      expect(
        html,
        contains(
          'data-url="https://raw.githubusercontent.com/wkjarosz/rendering-bib/master/rendering-bibtex.bib"',
        ),
      );
      expect(
        html,
        contains(
          'data-url="https://raw.githubusercontent.com/OMR-Research/omr-research.github.io/master/OMR-Research.bib"',
        ),
      );
      expect(
        html,
        contains(
          'data-url="https://raw.githubusercontent.com/iridia-ulb/references/master/biblio.bib"',
        ),
      );
    }, testOn: 'vm');
  });
}

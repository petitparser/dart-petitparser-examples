import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

void main() {
  test('latex decoder linter', () {
    final decoder = const LatexDecoderDefinition().build();
    expect(
      linter(
        decoder,
        excludedRules: {'Duplicate parser', 'Nested choice'},
        excludedTypes: {},
      ),
      isEmpty,
    );
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

    test(
      'strips matching outer delimiters without corrupting multiple tokens',
      () {
        expect(normalizeFieldValue('{Knuth} and {Steele}'), 'Knuth and Steele');
        expect(
          normalizeFieldValue('"Knuth" and "Steele"'),
          '"Knuth" and "Steele"',
        );
        expect(normalizeFieldValue('{{Knuth and Steele}}'), 'Knuth and Steele');
        expect(normalizeFieldValue('"{Knuth and Steele}"'), 'Knuth and Steele');
        expect(
          normalizeFieldValue(r'{\{foo\} and \{bar\}}'),
          '{foo} and {bar}',
        );
      },
    );

    test('expands LaTeX accents', () {
      expect(normalizeFieldValue(r"{\'e}"), 'é');
      expect(normalizeFieldValue(r'{\`e}'), 'è');
      expect(normalizeFieldValue(r'{D\"{o}derlein}'), 'Döderlein');
      expect(normalizeFieldValue(r'{D\"oderlein}'), 'Döderlein');
      expect(normalizeFieldValue(r"{S\'{e}bastien}"), 'Sébastien');
      expect(normalizeFieldValue(r"{S\'ebastien}"), 'Sébastien');
      expect(normalizeFieldValue(r"{S{\'e}bastien}"), 'Sébastien');
      expect(normalizeFieldValue(r'{Chi\c{s}}'), 'Chiș');
      expect(normalizeFieldValue(r'{Chi\cs}'), 'Chiș');
      expect(normalizeFieldValue(r'{Chi\c s}'), 'Chiș');
      expect(normalizeFieldValue(r'{B\"{u}hlmann}'), 'Bühlmann');
      expect(normalizeFieldValue(r'{B\"uhlmann}'), 'Bühlmann');
      expect(normalizeFieldValue(r"{Ot\'{a}vio}"), 'Otávio');
      expect(normalizeFieldValue(r"{Ot\'avio}"), 'Otávio');
      expect(normalizeFieldValue(r"{Dvo\v{r}\'{a}k}"), 'Dvořák');
      expect(normalizeFieldValue(r"{\v{C}ern\'{y}}"), 'Černý');
    });

    test('handles whitespace around accents and letters', () {
      expect(normalizeFieldValue(r'{\c{ s }}'), 'ș');
      expect(normalizeFieldValue(r'{\" {o} }'), 'ö');
      expect(normalizeFieldValue(r'{\"  o }'), 'ö');
      expect(normalizeFieldValue(r'{\" o}'), 'ö');
      expect(normalizeFieldValue(r'\~ {n}'), 'ñ');
      expect(normalizeFieldValue(r'\^ {a}'), 'â');
    });

    test('expands uppercase accents', () {
      expect(normalizeFieldValue(r'{\"A}'), 'Ä');
      expect(normalizeFieldValue(r'{\"O}'), 'Ö');
      expect(normalizeFieldValue(r'{\"U}'), 'Ü');
      expect(normalizeFieldValue(r"{\'E}"), 'É');
      expect(normalizeFieldValue(r'{\`A}'), 'À');
      expect(normalizeFieldValue(r'{\^{I}}'), 'Î');
      expect(normalizeFieldValue(r'{\v{S}}'), 'Š');
      expect(normalizeFieldValue(r'{\c{S}}'), 'Ș');
      expect(normalizeFieldValue(r'{\c{C}}'), 'Ç');
    });

    test('expands dotless i and j accents', () {
      expect(normalizeFieldValue(r"{\'{\i}}"), 'í');
      expect(normalizeFieldValue(r"{\'\i}"), 'í');
      expect(normalizeFieldValue(r"{\^{\i}}"), 'î');
      expect(normalizeFieldValue(r'{\`{\i}}'), 'ì');
      expect(normalizeFieldValue(r'{\"{\i}}'), 'ï');
      expect(normalizeFieldValue(r'{\~{\i}}'), 'ĩ');
      expect(normalizeFieldValue(r'{\={\i}}'), 'ī');
      expect(normalizeFieldValue(r'{\i}'), 'ı');
      expect(normalizeFieldValue(r'{\j}'), 'ȷ');
    });

    test('expands all accent families', () {
      expect(normalizeFieldValue(r'\~{a}\~{n}\~{o}\~{A}\~{N}\~{O}'), 'ãñõÃÑÕ');
      expect(normalizeFieldValue(r'\={a}\={e}\={i}\={o}\={u}'), 'āēīōū');
      expect(normalizeFieldValue(r'\u{g}\u{G}\u{a}\u{e}'), 'ğĞăĕ');
      expect(normalizeFieldValue(r'\.{z}\.{Z}\.{c}\.{g}\.{e}'), 'żŻċġė');
      expect(normalizeFieldValue(r'\H{o}\H{O}\H{u}\H{U}'), 'őŐűŰ');
      expect(normalizeFieldValue(r'\r{a}\r{A}\r{u}\r{U}'), 'åÅůŮ');
      expect(normalizeFieldValue(r'\k{a}\k{A}\k{e}\k{E}'), 'ąĄęĘ');
      expect(normalizeFieldValue(r'\d{a}\d{e}\d{i}\d{o}\d{u}'), 'ạẹịọụ');
      expect(normalizeFieldValue(r'\b{a}\b{A}'), 'ḇḆ');
    });

    test('expands special macros', () {
      expect(normalizeFieldValue(r'{\ss}'), 'ß');
      expect(normalizeFieldValue(r'\ss{}'), 'ß');
      expect(normalizeFieldValue(r'{\aa}'), 'å');
      expect(normalizeFieldValue(r'{\AA}'), 'Å');
      expect(normalizeFieldValue(r'{\o}'), 'ø');
      expect(normalizeFieldValue(r'{\O}'), 'Ø');
      expect(normalizeFieldValue(r'{\ae}'), 'æ');
      expect(normalizeFieldValue(r'{\AE}'), 'Æ');
      expect(normalizeFieldValue(r'{\oe}'), 'œ');
      expect(normalizeFieldValue(r'{\OE}'), 'Œ');
      expect(normalizeFieldValue(r'{\l}'), 'ł');
      expect(normalizeFieldValue(r'{\L}'), 'Ł');
      expect(normalizeFieldValue(r'{\i}'), 'ı');
    });

    test('expands math symbols, Greek letters, and branding macros', () {
      expect(
        normalizeFieldValue(r'\alpha \beta \gamma \lambda \omega \Theta'),
        'α β γ λ ω Θ',
      );
      expect(
        normalizeFieldValue(
          r'\times \wedge \sim \neq \tau \pi \nu \pm \le \ge',
        ),
        '× ∧ ~ ≠ τ π ν ± ≤ ≥',
      );
      expect(normalizeFieldValue(r'\ie, \eg'), 'i.e., e.g.');
      expect(
        normalizeFieldValue(r'\LaTeX{} and \TeX{} and \BibTeX{}'),
        'LaTeX and TeX and BibTeX',
      );
    });

    test('unescapes LaTeX symbols', () {
      expect(
        normalizeFieldValue(r'{Journal of Systems \& Software, 2021}'),
        'Journal of Systems & Software, 2021',
      );
      expect(normalizeFieldValue(r'{100\%}'), '100%');
      expect(normalizeFieldValue(r'{\$10}'), '\$10');
      expect(normalizeFieldValue(r'{\#1}'), '#1');
      expect(normalizeFieldValue(r'{foo\_bar}'), 'foo_bar');
      expect(normalizeFieldValue(r'\{foo\}'), '{foo}');
    });

    test('handles punctuation, spacing, and linebreaks', () {
      expect(
        normalizeFieldValue(r'{Zurich\\ Switzerland}'),
        'Zurich Switzerland',
      );
      expect(normalizeFieldValue(r'{Ratio 1\:2}'), 'Ratio 1:2');
      expect(normalizeFieldValue(r'{soft\-hyphen}'), 'softhyphen');
      expect(normalizeFieldValue(r'{italic\/correction}'), 'italiccorrection');
      expect(normalizeFieldValue(r'{input\slash{}output}'), 'input/output');
      expect(normalizeFieldValue(r'{A\ldots B\dots C}'), 'A… B… C');
      expect(
        normalizeFieldValue(
          r'\textquoteleft{}left\textquoteright{} and \textquotedblleft{}double\textquotedblright',
        ),
        '‘left’ and “double”',
      );
      expect(
        normalizeFieldValue(r'\textemdash and \textendash and \–'),
        '— and – and –',
      );
    });

    test('strips formatting markup and font switches', () {
      expect(normalizeFieldValue(r'{{\em foo}}'), 'foo');
      expect(normalizeFieldValue(r'{\emph{important}}'), 'important');
      expect(normalizeFieldValue(r'{\textbf{bold}}'), 'bold');
      expect(normalizeFieldValue(r'{\textit{italic}}'), 'italic');
      expect(normalizeFieldValue(r'{\texttt{code}}'), 'code');
      expect(normalizeFieldValue(r'{\textsc{smallcaps}}'), 'smallcaps');
      expect(
        normalizeFieldValue(r'{\url{https://example.com}}'),
        'https://example.com',
      );
      expect(normalizeFieldValue(r'{\path{/usr/bin}}'), '/usr/bin');
      expect(normalizeFieldValue(r'{\cite{knuth1984}}'), 'knuth1984');
      expect(normalizeFieldValue(r'{\textbf{\emph{deep}}}'), 'deep');
      expect(
        normalizeFieldValue(
          r'{\bf bold} and {\it italic} and {\rm roman} and {\sf sans} and {\tt mono}',
        ),
        'bold and italic and roman and sans and mono',
      );
      expect(normalizeFieldValue(r'{\fIpersistent\fR}'), 'persistent');
    });

    test('decodes HTML entities', () {
      expect(
        normalizeFieldValue(r'{Systems \&#38; Software}'),
        'Systems & Software',
      );
      expect(normalizeFieldValue(r'{A &mdash; B}'), 'A — B');
      expect(normalizeFieldValue(r"{it&rsquo;s}"), 'it’s');
      expect(normalizeFieldValue(r'{G&ouml;del}'), 'Gödel');
      expect(normalizeFieldValue(r'{&#60;tag&#62;}'), '<tag>');
      expect(normalizeFieldValue(r'{&#x26; and &#X3C;}'), '& and <');
      expect(normalizeFieldValue(r'{\&#x26; and \&amp;}'), '& and &');
    });

    test('preserves dashes in URLs and DOIs', () {
      expect(
        normalizeFieldValue('{https://example.com/foo--bar}', key: 'url'),
        'https://example.com/foo--bar',
      );
      expect(
        normalizeFieldValue('{10.1007/978-3-540-27836-8--53}', key: 'doi'),
        '10.1007/978-3-540-27836-8--53',
      );
    });

    test('handles unmatched braces and raw UTF-8 content', () {
      expect(normalizeFieldValue(r'{{\em foo}}'), 'foo');
      expect(normalizeFieldValue(r'foo{bar'), 'foobar');
      expect(normalizeFieldValue(r'foo}bar'), 'foobar');
      expect(
        normalizeFieldValue(r'{The {DNA} of {PETIT}}'),
        'The DNA of PETIT',
      );
      expect(normalizeFieldValue(r'{{A} and {B}}'), 'A and B');
      expect(normalizeFieldValue(r'{{'), '');
      expect(normalizeFieldValue(r'}}'), '');
      expect(
        normalizeFieldValue(r'München and Z\~urich'),
        'München and Zũrich',
      );
      expect(
        normalizeFieldValue(r'Dvořák and Jan\v{a}\v{c}ek'),
        'Dvořák and Janǎček',
      );
    });
  });
}

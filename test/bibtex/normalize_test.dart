import 'package:checks/checks.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/scaffolding.dart';

void main() {
  test('latex decoder linter', () {
    final decoder = const LatexDecoderDefinition().build();
    check(
      linter(
        decoder,
        excludedRules: {'Duplicate parser', 'Nested choice'},
        excludedTypes: {},
      ),
    ).isEmpty();
  });

  group('normalizeFieldValue', () {
    test('handles empty and blank values', () {
      check(normalizeFieldValue('')).equals('');
      check(normalizeFieldValue('{}')).equals('');
      check(normalizeFieldValue('""')).equals('');
    });

    test('strips outer braces', () {
      check(normalizeFieldValue('{hello}')).equals('hello');
    });

    test('strips outer quotes', () {
      check(normalizeFieldValue('"hello"')).equals('hello');
    });

    test('replaces --- with em dash', () {
      check(normalizeFieldValue('{A---B}')).equals('A\u2014B');
    });

    test('replaces -- with en dash', () {
      check(normalizeFieldValue('{10--20}')).equals('10\u201320');
    });

    test('does not affect single hyphens', () {
      check(normalizeFieldValue('{well-known}')).equals('well-known');
    });

    test(
      'strips matching outer delimiters without corrupting multiple tokens',
      () {
        check(normalizeFieldValue('{Knuth} and {Steele}'))
            .equals('Knuth and Steele');
        check(normalizeFieldValue('"Knuth" and "Steele"'))
            .equals('"Knuth" and "Steele"');
        check(normalizeFieldValue('{{Knuth and Steele}}'))
            .equals('Knuth and Steele');
        check(normalizeFieldValue('"{Knuth and Steele}"'))
            .equals('Knuth and Steele');
        check(normalizeFieldValue(r'{\{foo\} and \{bar\}}'))
            .equals('{foo} and {bar}');
      },
    );

    test('expands LaTeX accents', () {
      check(normalizeFieldValue(r"{\'e}")).equals('é');
      check(normalizeFieldValue(r'{\`e}')).equals('è');
      check(normalizeFieldValue(r'{D\"{o}derlein}')).equals('Döderlein');
      check(normalizeFieldValue(r'{D\"oderlein}')).equals('Döderlein');
      check(normalizeFieldValue(r"{S\'{e}bastien}")).equals('Sébastien');
      check(normalizeFieldValue(r"{S\'ebastien}")).equals('Sébastien');
      check(normalizeFieldValue(r"{S{\'e}bastien}")).equals('Sébastien');
      check(normalizeFieldValue(r'{Chi\c{s}}')).equals('Chiș');
      check(normalizeFieldValue(r'{Chi\cs}')).equals('Chiș');
      check(normalizeFieldValue(r'{Chi\c s}')).equals('Chiș');
      check(normalizeFieldValue(r'{B\"{u}hlmann}')).equals('Bühlmann');
      check(normalizeFieldValue(r'{B\"uhlmann}')).equals('Bühlmann');
      check(normalizeFieldValue(r"{Ot\'{a}vio}")).equals('Otávio');
      check(normalizeFieldValue(r"{Ot\'avio}")).equals('Otávio');
      check(normalizeFieldValue(r"{Dvo\v{r}\'{a}k}")).equals('Dvořák');
      check(normalizeFieldValue(r"{\v{C}ern\'{y}}")).equals('Černý');
    });

    test('handles whitespace around accents and letters', () {
      check(normalizeFieldValue(r'{\c{ s }}')).equals('ș');
      check(normalizeFieldValue(r'{\" {o} }')).equals('ö');
      check(normalizeFieldValue(r'{\"  o }')).equals('ö');
      check(normalizeFieldValue(r'{\" o}')).equals('ö');
      check(normalizeFieldValue(r'\~ {n}')).equals('ñ');
      check(normalizeFieldValue(r'\^ {a}')).equals('â');
    });

    test('expands uppercase accents', () {
      check(normalizeFieldValue(r'{\"A}')).equals('Ä');
      check(normalizeFieldValue(r'{\"O}')).equals('Ö');
      check(normalizeFieldValue(r'{\"U}')).equals('Ü');
      check(normalizeFieldValue(r"{\'E}")).equals('É');
      check(normalizeFieldValue(r'{\`A}')).equals('À');
      check(normalizeFieldValue(r'{\^{I}}')).equals('Î');
      check(normalizeFieldValue(r'{\v{S}}')).equals('Š');
      check(normalizeFieldValue(r'{\c{S}}')).equals('Ș');
      check(normalizeFieldValue(r'{\c{C}}')).equals('Ç');
    });

    test('expands dotless i and j accents', () {
      check(normalizeFieldValue(r"{\'{\i}}")).equals('í');
      check(normalizeFieldValue(r"{\'\i}")).equals('í');
      check(normalizeFieldValue(r"{\^{\i}}")).equals('î');
      check(normalizeFieldValue(r'{\`{\i}}')).equals('ì');
      check(normalizeFieldValue(r'{\"{\i}}')).equals('ï');
      check(normalizeFieldValue(r'{\~{\i}}')).equals('ĩ');
      check(normalizeFieldValue(r'{\={\i}}')).equals('ī');
      check(normalizeFieldValue(r'{\i}')).equals('ı');
      check(normalizeFieldValue(r'{\j}')).equals('ȷ');
    });

    test('expands all accent families', () {
      check(normalizeFieldValue(r'\~{a}\~{n}\~{o}\~{A}\~{N}\~{O}'))
          .equals('ãñõÃÑÕ');
      check(normalizeFieldValue(r'\={a}\={e}\={i}\={o}\={u}')).equals('āēīōū');
      check(normalizeFieldValue(r'\u{g}\u{G}\u{a}\u{e}')).equals('ğĞăĕ');
      check(normalizeFieldValue(r'\.{z}\.{Z}\.{c}\.{g}\.{e}')).equals('żŻċġė');
      check(normalizeFieldValue(r'\H{o}\H{O}\H{u}\H{U}')).equals('őŐűŰ');
      check(normalizeFieldValue(r'\r{a}\r{A}\r{u}\r{U}')).equals('åÅůŮ');
      check(normalizeFieldValue(r'\k{a}\k{A}\k{e}\k{E}')).equals('ąĄęĘ');
      check(normalizeFieldValue(r'\d{a}\d{e}\d{i}\d{o}\d{u}')).equals('ạẹịọụ');
      check(normalizeFieldValue(r'\b{a}\b{A}')).equals('ḇḆ');
    });

    test('expands special macros', () {
      check(normalizeFieldValue(r'{\ss}')).equals('ß');
      check(normalizeFieldValue(r'\ss{}')).equals('ß');
      check(normalizeFieldValue(r'{\aa}')).equals('å');
      check(normalizeFieldValue(r'{\AA}')).equals('Å');
      check(normalizeFieldValue(r'{\o}')).equals('ø');
      check(normalizeFieldValue(r'{\O}')).equals('Ø');
      check(normalizeFieldValue(r'{\ae}')).equals('æ');
      check(normalizeFieldValue(r'{\AE}')).equals('Æ');
      check(normalizeFieldValue(r'{\oe}')).equals('œ');
      check(normalizeFieldValue(r'{\OE}')).equals('Œ');
      check(normalizeFieldValue(r'{\l}')).equals('ł');
      check(normalizeFieldValue(r'{\L}')).equals('Ł');
      check(normalizeFieldValue(r'{\i}')).equals('ı');
    });

    test('expands math symbols, Greek letters, and branding macros', () {
      check(normalizeFieldValue(r'\alpha \beta \gamma \lambda \omega \Theta'))
          .equals('α β γ λ ω Θ');
      check(
        normalizeFieldValue(
          r'\times \wedge \sim \neq \tau \pi \nu \pm \le \ge',
        ),
      ).equals('× ∧ ~ ≠ τ π ν ± ≤ ≥');
      check(normalizeFieldValue(r'\ie, \eg')).equals('i.e., e.g.');
      check(normalizeFieldValue(r'\LaTeX{} and \TeX{} and \BibTeX{}'))
          .equals('LaTeX and TeX and BibTeX');
    });

    test('unescapes LaTeX symbols', () {
      check(normalizeFieldValue(r'{Journal of Systems \& Software, 2021}'))
          .equals('Journal of Systems & Software, 2021');
      check(normalizeFieldValue(r'{100\%}')).equals('100%');
      check(normalizeFieldValue(r'{\$10}')).equals('\$10');
      check(normalizeFieldValue(r'{\#1}')).equals('#1');
      check(normalizeFieldValue(r'{foo\_bar}')).equals('foo_bar');
      check(normalizeFieldValue(r'\{foo\}')).equals('{foo}');
    });

    test('handles punctuation, spacing, and linebreaks', () {
      check(normalizeFieldValue(r'{Zurich\\ Switzerland}'))
          .equals('Zurich Switzerland');
      check(normalizeFieldValue(r'{Ratio 1\:2}')).equals('Ratio 1:2');
      check(normalizeFieldValue(r'{soft\-hyphen}')).equals('softhyphen');
      check(normalizeFieldValue(r'{italic\/correction}'))
          .equals('italiccorrection');
      check(normalizeFieldValue(r'{input\slash{}output}'))
          .equals('input/output');
      check(normalizeFieldValue(r'{A\ldots B\dots C}')).equals('A… B… C');
      check(
        normalizeFieldValue(
          r'\textquoteleft{}left\textquoteright{} and \textquotedblleft{}double\textquotedblright',
        ),
      ).equals('‘left’ and “double”');
      check(normalizeFieldValue(r'\textemdash and \textendash and \–'))
          .equals('— and – and –');
    });

    test('strips formatting markup and font switches', () {
      check(normalizeFieldValue(r'{{\em foo}}')).equals('foo');
      check(normalizeFieldValue(r'{\emph{important}}')).equals('important');
      check(normalizeFieldValue(r'{\textbf{bold}}')).equals('bold');
      check(normalizeFieldValue(r'{\textit{italic}}')).equals('italic');
      check(normalizeFieldValue(r'{\texttt{code}}')).equals('code');
      check(normalizeFieldValue(r'{\textsc{smallcaps}}')).equals('smallcaps');
      check(normalizeFieldValue(r'{\url{https://example.com}}'))
          .equals('https://example.com');
      check(normalizeFieldValue(r'{\path{/usr/bin}}')).equals('/usr/bin');
      check(normalizeFieldValue(r'{\cite{knuth1984}}')).equals('knuth1984');
      check(normalizeFieldValue(r'{\textbf{\emph{deep}}}')).equals('deep');
      check(
        normalizeFieldValue(
          r'{\bf bold} and {\it italic} and {\rm roman} and {\sf sans} and {\tt mono}',
        ),
      ).equals('bold and italic and roman and sans and mono');
      check(normalizeFieldValue(r'{\fIpersistent\fR}')).equals('persistent');
    });

    test('decodes HTML entities', () {
      check(normalizeFieldValue(r'{Systems \&#38; Software}'))
          .equals('Systems & Software');
      check(normalizeFieldValue(r'{A &mdash; B}')).equals('A — B');
      check(normalizeFieldValue(r"{it&rsquo;s}")).equals('it’s');
      check(normalizeFieldValue(r'{G&ouml;del}')).equals('Gödel');
      check(normalizeFieldValue(r'{&#60;tag&#62;}')).equals('<tag>');
      check(normalizeFieldValue(r'{&#x26; and &#X3C;}')).equals('& and <');
      check(normalizeFieldValue(r'{\&#x26; and \&amp;}')).equals('& and &');
    });

    test('preserves dashes in URLs and DOIs', () {
      check(normalizeFieldValue('{https://example.com/foo--bar}', key: 'url'))
          .equals('https://example.com/foo--bar');
      check(normalizeFieldValue('{10.1007/978-3-540-27836-8--53}', key: 'doi'))
          .equals('10.1007/978-3-540-27836-8--53');
    });

    test('handles unmatched braces and raw UTF-8 content', () {
      check(normalizeFieldValue(r'{{\em foo}}')).equals('foo');
      check(normalizeFieldValue(r'foo{bar')).equals('foobar');
      check(normalizeFieldValue(r'foo}bar')).equals('foobar');
      check(normalizeFieldValue(r'{The {DNA} of {PETIT}}'))
          .equals('The DNA of PETIT');
      check(normalizeFieldValue(r'{{A} and {B}}')).equals('A and B');
      check(normalizeFieldValue(r'{{')).equals('');
      check(normalizeFieldValue(r'}}')).equals('');
      check(normalizeFieldValue(r'München and Z\~urich'))
          .equals('München and Zũrich');
      check(normalizeFieldValue(r'Dvořák and Jan\v{a}\v{c}ek'))
          .equals('Dvořák and Janǎček');
    });
  });
}

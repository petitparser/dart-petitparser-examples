import 'package:checks/checks.dart';
import 'package:petitparser_examples/bibtex.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('values', () {
    test('raw and normalized values', () {
      final field = BibTeXField('author', r"{S\'{e}bastien}");
      check(field.rawKey).equals('author');
      check(field.rawValue).equals(r"{S\'{e}bastien}");
      check(field.key).equals('author');
      check(field.value).equals('Sébastien');
      check(field.toString()).equals(r"author = {S\'{e}bastien}");
    });

    test('caching of normalized key and value', () {
      final field = BibTeXField('booktitle', '{A---B}');
      check(identical(field.key, field.key)).isTrue();
      check(identical(field.value, field.value)).isTrue();
    });

    test('empty and blank values', () {
      final fieldEmpty = BibTeXField('', '');
      check(fieldEmpty.rawKey).equals('');
      check(fieldEmpty.rawValue).equals('');
      check(fieldEmpty.key).equals('');
      check(fieldEmpty.value).equals('');

      final fieldBraces = BibTeXField('note', '{}');
      check(fieldBraces.key).equals('note');
      check(fieldBraces.value).equals('');
    });
  });

  group('dashes normalization', () {
    test('dashes normalization via field value', () {
      final fieldEn = BibTeXField('pages', '{10--20}');
      check(fieldEn.key).equals('pages');
      check(fieldEn.value).equals('10\u201320');

      final fieldEm = BibTeXField('title', '{A---B}');
      check(fieldEm.key).equals('title');
      check(fieldEm.value).equals('A\u2014B');

      final fieldHyphen = BibTeXField('note', '{well-known}');
      check(fieldHyphen.key).equals('note');
      check(fieldHyphen.value).equals('well-known');
    });
  });

  group('equality', () {
    test('equality and hashCode', () {
      final f1 = BibTeXField('title', '{foo}');
      final f2 = BibTeXField('title', '{foo}');
      final f3 = BibTeXField('other', '{foo}');
      final f4 = BibTeXField('title', '{bar}');
      check(f1).equals(f2);
      check(f1.hashCode).equals(f2.hashCode);
      check(f1).not((it) => it.equals(f3));
      check(f1).not((it) => it.equals(f4));
    });
  });
}

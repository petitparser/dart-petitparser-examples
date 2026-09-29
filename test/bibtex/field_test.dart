import 'package:petitparser_examples/bibtex.dart';
import 'package:test/test.dart';

void main() {
  group('values', () {
    test('raw and normalized values', () {
      final field = BibTeXField('author', r"{S\'{e}bastien}");
      expect(field.rawKey, 'author');
      expect(field.rawValue, r"{S\'{e}bastien}");
      expect(field.key, 'author');
      expect(field.value, 'Sébastien');
      expect(field.toString(), r"author = {S\'{e}bastien}");
    });

    test('caching of normalized key and value', () {
      final field = BibTeXField('booktitle', '{A---B}');
      expect(identical(field.key, field.key), isTrue);
      expect(identical(field.value, field.value), isTrue);
    });

    test('empty and blank values', () {
      final fieldEmpty = BibTeXField('', '');
      expect(fieldEmpty.rawKey, '');
      expect(fieldEmpty.rawValue, '');
      expect(fieldEmpty.key, '');
      expect(fieldEmpty.value, '');

      final fieldBraces = BibTeXField('note', '{}');
      expect(fieldBraces.key, 'note');
      expect(fieldBraces.value, '');
    });
  });

  group('dashes normalization', () {
    test('dashes normalization via field value', () {
      final fieldEn = BibTeXField('pages', '{10--20}');
      expect(fieldEn.key, 'pages');
      expect(fieldEn.value, '10\u201320');

      final fieldEm = BibTeXField('title', '{A---B}');
      expect(fieldEm.key, 'title');
      expect(fieldEm.value, 'A\u2014B');

      final fieldHyphen = BibTeXField('note', '{well-known}');
      expect(fieldHyphen.key, 'note');
      expect(fieldHyphen.value, 'well-known');
    });
  });

  group('equality', () {
    test('equality and hashCode', () {
      final f1 = BibTeXField('title', '{foo}');
      final f2 = BibTeXField('title', '{foo}');
      final f3 = BibTeXField('other', '{foo}');
      final f4 = BibTeXField('title', '{bar}');
      expect(f1, equals(f2));
      expect(f1.hashCode, equals(f2.hashCode));
      expect(f1, isNot(equals(f3)));
      expect(f1, isNot(equals(f4)));
    });
  });
}

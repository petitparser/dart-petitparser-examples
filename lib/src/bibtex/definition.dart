import 'package:petitparser/petitparser.dart';

import 'entry.dart';
import 'field.dart';

/// Grammar definition for BibTeX files.
///
/// Adapted from the grammar published by Oscar Nierstrasz at
/// https://twitter.com/onierstrasz/status/1621600391946289155.
class BibTeXDefinition extends GrammarDefinition<List<BibTeXEntry>> {
  @override
  Parser<List<BibTeXEntry>> start() => ref0(entries).end();

  // Entries
  Parser<List<BibTeXEntry>> entries() =>
      ref0(entry).star().skip(before: ref0(comments), after: ref0(comments));

  /// A single BibTeX entry (e.g. `@article{key, ...}`).
  Parser<BibTeXEntry> entry() =>
      seq5(
            type.trim(),
            char('{').trim(),
            citeKey.trim(),
            seq2(
              char(',').trim(),
              ref0(fields),
            ).map2((_, fields) => fields).optionalWith(const <BibTeXField>[]),
            char('}').trim(),
          )
          .map5(
            (type, _, key, fields, _) =>
                BibTeXEntry(type: type, key: key, fields: fields),
          )
          .skip(before: ref0(comments), after: ref0(comments));

  // Fields
  Parser<List<BibTeXField>> fields() =>
      ref0(field)
          .starSeparated(char(',').trim())
          .map((list) => list.elements)
          .skip(after: char(',').trim().optional());
  Parser<BibTeXField> field() => seq3(
    fieldName.trim(),
    char('=').trim(),
    ref0(fieldValue),
  ).map3((key, _, value) => BibTeXField(key, value));
  Parser<String> fieldValue() => [
    ref0(fieldValueInQuotes),
    ref0(fieldValueInBraces),
    rawString,
  ].toChoiceParser();

  // Quoted strings
  Parser<String> fieldValueInQuotes() => seq3(
    char('"'),
    ref0(fieldStringWithinQuotes),
    char('"'),
  ).flatten(message: 'quoted string expected');
  Parser<List> fieldStringWithinQuotes() =>
      [ref0(fieldCharWithinQuotes), escapeChar].toChoiceParser().star();
  Parser<String> fieldCharWithinQuotes() => pattern(r'^\"');

  // Braced strings
  Parser<String> fieldValueInBraces() => seq3(
    char('{'),
    ref0(fieldStringWithinBraces),
    char('}'),
  ).flatten(message: 'braced string expected');
  Parser<List> fieldStringWithinBraces() => [
    ref0(fieldCharWithinBraces),
    escapeChar,
    seq3(char('{'), ref0(fieldStringWithinBraces), char('}')),
  ].toChoiceParser().star();
  Parser<String> fieldCharWithinBraces() => pattern(r'^\{}');

  // Basic strings
  final type = letter()
      .plusString(message: 'type expected')
      .skip(before: char('@'));
  final citeKey = pattern('-a-zA-Z0-9_:./')
      .plusString(message: 'citation key expected');
  final fieldName = pattern('a-zA-Z0-9_-')
      .plusString(message: 'field name expected');
  final rawString = pattern('a-zA-Z0-9')
      .plusString(message: 'raw string expected');

  // Other tokens
  final escapeChar = seq2(char(r'\'), any());

  // Whitespace comments
  Parser<void> comments() =>
      [ref0(commentBlock), pattern('^@').plusString()].toChoiceParser().star();
  Parser<void> commentBlock() => seq3(
    string('@comment', ignoreCase: true),
    whitespace().star(),
    [
      seq2(
        seq3(char('{'), citeKey.trim(), anyOf(',}')).not(),
        ref0(fieldValueInBraces),
      ),
      seq3(char('('), pattern('^)').star(), char(')')),
      seq2(anyOf('{(').not(), pattern('^\r\n').star()),
    ].toChoiceParser(),
  );
}

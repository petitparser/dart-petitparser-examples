/// A simple CSV (comma seperated text) parser.
library;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser/petitparser.dart' as pp;

/// Customizable parser defintion for tabular text files.
class TabularDefinition extends GrammarDefinition<List<List<String>>> {
  /// Definition for "Comma-separated values" (CSV) input.
  factory TabularDefinition.csv() => TabularDefinition(
    quote: '"'.toParser(),
    escape: '""'.toParser().map((_) => '"'),
    delimiter: ','.toParser(),
    newline: pp.newline(),
  );

  /// Definition for "Tab-separated values" (TSV) input.
  factory TabularDefinition.tsv() => TabularDefinition(
    quote: failure(),
    escape: seq2(char(r'\'), any()).map2(
      (_, value) => switch (value) {
        't' => '\t',
        'n' => '\n',
        'r' => '\r',
        _ => value,
      },
    ),
    delimiter: '\t'.toParser(),
    newline: pp.newline(),
  );

  /// Generic constructor for tabular text files.
  TabularDefinition({
    required this.quote,
    required this.escape,
    required this.delimiter,
    required this.newline,
  });

  /// Specifies how values are quoted.
  final Parser<String> quote;

  /// Specifies how characters are escaped.
  final Parser<String> escape;

  /// Sepcifies how values are delimited in a row.
  final Parser<String> delimiter;

  /// Specifies how rows are delimited in a file.
  final Parser<String> newline;

  @override
  Parser<List<List<String>>> start() => ref0(_lines).end();

  Parser<List<List<String>>> _lines() =>
      ref0(_records).starSeparated(newline).map((list) => list.elements);
  Parser<List<String>> _records() =>
      ref0(_field).starSeparated(delimiter).map((list) => list.elements);

  Parser<String> _field() =>
      [ref0(_quotedField), ref0(_plainField)].toChoiceParser();

  Parser<String> _quotedField() =>
      ref0(_quotedFieldContent).skip(before: quote, after: quote);
  Parser<String> _quotedFieldContent() =>
      ref0(_quotedFieldChar).star().map((list) => list.join());
  Parser<String> _quotedFieldChar() => [escape, quote.neg()].toChoiceParser();

  Parser<String> _plainField() => ref0(_plainFieldContent);
  Parser<String> _plainFieldContent() =>
      ref0(_plainFieldChar).star().map((list) => list.join());
  Parser<String> _plainFieldChar() => [
    escape,
    [delimiter, newline].toChoiceParser().neg(),
  ].toChoiceParser();
}

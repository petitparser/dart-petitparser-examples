/// A simple CSV (comma seperated text) parser.
library;

import 'package:petitparser/petitparser.dart';

class CsvDefinition extends GrammarDefinition<List<List<String>>> {
  CsvDefinition({
    this.quoteChar = '"',
    this.escapeChar = '"',
    this.delimiter = ",",
    this.newline = "\n",
  });

  final String quoteChar;
  final String escapeChar;
  final String delimiter;
  final String newline;

  @override
  Parser<List<List<String>>> start() => ref0(lines).end();

  Parser<List<List<String>>> lines() =>
      ref0(records).starSeparated(string(newline)).map((list) => list.elements);
  Parser<List<String>> records() =>
      ref0(field).starSeparated(char(delimiter)).map((list) => list.elements);

  Parser<String> field() => [
        ref0(quotedField),
        ref0(plainField),
      ].toChoiceParser();

  Parser<String> quotedField() => ref0(quotedFieldContent)
      .skip(before: char(quoteChar), after: char(quoteChar));
  Parser<String> quotedFieldContent() =>
      ref0(quotedFieldChar).star().map((list) => list.join());
  Parser<String> quotedFieldChar() => [
        seq2(char(escapeChar), any()).map2((_, char) => char),
        pattern('^$quoteChar'),
      ].toChoiceParser();

  Parser<String> plainField() => ref0(plainFieldContent);
  Parser<String> plainFieldContent() =>
      ref0(plainFieldChar).star().map((list) => list.join());
  Parser<String> plainFieldChar() => [
        seq2(char(escapeChar), any()).map2((_, char) => char),
        pattern("^$delimiter$newline")
      ].toChoiceParser();
}

import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/csv.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

void main() {
  final csv = CsvDefinition().build();
  test('linter', () {
    expect(linter(csv, excludedTypes: {}), isEmpty);
  });
  test('basic string', () {
    expect(
        csv,
        isSuccess("", value: [
          [""]
        ]));
    expect(
        csv,
        isSuccess("a", value: [
          ["a"]
        ]));
    expect(
        csv,
        isSuccess("ab", value: [
          ["ab"]
        ]));
    expect(
        csv,
        isSuccess("abc", value: [
          ["abc"]
        ]));
  });
  test('quoted string', () {
    expect(
        csv,
        isSuccess("\"\"", value: [
          [""]
        ]));
    expect(
        csv,
        isSuccess("\"a\"", value: [
          ["a"]
        ]));
    expect(
        csv,
        isSuccess("\"ab\"", value: [
          ["ab"]
        ]));
    expect(
        csv,
        isSuccess("\"abc\"", value: [
          ["abc"]
        ]));
    expect(
        csv,
        isSuccess("\"\"\"\"", value: [
          ["\""]
        ]));
  });
  test('fields', () {
    expect(
        csv,
        isSuccess("", value: [
          [""]
        ]));
    expect(
        csv,
        isSuccess("a", value: [
          ["a"]
        ]));
    expect(
        csv,
        isSuccess("a,b", value: [
          ["a", "b"]
        ]));
    expect(
        csv,
        isSuccess("a,b,c", value: [
          ["a", "b", "c"]
        ]));
  });
  test('lines', () {
    expect(
        csv,
        isSuccess("", value: [
          [""]
        ]));
    expect(
        csv,
        isSuccess("a", value: [
          ["a"]
        ]));
    expect(
        csv,
        isSuccess("a\nb", value: [
          ["a"],
          ["b"]
        ]));
    expect(
        csv,
        isSuccess("a\nb\nc", value: [
          ["a"],
          ["b"],
          ["c"]
        ]));
  });
}

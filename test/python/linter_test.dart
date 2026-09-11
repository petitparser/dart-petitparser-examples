import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

void main() {
  final grammar = PythonGrammarDefinition();

  test('grammar linter', () {
    expect(linter(grammar.build()), isEmpty);
  });
}

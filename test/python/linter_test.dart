import 'package:checks/checks.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

void main() {
  final grammar = PythonGrammarDefinition();

  test('grammar linter', () {
    check(linter(grammar.build())).isEmpty();
  });
}

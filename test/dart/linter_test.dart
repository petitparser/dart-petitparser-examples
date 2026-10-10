import 'package:checks/checks.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

void main() {
  final grammar = DartGrammarDefinition();

  test('grammar linter', () {
    check(linter(grammar.build())).isEmpty();
  });
}

import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

void main() {
  final grammar = DartGrammarDefinition();

  test('grammar linter', () {
    expect(linter(grammar.build()), isEmpty);
  });
}

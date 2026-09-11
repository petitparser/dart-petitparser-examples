import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/test.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  test('grammar linter', () {
    final issues = linter(grammar.build());
    expect(issues, isEmpty, reason: issues.join('\n'));
  });
}

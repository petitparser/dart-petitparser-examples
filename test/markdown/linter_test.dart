import 'package:checks/checks.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/markdown.dart';
import 'package:test/scaffolding.dart';

void main() {
  final grammar = MarkdownGrammarDefinition();

  test('grammar linter', () {
    final issues = linter(grammar.build());
    check(because: issues.join('\n'), issues).isEmpty();
  });
}

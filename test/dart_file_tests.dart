/// This test-case automatically generates various tests from Dart source
/// code. Unfortunately the parser is currently unable to parse most of
/// these files.
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:petitparser/core.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

final grammar = DartGrammarDefinition().build();

String addLineNumbers(String input) => input
    .split('\n')
    .mapIndexed(
        (index, value) => '${(index + 1).toString().padLeft(4)}: $value')
    .join('\n');

void generateTests(String title, Directory root) {
  group(title, () {
    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    for (final file in files) {
      test(file.path.substring(root.path.length + 1), () async {
        final input = await file.readAsString();
        final result = grammar.parse(input);
        if (result is Failure) fail('$result\n\n${addLineNumbers(input)}');
      });
    }
  });
}

void main() {
  generateTests('PetitParser', Directory.current);
}

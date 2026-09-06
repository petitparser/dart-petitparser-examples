@TestOn('vm')
library;

import 'dart:io';

import 'package:petitparser/core.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

void main() {
  final dartFiles =
      Directory('.')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .where((file) => !file.path.contains('.dart_tool'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in dartFiles) {
    test(file.path, () {
      final content = file.readAsStringSync();
      try {
        parseDart(content);
      } on ParserException catch (exception) {
        fail(
          '${file.path}:${exception.failure.toPositionString()}: '
          '${exception.failure.message}',
        );
      }
    });
  }
}

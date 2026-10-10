@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:test/scaffolding.dart';

final dartExecutable = Platform.resolvedExecutable;

void main() {
  group('CLI subprocess flags', () {
    test('prints help on -?', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        '-?',
      ]);
      check(res.exitCode).equals(0);
      check(res.stdout.toString()).contains('prolog.dart rules...');
    });

    test('exits with code 1 on unknown option', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        '-xyz',
      ]);
      check(res.exitCode).equals(1);
      check(res.stdout.toString()).contains('Unknown option: -xyz');
    });

    test('exits with code 2 on missing file', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        'nonexistent_rules.pl',
      ]);
      check(res.exitCode).equals(2);
      check(res.stdout.toString())
          .contains('File not found: nonexistent_rules.pl');
    });
  });

  group('Interactive query execution', () {
    test('loads rule file and evaluates query from stdin', () async {
      final tempDir = Directory.systemTemp.createTempSync('prolog_cli_test');
      final ruleFile = File('${tempDir.path}/family.pl');
      ruleFile.writeAsStringSync('''
father(john, mary).
father(john, tom).
sibling(X, Y) :- father(P, X), father(P, Y).
''');

      final process = await Process.start(dartExecutable, [
        'bin/prolog/prolog.dart',
        ruleFile.path,
      ]);

      final outputBuffer = StringBuffer();
      process.stdout.transform(utf8.decoder).listen(outputBuffer.write);

      // Send query and close stdin
      process.stdin.writeln('father(john, Who)');
      await process.stdin.flush();
      await process.stdin.close();

      final exitCode = await process.exitCode;
      check(exitCode).equals(0);

      final output = outputBuffer.toString();
      check(output).contains('?- ');
      check(output).contains('father(john, mary)');
      check(output).contains('father(john, tom)');

      tempDir.deleteSync(recursive: true);
    });
  });
}

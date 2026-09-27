@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

final dartExecutable = () {
  const sdkDart =
      '/opt/homebrew/Caskroom/flutter/3.29.3/flutter/bin/cache/dart-sdk/bin/dart';
  if (File(sdkDart).existsSync()) return sdkDart;
  return Platform.resolvedExecutable;
}();

void main() {
  group('CLI subprocess flags', () {
    test('prints help on -?', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        '-?',
      ]);
      expect(res.exitCode, equals(0));
      expect(res.stdout.toString(), contains('prolog.dart rules...'));
    });

    test('exits with code 1 on unknown option', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        '-xyz',
      ]);
      expect(res.exitCode, equals(1));
      expect(res.stdout.toString(), contains('Unknown option: -xyz'));
    });

    test('exits with code 2 on missing file', () async {
      final res = await Process.run(dartExecutable, [
        'bin/prolog/prolog.dart',
        'nonexistent_rules.pl',
      ]);
      expect(res.exitCode, equals(2));
      expect(
        res.stdout.toString(),
        contains('File not found: nonexistent_rules.pl'),
      );
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
      expect(exitCode, equals(0));

      final output = outputBuffer.toString();
      expect(output, contains('?- '));
      expect(output, contains('father(john, mary)'));
      expect(output, contains('father(john, tom)'));

      tempDir.deleteSync(recursive: true);
    });
  });
}

@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:petitparser_examples/lisp.dart';
import 'package:test/test.dart';

import '../../bin/lisp/lisp.dart';

final dartExecutable = () {
  const sdkDart =
      '/opt/homebrew/Caskroom/flutter/3.29.3/flutter/bin/cache/dart-sdk/bin/dart';
  if (File(sdkDart).existsSync()) return sdkDart;
  return Platform.resolvedExecutable;
}();

void main() {
  group('evalInteractive', () {
    test('evaluates expressions and writes prompt and result', () async {
      final inputController = StreamController<String>();
      final outBytes = <int>[];
      final errBytes = <int>[];
      final outController = StreamController<List<int>>();
      outController.stream.listen(outBytes.addAll);
      final outSink = IOSink(outController);
      final errController = StreamController<List<int>>();
      errController.stream.listen(errBytes.addAll);
      final errSink = IOSink(errController);

      final env = StandardEnvironment(NativeEnvironment()).create();
      evalInteractive(
        lispParser,
        env,
        inputController.stream,
        outSink,
        errSink,
      );

      inputController.add('(+ 2 3)');
      inputController.add('(define x 42)');
      inputController.add('x');
      await pumpEventQueue();

      final out = utf8.decode(outBytes);
      expect(out, contains('>> '));
      expect(out, contains('=> 5'));
      expect(out, contains('=> 42'));
      expect(utf8.decode(errBytes), isEmpty);

      await inputController.close();
      await outSink.close();
      await errSink.close();
    });

    test('handles parser and evaluation errors gracefully', () async {
      final inputController = StreamController<String>();
      final outBytes = <int>[];
      final errBytes = <int>[];
      final outController = StreamController<List<int>>();
      outController.stream.listen(outBytes.addAll);
      final outSink = IOSink(outController);
      final errController = StreamController<List<int>>();
      errController.stream.listen(errBytes.addAll);
      final errSink = IOSink(errController);

      final env = StandardEnvironment(NativeEnvironment()).create();
      evalInteractive(
        lispParser,
        env,
        inputController.stream,
        outSink,
        errSink,
      );

      // Syntax error
      inputController.add('(+ 1 2');
      // Unbound symbol
      inputController.add('(unknown_func 1)');
      await pumpEventQueue();

      final err = utf8.decode(errBytes);
      expect(err, contains('Parser error:'));
      expect(err, contains('Argument error:'));

      await inputController.close();
      await outSink.close();
      await errSink.close();
    });
  });

  group('CLI subprocess', () {
    test('prints help on -?', () async {
      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        '-?',
      ]);
      expect(res.exitCode, equals(0));
      expect(res.stdout.toString(), contains('lisp.dart -n -i [files]'));
      expect(
        res.stdout.toString(),
        contains('-i enforces the interactive mode'),
      );
    });

    test('exits with code 1 on unknown option', () async {
      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        '-invalid',
      ]);
      expect(res.exitCode, equals(1));
      expect(res.stdout.toString(), contains('Unknown option: -invalid'));
    });

    test('exits with code 2 on missing file', () async {
      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        'nonexistent_test_script.lisp',
      ]);
      expect(res.exitCode, equals(2));
      expect(
        res.stdout.toString(),
        contains('File not found: nonexistent_test_script.lisp'),
      );
    });

    test('executes lisp file from argument', () async {
      final tempDir = Directory.systemTemp.createTempSync('lisp_cli_test');
      final scriptFile = File('${tempDir.path}/test.lisp');
      scriptFile.writeAsStringSync('(+ 10 20)');

      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        scriptFile.path,
      ]);
      expect(res.exitCode, equals(0));

      tempDir.deleteSync(recursive: true);
    });
  });
}

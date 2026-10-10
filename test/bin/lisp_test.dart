@TestOn('vm')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:checks/checks.dart';
import 'package:petitparser_examples/lisp.dart';
import 'package:test/scaffolding.dart';

import '../../bin/lisp/lisp.dart';

final dartExecutable = Platform.resolvedExecutable;

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
      check(out).contains('>> ');
      check(out).contains('=> 5');
      check(out).contains('=> 42');
      check(utf8.decode(errBytes)).isEmpty();

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
      check(err).contains('Parser error:');
      check(err).contains('Argument error:');

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
      check(res.exitCode).equals(0);
      check(res.stdout.toString()).contains('lisp.dart -n -i [files]');
      check(res.stdout.toString()).contains('-i enforces the interactive mode');
    });

    test('exits with code 1 on unknown option', () async {
      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        '-invalid',
      ]);
      check(res.exitCode).equals(1);
      check(res.stdout.toString()).contains('Unknown option: -invalid');
    });

    test('exits with code 2 on missing file', () async {
      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        'nonexistent_test_script.lisp',
      ]);
      check(res.exitCode).equals(2);
      check(res.stdout.toString())
          .contains('File not found: nonexistent_test_script.lisp');
    });

    test('executes lisp file from argument', () async {
      final tempDir = Directory.systemTemp.createTempSync('lisp_cli_test');
      final scriptFile = File('${tempDir.path}/test.lisp');
      scriptFile.writeAsStringSync('(+ 10 20)');

      final res = await Process.run(dartExecutable, [
        'bin/lisp/lisp.dart',
        scriptFile.path,
      ]);
      check(res.exitCode).equals(0);

      tempDir.deleteSync(recursive: true);
    });
  });
}

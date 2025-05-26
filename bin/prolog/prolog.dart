import 'dart:convert';
import 'dart:io';

import 'package:petitparser_examples/prolog.dart';

/// Entry point for the command line interpreter.
void main(List<String> arguments) {
  // parse arguments
  final rules = StringBuffer();
  for (final option in arguments) {
    if (option.startsWith('-')) {
      if (option == '-?') {
        stdout.writeln('${Platform.executable} prolog.dart rules...');
        exit(0);
      } else {
        stdout.writeln('Unknown option: $option');
        exit(1);
      }
    } else {
      final file = File(option);
      if (file.existsSync()) {
        rules.writeln(file.readAsStringSync());
      } else {
        stdout.writeln('File not found: $option');
        exit(2);
      }
    }
  }

  // evaluation context
  final db = Database.parse(rules.toString());

  // the read-eval loop
  stdout.write('?- ');
  stdin
      .transform(systemEncoding.decoder)
      .transform(const LineSplitter())
      .map(Term.parse)
      .map((goal) {
        db.query(goal).forEach(stdout.writeln);
      })
      .forEach((each) => stdout.write('?- '));
}

import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runString('string', string(defaultStringInput));
  runString('stringIgnoreCase', stringIgnoreCase(defaultStringInput));
  runString('predicate', predicate(defaultStringInput.length, (_) => true, ''));
  runString('pattern-regexp', PatternParser(RegExp('.*a.*', dotAll: true), ''));
  runString('pattern-string', PatternParser(defaultStringInput, ''));
}

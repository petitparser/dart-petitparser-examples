import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runString('predicate - string', string(defaultStringInput));
  runString(
      'predicate - stringIgnoreCase', stringIgnoreCase(defaultStringInput));
  runString('predicate - predicate',
      predicate(defaultStringInput.length, (_) => true, ''));
  runString('predicate - pattern - regexp',
      PatternParser(RegExp('.*a.*', dotAll: true), ''));
  runString(
      'predicate - pattern - string', PatternParser(defaultStringInput, ''));
}

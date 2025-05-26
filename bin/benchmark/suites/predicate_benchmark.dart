import 'package:petitparser/petitparser.dart';

import '../utils/runner.dart';

void main() {
  runString('predicate - string', string(defaultStringInput));
  runString(
    'predicate - string (ignore case)',
    string(defaultStringInput, ignoreCase: true),
  );
  runString(
    'predicate - predicate',
    predicate(defaultStringInput.length, (_) => true, ''),
  );
  runString(
    'predicate - pattern - regexp',
    PatternParser(RegExp('.*a.*', dotAll: true), ''),
  );
  runString(
    'predicate - pattern - string',
    PatternParser(defaultStringInput, ''),
  );
}

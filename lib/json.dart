/// This package contains a complete implementation of [JSON](https://json.org/).
library;

import 'src/json/definition.dart';
import 'src/json/types.dart';

export 'src/json/definition.dart';
export 'src/json/types.dart';

/// Internal JSON parser.
final _jsonParser = JsonDefinition().build();

/// Converts the given JSON-string [input] to its corresponding object.
///
/// For example:
///
/// ```dart
/// final result = parseJson('{"a": 1, "b": [2, 3.4], "c": false}');
/// print(result.value);  // {a: 1, b: [2, 3.4], c: false}
/// ```
JSON parseJson(String input) => _jsonParser.parse(input).value;

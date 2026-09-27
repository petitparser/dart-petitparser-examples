/// Parses an RFC-3986 URI query string.
///
/// Accepts input of the form `{key[=value]}&...`.
library;

import 'package:petitparser/petitparser.dart';

/// A parser that decomposes a URI query string into a list of key-value pairs.
///
/// Accepts input formatted as `{key[=value]}&...` and returns a list of
/// records with positional fields `($1: key, $2: value?)`.
///
/// For example:
///
/// ```dart
/// final result = query.parse('foo=1&bar=&baz');
/// print(result.value); // [('foo', '1'), ('bar', ''), ('baz', null)]
/// ```
final query = _param
    .plusSeparated('&'.toParser())
    .map(
      (list) => list.elements
          .where((each) => each.$1.isNotEmpty || each.$2 != null)
          .toList(),
    );

final _param = seq2(
  _paramKey,
  _paramValue.skip(before: '='.toParser()).optional(),
);

final _paramKey = pattern('^=&').starString(message: 'param key');

final _paramValue = pattern('^&').starString(message: 'param value');

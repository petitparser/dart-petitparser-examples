/// Parsers an URI query.
///
/// Accepts input of the form "{key[=value]}&...".
library;

import 'package:petitparser/petitparser.dart';

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

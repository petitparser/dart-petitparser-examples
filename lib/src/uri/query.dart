/// Parsers an URI query.
///
/// Accepts input of the form "{key[=value]}&...".
library;

import 'package:petitparser/petitparser.dart';

final query = _param
    .plusSeparated('&'.toParser())
    .map(
      (list) => list.elements.where((each) => each[0] != '' || each[1] != null),
    );

final _param = seq2(
  _paramKey,
  seq2('='.toParser(), _paramValue).optional(),
).map2((key, value) => <String?>[key, value?.$2]);

final _paramKey = pattern('^=&').starString(message: 'param key');

final _paramValue = pattern('^&').starString(message: 'param value');

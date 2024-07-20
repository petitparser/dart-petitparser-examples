/// A simple CSV (comma seperated text) parser.
library;

import 'package:petitparser/petitparser.dart';

final csv = _lines.end();

final _lines = _records.starSeparated(newline()).map((list) => list.elements);
final _records = _field.starSeparated(char(',')).map((list) => list.elements);

final _field = _quotedField | _plainField;

final _quotedField =
    _quotedFieldContent.skip(before: char('"'), after: char('"'));
final _quotedFieldContent = _quotedFieldChar.star().map((list) => list.join());
final _quotedFieldChar = string('""').map((value) => value[0]) | pattern('^"');

final _plainField = _plainFieldContent;
final _plainFieldContent = _plainFieldChar.starString();
final _plainFieldChar = pattern("^,\n\r");

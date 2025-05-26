import 'dart:convert' as convert;

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/json.dart' as json_example;

import '../utils/runner.dart';

final jsonParser = json_example.JsonDefinition().build();

const jsonArray = '[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]';
const jsonObject = '{"a": 1, "b": 2, "c": 3, "d": 4, "e": 5, "f": 6, "g": 7}';
const jsonEvent = '''
{"type": "change", "eventPhase": 2, "bubbles": true, "cancelable": true, 
"timeStamp": 0, "CAPTURING_PHASE": 1, "AT_TARGET": 2, "BUBBLING_PHASE": 3, 
"isTrusted": true, "MOUSEDOWN": 1, "MOUSEUP": 2, "MOUSEOVER": 4, "MOUSEOUT": 8, 
"MOUSEMOVE": 16, "MOUSEDRAG": 32, "CLICK": 64, "DBLCLICK": 128, "KEYDOWN": 256, 
"KEYUP": 512, "KEYPRESS": 1024, "DRAGDROP": 2048, "FOCUS": 4096, "BLUR": 8192, 
"SELECT": 16384, "CHANGE": 32768, "RESET": 65536, "SUBMIT": 131072, 
"SCROLL": 262144, "LOAD": 524288, "UNLOAD": 1048576, "XFER_DONE": 2097152, 
"ABORT": 4194304, "ERROR": 8388608, "LOCATE": 16777216, "MOVE": 33554432, 
"RESIZE": 67108864, "FORWARD": 134217728, "HELP": 268435456, "BACK": 536870912, 
"TEXT": 1073741824, "ALT_MASK": 1, "CONTROL_MASK": 2, "SHIFT_MASK": 4, 
"META_MASK": 8}
''';
const jsonNested = '''
{"items":{"item":[{"id": "0001","type": "donut",
"name": "Cake","ppu": 0.55,"batters":{"batter":[{ "id": "1001", "type": 
"Regular" },{ "id": "1002", "type": "Chocolate" },{ "id": "1003", "type": 
"Blueberry" },{ "id": "1004", "type": "Devil's Food" }]},"topping":[{ "id": 
"5001", "type": "None" },{ "id": "5002", "type": "Glazed" },{ "id": "5005", 
"type": "Sugar" },{ "id": "5007", "type": "Powdered Sugar" },{ "id": "5006", 
"type": "Chocolate with Sprinkles" },{ "id": "5003", "type": "Chocolate" },
{ "id": "5004", "type": "Maple" }]}]}}
''';

void runJson(String name, String input) => run(
  name,
  verify: () {
    final parserResult = jsonParser.parse(input).value;
    final nativeResult = convert.json.decode(input);
    if (parserResult.toString() != nativeResult.toString()) {
      throw StateError('Parsers provide inconsistent results');
    }
  },
  parse: () => jsonParser.parse(input),
  accept: () => jsonParser.accept(input),
  native: () => convert.json.decode(input),
);

void main() {
  runJson('json - string', '"abcdef"');
  runJson('json - integer', '33550336');
  runJson('json - floating', '3.14159265359');
  runJson('json - true', 'true');
  runJson('json - false', 'false');
  runJson('json - null', 'null');
  runJson('json - array', jsonArray);
  runJson('json - object', jsonObject);
  runJson('json - event', jsonEvent);
  runJson('json - nested', jsonNested);
}

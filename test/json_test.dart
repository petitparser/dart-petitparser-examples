import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/json.dart';
import 'package:test/scaffolding.dart';

import 'utils/checks.dart';

void main() {
  final parser = JsonDefinition().build();
  test('linter', () {
    check(linter(parser, excludedRules: {})).isEmpty();
  });
  group('arrays', () {
    test('empty', () {
      check(parser).isSuccess('[]', value: []);
    });
    test('small', () {
      check(parser).isSuccess('["a"]', value: ['a']);
    });
    test('large', () {
      check(parser).isSuccess('["a", "b", "c"]', value: ['a', 'b', 'c']);
    });
    test('nested', () {
      check(parser).isSuccess(
        '[["a"]]',
        value: [
          ['a'],
        ],
      );
    });
    test('invalid', () {
      check(parser).isFailure('[');
      check(parser).isFailure('[1');
      check(parser).isFailure('[1,');
      check(parser).isFailure('[1,]');
      check(parser).isFailure('[1 2]');
      check(parser).isFailure('[]]');
    });
  });
  group('objects', () {
    test('empty', () {
      check(parser).isSuccess('{}', value: {});
    });
    test('small', () {
      check(parser).isSuccess('{"a": 1}', value: {'a': 1});
    });
    test('large', () {
      check(
        parser,
      ).isSuccess('{"a": 1, "b": 2, "c": 3}', value: {'a': 1, 'b': 2, 'c': 3});
    });
    test('nested', () {
      check(parser).isSuccess(
        '{"obj": {"a": 1}}',
        value: {
          'obj': {'a': 1},
        },
      );
    });
    test('invalid', () {
      check(parser).isFailure('{');
      check(parser).isFailure("{'a'");
      check(parser).isFailure("{'a':");
      check(parser).isFailure("{'a':'b'");
      check(parser).isFailure("{'a':'b',");
      check(parser).isFailure("{'a'}");
      check(parser).isFailure("{'a':}");
      check(parser).isFailure("{'a':'b',}");
      check(parser).isFailure('{}}');
    });
  });
  group('literals', () {
    test('valid true', () {
      check(parser).isSuccess('true', value: true);
    });
    test('invalid true', () {
      check(parser).isFailure('tr');
      check(parser).isFailure('trace');
      check(parser).isFailure('truest');
    });
    test('valid false', () {
      check(parser).isSuccess('false', value: false);
    });
    test('invalid false', () {
      check(parser).isFailure('fa');
      check(parser).isFailure('falsely');
      check(parser).isFailure('fabulous');
    });
    test('valid null', () {
      check(parser).isSuccess('null', value: null);
    });
    test('invalid null', () {
      check(parser).isFailure('nu');
      check(parser).isFailure('nuclear');
      check(parser).isFailure('nullified');
    });
    test('valid integer', () {
      check(parser).isSuccess('0', value: 0);
      check(parser).isSuccess('1', value: 1);
      check(parser).isSuccess('-1', value: -1);
      check(parser).isSuccess('12', value: 12);
      check(parser).isSuccess('-12', value: -12);
      check(parser).isSuccess('1e2', value: 100);
      check(parser).isSuccess('1e+2', value: 100);
    });
    test('invalid integer', () {
      check(parser).isFailure('00');
      check(parser).isFailure('01');
    });
    test('valid float', () {
      check(parser).isSuccess('0.0', value: 0.0);
      check(parser).isSuccess('0.12', value: 0.12);
      check(parser).isSuccess('-0.12', value: -0.12);
      check(parser).isSuccess('12.34', value: 12.34);
      check(parser).isSuccess('-12.34', value: -12.34);
      check(parser).isSuccess('1.2e-1', value: 1.2e-1);
      check(parser).isSuccess('1.2E-1', value: 1.2e-1);
    });
    test('invalid float', () {
      check(parser).isFailure('.1');
      check(parser).isFailure('0.1.1');
    });
    test('plain string', () {
      check(parser).isSuccess('""', value: '');
      check(parser).isSuccess('"foo"', value: 'foo');
      check(parser).isSuccess('"foo bar"', value: 'foo bar');
    });
    test('escaped string', () {
      check(parser).isSuccess('"\\""', value: '"');
      check(parser).isSuccess('"\\\\"', value: '\\');
      check(parser).isSuccess('"\\/"', value: '/');
      check(parser).isSuccess('"\\b"', value: '\b');
      check(parser).isSuccess('"\\f"', value: '\f');
      check(parser).isSuccess('"\\n"', value: '\n');
      check(parser).isSuccess('"\\r"', value: '\r');
      check(parser).isSuccess('"\\t"', value: '\t');
    });
    test('unicode string', () {
      check(parser).isSuccess('"\\u0030"', value: '0');
      check(parser).isSuccess('"\\u007B"', value: '{');
      check(parser).isSuccess('"\\u007d"', value: '}');
    });
    test('invalid string', () {
      check(parser).isFailure('"');
      check(parser).isFailure('"a');
      check(parser).isFailure('"a\\"');
      check(parser).isFailure(r'"\a"');
      check(parser).isFailure(r'"\x41"');
      check(parser).isFailure('"\\u00"');
      check(parser).isFailure('"\\u000X"');
    });
  });
  group('browser', () {
    test('Internet Explorer', () {
      const input =
          '{"recordset": null, "type": "change", '
          '"fromElement": null, "toElement": null, "altLeft": false, '
          '"keyCode": 0, "repeat": false, "reason": 0, "behaviorCookie": 0, '
          '"contentOverflow": false, "behaviorPart": 0, "dataTransfer": null, '
          '"ctrlKey": false, "shiftLeft": false, "dataFld": "", '
          '"qualifier": "", "wheelDelta": 0, "bookmarks": null, "button": 0, '
          '"srcFilter": null, "nextPage": "", "cancelBubble": false, "x": 89, '
          '"y": 502, "screenX": 231, "screenY": 1694, "srcUrn": "", '
          '"boundElements": {"length": 0}, "clientX": 89, "clientY": 502, '
          '"propertyName": "", "shiftKey": false, "ctrlLeft": false, '
          '"offsetX": 25, "offsetY": 2, "altKey": false}';
      check(parseJson(input)).isNotNull();
    });
    test('FireFox', () {
      const input =
          '{"type": "change", "eventPhase": 2, "bubbles": true, '
          '"cancelable": true, "timeStamp": 0, "CAPTURING_PHASE": 1, '
          '"AT_TARGET": 2, "BUBBLING_PHASE": 3, "isTrusted": true, '
          '"MOUSEDOWN": 1, "MOUSEUP": 2, "MOUSEOVER": 4, "MOUSEOUT": 8, '
          '"MOUSEMOVE": 16, "MOUSEDRAG": 32, "CLICK": 64, "DBLCLICK": 128, '
          '"KEYDOWN": 256, "KEYUP": 512, "KEYPRESS": 1024, "DRAGDROP": 2048, '
          '"FOCUS": 4096, "BLUR": 8192, "SELECT": 16384, "CHANGE": 32768, '
          '"RESET": 65536, "SUBMIT": 131072, "SCROLL": 262144, "LOAD": 524288, '
          '"UNLOAD": 1048576, "XFER_DONE": 2097152, "ABORT": 4194304, '
          '"ERROR": 8388608, "LOCATE": 16777216, "MOVE": 33554432, '
          '"RESIZE": 67108864, "FORWARD": 134217728, "HELP": 268435456, '
          '"BACK": 536870912, "TEXT": 1073741824, "ALT_MASK": 1, '
          '"CONTROL_MASK": 2, "SHIFT_MASK": 4, "META_MASK": 8}';
      check(parseJson(input)).isNotNull();
    });
    test('WebKit', () {
      const input =
          '{"returnValue": true, "timeStamp": 1226697417289, '
          '"eventPhase": 2, "type": "change", "cancelable": false, '
          '"bubbles": true, "cancelBubble": false, "MOUSEOUT": 8, '
          '"FOCUS": 4096, "CHANGE": 32768, "MOUSEMOVE": 16, "AT_TARGET": 2, '
          '"SELECT": 16384, "BLUR": 8192, "KEYUP": 512, "MOUSEDOWN": 1, '
          '"MOUSEDRAG": 32, "BUBBLING_PHASE": 3, "MOUSEUP": 2, '
          '"CAPTURING_PHASE": 1, "MOUSEOVER": 4, "CLICK": 64, "DBLCLICK": 128, '
          '"KEYDOWN": 256, "KEYPRESS": 1024, "DRAGDROP": 2048}';
      check(parseJson(input)).isNotNull();
    });
  });
  group('errors', () {
    test('expected value', () {
      check(parser).isFailure('', position: 0, message: 'value expected');
    });
    test('expected array closing', () {
      check(parser).isFailure('[', position: 0, message: 'value expected');
    });
    test('expected array element', () {
      check(parser).isFailure('[1,', position: 0, message: 'value expected');
    });
    test('expected object closing', () {
      check(parser).isFailure('{', position: 0, message: 'value expected');
    });
    test('expected object colon', () {
      check(parser).isFailure('{"a"', position: 0, message: 'value expected');
    });
    test('expected object value', () {
      check(parser).isFailure('{"a":', position: 0, message: 'value expected');
    });
    test('expected object entry', () {
      check(parser)
          .isFailure('{"a":1,', position: 0, message: 'value expected');
    });
    test('expected string closing', () {
      check(parser).isFailure('"', position: 0, message: 'value expected');
    });
    test('expected number (fractional part)', () {
      check(parser)
          .isFailure('1.', position: 1, message: 'end of input expected');
    });
    test('expected number (exponent part)', () {
      check(parser)
          .isFailure('1e', position: 1, message: 'end of input expected');
    });
  });
  group('malformed inputs & parseJson exceptions', () {
    test('empty and whitespace-only input', () {
      check(parser).isFailure('');
      check(parser).isFailure('   ');
      check(parser).isFailure('\t\n');
      check(() => parseJson('')).throws<ParserException>();
      check(() => parseJson('   ')).throws<ParserException>();
    });

    test('unclosed brackets and braces', () {
      check(parser).isFailure('[');
      check(parser).isFailure('[1');
      check(parser).isFailure('[1, 2');
      check(parser).isFailure('{');
      check(parser).isFailure('{"a"');
      check(parser).isFailure('{"a": 1');
      check(() => parseJson('[1, 2')).throws<ParserException>();
      check(() => parseJson('{"a": 1')).throws<ParserException>();
    });

    test('unquoted keys', () {
      check(parser).isFailure('{a: 1}');
      check(parser).isFailure('{foo: "bar"}');
      check(parser).isFailure('{1: "numeric"}');
      check(() => parseJson('{a: 1}')).throws<ParserException>();
      check(() => parseJson('{foo: "bar"}')).throws<ParserException>();
    });

    test('single quoted strings and keys', () {
      check(parser).isFailure("'hello'");
      check(parser).isFailure("{'a': 1}");
      check(parser).isFailure("{'a': 'b'}");
      check(parser).isFailure("['item1', 'item2']");
      check(() => parseJson("'hello'")).throws<ParserException>();
      check(() => parseJson("{'a': 1}")).throws<ParserException>();
    });

    test('trailing commas in collections', () {
      check(parser).isFailure('[1, 2,]');
      check(parser).isFailure('["a",]');
      check(parser).isFailure('{"a": 1,}');
      check(parser).isFailure('{"a": 1, "b": 2,}');
      check(() => parseJson('[1, 2,]')).throws<ParserException>();
      check(() => parseJson('{"a": 1,}')).throws<ParserException>();
    });

    test('trailing garbage after valid JSON', () {
      check(parser).isFailure('{"a": 1} trailing');
      check(parser).isFailure('[] trailing');
      check(parser).isFailure('true false');
      check(parser).isFailure('123 456');
      check(parser).isFailure('"hello" "world"');
      check(parser).isFailure('null 0');
      check(() => parseJson('{"a": 1} trailing')).throws<ParserException>();
      check(() => parseJson('true false')).throws<ParserException>();
      check(() => parseJson('123 456')).throws<ParserException>();
    });

    test('parseJson error handling', () {
      check(() => parseJson('invalid')).throws<ParserException>();
      check(() => parseJson('undefined')).throws<ParserException>();
      check(() => parseJson('{')).throws<ParserException>();
      check(() => parseJson('NaN')).throws<ParserException>();
      check(() => parseJson('Infinity')).throws<ParserException>();
    });

    test('Json type alias compatibility', () {
      final values = <Json>[
        null,
        42,
        'hello',
        [1, 'two'],
        {'key': 'value'},
      ];
      check(values).length.equals(5);
      check(values[0]).isNull();
      check(values[1]).equals(42);
      check(values[2]).equals('hello');
      check(values[3]).isA<List<Object?>>();
      check(values[4]).isA<Map<String, Object?>>();
    });
  });
}

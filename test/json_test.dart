import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/json.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

void main() {
  final parser = JsonDefinition().build();
  test('linter', () {
    expect(linter(parser, excludedTypes: {}), isEmpty);
  });
  group('arrays', () {
    test('empty', () {
      expect(parser, isSuccess('[]', value: []));
    });
    test('small', () {
      expect(parser, isSuccess('["a"]', value: ['a']));
    });
    test('large', () {
      expect(parser, isSuccess('["a", "b", "c"]', value: ['a', 'b', 'c']));
    });
    test('nested', () {
      expect(
        parser,
        isSuccess(
          '[["a"]]',
          value: [
            ['a'],
          ],
        ),
      );
    });
    test('invalid', () {
      expect(parser, isFailure('['));
      expect(parser, isFailure('[1'));
      expect(parser, isFailure('[1,'));
      expect(parser, isFailure('[1,]'));
      expect(parser, isFailure('[1 2]'));
      expect(parser, isFailure('[]]'));
    });
  });
  group('objects', () {
    test('empty', () {
      expect(parser, isSuccess('{}', value: {}));
    });
    test('small', () {
      expect(parser, isSuccess('{"a": 1}', value: {'a': 1}));
    });
    test('large', () {
      expect(
        parser,
        isSuccess('{"a": 1, "b": 2, "c": 3}', value: {'a': 1, 'b': 2, 'c': 3}),
      );
    });
    test('nested', () {
      expect(
        parser,
        isSuccess(
          '{"obj": {"a": 1}}',
          value: {
            'obj': {'a': 1},
          },
        ),
      );
    });
    test('invalid', () {
      expect(parser, isFailure('{'));
      expect(parser, isFailure("{'a'"));
      expect(parser, isFailure("{'a':"));
      expect(parser, isFailure("{'a':'b'"));
      expect(parser, isFailure("{'a':'b',"));
      expect(parser, isFailure("{'a'}"));
      expect(parser, isFailure("{'a':}"));
      expect(parser, isFailure("{'a':'b',}"));
      expect(parser, isFailure('{}}'));
    });
  });
  group('literals', () {
    test('valid true', () {
      expect(parser, isSuccess('true', value: true));
    });
    test('invalid true', () {
      expect(parser, isFailure('tr'));
      expect(parser, isFailure('trace'));
      expect(parser, isFailure('truest'));
    });
    test('valid false', () {
      expect(parser, isSuccess('false', value: false));
    });
    test('invalid false', () {
      expect(parser, isFailure('fa'));
      expect(parser, isFailure('falsely'));
      expect(parser, isFailure('fabulous'));
    });
    test('valid null', () {
      expect(parser, isSuccess('null', value: null));
    });
    test('invalid null', () {
      expect(parser, isFailure('nu'));
      expect(parser, isFailure('nuclear'));
      expect(parser, isFailure('nullified'));
    });
    test('valid integer', () {
      expect(parser, isSuccess('0', value: 0));
      expect(parser, isSuccess('1', value: 1));
      expect(parser, isSuccess('-1', value: -1));
      expect(parser, isSuccess('12', value: 12));
      expect(parser, isSuccess('-12', value: -12));
      expect(parser, isSuccess('1e2', value: 100));
      expect(parser, isSuccess('1e+2', value: 100));
    });
    test('invalid integer', () {
      expect(parser, isFailure('00'));
      expect(parser, isFailure('01'));
    });
    test('valid float', () {
      expect(parser, isSuccess('0.0', value: 0.0));
      expect(parser, isSuccess('0.12', value: 0.12));
      expect(parser, isSuccess('-0.12', value: -0.12));
      expect(parser, isSuccess('12.34', value: 12.34));
      expect(parser, isSuccess('-12.34', value: -12.34));
      expect(parser, isSuccess('1.2e-1', value: 1.2e-1));
      expect(parser, isSuccess('1.2E-1', value: 1.2e-1));
    });
    test('invalid float', () {
      expect(parser, isFailure('.1'));
      expect(parser, isFailure('0.1.1'));
    });
    test('plain string', () {
      expect(parser, isSuccess('""', value: ''));
      expect(parser, isSuccess('"foo"', value: 'foo'));
      expect(parser, isSuccess('"foo bar"', value: 'foo bar'));
    });
    test('escaped string', () {
      expect(parser, isSuccess('"\\""', value: '"'));
      expect(parser, isSuccess('"\\\\"', value: '\\'));
      expect(parser, isSuccess('"\\b"', value: '\b'));
      expect(parser, isSuccess('"\\f"', value: '\f'));
      expect(parser, isSuccess('"\\n"', value: '\n'));
      expect(parser, isSuccess('"\\r"', value: '\r'));
      expect(parser, isSuccess('"\\t"', value: '\t'));
    });
    test('unicode string', () {
      expect(parser, isSuccess('"\\u0030"', value: '0'));
      expect(parser, isSuccess('"\\u007B"', value: '{'));
      expect(parser, isSuccess('"\\u007d"', value: '}'));
    });
    test('invalid string', () {
      expect(parser, isFailure('"'));
      expect(parser, isFailure('"a'));
      expect(parser, isFailure('"a\\"'));
      expect(parser, isFailure('"\\u00"'));
      expect(parser, isFailure('"\\u000X"'));
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
      expect(parseJson(input), isNotNull);
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
      expect(parseJson(input), isNotNull);
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
      expect(parseJson(input), isNotNull);
    });
  });
  group('errors', () {
    test('expected value', () {
      expect(parser, isFailure('', position: 0, message: 'value expected'));
    });
    test('expected array closing', () {
      expect(parser, isFailure('[', position: 0, message: 'value expected'));
    });
    test('expected array element', () {
      expect(parser, isFailure('[1,', position: 0, message: 'value expected'));
    });
    test('expected object closing', () {
      expect(parser, isFailure('{', position: 0, message: 'value expected'));
    });
    test('expected object colon', () {
      expect(parser, isFailure('{"a"', position: 0, message: 'value expected'));
    });
    test('expected object value', () {
      expect(
        parser,
        isFailure('{"a":', position: 0, message: 'value expected'),
      );
    });
    test('expected object entry', () {
      expect(
        parser,
        isFailure('{"a":1,', position: 0, message: 'value expected'),
      );
    });
    test('expected string closing', () {
      expect(parser, isFailure('"', position: 0, message: 'value expected'));
    });
    test('expected number (fractional part)', () {
      expect(
        parser,
        isFailure('1.', position: 1, message: 'end of input expected'),
      );
    });
    test('expected number (exponent part)', () {
      expect(
        parser,
        isFailure('1e', position: 1, message: 'end of input expected'),
      );
    });
  });
}

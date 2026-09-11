import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final pat = grammar.buildFrom(grammar.pythonPattern()).end();

  group('literal and singleton patterns', () {
    test('singletons', () {
      expect(pat, isSuccess('None'));
      expect(pat, isSuccess('True'));
      expect(pat, isSuccess('False'));
    });

    test('numbers and strings', () {
      expect(pat, isSuccess('42'));
      expect(pat, isSuccess('3.14'));
      expect(pat, isSuccess('"hello"'));
    });
  });

  group('wildcard and capture patterns', () {
    test('wildcard', () {
      expect(pat, isSuccess('_'));
    });

    test('capture variable', () {
      expect(pat, isSuccess('x'));
      expect(pat, isSuccess('point_name'));
    });
  });

  group('as and or patterns', () {
    test('as pattern', () {
      expect(pat, isSuccess('42 as x'));
      expect(pat, isSuccess('Point(x, y) as p'));
    });

    test('or pattern', () {
      expect(pat, isSuccess('1 | 2'));
      expect(pat, isSuccess('401 | 403 | 404'));
      expect(pat, isSuccess('Point(0, 0) | Point(1, 1)'));
    });
  });

  group('sequence patterns', () {
    test('list sequence', () {
      expect(pat, isSuccess('[]'));
      expect(pat, isSuccess('[1, 2]'));
      expect(pat, isSuccess('[first, *rest]'));
      expect(pat, isSuccess('[*_, last]'));
    });

    test('tuple sequence', () {
      expect(pat, isSuccess('()'));
      expect(pat, isSuccess('(1,)'));
      expect(pat, isSuccess('(1, 2)'));
      expect(pat, isSuccess('(head, *middle, tail)'));
    });
  });

  group('mapping patterns', () {
    test('empty and simple mapping', () {
      expect(pat, isSuccess('{}'));
      expect(pat, isSuccess('{"key": "value"}'));
      expect(pat, isSuccess('{"x": 1, "y": 2}'));
    });

    test('mapping with double star rest', () {
      expect(pat, isSuccess('{**rest}'));
      expect(pat, isSuccess('{"type": "admin", **details}'));
    });
  });

  group('class patterns', () {
    test('positional and keyword arguments', () {
      expect(pat, isSuccess('Point()'));
      expect(pat, isSuccess('Point(x, y)'));
      expect(pat, isSuccess('Point(x=1, y=2)'));
      expect(pat, isSuccess('Color(r, g, b, alpha=1.0)'));
    });

    test('dotted class name', () {
      expect(pat, isSuccess('geom.Point(x, y)'));
      expect(pat, isSuccess('pkg.subpkg.Class()'));
    });
  });
}

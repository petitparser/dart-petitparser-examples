import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = PythonGrammarDefinition();
  final pat = grammar.buildFrom(grammar.pythonPattern()).end();

  group('literal and singleton patterns', () {
    test('singletons', () {
      check(pat).isSuccess('None');
      check(pat).isSuccess('True');
      check(pat).isSuccess('False');
    });

    test('numbers and strings', () {
      check(pat).isSuccess('42');
      check(pat).isSuccess('3.14');
      check(pat).isSuccess('"hello"');
    });
  });

  group('wildcard and capture patterns', () {
    test('wildcard', () {
      check(pat).isSuccess('_');
    });

    test('capture variable', () {
      check(pat).isSuccess('x');
      check(pat).isSuccess('point_name');
    });
  });

  group('as and or patterns', () {
    test('as pattern', () {
      check(pat).isSuccess('42 as x');
      check(pat).isSuccess('Point(x, y) as p');
    });

    test('or pattern', () {
      check(pat).isSuccess('1 | 2');
      check(pat).isSuccess('401 | 403 | 404');
      check(pat).isSuccess('Point(0, 0) | Point(1, 1)');
    });
  });

  group('sequence patterns', () {
    test('list sequence', () {
      check(pat).isSuccess('[]');
      check(pat).isSuccess('[1, 2]');
      check(pat).isSuccess('[first, *rest]');
      check(pat).isSuccess('[*_, last]');
    });

    test('tuple sequence', () {
      check(pat).isSuccess('()');
      check(pat).isSuccess('(1,)');
      check(pat).isSuccess('(1, 2)');
      check(pat).isSuccess('(head, *middle, tail)');
    });
  });

  group('mapping patterns', () {
    test('empty and simple mapping', () {
      check(pat).isSuccess('{}');
      check(pat).isSuccess('{"key": "value"}');
      check(pat).isSuccess('{"x": 1, "y": 2}');
    });

    test('mapping with double star rest', () {
      check(pat).isSuccess('{**rest}');
      check(pat).isSuccess('{"type": "admin", **details}');
    });
  });

  group('class patterns', () {
    test('positional and keyword arguments', () {
      check(pat).isSuccess('Point()');
      check(pat).isSuccess('Point(x, y)');
      check(pat).isSuccess('Point(x=1, y=2)');
      check(pat).isSuccess('Color(r, g, b, alpha=1.0)');
    });

    test('dotted class name', () {
      check(pat).isSuccess('geom.Point(x, y)');
      check(pat).isSuccess('pkg.subpkg.Class()');
    });
  });
}

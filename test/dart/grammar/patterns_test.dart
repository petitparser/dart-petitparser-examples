import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/scaffolding.dart';

import '../../utils/checks.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final pat = grammar.buildFrom(grammar.dartPattern()).end();

  group('constant patterns', () {
    test('literals as patterns', () {
      check(pat).isSuccess('1');
      check(pat).isSuccess('-1');
      check(pat).isSuccess('3.14');
      check(pat).isSuccess('"str"');
      check(pat).isSuccess('true');
      check(pat).isSuccess('false');
      check(pat).isSuccess('null');
      check(pat).isSuccess('#sym');
    });

    test('const parenthesized expressions', () {
      check(pat).isSuccess('const (1 + 2)');
      check(pat).isSuccess('const [1, 2]');
    });

    test('identifier and qualified constants', () {
      check(pat).isSuccess('Color.red');
      check(pat).isSuccess('MyClass.constantField');
    });
  });

  group('variable & wildcard patterns', () {
    test('variable declarations', () {
      check(pat).isSuccess('var x');
      check(pat).isSuccess('final x');
      check(pat).isSuccess('int x');
      check(pat).isSuccess('final int x');
      check(pat).isSuccess('final List<String> list');
      check(pat).isSuccess('_Reference reference');
      check(pat).isSuccess('_privateVar');
    });

    test('wildcards', () {
      check(pat).isSuccess('_');
      check(pat).isSuccess('var _');
      check(pat).isSuccess('final _');
      check(pat).isSuccess('int _');
    });
  });

  group('relational patterns', () {
    test('comparison operators', () {
      check(pat).isSuccess('> 5');
      check(pat).isSuccess('>= 0');
      check(pat).isSuccess('< 100');
      check(pat).isSuccess('<= -1');
      check(pat).isSuccess('== 0');
      check(pat).isSuccess('!= null');
      check(pat).isSuccess('== "target"');
    });
  });

  group('logical patterns', () {
    test('logical OR (||)', () {
      check(pat).isSuccess('1 || 2');
      check(pat).isSuccess('1 || 2 || 3');
      check(pat).isSuccess('var a || var b');
    });

    test('logical AND (&&)', () {
      check(pat).isSuccess('> 0 && < 10');
      check(pat).isSuccess('int _ && != 0');
      check(pat).isSuccess('int a && > 5');
    });
  });

  group('unary patterns', () {
    test('cast pattern (as)', () {
      check(pat).isSuccess('var x as int');
      check(pat).isSuccess('_ as String');
    });

    test('null-check pattern (?)', () {
      check(pat).isSuccess('var x?');
      check(pat).isSuccess('final int x?');
      check(pat).isSuccess('_?');
    });

    test('null-assert pattern (!)', () {
      check(pat).isSuccess('var x!');
      check(pat).isSuccess('final int x!');
      check(pat).isSuccess('_!');
    });
  });

  group('list patterns', () {
    test('empty and simple lists', () {
      check(pat).isSuccess('[]');
      check(pat).isSuccess('[a]');
      check(pat).isSuccess('[a, b]');
      check(pat).isSuccess('[var a, final b]');
      check(pat).isSuccess('<int>[1, 2]');
    });

    test('rest element (...)', () {
      check(pat).isSuccess('[...]');
      check(pat).isSuccess('[...rest]');
      check(pat).isSuccess('[...var rest]');
      check(pat).isSuccess('[1, 2, ...]');
      check(pat).isSuccess('[1, ...rest, 4]');
    });
  });

  group('map patterns', () {
    test('empty and key-value entries', () {
      check(pat).isSuccess('{}');
      check(pat).isSuccess('{"a": 1}');
      check(pat).isSuccess('{"a": var x, "b": 2}');
      check(pat).isSuccess('<String, int>{"a": 1}');
    });
  });

  group('record patterns', () {
    test('positional fields', () {
      check(pat).isSuccess('(a, b)');
      check(pat).isSuccess('(var a, final b)');
      check(pat).isSuccess('(1, 2)');
    });

    test('named fields', () {
      check(pat).isSuccess('(a: 1, b: 2)');
      check(pat).isSuccess('(x: var a, y: var b)');
    });

    test('inferred field names (:var x)', () {
      check(pat).isSuccess('(:var x, :final y)');
    });

    test('mixed positional and named', () {
      check(pat).isSuccess('(1, b: 2)');
      check(pat).isSuccess('(var x, y: 2)');
    });
  });

  group('object patterns', () {
    test('class matching with field patterns', () {
      check(pat).isSuccess('Point(x: 1, y: 2)');
      check(pat).isSuccess('Point(x: var x, y: var y)');
      check(pat).isSuccess('Point(:var x, :var y)');
      check(pat).isSuccess('Rect(topLeft: Point(x: 0, y: 0))');
    });
  });
}

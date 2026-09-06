import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:test/test.dart';

import '../../utils/expect.dart';

void main() {
  final grammar = DartGrammarDefinition();
  final pat = grammar.buildFrom(grammar.dartPattern()).end();

  group('constant patterns', () {
    test('literals as patterns', () {
      expect(pat, isSuccess('1'));
      expect(pat, isSuccess('-1'));
      expect(pat, isSuccess('3.14'));
      expect(pat, isSuccess('"str"'));
      expect(pat, isSuccess('true'));
      expect(pat, isSuccess('false'));
      expect(pat, isSuccess('null'));
      expect(pat, isSuccess('#sym'));
    });

    test('const parenthesized expressions', () {
      expect(pat, isSuccess('const (1 + 2)'));
      expect(pat, isSuccess('const [1, 2]'));
    });

    test('identifier and qualified constants', () {
      expect(pat, isSuccess('Color.red'));
      expect(pat, isSuccess('MyClass.constantField'));
    });
  });

  group('variable & wildcard patterns', () {
    test('variable declarations', () {
      expect(pat, isSuccess('var x'));
      expect(pat, isSuccess('final x'));
      expect(pat, isSuccess('int x'));
      expect(pat, isSuccess('final int x'));
      expect(pat, isSuccess('final List<String> list'));
      expect(pat, isSuccess('_Reference reference'));
      expect(pat, isSuccess('_privateVar'));
    });

    test('wildcards', () {
      expect(pat, isSuccess('_'));
      expect(pat, isSuccess('var _'));
      expect(pat, isSuccess('final _'));
      expect(pat, isSuccess('int _'));
    });
  });

  group('relational patterns', () {
    test('comparison operators', () {
      expect(pat, isSuccess('> 5'));
      expect(pat, isSuccess('>= 0'));
      expect(pat, isSuccess('< 100'));
      expect(pat, isSuccess('<= -1'));
      expect(pat, isSuccess('== 0'));
      expect(pat, isSuccess('!= null'));
      expect(pat, isSuccess('== "target"'));
    });
  });

  group('logical patterns', () {
    test('logical OR (||)', () {
      expect(pat, isSuccess('1 || 2'));
      expect(pat, isSuccess('1 || 2 || 3'));
      expect(pat, isSuccess('var a || var b'));
    });

    test('logical AND (&&)', () {
      expect(pat, isSuccess('> 0 && < 10'));
      expect(pat, isSuccess('int _ && != 0'));
      expect(pat, isSuccess('int a && > 5'));
    });
  });

  group('unary patterns', () {
    test('cast pattern (as)', () {
      expect(pat, isSuccess('var x as int'));
      expect(pat, isSuccess('_ as String'));
    });

    test('null-check pattern (?)', () {
      expect(pat, isSuccess('var x?'));
      expect(pat, isSuccess('final int x?'));
      expect(pat, isSuccess('_?'));
    });

    test('null-assert pattern (!)', () {
      expect(pat, isSuccess('var x!'));
      expect(pat, isSuccess('final int x!'));
      expect(pat, isSuccess('_!'));
    });
  });

  group('list patterns', () {
    test('empty and simple lists', () {
      expect(pat, isSuccess('[]'));
      expect(pat, isSuccess('[a]'));
      expect(pat, isSuccess('[a, b]'));
      expect(pat, isSuccess('[var a, final b]'));
      expect(pat, isSuccess('<int>[1, 2]'));
    });

    test('rest element (...)', () {
      expect(pat, isSuccess('[...]'));
      expect(pat, isSuccess('[...rest]'));
      expect(pat, isSuccess('[...var rest]'));
      expect(pat, isSuccess('[1, 2, ...]'));
      expect(pat, isSuccess('[1, ...rest, 4]'));
    });
  });

  group('map patterns', () {
    test('empty and key-value entries', () {
      expect(pat, isSuccess('{}'));
      expect(pat, isSuccess('{"a": 1}'));
      expect(pat, isSuccess('{"a": var x, "b": 2}'));
      expect(pat, isSuccess('<String, int>{"a": 1}'));
    });
  });

  group('record patterns', () {
    test('positional fields', () {
      expect(pat, isSuccess('(a, b)'));
      expect(pat, isSuccess('(var a, final b)'));
      expect(pat, isSuccess('(1, 2)'));
    });

    test('named fields', () {
      expect(pat, isSuccess('(a: 1, b: 2)'));
      expect(pat, isSuccess('(x: var a, y: var b)'));
    });

    test('inferred field names (:var x)', () {
      expect(pat, isSuccess('(:var x, :final y)'));
    });

    test('mixed positional and named', () {
      expect(pat, isSuccess('(1, b: 2)'));
      expect(pat, isSuccess('(var x, y: 2)'));
    });
  });

  group('object patterns', () {
    test('class matching with field patterns', () {
      expect(pat, isSuccess('Point(x: 1, y: 2)'));
      expect(pat, isSuccess('Point(x: var x, y: var y)'));
      expect(pat, isSuccess('Point(:var x, :var y)'));
      expect(pat, isSuccess('Rect(topLeft: Point(x: 0, y: 0))'));
    });
  });
}

import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:test/test.dart';

void main() {
  test('empty', () {
    final matcher = regexpParser.parse('').value;
    expect(matcher, isA<Empty>());
    expect(matcher.matches(''), isTrue);
    expect(matcher.matches('a'), isFalse);
  });
  test('dot', () {
    final matcher = regexpParser.parse('.').value;
    expect(matcher, isA<Dot>());
    expect(matcher.matches(''), isFalse);
    expect(matcher.matches('a'), isTrue);
  });
  test('literal', () {
    final matcher = regexpParser.parse('a').value;
    expect(matcher, isA<Literal>());
    expect(matcher.matches('a'), isTrue);
    expect(matcher.matches('b'), isFalse);
  });
  test('meta', () {
    final matcher = regexpParser.parse('\\(').value;
    expect(matcher, isA<Literal>());
    expect(matcher.matches('('), isTrue);
    expect(matcher.matches(')'), isFalse);
  });
  test('star', () {
    final matcher = regexpParser.parse('a*').value;
    expect(matcher, isA<Star>());
    expect(matcher.matches(''), isTrue);
    expect(matcher.matches('a'), isTrue);
    expect(matcher.matches('aa'), isTrue);
    expect(matcher.matches('aaa'), isTrue);
  });
  test('plus', () {
    final matcher = regexpParser.parse('a+').value;
    expect(matcher, isA<Concat>());
    expect(matcher.matches(''), isFalse);
    expect(matcher.matches('a'), isTrue);
    expect(matcher.matches('aa'), isTrue);
    expect(matcher.matches('aaa'), isTrue);
  });
  test('maybe', () {
    final matcher = regexpParser.parse('a?').value;
    expect(matcher, isA<Or>());
    expect(matcher.matches(''), isTrue);
    expect(matcher.matches('a'), isTrue);
  });
  test('concat', () {
    final matcher = regexpParser.parse('ab').value;
    expect(matcher, isA<Concat>());
    expect(matcher.matches('ab'), isTrue);
    expect(matcher.matches('ba'), isFalse);
  });
  test('or', () {
    final matcher = regexpParser.parse('a|b').value;
    expect(matcher, isA<Or>());
    expect(matcher.matches('a'), isTrue);
    expect(matcher.matches('b'), isTrue);
    expect(matcher.matches('c'), isFalse);
  });
  test('group', () {
    final matcher = regexpParser.parse('(ab)').value;
    expect(matcher, isA<Concat>());
    expect(matcher.matches('ab'), isTrue);
    expect(matcher.matches('ba'), isFalse);
  });
  group('precedence', () {
    test('1', () {
      final matcher = regexpParser.parse('ab|cd').value;
      expect(matcher, isA<Or>());
      expect(matcher.matches('ab'), isTrue);
      expect(matcher.matches('cd'), isTrue);
      expect(matcher.matches('ac'), isFalse);
      expect(matcher.matches('bd'), isFalse);
    });
    test('2', () {
      final matcher = regexpParser.parse('a(b|c)d').value;
      expect(matcher, isA<Concat>());
      expect(matcher.matches('abd'), isTrue);
      expect(matcher.matches('acd'), isTrue);
      expect(matcher.matches('ad'), isFalse);
      expect(matcher.matches('abcd'), isFalse);
    });
  });
  test('linter', () {
    expect(linter(regexpParser), isEmpty);
  });
}

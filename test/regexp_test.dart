import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/regexp.dart';
import 'package:test/test.dart';

void main() {
  group('parser', () {
    final la = LiteralNode('a');
    final lb = LiteralNode('b');
    final lc = LiteralNode('c');
    final ld = LiteralNode('d');
    test('empty', () {
      expect(Node.fromString(r''), EmptyNode());
      expect(Node.fromString(r'()'), EmptyNode());
      expect(Node.fromString(r'(())'), EmptyNode());
    });
    test('literal', () {
      expect(Node.fromString(r'a'), la);
      expect(Node.fromString(r'(a)'), la);
      expect(Node.fromString(r'((a))'), la);
    });
    test('escape', () {
      expect(Node.fromString(r'\\'), LiteralNode('\\'));
      expect(Node.fromString(r'\('), LiteralNode('('));
      expect(Node.fromString(r'\)'), LiteralNode(')'));
      expect(Node.fromString(r'\?'), LiteralNode('?'));
      expect(Node.fromString(r'\+'), LiteralNode('+'));
      expect(Node.fromString(r'\*'), LiteralNode('*'));
      expect(Node.fromString(r'\|'), LiteralNode('|'));
    });
    test('concat', () {
      expect(Node.fromString(r'ab'), ConcatNode([la, lb]));
      expect(Node.fromString(r'abc'), ConcatNode([la, lb, lc]));
      expect(Node.fromString(r'abcd'), ConcatNode([la, lb, lc, ld]));
    });
    test('or', () {
      expect(Node.fromString(r'a|b'), AlternateNode([la, lb]));
      expect(Node.fromString(r'a|b|c'), AlternateNode([la, lb, lc]));
      expect(Node.fromString(r'a|b|c|d'), AlternateNode([la, lb, lc, ld]));
    });
    test('optional', () {
      expect(Node.fromString(r'a?'), RepeatNode(la, 0, 1));
    });
    test('star', () {
      expect(Node.fromString(r'a*'), RepeatNode(la, 0, null));
    });
    test('plus', () {
      expect(Node.fromString(r'a+'), RepeatNode(la, 1, null));
    });
    test('repeat n times', () {
      expect(Node.fromString(r'a{1}'), RepeatNode(la, 1, 1));
      expect(Node.fromString(r'a{23}'), RepeatNode(la, 23, 23));
    });
    test('repeat n or more times', () {
      expect(Node.fromString(r'a{4,}'), RepeatNode(la, 4, null));
      expect(Node.fromString(r'a{56,}'), RepeatNode(la, 56, null));
    });
    test('repeat up to n times', () {
      expect(Node.fromString(r'a{,7}'), RepeatNode(la, 0, 7));
      expect(Node.fromString(r'a{,89}'), RepeatNode(la, 0, 89));
    });
    test('repeat at lest n and at most m times', () {
      expect(Node.fromString(r'a{1,2}'), RepeatNode(la, 1, 2));
      expect(Node.fromString(r'a{34,567}'), RepeatNode(la, 34, 567));
    });
    test('concat and or', () {
      expect(
          Node.fromString(r'ab|cd'),
          AlternateNode([
            ConcatNode([la, lb]),
            ConcatNode([lc, ld]),
          ]));
      expect(
          Node.fromString(r'a(b|c)d'),
          ConcatNode([
            la,
            AlternateNode([lb, lc]),
            ld
          ]));
    });
    test('concat and repeat', () {
      expect(
          Node.fromString(r'ab+'), ConcatNode([la, RepeatNode(lb, 1, null)]));
      expect(
          Node.fromString(r'(ab)+'), RepeatNode(ConcatNode([la, lb]), 1, null));
    });
  });
  test('linter', () {
    expect(linter(nodeParser), isEmpty);
  });
}

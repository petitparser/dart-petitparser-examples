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
    test('alternate', () {
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
  group('NFA', () {
    StateRange toNFA(String regexp) => Node.fromString(regexp).toNFA();
    test('empty', () {
      final matcher = toNFA('');
      expect(matcher.match(''), isTrue);
      expect(matcher.match('a'), isFalse);
      expect(matcher.match(' ab'), isFalse);
    });
    test('literal', () {
      final matcher = toNFA('a');
      expect(matcher.match(''), isFalse);
      expect(matcher.match('a'), isTrue);
      expect(matcher.match('aaa'), isFalse);
    });
    test('concat', () {
      final matcher = toNFA('abc');
      expect(matcher.match('abc'), isTrue);
      expect(matcher.match(''), isFalse);
      expect(matcher.match('a'), isFalse);
      expect(matcher.match('ab'), isFalse);
      expect(matcher.match('abd'), isFalse);
      expect(matcher.match('abcd'), isFalse);
      expect(matcher.match('cba'), isFalse);
    });
    test('alternate', () {
      final matcher = toNFA('a|b');
      expect(matcher.match('a'), isTrue);
      expect(matcher.match('b'), isTrue);
      expect(matcher.match('d'), isFalse);
    });
    test('optional', () {
      final matcher = toNFA('a?');
      expect(matcher.match(''), isTrue);
      expect(matcher.match('a'), isTrue);
      expect(matcher.match('aa'), isFalse);
      expect(matcher.match('aaa'), isFalse);
      expect(matcher.match('aba'), isFalse);
      expect(matcher.match('b'), isFalse);
    });
    test('star', () {
      final matcher = toNFA('a*');
      expect(matcher.match(''), isTrue);
      expect(matcher.match('aaaa'), isTrue);
      expect(matcher.match('aa'), isTrue);
      expect(matcher.match('aba'), isFalse);
    });
    test('plus', () {
      final matcher = toNFA('a+');
      expect(matcher.match(''), isFalse);
      expect(matcher.match('a'), isTrue);
      expect(matcher.match('aa'), isTrue);
      expect(matcher.match('aaa'), isTrue);
      expect(matcher.match('aba'), isFalse);
      expect(matcher.match('b'), isFalse);
    });
    group('examples', () {
      test('a*b', () {
        final matcher = toNFA('a*b');
        expect(matcher.match(''), isFalse);
        expect(matcher.match('aaaab'), isTrue);
        expect(matcher.match('aab'), isTrue);
        expect(matcher.match('b'), isTrue);
        expect(matcher.match('aba'), isFalse);
      });
      test('(0|(1(01*(00)*0)*1)*)*', () {
        // All binary numbers divisible by 3
        final matcher = toNFA('(0|(1(01*(00)*0)*1)*)*');
        expect(matcher.match(''), isTrue);
        expect(matcher.match('0'), isTrue);
        expect(matcher.match('00'), isTrue);
        expect(matcher.match('11'), isTrue);
        expect(matcher.match('000'), isTrue);
        expect(matcher.match('011'), isTrue);
        expect(matcher.match('110'), isTrue);
        expect(matcher.match('0000'), isTrue);
        expect(matcher.match('0011'), isTrue);
      });
      test('(a|b)*c', () {
        final matcher = toNFA('(a|b)*c');
        expect(matcher.match('c'), isTrue);
        expect(matcher.match('ac'), isTrue);
        expect(matcher.match('ababc'), isTrue);
        expect(matcher.match('bbbc'), isTrue);
        expect(matcher.match('aaaaaaac'), isTrue);
        expect(matcher.match('ac'), isTrue);
        expect(matcher.match('bac'), isTrue);
        expect(matcher.match('abbbbc'), isTrue);
        expect(matcher.match('cc'), isFalse);
        expect(matcher.match('a'), isFalse);
        expect(matcher.match('b'), isFalse);
        expect(matcher.match('ababab'), isFalse);
      });
      test('a(b*|c)', () {
        final matcher = toNFA('a(b*|c)');
        expect(matcher.match('ac'), isTrue);
        expect(matcher.match('abbbb'), isTrue);
        expect(matcher.match('ab'), isTrue);
        expect(matcher.match('a'), isTrue);
        expect(matcher.match('abc'), isFalse);
        expect(matcher.match('acc'), isFalse);
        expect(matcher.match(''), isFalse);
      });
    });
  });
  test('linter', () {
    expect(linter(nodeParser), isEmpty);
  });
}

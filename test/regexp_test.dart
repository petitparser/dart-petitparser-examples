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
      expect(Node.fromString(r'ab'), ConcatNode(la, lb));
      expect(Node.fromString(r'abc'), ConcatNode(ConcatNode(la, lb), lc));
      expect(Node.fromString(r'abcd'),
          ConcatNode(ConcatNode(ConcatNode(la, lb), lc), ld));
    });
    test('alternate', () {
      expect(Node.fromString(r'a|b'), AlternateNode(la, lb));
      expect(
          Node.fromString(r'a|b|c'), AlternateNode(AlternateNode(la, lb), lc));
      expect(Node.fromString(r'a|b|c|d'),
          AlternateNode(AlternateNode(AlternateNode(la, lb), lc), ld));
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
      expect(Node.fromString(r'ab|cd'),
          AlternateNode(ConcatNode(la, lb), ConcatNode(lc, ld)));
      expect(Node.fromString(r'a(b|c)d'),
          ConcatNode(ConcatNode(la, AlternateNode(lb, lc)), ld));
    });
    test('concat and repeat', () {
      expect(Node.fromString(r'ab+'), ConcatNode(la, RepeatNode(lb, 1)));
      expect(Node.fromString(r'(ab)+'), RepeatNode(ConcatNode(la, lb), 1));
    });
  });
  group('NFA', () {
    Nfa toNFA(String regexp) => Node.fromString(regexp).toNfa();
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
      // https://regex-generate.github.io/regenerate/
      test('(b(ab*a)*b|a)*', () {
        final matcher = toNFA('(b(ab*a)*b|a)*');
        expect(matcher.match('a'), isTrue);
        expect(matcher.match('aa'), isTrue);
        expect(matcher.match('bb'), isTrue);
        expect(matcher.match('aaa'), isTrue);
        expect(matcher.match('abb'), isTrue);
        expect(matcher.match('bbaa'), isTrue);
        expect(matcher.match('bbbb'), isTrue);
        expect(matcher.match('abbaa'), isTrue);
        expect(matcher.match('bbabb'), isTrue);
        expect(matcher.match('baabaa'), isTrue);
        expect(matcher.match('baabbb'), isTrue);
        expect(matcher.match('abbbaab'), isTrue);
        expect(matcher.match('baababb'), isTrue);
        expect(matcher.match('bababaa'), isTrue);
        expect(matcher.match('bababbb'), isTrue);
        expect(matcher.match('bbabbaa'), isTrue);
        expect(matcher.match('aaaabbaa'), isTrue);
        expect(matcher.match('abaabaaa'), isTrue);
        expect(matcher.match('abbbbabb'), isTrue);
        expect(matcher.match('b'), isFalse);
        expect(matcher.match('ab'), isFalse);
        expect(matcher.match('ba'), isFalse);
        expect(matcher.match('aab'), isFalse);
        expect(matcher.match('aba'), isFalse);
        expect(matcher.match('bbab'), isFalse);
        expect(matcher.match('baaaa'), isFalse);
        expect(matcher.match('babba'), isFalse);
        expect(matcher.match('aaabbb'), isFalse);
        expect(matcher.match('aababa'), isFalse);
        expect(matcher.match('aabbba'), isFalse);
        expect(matcher.match('abbaba'), isFalse);
        expect(matcher.match('baabab'), isFalse);
        expect(matcher.match('babaab'), isFalse);
        expect(matcher.match('bababb'), isFalse);
        expect(matcher.match('babbaa'), isFalse);
        expect(matcher.match('babbba'), isFalse);
        expect(matcher.match('aaaabaa'), isFalse);
        expect(matcher.match('aabaaab'), isFalse);
        expect(matcher.match('aabbbaa'), isFalse);
      });
      test('(ab*)*', () {
        final matcher = toNFA('(ab*)*');
        expect(matcher.match('a'), isTrue);
        expect(matcher.match('aa'), isTrue);
        expect(matcher.match('ab'), isTrue);
        expect(matcher.match('aaa'), isTrue);
        expect(matcher.match('aab'), isTrue);
        expect(matcher.match('aba'), isTrue);
        expect(matcher.match('aaaa'), isTrue);
        expect(matcher.match('abaa'), isTrue);
        expect(matcher.match('abba'), isTrue);
        expect(matcher.match('aaaab'), isTrue);
        expect(matcher.match('aabaa'), isTrue);
        expect(matcher.match('aabba'), isTrue);
        expect(matcher.match('abaab'), isTrue);
        expect(matcher.match('abbab'), isTrue);
        expect(matcher.match('abbba'), isTrue);
        expect(matcher.match('abbbb'), isTrue);
        expect(matcher.match('aaaaaa'), isTrue);
        expect(matcher.match('aaabaa'), isTrue);
        expect(matcher.match('aabbaa'), isTrue);
        expect(matcher.match('b'), isFalse);
        expect(matcher.match('ba'), isFalse);
        expect(matcher.match('bb'), isFalse);
        expect(matcher.match('baa'), isFalse);
        expect(matcher.match('bab'), isFalse);
        expect(matcher.match('baab'), isFalse);
        expect(matcher.match('babab'), isFalse);
        expect(matcher.match('babbb'), isFalse);
        expect(matcher.match('bbbbb'), isFalse);
        expect(matcher.match('baabba'), isFalse);
        expect(matcher.match('baabbb'), isFalse);
        expect(matcher.match('babbba'), isFalse);
        expect(matcher.match('bbbaba'), isFalse);
        expect(matcher.match('bbbabb'), isFalse);
        expect(matcher.match('bbbbbb'), isFalse);
        expect(matcher.match('baaabab'), isFalse);
        expect(matcher.match('baababa'), isFalse);
        expect(matcher.match('bababaa'), isFalse);
        expect(matcher.match('babbaab'), isFalse);
        expect(matcher.match('babbbbb'), isFalse);
      });
      test('(b*ab*ab*a)*b*', () {
        final matcher = toNFA('(b*ab*ab*a)*b*');
        expect(matcher.match('b'), isTrue);
        expect(matcher.match('bb'), isTrue);
        expect(matcher.match('aaa'), isTrue);
        expect(matcher.match('bbb'), isTrue);
        expect(matcher.match('bbbb'), isTrue);
        expect(matcher.match('bbaaa'), isTrue);
        expect(matcher.match('abbaba'), isTrue);
        expect(matcher.match('abbbaa'), isTrue);
        expect(matcher.match('babaab'), isTrue);
        expect(matcher.match('bbaaba'), isTrue);
        expect(matcher.match('aaabbbb'), isTrue);
        expect(matcher.match('aababbb'), isTrue);
        expect(matcher.match('aabbbba'), isTrue);
        expect(matcher.match('ababbba'), isTrue);
        expect(matcher.match('baababb'), isTrue);
        expect(matcher.match('babbbaa'), isTrue);
        expect(matcher.match('bbbaaab'), isTrue);
        expect(matcher.match('bbbabaa'), isTrue);
        expect(matcher.match('aabbbbba'), isTrue);
        expect(matcher.match('a'), isFalse);
        expect(matcher.match('aa'), isFalse);
        expect(matcher.match('ab'), isFalse);
        expect(matcher.match('ba'), isFalse);
        expect(matcher.match('aab'), isFalse);
        expect(matcher.match('aba'), isFalse);
        expect(matcher.match('baab'), isFalse);
        expect(matcher.match('aabbb'), isFalse);
        expect(matcher.match('ababb'), isFalse);
        expect(matcher.match('bbaab'), isFalse);
        expect(matcher.match('bbbba'), isFalse);
        expect(matcher.match('aabaab'), isFalse);
        expect(matcher.match('aabbaa'), isFalse);
        expect(matcher.match('abaaab'), isFalse);
        expect(matcher.match('abbabb'), isFalse);
        expect(matcher.match('baaaab'), isFalse);
        expect(matcher.match('bbaaaa'), isFalse);
        expect(matcher.match('aaaabba'), isFalse);
        expect(matcher.match('aababab'), isFalse);
        expect(matcher.match('aabbbbb'), isFalse);
      });
      for (final example
          in examples.split('\n').map((line) => line.split(' '))) {
        test(example[0], () {
          final matcher = toNFA(example[0]);
          expect(matcher.match(example[1]), isTrue);
          if (example.length > 2) {
            expect(matcher.match(example[2]), isFalse);
          }
        });
      }
    });
  });
  test('linter', () {
    expect(linter(nodeParser), isEmpty);
  });
}

// https://github.com/xysun/regex/blob/master/testing.py
const examples = '''(ab|a)(bc|c) abc acb
(ab)c|abc abc ab
(a*)(b?)(b+) aaabbbb aaaa
((a|a)|a) a aa
(a*)(a|aa) aaaa b
a(b)|c(d)|a(e)f aef adf
(a|b)c|a(b|c) ac acc
(a|b)c|a(b|c) ab acc
(a|b)*c|(a|ab)*c abc bbbcabbbc
a?(ab|ba)ab abab aaabab
(aa|aaa)*|(a|aaaaa) aa
(a)(b)(c) abc
((((((((((x)))))))))) x
((((((((((x))))))))))* xx
a?(ab|ba)* ababababababababababababababababa
a*a*a*a*a*b aaaaaaaab
abc abc
ab*c abc
ab*bc abbc
ab*bc abbbbc
ab+bc abbc
ab+bc abbbbc
ab?bc abbc
ab?bc abc
ab|cd ab
(a)b(c) abc
a* aaa
(a+|b)* ab
(a+|b)+ ab
a|b|c|d|e e
(a|b|c|d|e)f ef
abcd*efg abcdefg
(ab|ab*)bc abc
(ab|a)b*c abc
((a)(b)c)(d) abcd
(a|ab)(c|bcd) abcd
(a|ab)(bcd|c) abcd
(ab|a)(c|bcd) abcd
(ab|a)(bcd|c) abcd
((a|ab)(c|bcd))(d*) abcd
((a|ab)(bcd|c))(d*) abcd
((ab|a)(c|bcd))(d*) abcd
((ab|a)(bcd|c))(d*) abcd
(a|ab)((c|bcd)(d*)) abcd
(a|ab)((bcd|c)(d*)) abcd
(ab|a)((c|bcd)(d*)) abcd
(ab|a)((bcd|c)(d*)) abcd
(a*)(b|abc) abc
(a*)(abc|b) abc
((a*)(b|abc))(c*) abc
((a*)(abc|b))(c*) abc
(a*)((b|abc))(c*) abc
(a*)((abc|b)(c*)) abc
(a*)(b|abc) abc
(a*)(abc|b) abc
((a*)(b|abc))(c*) abc
((a*)(abc|b))(c*) abc
(a*)((b|abc)(c*)) abc
(a*)((abc|b)(c*)) abc
(a|ab) ab
(ab|a) ab
(a|ab)(b*) ab
(ab|a)(b*) ab''';

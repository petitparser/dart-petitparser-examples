import 'node.dart';

final spaceCharClass = <Node>[
  LiteralNode(' '),
  LiteralNode('\t'),
  LiteralNode('\n'),
  LiteralNode('\r'),
  LiteralNode('\f'),
  LiteralNode('\v'),
].reduce(AlternationNode.new);

final digitCharClass = RangeNode('0', '9');

final wordCharClass = <Node>[
  RangeNode('a', 'z'),
  RangeNode('A', 'Z'),
  RangeNode('0', '9'),
  LiteralNode('_'),
].reduce(AlternationNode.new);

final escapeClasses = <String, Node>{
  't': LiteralNode('\t'),
  'n': LiteralNode('\n'),
  'r': LiteralNode('\r'),
  'f': LiteralNode('\f'),
  'e': LiteralNode('\x1b'),
  's': spaceCharClass,
  'S': ComplementNode(spaceCharClass),
  'd': digitCharClass,
  'D': ComplementNode(digitCharClass),
  'w': wordCharClass,
  'W': ComplementNode(wordCharClass),
};

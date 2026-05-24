import 'node.dart';

final escapeChars = <String, String>{
  't': '\t',
  'n': '\n',
  'r': '\r',
  'f': '\f',
  'e': '\x1b',
};

final escapeClasses = <String, Node>{
  's': _spaceCharClass,
  'S': ComplementNode(_spaceCharClass),
  'd': _digitCharClass,
  'D': ComplementNode(_digitCharClass),
  'w': _wordCharClass,
  'W': ComplementNode(_wordCharClass),
};

final _spaceCharClass = <Node>[
  LiteralNode(' '),
  LiteralNode('\t'),
  LiteralNode('\n'),
  LiteralNode('\r'),
  LiteralNode('\f'),
  LiteralNode('\v'),
].reduce(AlternationNode.new);

final _digitCharClass = RangeNode('0', '9');

final _wordCharClass = <Node>[
  RangeNode('a', 'z'),
  RangeNode('A', 'Z'),
  RangeNode('0', '9'),
  LiteralNode('_'),
].reduce(AlternationNode.new);

import 'package:petitparser/expression.dart';
import 'package:petitparser/parser.dart';

import 'node.dart';

final nodeParser = () {
  final builder = ExpressionBuilder<Node>();

  const meta = r'\()*+?|';
  builder
    ..primitive(noneOf(meta).map((char) => LiteralNode(char)))
    ..primitive(
        anyOf(meta).skip(before: char(r'\')).map((char) => LiteralNode(char)));

  builder.group().wrapper(char('('), char(')'), (_, value, __) => value);

  final integer = digit().plusString().trim().map(int.parse);
  final range =
      seq3(integer.optional(), char(',').trim().optional(), integer.optional())
          .skip(before: char('{'), after: char('}'))
          .map3((min, comma, max) => Sequence2<int, int?>(
              min ?? 0, max ?? (comma == null ? min ?? 0 : null)));

  builder.group()
    ..postfix(char('*'), (exp, _) => exp.star())
    ..postfix(char('+'), (exp, _) => exp.plus())
    ..postfix(char('?'), (exp, _) => exp.optional())
    ..postfix(range, (exp, range) => exp.repeat(range.first, range.second));

  builder.group()
    ..left(epsilon(), (left, _, right) => left.concat(right))
    ..optional(EmptyNode());

  builder.group().left(char('|'), (left, _, right) => left.or(right));

  return builder.build().end();
}();

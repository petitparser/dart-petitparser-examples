import 'package:petitparser/definition.dart';
import 'package:petitparser/expression.dart';
import 'package:petitparser/parser.dart';

import 'node.dart';

final nodeParser = () {
  final builder = ExpressionBuilder<Node>();

  const meta = r'\.()!*+?|&';
  builder
    ..primitive(noneOf(meta).map(LiteralNode.new))
    ..primitive(anyOf(meta).skip(before: char(r'\')).map(LiteralNode.new))
    ..primitive(char('.').map((_) => DotNode()));

  builder.group().wrapper(char('('), char(')'), (_, value, _) => value);

  final integer = digit().plusString().trim().map(int.parse);
  final range =
      seq3(integer.optional(), char(',').trim().optional(), integer.optional())
          .skip(before: char('{'), after: char('}'))
          .map3(
            (min, comma, max) =>
                (min ?? 0, max ?? (comma == null ? min ?? 0 : null)),
          );

  builder.group()
    ..prefix(char('!'), (_, exp) => ComplementNode(exp))
    ..postfix(char('*'), (exp, _) => QuantificationNode(exp, 0))
    ..postfix(char('+'), (exp, _) => QuantificationNode(exp, 1))
    ..postfix(char('?'), (exp, _) => QuantificationNode(exp, 0, 1))
    ..postfix(
      range,
      (exp, range) => QuantificationNode(exp, range.$1, range.$2),
    );

  builder.group()
    ..left(epsilon(), (left, _, right) => ConcatenationNode(left, right))
    ..optional(EmptyNode());

  builder.group()
    ..left(char('|'), (left, _, right) => AlternationNode(left, right))
    ..left(char('&'), (left, _, right) => IntersectionNode(left, right));

  return resolve(builder.build()).end();
}();

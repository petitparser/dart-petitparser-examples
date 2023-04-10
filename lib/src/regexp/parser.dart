import 'package:petitparser/expression.dart';
import 'package:petitparser/parser.dart';

import 'matcher.dart';

Parser<Matcher> createParser() {
  final builder = ExpressionBuilder<Matcher>();

  const meta = r'\().*+?|';
  builder
    ..primitive(noneOf(meta).map((char) => Literal(char)))
    ..primitive(
        anyOf(meta).skip(before: char(r'\')).map((char) => Literal(char)))
    ..primitive(char('.').map((_) => Dot()));

  builder.group().wrapper(char('('), char(')'), (_, value, __) => value);

  builder.group()
    ..postfix(char('*'), (regex, _) => Star(regex))
    ..postfix(char('+'), (regex, _) => Concat(regex, Star(regex)))
    ..postfix(char('?'), (regex, _) => Or(regex, Empty()));

  builder
      .group()
      .concat((list) => list.reduce((left, right) => Concat(left, right)));

  builder.group().left(char('|'), (left, _, right) => Or(left, right));

  final empty = epsilonWith(Empty());
  return [builder.build(), empty].toChoiceParser().end();
}

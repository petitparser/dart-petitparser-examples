import 'package:petitparser/definition.dart';
import 'package:petitparser/expression.dart';
import 'package:petitparser/parser.dart';

import 'escape.dart';
import 'node.dart';

class RegexpParserDefinition extends GrammarDefinition<Node> {
  Parser<Node> escape() => any()
      .skip(before: char(r'\'))
      .map(
        (char) => escapeClasses.containsKey(char)
            ? escapeClasses[char]!
            : LiteralNode(escapeChars[char] ?? char),
      );
  Parser<Node> dot() => char('.').map((_) => DotNode());
  Parser<Node> startAnchor() => char('^').map((_) => StartAnchorNode());
  Parser<Node> endAnchor() => char(r'$').map((_) => EndAnchorNode());
  Parser<Node> other() => noneOf('()!|&').map((char) => LiteralNode(char));

  Parser<Node> charClass() => seq2(char('^').optional(), ref0(charClassItems))
      .map2((negate, items) => negate != null ? ComplementNode(items) : items)
      .skip(before: char('['), after: char(']'));
  Parser<Node> charClassItems() => ref0(
    charClassItem,
  ).plus().map((items) => items.reduce(AlternationNode.new));
  Parser<String> charClassChar() => [
    any().skip(before: char(r'\')).map((char) => escapeChars[char] ?? char),
    noneOf(']'),
  ].toChoiceParser();
  Parser<Node> charClassRange() => seq3(
    ref0(charClassChar),
    char('-'),
    ref0(charClassChar),
  ).map3((start, _, end) => RangeNode(start, end));
  Parser<Node> charClassItem() => [
    ref0(charClassRange),
    ref0(charClassChar).map(LiteralNode.new),
  ].toChoiceParser();

  Parser<int> integer() => digit().plusString().trim().map(int.parse);
  Parser<({int min, int? max})> range() =>
      seq3(
            ref0(integer).optional(),
            char(',').trim().optional(),
            ref0(integer).optional(),
          )
          .skip(before: char('{'), after: char('}'))
          .map3(
            (min, comma, max) =>
                (min: min ?? 0, max: max ?? (comma == null ? min ?? 0 : null)),
          );

  @override
  Parser<Node> start() {
    final builder = ExpressionBuilder<Node>();

    builder
      ..primitive(ref0(dot))
      ..primitive(ref0(startAnchor))
      ..primitive(ref0(endAnchor))
      ..primitive(ref0(charClass))
      ..primitive(ref0(escape))
      ..primitive(ref0(other));

    builder.group().wrapper(char('('), char(')'), (_, value, _) => value);

    builder.group()
      ..prefix(char('!'), (_, exp) => ComplementNode(exp))
      ..postfix(char('*'), (exp, _) => QuantificationNode(exp, 0))
      ..postfix(char('+'), (exp, _) => QuantificationNode(exp, 1))
      ..postfix(char('?'), (exp, _) => QuantificationNode(exp, 0, 1))
      ..postfix(
        ref0(range),
        (exp, range) => QuantificationNode(exp, range.min, range.max),
      );

    builder.group()
      ..left(epsilon(), (left, _, right) => ConcatenationNode(left, right))
      ..optional(EmptyNode());

    builder.group()
      ..left(char('|'), (left, _, right) => AlternationNode(left, right))
      ..left(char('&'), (left, _, right) => IntersectionNode(left, right));

    return resolve(builder.build()).end();
  }
}

final nodeParser = RegexpParserDefinition().build();

import 'package:petitparser/petitparser.dart';

import 'cons.dart';
import 'name.dart';
import 'quote.dart';

/// The standard lisp parser definition.
final _definition = LispParserDefinition();

/// The standard lisp parser.
final lispParser = _definition.build();

/// LISP parser definition that directly creates typed Lisp AST structures.
class LispParserDefinition extends GrammarDefinition<List<dynamic>> {
  @override
  Parser<List<dynamic>> start() => ref0(atom).star().end();

  Parser<dynamic> atom() => ref0(atomChoice).trim(ref0(space));

  Parser<dynamic> atomChoice() => [
    ref2(bracket, '()', ref0(cells)),
    ref2(bracket, '[]', ref0(cells)),
    ref2(bracket, '{}', ref0(cells)),
    ref0(number),
    ref0(string),
    ref0(symbol),
    ref0(quote),
    ref0(quasiquote),
    ref0(unquote),
    ref0(splice),
  ].toChoiceParser();

  Parser<dynamic> list() => [
    ref2(bracket, '()', ref0(cells)),
    ref2(bracket, '[]', ref0(cells)),
    ref2(bracket, '{}', ref0(cells)),
  ].toChoiceParser();

  Parser<dynamic> cells() => [ref0(cell), ref0(empty)].toChoiceParser();

  Parser<Cons> cell() =>
      seq2(ref0(atom), ref0(cells)).map2((car, cdr) => Cons(car, cdr));

  Parser<dynamic> empty() => epsilonWith(null);

  Parser<num> number() =>
      ref0(numberToken).flatten(message: 'Number expected').map(num.parse);

  Parser<void> numberToken() => seq4(
    anyOf('-+').optional(),
    [char('0'), digit().plus()].toChoiceParser(),
    seq2(char('.'), digit().plus()).optional(),
    seq3(anyOf('eE'), anyOf('-+').optional(), digit().plus()).optional(),
  );

  Parser<String> string() =>
      ref0(character)
          .star()
          .skip(before: char('"'), after: char('"'))
          .map((chars) => chars.join());

  Parser<String> character() =>
      [ref0(characterEscape), ref0(characterRaw)].toChoiceParser();

  Parser<String> characterEscape() =>
      seq2(char(r'\'), any()).map2((_, char) => char);

  Parser<String> characterRaw() => pattern('^"');

  Parser<Name> symbol() =>
      ref0(symbolToken).flatten(message: 'Symbol expected').map(Name.new);

  Parser<void> symbolToken() => seq2(
    pattern(r'a-zA-Z!#$%&*/:<=>?@\_|~+-'),
    pattern(r'a-zA-Z0-9!#$%&*/:<=>?@\_|~+-').starString(),
  );

  Parser<Quote> quote() =>
      seq2(char("'"), ref0(atom)).map2((_, atom) => Quote(atom));

  Parser<Cons> quasiquote() => seq2(
    char('`'),
    ref0(list),
  ).map2((_, list) => Cons(Name('quasiquote'), Cons(list, null)));

  Parser<Cons> unquote() => seq2(
    char(','),
    ref0(list),
  ).map2((_, list) => Cons(Name('unquote'), Cons(list, null)));

  Parser<Cons> splice() => seq2(
    char('@'),
    ref0(list),
  ).map2((_, list) => Cons(Name('unquote-splicing'), Cons(list, null)));

  Parser<void> space() => [whitespace(), ref0(comment)].toChoiceParser();

  Parser<void> comment() => seq2(char(';'), pattern('^\r\n').starString());

  Parser<dynamic> bracket(String brackets, Parser parser) => parser
      .trim(ref0(space))
      .skip(before: char(brackets[0]), after: char(brackets[1]));
}

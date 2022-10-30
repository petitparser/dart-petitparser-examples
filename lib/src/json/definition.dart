import 'package:petitparser/definition.dart';
import 'package:petitparser/parser.dart';

import 'encoding.dart';
import 'types.dart';

/// JSON grammar definition.
class JsonDefinition extends GrammarDefinition<JSON> {
  @override
  Parser<JSON> start() => ref0(value).end();
  Parser<JSON> value() => [
        ref0(stringToken),
        ref0(numberToken),
        ref0(object),
        ref0(array),
        ref0(trueToken),
        ref0(falseToken),
        ref0(nullToken),
      ].toChoiceParser(failureJoiner: selectFarthestJoined);

  Parser<Map<String, JSON>> object() => seq3(
        char('{').trim(),
        ref0(objectElements),
        char('}').trim(),
      ).map3((_, elements, __) => elements);
  Parser<Map<String, JSON>> objectElements() => ref0(objectElement)
      .starSeparated(char(',').trim())
      .map((list) => Map.fromEntries(list.elements));
  Parser<MapEntry<String, JSON>> objectElement() =>
      seq3(ref0(stringToken), char(':').trim(), ref0(value))
          .map3((key, _, value) => MapEntry(key, value));

  Parser<List<JSON>> array() => seq3(
        char('[').trim(),
        ref0(arrayElements),
        char(']').trim(),
      ).map3((_, elements, __) => elements);
  Parser<List<JSON>> arrayElements() =>
      ref0(value).starSeparated(char(',').trim()).map((list) => list.elements);

  Parser<bool> trueToken() => string('true').trim().map((_) => true);
  Parser<bool> falseToken() => string('false').trim().map((_) => false);
  Parser<Object?> nullToken() => string('null').trim().map((_) => null);

  Parser<String> stringToken() => seq3(
        char('"'),
        ref0(characterPrimitive).star(),
        char('"'),
      ).trim().map3((_, chars, __) => chars.join());
  Parser<String> characterPrimitive() => [
        ref0(characterNormal),
        ref0(characterEscape),
        ref0(characterUnicode),
      ].toChoiceParser();
  Parser<String> characterNormal() => pattern('^"\\');
  Parser<String> characterEscape() => seq2(
        char('\\'),
        anyOf(jsonEscapeChars.keys.join()),
      ).map2((_, char) => jsonEscapeChars[char]!);
  Parser<String> characterUnicode() => seq2(
        string('\\u'),
        pattern('0-9A-Fa-f').times(4).flatten('4-digit hex number expected'),
      ).map2((_, value) => String.fromCharCode(int.parse(value, radix: 16)));

  Parser<num> numberToken() =>
      ref0(numberPrimitive).flatten('number expected').trim().map(num.parse);
  Parser<void> numberPrimitive() =>
      char('-').optional() &
      char('0').or(digit().plus()) &
      char('.').seq(digit().plus()).optional() &
      anyOf('eE').seq(anyOf('-+').optional()).seq(digit().plus()).optional();
}

import 'package:petitparser/definition.dart';
import 'package:petitparser/parser.dart';

import 'encoding.dart';
import 'types.dart';

/// JSON grammar definition.
class JsonDefinition extends GrammarDefinition<JSON> {
  @override
  Parser<JSON> start() => ref0(value).end();
  Parser<JSON> value() => [
        ref0(object),
        ref0(array),
        ref0(stringToken),
        ref0(numberToken),
        ref0(trueToken),
        ref0(falseToken),
        ref0(nullToken),
        failure('value expected'),
      ].toChoiceParser();

  Parser<Map<String, JSON>> object() => seq4(
        char('{').trim(),
        cut(),
        ref0(objectElements),
        char('}').trim(),
      ).map4((_, __, elements, ___) => elements);
  Parser<Map<String, JSON>> objectElements() => ref0(objectElement)
      .starSeparated(char(',').trim().commit())
      .map((list) => Map.fromEntries(list.elements));
  Parser<MapEntry<String, JSON>> objectElement() =>
      seq5(ref0(stringToken), cut(), char(':').trim(), cut(), ref0(value))
          .map5((key, _, __, ___, value) => MapEntry(key, value));

  Parser<List<JSON>> array() => seq4(
        char('[').trim(),
        cut(),
        ref0(arrayElements),
        char(']').trim(),
      ).map4((_, __, elements, ___) => elements);
  Parser<List<JSON>> arrayElements() => ref0(value)
      .starSeparated(char(',').trim().commit())
      .map((list) => list.elements);

  Parser<bool> trueToken() => string('true').trim().map((_) => true);
  Parser<bool> falseToken() => string('false').trim().map((_) => false);
  Parser<Object?> nullToken() => string('null').trim().map((_) => null);

  Parser<String> stringToken() => seq4(
        char('"'),
        cut(),
        ref0(characterPrimitive).star(),
        char('"'),
      ).trim().map4((_, __, chars, ___) => chars.join());
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
  Parser<void> numberPrimitive() => <Parser>[
        char('-').optional(),
        [char('0'), digit().plus()].toChoiceParser(),
        [char('.'), cut(), digit().plus()].toSequenceParser().optional(),
        [anyOf('eE'), cut(), anyOf('-+').optional(), digit().plus()]
            .toSequenceParser()
            .optional()
      ].toSequenceParser();
}

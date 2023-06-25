import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('combinator - and', any().and(), 255);
  for (var i = 2; i < 10; i++) {
    final parsers = [...List.filled(i - 1, failure()), any()];
    runChars('combinator - or [$i]', parsers.toChoiceParser(), 255);
  }
  runChars('combinator - not', any().not(), 0);
  runChars('combinator - neg', any().neg(), 0);
  runChars('combinator - optional', any().optional(), 255);
  runChars('combinator - optionalWith', any().optionalWith('!'), 255);
  for (var i = 2; i < 256; i *= 2) {
    runString('combinator - seq [${i.toString().padLeft(3)}]',
        List.filled(i, any()).toSequenceParser());
  }
  runString('combinator - seq2', seq2(any(), any()));
  runString('combinator - seq3', seq3(any(), any(), any()));
  runString('combinator - seq4', seq4(any(), any(), any(), any()));
  runString('combinator - seq5', seq5(any(), any(), any(), any(), any()));
  runString(
      'combinator - seq6', seq6(any(), any(), any(), any(), any(), any()));
  runString('combinator - seq7',
      seq7(any(), any(), any(), any(), any(), any(), any()));
  runString('combinator - seq8',
      seq8(any(), any(), any(), any(), any(), any(), any(), any()));
  runString('combinator - seq9',
      seq9(any(), any(), any(), any(), any(), any(), any(), any(), any()));
  runChars('combinator - settable', any().settable(), 255);
  runChars('combinator - skip', any().skip(before: epsilon(), after: epsilon()),
      255);
}

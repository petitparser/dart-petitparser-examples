import 'package:petitparser/petitparser.dart';

import '../utils/runner.dart';

void main() {
  runChars('combinator - and', any().and(), success: 351);
  for (var i = 2; i < 10; i++) {
    final parsers = [...List.filled(i - 1, failure()), any()];
    runChars('combinator - or [$i]', parsers.toChoiceParser(), success: 351);
  }
  runChars('combinator - not', any().not(), success: 0);
  runChars('combinator - neg', any().neg(), success: 0);
  runChars('combinator - optional', any().optional(), success: 351);
  runChars('combinator - optionalWith', any().optionalWith('!'), success: 351);
  for (var i = 2; i < 256; i *= 2) {
    runString(
      'combinator - seq [${i.toString().padLeft(3, '0')}]',
      List.filled(i, any()).toSequenceParser(),
      position: i,
    );
  }
  runString('combinator - seq2', seq2(any(), any()), position: 2);
  runString('combinator - seq3', seq3(any(), any(), any()), position: 3);
  runString('combinator - seq4', seq4(any(), any(), any(), any()), position: 4);
  runString(
    'combinator - seq5',
    seq5(any(), any(), any(), any(), any()),
    position: 5,
  );
  runString(
    'combinator - seq6',
    seq6(any(), any(), any(), any(), any(), any()),
    position: 6,
  );
  runString(
    'combinator - seq7',
    seq7(any(), any(), any(), any(), any(), any(), any()),
    position: 7,
  );
  runString(
    'combinator - seq8',
    seq8(any(), any(), any(), any(), any(), any(), any(), any()),
    position: 8,
  );
  runString(
    'combinator - seq9',
    seq9(any(), any(), any(), any(), any(), any(), any(), any(), any()),
    position: 9,
  );
  runChars('combinator - settable', any().settable(), success: 351);
  runChars(
    'combinator - skip',
    any().skip(before: epsilon(), after: epsilon()),
    success: 351,
  );
}

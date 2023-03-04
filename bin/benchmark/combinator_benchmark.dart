import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('and', any().and(), 255);
  for (var i = 2; i <= 16; i *= 2) {
    final parsers = [...List.filled(i - 1, failure()), any()];
    runString('choice($i, select-first)',
        parsers.toChoiceParser(failureJoiner: selectFirst));
    runString('choice($i, select-last)',
        parsers.toChoiceParser(failureJoiner: selectLast));
    runString('choice($i, select-farthest)',
        parsers.toChoiceParser(failureJoiner: selectFarthest));
    runString('choice($i, select-farthest-joined)',
        parsers.toChoiceParser(failureJoiner: selectFarthestJoined));
  }
  runChars('not', any().not(), 0);
  runChars('neg', any().neg(), 0);
  runChars('optional', any().optional(), 255);
  runChars('optionalWith', any().optionalWith('!'), 255);
  for (var i = 2; i < defaultStringInput.length; i *= 2) {
    runString('seq($i)', List.filled(i, any()).toSequenceParser());
  }
  runString('seq2', seq2(any(), any()));
  runString('seq3', seq3(any(), any(), any()));
  runString('seq4', seq4(any(), any(), any(), any()));
  runString('seq5', seq5(any(), any(), any(), any(), any()));
  runString('seq6', seq6(any(), any(), any(), any(), any(), any()));
  runString('seq7', seq7(any(), any(), any(), any(), any(), any(), any()));
  runString(
    'seq8',
    seq8(any(), any(), any(), any(), any(), any(), any(), any()),
  );
  runString(
    'seq9',
    seq9(any(), any(), any(), any(), any(), any(), any(), any(), any()),
  );
  runChars('settable', any().settable(), 255);
  runChars('skip', any().skip(before: epsilon(), after: epsilon()), 255);
}

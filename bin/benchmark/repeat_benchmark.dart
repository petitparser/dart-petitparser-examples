import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

final length = defaultStringInput.length;
final half = length ~/ 2;
final last = defaultStringInput[length - 1];

void main() {
  runString('star', any().star());
  runString('plus', any().plus());
  runString('times', any().times(length));
  runString('repeat', any().repeat(half, length));

  runString('starGreedy', any().starGreedy(char(last)));
  runString('plusGreedy', any().plusGreedy(char(last)));
  runString('timesGreedy', any().repeatGreedy(char(last), half, length));

  runString('starLazy', any().starLazy(char(last)));
  runString('plusLazy', any().plusLazy(char(last)));
  runString('timesLazy', any().repeatLazy(char(last), half, length));

  runString('starSeparated', any().starSeparated(epsilon()));
  runString('plusSeparated', any().plusSeparated(epsilon()));
  runString('timesSeparated', any().timesSeparated(epsilon(), length));
  runString('repeatSeparated', any().repeatSeparated(epsilon(), half, length));

  for (var i = 2; i < length; i *= 2) {
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
}

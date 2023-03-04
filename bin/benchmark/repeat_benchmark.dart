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
}

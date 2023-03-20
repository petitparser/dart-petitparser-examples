import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

final length = defaultStringInput.length;
final half = length ~/ 2;
final last = defaultStringInput[length - 1];

void main() {
  runString('repeat - star', any().star());
  runString('repeat - plus', any().plus());
  runString('repeat - times', any().times(length));
  runString('repeat - repeat', any().repeat(half, length));

  runString('repeat - starGreedy', any().starGreedy(char(last)));
  runString('repeat - plusGreedy', any().plusGreedy(char(last)));
  runString(
      'repeat - timesGreedy', any().repeatGreedy(char(last), half, length));

  runString('repeat - starLazy', any().starLazy(char(last)));
  runString('repeat - plusLazy', any().plusLazy(char(last)));
  runString('repeat - timesLazy', any().repeatLazy(char(last), half, length));

  runString('repeat - starSeparated', any().starSeparated(epsilon()));
  runString('repeat - plusSeparated', any().plusSeparated(epsilon()));
  runString('repeat - timesSeparated', any().timesSeparated(epsilon(), length));
  runString('repeat - repeatSeparated',
      any().repeatSeparated(epsilon(), half, length));

  runString('repeat - starString', any().starString());
  runString('repeat - plusString', any().plusString());
  runString('repeat - timesString', any().timesString(length));
  runString('repeat - repeatString', any().repeatString(half, length));
}

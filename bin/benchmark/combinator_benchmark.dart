import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('and', any().and(), 255);
  runChars('cast', any().cast(), 255);
  runChars('castList', any().star().castList(), 255);
  runChars('end', any().end(), 255);
  runChars('epsilon', epsilon(), 255);
  runChars('epsilonWith', epsilonWith<String>('!'), 255);
  runChars('failure', failure(), 0);
  runChars('flatten', any().flatten(), 255);
  runChars('label', any().labeled('label'), 255);
  runChars('map', any().map((_) {}), 255);
  runChars('neg', any().neg(), 0);
  runChars('newline', newline(), 2);
  runChars('not', any().not(), 0);
  runChars('optional', any().optional(), 255);
  runChars('optionalWith', any().optionalWith('!'), 255);
  runChars('or', failure().or(any()).star(), 255);
  runChars('permute', any().star().permute([0]), 255);
  runChars('pick', any().star().pick(0), 255);
  runChars('position', position(), 255);
  runChars('set', any().settable(), 255);
  runChars('skip', any().skip(before: epsilon(), after: epsilon()), 255);
  runChars('token', any().token(), 255);
  runChars('trim', any().trim(), 247);
  runChars('where', any().where((_) => true), 255);
}

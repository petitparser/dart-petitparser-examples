import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('misc - end', any().end(), 1);
  runChars('misc - endOfInput', endOfInput(), 0);
  runChars('misc - epsilon', epsilon(), 255);
  runChars('misc - epsilonWith', epsilonWith<String>('!'), 255);
  runChars('misc - failure', failure(), 0);
  runChars('misc - label', any().labeled('label'), 255);
  runChars('misc - newline', newline(), 2);
  runChars('misc - position', position(), 255);
}

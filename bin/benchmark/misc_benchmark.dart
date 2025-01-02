import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('misc - end', any().end(), success: 287);
  runChars('misc - endOfInput', endOfInput(), success: 0);
  runChars('misc - epsilon', epsilon(), success: 319);
  runChars('misc - epsilonWith', epsilonWith<String>('!'), success: 319);
  runChars('misc - failure', failure(), success: 0);
  runChars('misc - label', any().labeled('label'), success: 319);
  runChars('misc - newline', newline(), success: 2);
  runChars('misc - position', position(), success: 319);
}

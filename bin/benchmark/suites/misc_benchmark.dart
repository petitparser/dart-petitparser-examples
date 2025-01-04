import 'package:petitparser/petitparser.dart';

import '../utils/runner.dart';

void main() {
  runChars('misc - end', any().end(), success: 1);
  runChars('misc - endOfInput', endOfInput(), success: 0);
  runChars('misc - epsilon', epsilon(), success: 351);
  runChars('misc - epsilonWith', epsilonWith<String>('!'), success: 351);
  runChars('misc - failure', failure(), success: 0);
  runChars('misc - label', any().labeled('label'), success: 351);
  runChars('misc - newline', newline(), success: 2);
  runChars('misc - position', position(), success: 351);
}

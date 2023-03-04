import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('end', any().end(), 255);
  runChars('endOfInput', endOfInput(), 0);
  runChars('epsilon', epsilon(), 255);
  runChars('epsilonWith', epsilonWith<String>('!'), 255);
  runChars('failure', failure(), 0);
  runChars('label', any().labeled('label'), 255);
  runChars('newline', newline(), 2);
  runChars('position', position(), 255);
}

import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('any', any(), 255);
  runChars('anyOf', anyOf('uncopyrightable'), 15);
  runChars('char', char('a'), 1);
  runChars('digit', digit(), 10);
  runChars('letter', letter(), 52);
  runChars('lowercase', lowercase(), 26);
  runChars('noneOf', noneOf('uncopyrightable'), 240);
  runChars('pattern ^a', pattern('^a'), 254);
  runChars('pattern ^a-cx-zA-CX-Z1-37-9', pattern('^a-cx-zA-CX-Z1-37-9'), 237);
  runChars('pattern ^a-z', pattern('^a-z'), 229);
  runChars('pattern ^acegik', pattern('^acegik'), 249);
  runChars('pattern a', pattern('a'), 1);
  runChars('pattern a-cx-zA-CX-Z1-37-9', pattern('a-cx-zA-CX-Z1-37-9'), 18);
  runChars('pattern a-z', pattern('a-z'), 26);
  runChars('pattern acegik', pattern('acegik'), 6);
  runChars('range', range('a', 'z'), 26);
  runChars('uppercase', uppercase(), 26);
  runChars('whitespace', whitespace(), 8);
  runChars('word', word(), 63);
}

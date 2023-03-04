import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('character - any', any(), 255);
  runChars('character - anyOf', anyOf('uncopyrightable'), 15);
  runChars('character - char', char('a'), 1);
  runChars('character - digit', digit(), 10);
  runChars('character - letter', letter(), 52);
  runChars('character - lowercase', lowercase(), 26);
  runChars('character - noneOf', noneOf('uncopyrightable'), 240);
  runChars('character - pattern - ^a', pattern('^a'), 254);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9',
      pattern('^a-cx-zA-CX-Z1-37-9'), 237);
  runChars('character - pattern - ^a-z', pattern('^a-z'), 229);
  runChars('character - pattern - ^acegik', pattern('^acegik'), 249);
  runChars('character - pattern - a', pattern('a'), 1);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9',
      pattern('a-cx-zA-CX-Z1-37-9'), 18);
  runChars('character - pattern - a-z', pattern('a-z'), 26);
  runChars('character - pattern - acegik', pattern('acegik'), 6);
  runChars('character - range', range('a', 'z'), 26);
  runChars('character - uppercase', uppercase(), 26);
  runChars('character - whitespace', whitespace(), 8);
  runChars('character - word', word(), 63);
}

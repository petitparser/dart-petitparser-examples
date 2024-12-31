import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('character - any', any(), 255);
  runChars('character - any (unicode)', any(unicode: true), 255);
  runChars('character - anyOf', anyOf('uncopyrightable'), 15);
  runChars('character - anyOf (unicode)',
      anyOf('uncopyrightable', unicode: true), 15);
  runChars('character - char', char('a'), 1);
  runChars('character - char (unicode)', char('a', unicode: true), 1);
  runChars('character - char (ignore case)', char('a', ignoreCase: true), 2);
  runChars('character - char (ignore case, unicode)',
      char('a', ignoreCase: true, unicode: true), 2);
  runChars('character - digit', digit(), 10);
  runChars('character - letter', letter(), 52);
  runChars('character - lowercase', lowercase(), 26);
  runChars('character - noneOf', noneOf('uncopyrightable'), 240);
  runChars('character - noneOf (unicode)',
      noneOf('uncopyrightable', unicode: true), 240);
  runChars('character - pattern - ^a', pattern('^a'), 254);
  runChars('character - pattern - ^a (ignore case)',
      pattern('^a', ignoreCase: true), 253);
  runChars(
      'character - pattern - ^a (unicode)', pattern('^a', unicode: true), 254);
  runChars('character - pattern - ^a (ignore case, unicode)',
      pattern('^a', ignoreCase: true, unicode: true), 253);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9',
      pattern('^a-cx-zA-CX-Z1-37-9'), 237);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (ignore case)',
      pattern('^a-cx-zA-CX-Z1-37-9', ignoreCase: true), 237);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (unicode',
      pattern('^a-cx-zA-CX-Z1-37-9', unicode: true), 237);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (ignore case, unicode)',
      pattern('^a-cx-zA-CX-Z1-37-9', ignoreCase: true, unicode: true), 237);
  runChars('character - pattern - ^a-z', pattern('^a-z'), 229);
  runChars('character - pattern - ^a-z (ignore case)',
      pattern('^a-z', ignoreCase: true), 203);
  runChars('character - pattern - ^a-z (unicode)',
      pattern('^a-z', unicode: true), 229);
  runChars('character - pattern - ^a-z (ignore case, unicode)',
      pattern('^a-z', ignoreCase: true, unicode: true), 203);
  runChars('character - pattern - ^acegik', pattern('^acegik'), 249);
  runChars('character - pattern - ^acegik (ignore case)',
      pattern('^acegik', ignoreCase: true), 243);
  runChars('character - pattern - ^acegik (unicode)',
      pattern('^acegik', unicode: true), 249);
  runChars('character - pattern - ^acegik (ignore case, unicode)',
      pattern('^acegik', ignoreCase: true, unicode: true), 243);
  runChars('character - pattern - a', pattern('a'), 1);
  runChars('character - pattern - a (ignore case)',
      pattern('a', ignoreCase: true), 2);
  runChars('character - pattern - a (unicode)', pattern('a', unicode: true), 1);
  runChars('character - pattern - a (ignore case, unicode)',
      pattern('a', ignoreCase: true, unicode: true), 2);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9',
      pattern('a-cx-zA-CX-Z1-37-9'), 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (ignore case)',
      pattern('a-cx-zA-CX-Z1-37-9', ignoreCase: true), 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (unicode)',
      pattern('a-cx-zA-CX-Z1-37-9', unicode: true), 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (ignore case, unicode)',
      pattern('a-cx-zA-CX-Z1-37-9', ignoreCase: true, unicode: true), 18);
  runChars('character - pattern - a-z', pattern('a-z'), 26);
  runChars('character - pattern - a-z (ignore case)',
      pattern('a-z', ignoreCase: true), 52);
  runChars(
      'character - pattern - a-z (unicode)', pattern('a-z', unicode: true), 26);
  runChars('character - pattern - a-z (ignore case, unicode)',
      pattern('a-z', ignoreCase: true, unicode: true), 52);
  runChars('character - pattern - acegik', pattern('acegik'), 6);
  runChars('character - pattern - acegik (ignore case)',
      pattern('acegik', ignoreCase: true), 12);
  runChars('character - pattern - acegik (unicode)',
      pattern('acegik', unicode: true), 6);
  runChars('character - pattern - acegik (ignore case, unicode)',
      pattern('acegik', ignoreCase: true, unicode: true), 12);
  runChars('character - pattern - any', pattern('\u0000-\uffff'), 255);
  runChars('character - pattern - any (ignore case)',
      pattern('\u0000-\uffff', ignoreCase: true), 255);
  runChars('character - pattern - any (unicode)',
      pattern('\u0000-\uffff', unicode: true), 255);
  runChars('character - pattern - any (ignore case, unicode)',
      pattern('\u0000-\uffff', ignoreCase: true, unicode: true), 255);
  runChars('character - pattern - none', pattern('^\u0000-\uffff'), 0);
  runChars('character - pattern - none (ignore case)',
      pattern('^\u0000-\uffff', ignoreCase: true), 0);
  runChars('character - pattern - none (unicode)',
      pattern('^\u0000-\uffff', unicode: true), 0);
  runChars('character - pattern - none (ignore case, unicode))',
      pattern('^\u0000-\uffff', ignoreCase: true, unicode: true), 0);
  runChars('character - range', range('a', 'z'), 26);
  runChars('character - range (unicode)', range('a', 'z', unicode: true), 26);
  runChars('character - uppercase', uppercase(), 26);
  runChars('character - whitespace', whitespace(), 8);
  runChars('character - word', word(), 63);
}

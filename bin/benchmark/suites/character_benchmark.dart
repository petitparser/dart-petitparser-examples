import 'package:petitparser/petitparser.dart';

import '../utils/runner.dart';

void main() {
  runChars('character - any', any(), success: 319);
  runChars('character - any (unicode)', any(unicode: true), success: 319);

  runChars('character - anyOf', anyOf('uncopyrightable'), success: 15);
  runChars(
      'character - anyOf (unicode)', anyOf('uncopyrightable', unicode: true),
      success: 15);
  runChars('character - anyOf (ignore case)',
      anyOf('uncopyrightable', ignoreCase: true),
      success: 30);
  runChars('character - anyOf (ignore case, unicode)',
      anyOf('uncopyrightable', ignoreCase: true, unicode: true),
      success: 30);

  runChars('character - char', char('a'), success: 1);
  runChars('character - char (unicode)', char('a', unicode: true), success: 1);
  runChars('character - char (ignore case)', char('a', ignoreCase: true),
      success: 2);
  runChars('character - char (ignore case, unicode)',
      char('a', ignoreCase: true, unicode: true),
      success: 2);

  runChars('character - digit', digit(), success: 10);
  runChars('character - letter', letter(), success: 52);
  runChars('character - lowercase', lowercase(), success: 26);

  runChars('character - noneOf', noneOf('uncopyrightable'), success: 304);
  runChars(
      'character - noneOf (unicode)', noneOf('uncopyrightable', unicode: true),
      success: 304);
  runChars('character - noneOf (ignore case)',
      noneOf('uncopyrightable', ignoreCase: true),
      success: 289);
  runChars('character - noneOf (ignore case, unicode)',
      noneOf('uncopyrightable', ignoreCase: true, unicode: true),
      success: 289);

  runChars('character - pattern - ^a', pattern('^a'), success: 318);
  runChars(
      'character - pattern - ^a (ignore case)', pattern('^a', ignoreCase: true),
      success: 317);
  runChars('character - pattern - ^a (unicode)', pattern('^a', unicode: true),
      success: 318);
  runChars('character - pattern - ^a (ignore case, unicode)',
      pattern('^a', ignoreCase: true, unicode: true),
      success: 317);

  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9',
      pattern('^a-cx-zA-CX-Z1-37-9'),
      success: 301);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (ignore case)',
      pattern('^a-cx-zA-CX-Z1-37-9', ignoreCase: true),
      success: 301);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (unicode)',
      pattern('^a-cx-zA-CX-Z1-37-9', unicode: true),
      success: 301);
  runChars('character - pattern - ^a-cx-zA-CX-Z1-37-9 (ignore case, unicode)',
      pattern('^a-cx-zA-CX-Z1-37-9', ignoreCase: true, unicode: true),
      success: 301);

  runChars('character - pattern - ^a-z', pattern('^a-z'), success: 293);
  runChars('character - pattern - ^a-z (ignore case)',
      pattern('^a-z', ignoreCase: true),
      success: 267);
  runChars(
      'character - pattern - ^a-z (unicode)', pattern('^a-z', unicode: true),
      success: 293);
  runChars('character - pattern - ^a-z (ignore case, unicode)',
      pattern('^a-z', ignoreCase: true, unicode: true),
      success: 267);

  runChars('character - pattern - ^acegik', pattern('^acegik'), success: 313);
  runChars('character - pattern - ^acegik (ignore case)',
      pattern('^acegik', ignoreCase: true),
      success: 307);
  runChars('character - pattern - ^acegik (unicode)',
      pattern('^acegik', unicode: true),
      success: 313);
  runChars('character - pattern - ^acegik (ignore case, unicode)',
      pattern('^acegik', ignoreCase: true, unicode: true),
      success: 307);

  runChars('character - pattern - a', pattern('a'), success: 1);
  runChars(
      'character - pattern - a (ignore case)', pattern('a', ignoreCase: true),
      success: 2);
  runChars('character - pattern - a (unicode)', pattern('a', unicode: true),
      success: 1);
  runChars('character - pattern - a (ignore case, unicode)',
      pattern('a', ignoreCase: true, unicode: true),
      success: 2);

  runChars(
      'character - pattern - a-cx-zA-CX-Z1-37-9', pattern('a-cx-zA-CX-Z1-37-9'),
      success: 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (ignore case)',
      pattern('a-cx-zA-CX-Z1-37-9', ignoreCase: true),
      success: 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (unicode)',
      pattern('a-cx-zA-CX-Z1-37-9', unicode: true),
      success: 18);
  runChars('character - pattern - a-cx-zA-CX-Z1-37-9 (ignore case, unicode)',
      pattern('a-cx-zA-CX-Z1-37-9', ignoreCase: true, unicode: true),
      success: 18);

  runChars('character - pattern - a-z', pattern('a-z'), success: 26);
  runChars('character - pattern - a-z (ignore case)',
      pattern('a-z', ignoreCase: true),
      success: 52);
  runChars('character - pattern - a-z (unicode)', pattern('a-z', unicode: true),
      success: 26);
  runChars('character - pattern - a-z (ignore case, unicode)',
      pattern('a-z', ignoreCase: true, unicode: true),
      success: 52);

  runChars('character - pattern - acegik', pattern('acegik'), success: 6);
  runChars('character - pattern - acegik (ignore case)',
      pattern('acegik', ignoreCase: true),
      success: 12);
  runChars('character - pattern - acegik (unicode)',
      pattern('acegik', unicode: true),
      success: 6);
  runChars('character - pattern - acegik (ignore case, unicode)',
      pattern('acegik', ignoreCase: true, unicode: true),
      success: 12);

  runChars('character - pattern - any', pattern('\u0000-\uffff'));
  runChars('character - pattern - any (unicode)',
      pattern('\u0000-\u{10ffff}', unicode: true));

  runChars('character - pattern - none', pattern('^\u0000-\uffff'), success: 0);
  runChars('character - pattern - none (unicode)',
      pattern('^\u0000-\u{10ffff}', unicode: true),
      success: 0);

  runChars('character - range', range('a', 'z'), success: 26);
  runChars('character - range (unicode)', range('a', 'z', unicode: true),
      success: 26);

  runChars('character - uppercase', uppercase(), success: 26);
  runChars('character - whitespace', whitespace(), success: 8);
  runChars('character - word', word(), success: 63);
}

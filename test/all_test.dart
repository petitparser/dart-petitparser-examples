import 'package:test/test.dart';

import 'bibtex_test.dart' as bibtex_test;
import 'dart_test.dart' as dart_test;
import 'json_test.dart' as json_test;
import 'lisp_test.dart' as lisp_test;
import 'math_test.dart' as math_test;
import 'pascal_test.dart' as pascal_test;
import 'prolog_test.dart' as prolog_test;
import 'regexp_test.dart' as regexp_test;
import 'smalltalk_test.dart' as smalltalk_test;
import 'tabular_test.dart' as tabular_test;
import 'uri_test.dart' as uri_test;

void main() {
  group('bibtex', bibtex_test.main);
  group('dart', dart_test.main);
  group('json', json_test.main);
  group('lisp', lisp_test.main);
  group('math', math_test.main);
  group('pascal', pascal_test.main);
  group('prolog', prolog_test.main);
  group('regexp', regexp_test.main);
  group('smalltalk', smalltalk_test.main);
  group('tabular', tabular_test.main);
  group('uri', uri_test.main);
}

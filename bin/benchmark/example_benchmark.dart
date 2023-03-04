import 'package:petitparser_examples/bibtex.dart' as bibtex_example;
import 'package:petitparser_examples/json.dart' as json_example;
import 'package:petitparser_examples/lisp.dart' as lisp_example;
import 'package:petitparser_examples/math.dart' as math_example;
import 'package:petitparser_examples/prolog.dart' as prolog_example;
import 'package:petitparser_examples/uri.dart' as uri_example;

import 'util/runner.dart';

final bibtexParser = bibtex_example.BibTeXDefinition().build();
const bibtexInput = '@inproceedings{Reng10c,\n'
    '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
    '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
    '\tMonth = jun,\n'
    '\tYear = 2010,\n'
    '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}';

final lispParser = lisp_example.LispParserDefinition().build();
const lispInput = '(define (fib n)\n'
    '  (if (<= n 1)\n'
    '    1\n'
    '    (+ (fib (- n 1)) (fib (- n 2)))))';

final jsonParser = json_example.JsonDefinition().build();
const jsonInput =
    '{"type": "change", "eventPhase": 2, "bubbles": true, "cancelable": true, '
    '"timeStamp": 0, "CAPTURING_PHASE": 1, "AT_TARGET": 2, '
    '"BUBBLING_PHASE": 3, "isTrusted": true, "MOUSEDOWN": 1, "MOUSEUP": 2, '
    '"MOUSEOVER": 4, "MOUSEOUT": 8, "MOUSEMOVE": 16, "MOUSEDRAG": 32, '
    '"CLICK": 64, "DBLCLICK": 128, "KEYDOWN": 256, "KEYUP": 512, '
    '"KEYPRESS": 1024, "DRAGDROP": 2048, "FOCUS": 4096, "BLUR": 8192, '
    '"SELECT": 16384, "CHANGE": 32768, "RESET": 65536, "SUBMIT": 131072, '
    '"SCROLL": 262144, "LOAD": 524288, "UNLOAD": 1048576, '
    '"XFER_DONE": 2097152, "ABORT": 4194304, "ERROR": 8388608, '
    '"LOCATE": 16777216, "MOVE": 33554432, "RESIZE": 67108864, '
    '"FORWARD": 134217728, "HELP": 268435456, "BACK": 536870912, '
    '"TEXT": 1073741824, "ALT_MASK": 1, "CONTROL_MASK": 2, '
    '"SHIFT_MASK": 4, "META_MASK": 8}';

final prologParser = prolog_example.rulesParser;
const prologInput = 'foo(bar, zork) :- true.\n'
    'bok(X, Y) :- foo(X, Y), foo(Y, X).';

final mathParser = math_example.parser;
const mathInput = '1 + 2 - (3 * 4 / sqrt(5 ^ pi)) - e';

final uriParser = uri_example.uri;
const uriInput =
    'https://www.lukas-renggli.ch/blog/petitparser-1?_s=Q5vcT_xEIhxf2Z4Q&_k=4pr02qyT&_n&42';

void main() {
  runString('bibtex', bibtexParser, bibtexInput);
  runString('json', jsonParser, jsonInput);
  runString('lisp', lispParser, lispInput);
  runString('math', mathParser, mathInput);
  runString('prolog', prologParser, prologInput);
  runString('uri', uriParser, uriInput);
}

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart' as bibtex_example;
import 'package:petitparser_examples/json.dart' as json_example;
import 'package:petitparser_examples/lisp.dart' as lisp_example;
import 'package:petitparser_examples/math.dart' as math_example;
import 'package:petitparser_examples/prolog.dart' as prolog_example;
import 'package:petitparser_examples/tabular.dart' as csv_example;
import 'package:petitparser_examples/uri.dart' as uri_example;
import 'package:xml/src/xml_events/parser.dart' as xml_example;
import 'package:xml/xml.dart';

import '../utils/runner.dart';

final bibtexParser = bibtex_example.BibTeXDefinition().build();
const bibtexInput =
    '@inproceedings{Reng10c,\n'
    '\tTitle = "Practical Dynamic Grammars for Dynamic Languages",\n'
    '\tAuthor = {Lukas Renggli and St\\\'ephane Ducasse and Tudor G\\^irba and Oscar Nierstrasz},\n'
    '\tMonth = jun,\n'
    '\tYear = 2010,\n'
    '\tUrl = {http://scg.unibe.ch/archive/papers/Reng10cDynamicGrammars.pdf}}';

final csvParser = csv_example.TabularDefinition.csv().build();
const csvInput =
    'Los Angeles,34°03′N,118°15′W\n'
    'New York City,40°42′46″N,74°00′21″W\n'
    'Paris,48°51′24″N,2°21′03″E';

final tsvParser = csv_example.TabularDefinition.tsv().build();
const tsvInput =
    'Sepal length	Sepal width	Petal length	Petal width	Species\n'
    '5.1	3.5	1.4	0.2	I. setosa\n'
    '4.9	3.0	1.4	0.2	I. setosa\n'
    '4.7	3.2	1.3	0.2	I. setosa\n'
    '4.6	3.1	1.5	0.2	I. setosa\n'
    '5.0	3.6	1.4	0.2	I. setosa\n';

final lispParser = lisp_example.LispParserDefinition().build();
const lispInput =
    '(define (fib n)\n'
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
const prologInput =
    'foo(bar, zork) :- true.\n'
    'bok(X, Y) :- foo(X, Y), foo(Y, X).';

final mathParser = math_example.parser;
const mathInput = '1 + 2 - (3 * 4 / sqrt(5 ^ pi)) - e';

final uriParser = uri_example.uri;
const uriInput =
    'https://www.lukas-renggli.ch/blog/petitparser-1?_s=Q5vcT_xEIhxf2Z4Q&_k=4pr02qyT&_n&42';

final xmlParser = xml_example.XmlEventParser(
  defaultEntityMapping,
).build().star().end();
const xmlInput =
    '<?xml version="1.0"?>\n'
    '<!DOCTYPE name [ <!ELEMENT html (head, body)> ]>\n'
    '<ns:foo attr="not namespaced" n1:ans="namespaced 1" '
    '        n2:ans="namespace 2" >\n'
    '  Plain text contents!'
    '  <element/>\n'
    '  <ns:element/>\n'
    '  <!-- comment -->\n'
    '  <![CDATA[cdata]]>\n'
    '  <?processing instruction?>\n'
    '</ns:foo>';

void main() {
  runString('example - bibtex', bibtexParser, input: bibtexInput);
  runString('example - csv', csvParser, input: csvInput);
  runString('example - json', jsonParser, input: jsonInput);
  runString('example - lisp', lispParser, input: lispInput);
  runString('example - math', mathParser, input: mathInput);
  runString('example - prolog', prologParser, input: prologInput);
  runString('example - tsv', tsvParser, input: tsvInput);
  runString('example - uri', uriParser, input: uriInput);
  runString('example - xml', xmlParser, input: xmlInput);
}

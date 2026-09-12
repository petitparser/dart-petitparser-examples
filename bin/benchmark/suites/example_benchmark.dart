import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/bibtex.dart' as bibtex_example;
import 'package:petitparser_examples/dart.dart' as dart_example;
import 'package:petitparser_examples/json.dart' as json_example;
import 'package:petitparser_examples/lisp.dart' as lisp_example;
import 'package:petitparser_examples/math.dart' as math_example;
import 'package:petitparser_examples/pascal.dart' as pascal_example;
import 'package:petitparser_examples/prolog.dart' as prolog_example;
import 'package:petitparser_examples/smalltalk.dart' as smalltalk_example;
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
    'id,name,category,coordinates,notes,score,status\n'
    '1,"Doe, Jane",engineer,"37°46\'29.7""N, 122°25\'09.8""W",simple note,98.5,active\n'
    '2,"Smith, John ""The Expert""",manager,"40°42\'46""N, 74°00\'21""W","Multi-line\n'
    'bio with embedded\n'
    'newlines and ""quotes""",84.0,pending\n'
    '3,"O\'Connor, Tim",analyst,"48°51\'24""N, 2°21\'03""E",,92.25,active\n'
    '4,"Müller, Stefan",director,"52°31\'12""N, 13°24\'18""E","Comma, separated, words",78.0,inactive\n'
    '5,"Empty fields test",,,,-1.5e+2,unknown\n'
    '6,"Tanaka, 太郎",lead,"35°41\'22""N, 139°41\'30""E","Unicode and symbols: ©, §",99.9,active\n'
    '7,SingleWord,plain,0°N 0°E,"No quotes needed",0,verified\n'
    '8,EndRecord,final,"10°S, 20°W",last row,100,closed\n'
    '9,"Trailing, comma and empty",item,"",last note,42.0,';

final dartParser = dart_example.DartGrammarDefinition().build();
const dartInput =
    'typedef Handler<T> = Future<T> Function(int, [String?]);\n'
    'abstract final class Processor<T extends num> implements Comparable<Processor<T>> {\n'
    '  const Processor(this.id, {required this.tag, this.extra = const [1, 2.5]});\n'
    '  final (int, {String name}) id;\n'
    '  final String? tag;\n'
    '  final List<num> extra;\n'
    '  late final int count = extra.length;\n'
    '  @pragma(\'vm:prefer-inline\')\n'
    '  (int, double) compute(List<T?> values, [Map<String, dynamic>? options]) {\n'
    '    final [first, ..., last] = values;\n'
    '    final score = switch ((first, last)) { (int a, int b) when a > b => a * 2 + b, (null, _) => options?[\'def\'] ?? -1, _ => ~0 };\n'
    '    return (score, [for (final v in extra) if (v case double d when d > 1.0) d else 0.0].fold(0.0, (a, b) => a + b));\n'
    '  }\n'
    '}';

final tsvParser = csv_example.TabularDefinition.tsv().build();
const tsvInput =
    'id\tname\tdepartment\tpath\tnotes\trating\tstatus\n'
    '101\tAlice Smith\tEngineering\tC:\\\\Program Files\\\\App\tStandard record\t4.95\tactive\n'
    '102\tBob Jones\tResearch\t/usr/local/bin\tEmbedded\\ttab and\\nnewline\t3.80\tpending\n'
    '103\tCarol White\tDesign\tD:\\\\Assets\\\\Images\tSpecial chars: © & ™\t5.00\tactive\n'
    '104\tDavid Brown\tOperations\t/var/log/system\tEscaped \\\\ backslash\t2.15\tinactive\n'
    '105\tEva Green\tFinance\t/etc/config.json\t\t4.50\tactive\n'
    '106\tFrank Black\tSecurity\t/home/frank/.ssh\tScientific: 1.25e+3\t-0.50\tsuspended\n'
    '107\tGrace Hopper\tSystems\t/bin/sh\tPioneer \\"admiral\\"\t5.00\thonored\n'
    '108\tHeidi Miller\tLegal\t/share/docs\tEmpty dept next\t3.40\tactive\n'
    '109\tIvan Petrov\t\t/tmp/scratch\tNull department record\t1.00\treview\n'
    '110\tJudy Davis\tSupport\tC:\\\\Users\\\\Judy\tTrailing record\t4.75\tactive\n'
    '111\tKarl Marx\tEconomics\t/var/data/archive\tUnicode: ¢ £ ¥ €\t2.50\tretired';

final lispParser = lisp_example.LispParserDefinition().build();
const lispInput =
    '; Quicksort with higher-order functions and template expansion\n'
    '(define (filter pred seq)\n'
    '  (if (null? seq) \'() (if (pred (car seq)) (cons (car seq) (filter pred (cdr seq))) (filter pred (cdr seq)))))\n'
    '(define (quicksort items)\n'
    '  (if (or (null? items) (null? (cdr items))) items\n'
    '    (let ([pivot (car items)] [rest (cdr items)])\n'
    '      (append (quicksort (filter (lambda (x) (< x pivot)) rest))\n'
    '              (cons pivot (quicksort (filter (lambda (x) (>= x pivot)) rest)))))))\n'
    '; Quasiquoting with multiple bracket types, strings, numbers\n'
    '(define (wrap-expr name target)\n'
    '  `{ :tag "expression" :name ,(name) :value -1.25e+2\n'
    '     :body [lambda (x) `(apply ,(target) @(x))] })';

final jsonParser = json_example.JsonDefinition().build();
const jsonInput =
    '{\n'
    '  "name": "PetitParser JSON \\u00a9 \\u2603",\n'
    '  "meta": { "active": true, "deprecated": false, "payload": null },\n'
    '  "escapes": "\\"quotes\\", \\\\backslash\\\\, \\/slash\\/, \\b\\f\\n\\r\\t",\n'
    '  "integers": [0, 42, -999],\n'
    '  "floating": [3.14159265, -0.0012, 1e6, -2.5E-3, 6.022e+23],\n'
    '  "empty_containers": { "obj": {}, "arr": [] },\n'
    '  "nested_records": [\n'
    '    { "id": 1, "coordinates": [-122.4194, 37.7749], "valid": true },\n'
    '    { "id": 2, "coordinates": [0.0, 51.5074], "valid": false }\n'
    '  ],\n'
    '  "summary": "Full JSON spec test suite covering all tokens and types."\n'
    '}';

final prologParser = prolog_example.rulesParser;
const prologInput =
    '% Complex knowledge base: binary search tree and path reachability\n'
    '% Base graph facts and directed connectivity\n'
    'edge(a, b). edge(b, c). edge(c, d). edge(b, e). edge(e, d).\n'
    'connected(X, X).\n'
    'connected(X, Y) :- edge(X, Z), connected(Z, Y).\n'
    '% Binary search tree operations with nested functor structures\n'
    'bst_member(Key, tree(Key, _, _)).\n'
    'bst_member(Key, tree(Root, Left, _)) :-\n'
    '    less_than(Key, Root),\n'
    '    bst_member(Key, Left).\n'
    'bst_member(Key, tree(Root, _, Right)) :-\n'
    '    greater_than(Key, Root),\n'
    '    bst_member(Key, Right).\n'
    'bst_insert(Key, nil, tree(Key, nil, nil)).';

final mathParser = math_example.parser;
const mathInput =
    'atan2('
    '  max('
    '    sin(alpha * pi / 180.0) ^ 2 + cos(beta * pi / 180.0) ^ 2,'
    '    min('
    '      log(abs(x) + 1.0e-5) * sqrt(pow(y, 2) + pow(z, 2)),'
    '      exp(-1.5e-3 * gamma) / (1.0 + exp(-gamma))'
    '    )'
    '  ),'
    '  sqrt('
    '    abs('
    '      pow('
    '        (round(x * 100.0) / 100.0 - floor(y)) * ceil(z + 0.5),'
    '        3'
    '      )'
    '      - truncate(asin(min(1.0, max(-1.0, x / (y + 1.0e-8)))) * 180.0 / pi)'
    '    )'
    '    + 1.0'
    '  )'
    ') * ('
    '  -sign(x) * (2.0 ^ (3.0 ^ 2.0)) / (4.0 * atan(1.0))'
    '  + (+acos(-0.5)) * tan(pi / 6.0)'
    ') - ('
    '  (e ^ -(x ^ 2 + y ^ 2)) / (sqrt(2.0 * pi) * (1.0 + abs(sin(z))))'
    ')';

final pascalParser = pascal_example.PascalParserDefinition().build();
const pascalInput =
    'program ComplexDemo(input, output);\n'
    'label 99;\n'
    'const Max = 100; Factor = +2.5e-1;\n'
    'type Color = (Red, Green, Blue); CharSet = set of \'A\'..\'Z\';\n'
    'var i, sum: integer; c: Color; s: CharSet;\n'
    'function Calc(var x: integer; d: integer): integer;\n'
    'begin x := x + d; Calc := x end;\n'
    'begin\n'
    '  sum := 0; c := Green; s := [\'A\', \'C\'..\'Z\'];\n'
    '  for i := 1 to 10 do while sum < 5 do sum := Calc(sum, i);\n'
    '  case c of Red: sum := 1; Green, Blue: sum := 2 end;\n'
    '  repeat sum := sum - 1 until sum = 0;\n'
    '  99: if (\'A\' in s) and not false then writeln(\'Done: \', sum);\n'
    'end.';

final smalltalkParser = smalltalk_example.SmalltalkParserDefinition().build();
const smalltalkInput =
    'process: anItem context: aContext\n'
    '  <primitive: 42 error: #ec>\n'
    '  <custom: #(1 2 3)>\n'
    '  "Process the item with multiple Smalltalk constructs"\n'
    '  | result stream bytes count |\n'
    '  count := 0.\n'
    '  bytes := #[16rDE 16rAD 16rBE 16rEF].\n'
    '  stream := WriteStream on: (Array new: 10).\n'
    '  stream nextPut: \$A; nextPutAll: \'hello\'; nextPut: (1.5s2 negated).\n'
    '  result := anItem at: #key ifAbsent: [ :err | | fallback | fallback := { true. false. nil }. fallback ].\n'
    '  bytes do: [ :each | count := count + (each bitAnd: 16r0F) ].\n'
    '  count > 10 ifTrue: [ ^ stream contents ] ifFalse: [ ^ { result. #(1 \$x \'str\' (true)) } ]';

final uriParser = uri_example.uri;
const uriInput =
    'https://www.lukas-renggli.ch/blog/petitparser-1?_s=Q5vcT_xEIhxf2Z4Q&_k=4pr02qyT&_n&42';

final xmlParser = xml_example.XmlEventParser(defaultEntityMapping)
    .build()
    .star()
    .end();
const xmlInput =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<!DOCTYPE catalog [ <!ELEMENT catalog (item+)> <!ENTITY copy "©"> ]>\n'
    '<catalog xmlns="http://example.org/default" xmlns:meta="http://example.org/meta" version="2.0">\n'
    '  <!-- Multi-element catalog with namespaces, entities, and CDATA -->\n'
    '  <?catalog-pi directive="optimize" level="maximum"?>\n'
    '  <meta:item id="item-42" category=\'parser-test\' meta:active="true">\n'
    '    <title>Parsing &amp; Analysis &lt;PetitParser&gt; &#x2603;</title>\n'
    '    <description>Quoted: &quot;XML 1.0&quot; and &apos;entities&apos;</description>\n'
    '    <payload format="raw"><![CDATA[<data><unparsed a="1" & b="2"/></data>]]></payload>\n'
    '    <meta:checksum algorithm="sha256" verified="true"/>\n'
    '    <meta:empty-tag selfClosed="yes" />\n'
    '  </meta:item>\n'
    '</catalog>';

void main() {
  runString('example - bibtex', bibtexParser, input: bibtexInput);
  runString('example - csv', csvParser, input: csvInput);
  runString('example - dart', dartParser, input: dartInput);
  runString('example - json', jsonParser, input: jsonInput);
  runString('example - lisp', lispParser, input: lispInput);
  runString('example - math', mathParser, input: mathInput);
  runString('example - pascal', pascalParser, input: pascalInput);
  runString('example - prolog', prologParser, input: prologInput);
  runString('example - smalltalk', smalltalkParser, input: smalltalkInput);
  runString('example - tsv', tsvParser, input: tsvInput);
  runString('example - uri', uriParser, input: uriInput);
  runString('example - xml', xmlParser, input: xmlInput);
}

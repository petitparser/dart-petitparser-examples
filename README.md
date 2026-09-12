# PetitParser Examples

[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)
[![Build Status](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml)
[![Code Coverage](https://codecov.io/gh/petitparser/dart-petitparser-examples/branch/main/graph/badge.svg?token=NVECPJQD87)](https://codecov.io/gh/petitparser/dart-petitparser-examples)
[![GitHub Issues](https://img.shields.io/github/issues/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/issues)
[![GitHub Forks](https://img.shields.io/github/forks/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/network)
[![GitHub Stars](https://img.shields.io/github/stars/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/stargazers)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/petitparser/dart-petitparser-examples/main/LICENSE)

A collection of real-world grammars, evaluators, interactive tools, and performance benchmarks illustrating [PetitParser for Dart](https://pub.dev/packages/petitparser).

This package showcases how to model domain-specific notations, standard interchange formats, and full programming languages directly in plain Dart.

## Highlights

- **Grammar Catalog**: Practical parser definitions ranging from small data formats like JSON, BibTeX, CSV, and URIs to full programming languages such as Pascal, Smalltalk, and Dart.
- **Interpreters and Evaluators**: Working interpreters for Prolog with resolution search and Lisp with lexical scoping and native functions.
- **Automata Engine**: Regular expression parser compiling abstract syntax trees directly into non-deterministic finite automata for pattern matching.
- **Interactive Tools**: Ready to use console command line REPLs and browser applications.
- **Performance Benchmarks**: Microbenchmarks measuring standard parsing, fast non-capturing parsing, and comparisons with native platform parsers.

## Installation

Add PetitParser and the examples package to your project dependencies:

```bash
dart pub add petitparser petitparser_examples
```

## Grammars

### BibTeX

Parses [BibTeX](https://en.wikipedia.org/wiki/BibTeX) files into strongly typed entry objects with citation keys and key-value fields.

```dart
import 'package:petitparser_examples/bibtex.dart';

void main() {
  final parser = BibTeXDefinition().build();
  final result = parser.parse(r'''
@inproceedings{Reng10c,
  title = "Practical Dynamic Grammars for Dynamic Languages",
  author = "Lukas Renggli and Stéphane Ducasse and Tudor Gîrba and Oscar Nierstrasz",
  year = 2010
}''');

  final entry = result.value.single;
  print(entry.key);    // Reng10c
  print(entry.type);   // inproceedings
  print(entry.fields); // {title: "Practical Dynamic Grammars for Dynamic Languages", ...}
}
```

Try the interactive [BibTeX Browser & Search](web/bibtex/bibtex.html) to download, search, filter, and export citations from real-world `.bib` files directly in the browser.

### Dart

A comprehensive implementation of the Dart 3 grammar and parser producing strongly-typed Abstract Syntax Trees (ASTs). Supports records, patterns, switch expressions, class modifiers, enhanced enums, extension types, and null safety.

```dart
import 'package:petitparser_examples/dart.dart';

void main() {
  final unit = parseDart('void main() => print("Hello, Dart!");');
  print(unit.declarations.first); // FunctionDeclarationNode(main)
}
```

### JSON

A complete implementation of the [JSON specification](https://json.org/). Transforms JSON text into native Dart maps, lists, strings, numbers, booleans, and null values.

```dart
import 'package:petitparser_examples/json.dart';

void main() {
  final data = parseJson(
    '{"name": "PetitParser", "tags": ["dart", "parser"], "active": true}',
  );
  print(data); // {name: PetitParser, tags: [dart, parser], active: true}
}
```

### Lisp

A Lisp grammar and tree-walking evaluator supporting symbols, numbers, strings, quoted forms, lexical closures, and native functions.

```dart
import 'package:petitparser_examples/lisp.dart';

void main() {
  final environment = NativeEnvironment();
  final result = evalString(lispParser, environment, '(+ 1 (* 2 3))');
  print(result); // 7
}
```

Run the interactive console REPL:

```bash
dart run bin/lisp/lisp.dart
```

### Math

A mathematical expression evaluator built using `ExpressionBuilder`. Handles operator precedence, associativity, parentheses, variables, and standard mathematical functions.

```dart
import 'package:petitparser_examples/math.dart';

void main() {
  final expression = parser.parse('sqrt(16) + 2 ^ 3').value;
  print(expression.eval({})); // 12.0
}
```

### Pascal

A grammar for Pascal following the 1978 Apple Pascal Standard.

```dart
import 'package:petitparser_examples/pascal.dart';

void main() {
  final parser = PascalParserDefinition().build();
  final result = parser.parse('''
program HelloWorld;
begin
  writeln('Hello, World!');
end.
''');
  print(result is Success); // true
}
```

### Prolog

A Prolog grammar and inference engine supporting facts, rules, unification, and variable substitution.

```dart
import 'package:petitparser_examples/prolog.dart';

void main() {
  final db = Database.parse('''
parent(bob, ann).
parent(bob, pat).
sibling(X, Y) :- parent(Z, X), parent(Z, Y).
''');
  final query = Term.parse('sibling(ann, S)');
  for (final solution in db.query(query)) {
    print(solution); // sibling(ann, ann), sibling(ann, pat)
  }
}
```

Run the interactive console REPL:

```bash
dart run bin/prolog/prolog.dart
```

### Regular Expressions

A parser and compiler for regular expressions. Compiles parsed patterns into non-deterministic finite automata supporting concatenation, alternation, repetition, and character classes.

```dart
import 'package:petitparser_examples/regexp.dart';

void main() {
  final nfa = Nfa.fromString(r'a*b+');
  print(nfa.matchAsPrefix('aaab') != null); // true
  print(nfa.matchAsPrefix('b') != null);    // true
  print(nfa.matchAsPrefix('a') != null);    // false
}
```

### Smalltalk

A complete Smalltalk grammar exported from the original PetitParser implementation in Smalltalk, foundational to the [Helvetia Language Workbench](https://www.lukas-renggli.ch/smalltalk/helvetia).

```dart
import 'package:petitparser_examples/smalltalk.dart';

void main() {
  final parser = SmalltalkParserDefinition().build();
  final result = parser.parse('''
example
  1 to: 10 do: [ :i | Transcript show: i printString ]
''');
  print(result is Success); // true
}
```

### Tabular (CSV and TSV)

A configurable parser definition for delimited text formats with support for custom delimiters, quotation characters, and escaping rules.

```dart
import 'package:petitparser_examples/tabular.dart';

void main() {
  final csv = TabularDefinition.csv().build();
  final result = csv.parse(
    'language,paradigm\nDart,multi-paradigm\nSmalltalk,object-oriented',
  );
  print(result.value);
  // [[language, paradigm], [Dart, multi-paradigm], [Smalltalk, object-oriented]]
}
```

### URI

Decomposes RFC-3986 URI strings into structured components including scheme, authority, user info, host, port, path, query parameters, and fragments.

```dart
import 'package:petitparser_examples/uri.dart';

void main() {
  final result = uri.parse(
    'https://user:pass@example.com:8080/path/to/page?lang=en#heading',
  );
  print(result.value.scheme);   // https
  print(result.value.hostname); // example.com
  print(result.value.port);     // 8080
  print(result.value.path);     // /path/to/page
}
```

### XML

The `web/xml` directory demonstrates parsing XML documents into event streams, constructing DOM trees, pretty printing, and evaluating XPath expressions using the [xml](https://pub.dev/packages/xml) package.

## Web Applications

Interactive browser playgrounds and visualization tools are located in the `web/` directory.

To run the web applications locally:

```bash
dart pub global activate webdev
webdev serve --release
```

Open <http://localhost:8080/> to browse the interactive playgrounds for BibTeX search & browsing, Dart grammar visualization, JSON, Lisp, Math evaluation, Math plotting, Prolog, Regular Expressions, Smalltalk, Tabular data, URI parsing, and XML.

## Benchmarks

Run performance benchmarks directly with the Dart CLI:

```bash
dart run --no-enable-asserts bin/benchmark/benchmark.dart
```

Each suite measures standard parsing throughput, fast non-capturing parse performance, and compares results against native implementations where available.

To run correctness verification without running the performance suite:

```bash
dart run bin/benchmark/benchmark.dart --no-benchmark
```

## Resources

- [PetitParser on pub.dev](https://pub.dev/packages/petitparser)
- [PetitParser GitHub Repository](https://github.com/petitparser/dart-petitparser)
- [API Documentation](https://pub.dev/documentation/petitparser_examples/latest/)
- [Project Website](https://petitparser.github.io/)

PetitParser Examples
====================

[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)
[![Build Status](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml)
[![Code Coverage](https://codecov.io/gh/petitparser/dart-petitparser-examples/branch/main/graph/badge.svg?token=TDwmzZtPdj)](https://codecov.io/gh/petitparser/dart-petitparser-examples)
[![GitHub Issues](https://img.shields.io/github/issues/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/issues)
[![GitHub Forks](https://img.shields.io/github/forks/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/network)
[![GitHub Stars](https://img.shields.io/github/stars/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/stargazers)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/petitparser/dart-petitparser-examples/main/LICENSE)

This package contains examples to illustrate the use of [PetitParser](https://github.com/petitparser/dart-petitparser). A tutorial and full documentation is contained in the [package description](https://pub.dev/packages/petitparser) and [API documentation](https://pub.dev/documentation/petitparser/latest/). [petitparser.github.io](https://petitparser.github.io/) contains more information about PetitParser, running examples in the browser, and links to ports to other languages.

## Examples

### BibTeX

A simple parser that reads a [BibTeX](https://en.wikipedia.org/wiki/BibTeX) file into a list of BibTeX entries with a list of fields.

### Dart

This example contains the grammar of the Dart programming language. This is based on an early Dart 1.0 grammar specification and unfortunately does not support all valid Dart programs yet.

### JSON

This example contains a complete implementation of [JSON](https://json.org/). It is a simple grammar that can be used for benchmarking with the native implementation.

### Lisp

This example contains a simple grammar and evaluator for LISP. The code is reasonably complete to run and evaluate complex programs. Binaries for a Read–Eval–Print Loop (REPL) are provided for the console and the web browser.

```bash
dart run bin/lisp/lisp.dart
```

### Math

This example contains a simple evaluator for mathematical expressions, it builds a parse-tree that can then be used to print or evaluate expressions.

### Prolog

This example contains a simple grammar and evaluator for Prolog programs. The code is reasonably complete to run and evaluate basic prolog programs. Binaries for a Read–Eval–Print Loop (REPL) are provided for the console and the web browser.

```bash
dart run bin/prolog/prolog.dart
```

### Smalltalk

This example contains a complete implementation of the Smalltalk grammar. This is a verbatim export of a grammar that was originally developed for the PetitParser infrastructure in Smalltalk and that was the base of the [Helvetia Language Workbench](https://www.lukas-renggli.ch/smalltalk/helvetia).

### URI

This is a simple grammar that takes an URL string and decomposes it into scheme, authority (including username, password, hostname, and port), path, query (including parameters as key-value pairs), and fragment.

### XML

This examples parses XML files to events, creates and pretty-prints a DOM tree, and evaluates XPath expressions. Depends on [xml](https://github.com/renggli/dart-xml) package.

## Web

To run the web examples execute the following commands from the command line and navigate to http://localhost:8080/:

```bash
dart pub global activate webdev
webdev serve --release
```

## Benchmarks

To run the benchmarks execute the following command from the command line:

```bash
ls -1 bin/benchmark/*.dart | xargs -n 1 dart run --no-enable-asserts
```
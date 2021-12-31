PetitParser Examples
====================

[![Pub Package](https://img.shields.io/pub/v/petitparser_examples.svg)](https://pub.dev/packages/petitparser_examples)
[![Build Status](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml/badge.svg?branch=main)](https://github.com/petitparser/dart-petitparser-examples/actions/workflows/dart.yml)
[![GitHub Issues](https://img.shields.io/github/issues/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/issues)
[![GitHub Forks](https://img.shields.io/github/forks/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/network)
[![GitHub Stars](https://img.shields.io/github/stars/petitparser/dart-petitparser-examples.svg)](https://github.com/petitparser/dart-petitparser-examples/stargazers)
[![GitHub License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/petitparser/dart-petitparser-examples/main/LICENSE)

This package contains examples to illustrate the use of [PetitParser](https://github.com/petitparser/dart-petitparser). A tutorial and full documentation is contained in the [package description](https://pub.dev/packages/petitparser) and [API documentation](https://pub.dev/documentation/petitparser/latest/). [petitparser.github.io](https://petitparser.github.io/) contains more information about PetitParser, running examples in the browser, and links to ports to other languages.

To run the web examples execute the following commands from the command line and navigate to http://localhost:8080/:

```bash
dart pub global activate webdev
webdev serve --release
```

### Dart

This example contains the grammar of the Dart programming language. This is based on an early Dart 1.0 grammar specification and unfortunately does not support all valid Dart programs yet.

### JSON

This example contains a complete implementation of [JSON](https://json.org/). It is a simple grammar that can be used for benchmarking with the native implementation.

### Lisp

This example contains a simple grammar and evaluator for LISP. The code is reasonably complete to run and evaluate complex programs. Binaries for a Read–Eval–Print Loop (REPL) are provided for the console and the web browser.

### Prolog

This example contains a simple grammar and evaluator for Prolog programs. The code is reasonably complete to run and evaluate basic prolog programs. Binaries for a Read–Eval–Print Loop (REPL) are provided for the console and the web browser.

### Smalltalk

This example contains a complete implementation of the Smalltalk grammar. This is a verbatim export of a grammar that was originally developed for the PetitParser infrastructure in Smalltalk and that was the base of the [Helvetia Language Workbench](https://www.lukas-renggli.ch/smalltalk/helvetia).

# Changelog

## 7.1.0 (Unpublished)

- Update to Dart 3.13 and PetitParser 7.1.
- **Markdown Grammar & Tools**: Added CommonMark 0.31.2 grammar with GitHub Flavored Markdown (GFM) extensions, strongly typed AST parser, HTML renderer, syntax highlighter, and interactive web playground.
- **Python Grammar & Tokenizer**: Added modern Python 3.12+ grammar, indentation-aware lexical tokenizer, strongly typed AST model, and web visualizer supporting match/case pattern matching, PEP 695 type parameter syntax, and async constructs.
- **Public API Exports**: Completed public library exports for `quote.dart` in `lib/lisp.dart`, `pattern.dart` in `lib/regexp.dart`, and `authority.dart` and `query.dart` in `lib/uri.dart`.
- **Code Cleanup**: Removed dead code (`lib/src/smalltalk/objects.dart`) and eliminated misplaced documentation files (`lib/src/dart/AGENTS.md`, `lib/src/python/AGENTS.md`).
- **Effective Dart Modernizations**: Standardized JSON model typing with `typedef Json`, encapsulated internal helpers with `_` prefix (`_checkValue`, `_throwUnknown`, `_argumentEquality`, `_newBindings`, `_mergeBindings`), replaced deprecated `ArgumentError.notNull`, and converted non-null assertions to safe idioms.
- **Hermetic Offline Test Suite**: Replaced live network HTTP requests in `test/bibtex_test.dart` with bundled synthetic test fixtures for deterministic offline execution.
- **Comprehensive Test Expansion**: Added extensive unit test suites covering AST traversal, visitors, error-handling branches, negative inputs (`isFailure`), and CLI entry points (`bin/lisp`, `bin/prolog`, `bin/benchmark`).
- **Web Applications**: Fixed DOM typing bug in `web/xml/xml.dart`, resolved broken source and documentation links across web demos, and verified clean JavaScript compilation for all 16 web applications.
- **Package Metadata & Dependencies**: Bumped version to `7.1.0` and moved `package:http` from `dependencies` to `dev_dependencies`.
- **Documentation & Parity**: Updated `README.md` and `example/README.md` with Markdown and Python grammar catalogs, code examples, web demo links, and verified README unit test coverage.
- Updated URI parser to return strongly typed records with auto-inferred fields.
- Modernized example grammars to use Dart 3 pattern matching, switch expressions, and modern combinators.
- BibTeX: added web demo downloading public `.bib` databases (like SCG bibliography with 9,600+ entries) with instant searching, filtering, and citation export.
- Dart grammar: updated to full Dart 3 syntax (records, patterns, switch expressions, enhanced enums, extension types, class modifiers) with strongly typed AST output.
- Dart grammar: added web visualizer playground with interactive AST inspection and performance measurements.
- RegExp: added web demo, support for `^` and `$` anchors, arbitrary repetition ranges, character classes, and NFA execution optimizations.
- Tabular: generalized to `TabularDefinition` with CSV and TSV support, and added web demo.
- XML/XPath: showcased latest XPath features in web demo.

## 7.0.0

- Update to Dart 3.8 and PetitParser 7.0.
- Added Pascal, CSV example grammars.
- Numerous fixes and improvements.
- Better testing of grammars.

## 6.0.0

- Update to Dart 3.0 and PetitParser 6.0.
- Cleanup usage of deprecated code.
- Better test coverage.

## 5.4.0

- Upgrade to Dart 2.19 and PetitParser 5.4.
- Add BibTeX and RegExp examples.
- Add XML, XPath, and BibTeX demos.

## 5.1.0

- Dart 2.18 requirement.
- Cleanup the JSON and URL parsers to be fully typed.

## 5.0.0

- Dart 2.16 requirement.
- Cleaned up dynamic typing.
- Updates to latest version of PetitParser.
- Added a mathematical expression example.

## 4.4.0

- Initial version extracted from <https://github.com/petitparser/dart-petitparser>.

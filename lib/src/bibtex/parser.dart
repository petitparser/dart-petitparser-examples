import 'dart:async';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser/stream.dart';

import 'definition.dart';
import 'entry.dart';

final _definition = BibTeXDefinition();

/// Compiled parser for a single [BibTeXEntry].
///
/// For example:
///
/// ```dart
/// final result = entryParser.parse('@article{k, title = "A"}');
/// print(result.value.key); // 'k'
/// ```
final Parser<BibTeXEntry> entryParser = _definition.buildFrom(
  _definition.entry(),
);

final _delimiter = char('@');

/// Returns a lazily evaluated [Iterable] of [BibTeXEntry] items from [input].
///
/// For example:
///
/// ```dart
/// for (final entry in parseEntries(content)) {
///   print(entry.key);
/// }
/// ```
Iterable<BibTeXEntry> parseEntries(String input) =>
    entryParser.parseIterable(input, delimiter: _delimiter);

/// Parses [input] into a progressive asynchronous [Stream] of [BibTeXEntry]
/// items.
///
/// For example:
///
/// ```dart
/// await for (final entry in parseStream(content)) {
///   print(entry.key);
/// }
/// ```
Stream<BibTeXEntry> parseStream(String input) =>
    entryParser.parseStream(input, delimiter: _delimiter);

/// Parses chunks of text from [stream] into a progressive [Stream] of
/// [BibTeXEntry] items.
///
/// Incomplete entries split across chunk boundaries are buffered until
/// sufficient text arrives.
///
/// For example:
///
/// ```dart
/// final chunks = Stream.fromIterable(['@article{k, ', 'title = "V"}\n']);
/// await for (final entry in parseStreamChunks(chunks)) {
///   print(entry.key);
/// }
/// ```
Stream<BibTeXEntry> parseStreamChunks(Stream<String> stream) =>
    entryParser.parseStreamChunks(stream, delimiter: _delimiter);

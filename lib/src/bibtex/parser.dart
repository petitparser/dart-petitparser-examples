import 'dart:async';

import 'package:petitparser/petitparser.dart';

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

/// Returns a lazily evaluated [Iterable] of [BibTeXEntry] items from [input].
///
/// For example:
///
/// ```dart
/// for (final entry in parseEntries(content)) {
///   print(entry.key);
/// }
/// ```
Iterable<BibTeXEntry> parseEntries(String input) sync* {
  var pos = 0;
  while (pos < input.length) {
    final atIndex = input.indexOf('@', pos);
    if (atIndex == -1) break;
    final result = entryParser.parseOn(Context(input, atIndex));
    if (result is Success) {
      yield result.value;
      pos = result.position;
    } else {
      pos = atIndex + 1;
    }
  }
}

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
Stream<BibTeXEntry> parseStream(String input) async* {
  var pos = 0;
  while (pos < input.length) {
    final atIndex = input.indexOf('@', pos);
    if (atIndex == -1) break;
    final result = entryParser.parseOn(Context(input, atIndex));
    if (result is Success) {
      yield result.value;
      pos = result.position;
    } else {
      pos = atIndex + 1;
    }
  }
}

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
Stream<BibTeXEntry> parseStreamChunks(Stream<String> stream) async* {
  var buffer = '';
  await for (final chunk in stream) {
    buffer += chunk;
    var pos = 0;
    while (pos < buffer.length) {
      final atIndex = buffer.indexOf('@', pos);
      if (atIndex == -1) {
        buffer = '';
        pos = 0;
        break;
      }
      final result = entryParser.parseOn(Context(buffer, atIndex));
      if (result is Success) {
        yield result.value;
        pos = result.position;
      } else {
        final nextAt = buffer.indexOf('@', atIndex + 1);
        if (nextAt != -1 && result.position <= nextAt) {
          pos = atIndex + 1;
        } else {
          buffer = buffer.substring(atIndex);
          pos = 0;
          break;
        }
      }
    }
    if (pos > 0) {
      buffer = buffer.substring(pos);
    }
  }
  if (buffer.isNotEmpty) {
    var pos = 0;
    while (pos < buffer.length) {
      final atIndex = buffer.indexOf('@', pos);
      if (atIndex == -1) break;
      final result = entryParser.parseOn(Context(buffer, atIndex));
      if (result is Success) {
        yield result.value;
        pos = result.position;
      } else {
        pos = atIndex + 1;
      }
    }
  }
}

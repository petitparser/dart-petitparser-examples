import 'dart:io';

import 'package:collection/collection.dart';
import 'package:petitparser/petitparser.dart';

import 'benchmark.dart';

const Equality equality = ListEquality();

void compare(String regExp, Parser parser, String input) {
  final nativePattern = RegExp(regExp);
  final nativeResult = nativePattern
      .allMatches(input)
      .map((matcher) => matcher.group(0))
      .toList();

  final parserPattern = parser.toPattern();
  final parserResult = parserPattern
      .allMatches(input)
      .map((matcher) => matcher.group(0))
      .toList();

  if (nativeResult.isEmpty ||
      parserResult.isEmpty ||
      !equality.equals(nativeResult, parserResult)) {
    stdout.writeln('$regExp\tERROR');
    stdout.writeln(' - Native: $nativeResult');
    stdout.writeln(' - Parser: $parserResult');
    return;
  }

  final nativeTime = benchmark(() => nativePattern
      .allMatches(input)
      .map((matcher) => matcher.group(0))
      .toList());
  final parserTime = benchmark(() => parserPattern
      .allMatches(input)
      .map((matcher) => matcher.group(0))
      .toList());
  stdout.writeln('$regExp\t'
      '${nativeTime.toStringAsFixed(3)}\t'
      '${parserTime.toStringAsFixed(3)}\t'
      '${percentChange(nativeTime, parserTime).round()}%');
}

void main() {
  stdout.writeln('Expression\tNative\tParser\tChange');
  compare(r'[0-9]', digit(),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'[^0-9]', seq2(digit().not(), any()),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'[0-9]+', digit().plus(),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'[0-9]*!', seq2(digit().star(), char('!')),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'![0-9]*', seq2(char('!'), digit().star()),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(
      r'#([a-f0-9]{6}|[a-f0-9]{3})',
      seq3(
          char('#'),
          pattern('a-f0-9').repeat(3),
          pattern('a-f0-9').repeat(3).optional(),
      ),
      '#419527 #0839c4 #a95ba4 #da3e9e #15b331 #cafe00 #a7f #20c #46f #bb5');
  compare(
      r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',
      digit().repeat(1, 3).timesSeparated(char('.'), 4),
      '127.0.0.1, 73.60.124.136, 192.88.99.12, 203.0.113.0, 10.1.2.3, 0.0.0.0');
  compare(
      r'[a-z]+@[a-z]+\.[a-z]{2,3}',
      seq5(
        letter().plus(),
        char('@'),
        letter().plus(),
        char('.'),
        letter().repeat(2, 3),
      ),
      'a@b.c, de@fg.hi, jkl@mno.pqr, stuv@wxyz.abcd, efghi@jklmn.opqrs');
  compare(
      r'[+-]?\d+(\.\d+)?([eE][+-]?\d+)?',
      seq4(
        pattern('+-').optional(),
        digit().plus(),
        seq2(char('.'), digit().plus()).optional(),
        seq3(pattern('eE'), pattern('+-').optional(), digit().plus())
            .optional(),
      ),
      '1, -2, 3.4, -5.6, 7e8, 9E0, 0e+1, 2E-3, -4.567e-890');
  compare(r'\n|\r\n?', newline(),
      '1\n12\n123\n1234\n12345\n123456\n1234567\n12345678\r\n123456789\r');
}

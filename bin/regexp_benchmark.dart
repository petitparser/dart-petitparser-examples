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

  if (!equality.equals(nativeResult, parserResult)) {
    stdout.writeln('$regExp\tERROR');
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
  compare(r'[^0-9]', digit().not() & any(),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'[0-9]+', digit().plus(),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'[0-9]*!', digit().star() & char('!'),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(r'![0-9]*', char('!') & digit().star(),
      '!1!12!123!1234!12345!123456!1234567!12345678!123456789!');
  compare(
      r'[a-z]+@[a-z]+\.[a-z]{2,3}',
      letter().plus() &
          char('@') &
          letter().plus() &
          char('.') &
          letter().repeat(2, 3),
      'a@b.c, de@fg.hi, jkl@mno.pqr, stuv@wxyz.abcd, efghi@jklmn.opqrs');
  compare(
      r'[+-]?\d+(\.\d+)?([eE][+-]?\d+)?',
      pattern('+-').optional() &
          digit().plus() &
          (char('.') & digit().plus()).optional() &
          (pattern('eE') & pattern('+-').optional() & digit().plus())
              .optional(),
      '1, -2, 3.4, -5.6, 7e8, 9E0, 0e+1, 2E-3, -4.567e-890');
  compare(r'\n|\r\n?', Token.newlineParser(),
      '1\n12\n123\n1234\n12345\n123456\n1234567\n12345678\r\n123456789\r');
}

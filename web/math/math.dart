import 'dart:html';
import 'dart:math';

import 'package:petitparser/petitparser.dart';

final input = querySelector('#input')! as TextInputElement;
final output = querySelector('#output')! as ParagraphElement;

final evaluator = buildEvaluator();

Parser<num> buildEvaluator() {
  final builder = ExpressionBuilder<num>();
  builder.group()
    ..primitive((pattern('+-').optional() &
            digit().plus() &
            (char('.') & digit().plus()).optional() &
            (pattern('eE') & pattern('+-').optional() & digit().plus())
                .optional())
        .flatten('number expected')
        .trim()
        .map(num.parse))
    ..wrapper(
        char('(').trim(), char(')').trim(), (left, value, right) => value);
  builder.group().prefix(char('-').trim(), (op, a) => -a);
  builder.group().right(char('^').trim(), (a, op, b) => pow(a, b));
  builder.group()
    ..left(char('*').trim(), (a, op, b) => a * b)
    ..left(char('/').trim(), (a, op, b) => a / b);
  builder.group()
    ..left(char('+').trim(), (a, op, b) => a + b)
    ..left(char('-').trim(), (a, op, b) => a - b);
  return builder.build().end();
}

void update() {
  try {
    final result = evaluator.parse(input.value ?? '').value;
    output.text = ' = $result';
    output.classes.clear();
  } on Object catch (exception) {
    output.text = exception.toString();
    output.classes.add('error');
  }
}

void main() {
  input.onInput.listen((event) => update());
  update();
}

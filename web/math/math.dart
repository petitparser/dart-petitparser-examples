import 'dart:html';

import 'package:petitparser_examples/math.dart';

final input = querySelector('#input')! as TextInputElement;
final result = querySelector('#result')! as ParagraphElement;
final tree = querySelector('#tree')! as ParagraphElement;

void update() {
  tree.text = '';
  try {
    final expr = parser.parse(input.value ?? '0').value;
    tree.innerHtml = inspect(expr);
    result.text = ' = ${expr({})}';
    result.classes.clear();
  } on Object catch (exception) {
    result.text = exception.toString();
    result.classes.add('error');
  }
}

String inspect(Expression expr, [String indent = '']) {
  final result = StringBuffer('$indent$expr<br>');
  if (expr is Unary) {
    result.write(inspect(expr.value, '&nbsp;&nbsp;$indent'));
  } else if (expr is Binary) {
    result.write(inspect(expr.left, '&nbsp;&nbsp;$indent'));
    result.write(inspect(expr.right, '&nbsp;&nbsp;$indent'));
  }
  return result.toString();
}

void main() {
  input.onInput.listen((event) => update());
  update();
}

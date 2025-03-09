import 'dart:js_interop';

import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final result = document.querySelector('#result') as HTMLElement;
final tree = document.querySelector('#tree') as HTMLElement;

void update() {
  tree.textContent = '';
  try {
    final expr = parser.parse(input.value).value;
    tree.innerHTML = inspect(expr).toJS;
    result.textContent = ' = ${expr.eval({})}';
    result.classList.value = '';
  } on Object catch (exception) {
    result.textContent = exception.toString();
    result.classList.add('error');
  }
  window.location.hash = Uri.encodeComponent(input.value);
}

String inspect(Expression expr, [String indent = '']) {
  final result = StringBuffer('$indent$expr<br>');
  if (expr is Application) {
    for (final argument in expr.arguments) {
      result.write(inspect(argument, '&nbsp;&nbsp;$indent'));
    }
  }
  return result.toString();
}

void main() {
  if (window.location.hash.startsWith('#')) {
    input.value = Uri.decodeComponent(window.location.hash.substring(1));
  }
  update();
  input.onInput.listen((event) => update());
}

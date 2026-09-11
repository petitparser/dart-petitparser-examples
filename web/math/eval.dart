import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/math.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final result = document.querySelector('#result') as HTMLElement;
final tree = document.querySelector('#tree') as HTMLElement;

void update() {
  tree.textContent = '';
  final parseResult = parser.parse(input.value);
  if (parseResult is Failure) {
    result.textContent =
        '${parseResult.message} at ${parseResult.toPositionString()}';
    result.className = 'error';
    window.location.hash = Uri.encodeComponent(input.value);
    return;
  }
  try {
    final expr = parseResult.value;
    tree.innerHTML = inspect(expr).toJS;
    result.textContent = ' = ${expr.eval({})}';
    result.className = '';
  } on Object catch (exception) {
    result.textContent = exception.toString();
    result.className = 'error';
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

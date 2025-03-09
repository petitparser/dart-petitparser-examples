import 'dart:js_interop';

import 'package:petitparser_examples/lisp.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final output = document.querySelector('#output') as HTMLElement;
final console = document.querySelector('#console') as HTMLElement;
final environment = document.querySelector('#environment') as HTMLElement;
final evaluate = document.querySelector('#evaluate') as HTMLButtonElement;

final root = NativeEnvironment();
final standard = StandardEnvironment(root);
final user = standard.create();

void main() {
  printer = (object) {
    console.append(document.createTextNode(object.toString()));
    console.append(document.createElement('br'));
  };
  evaluate.onClick.listen((event) {
    output.textContent = 'Evaluating...';
    output.classList.value = '';
    console.textContent = '';
    try {
      final result = evalString(lispParser, user, input.value);
      output.textContent = result.toString();
    } on Object catch (exception) {
      output.textContent = exception.toString();
      output.classList.add('error');
    }
    inspect(environment, user);
  });
  inspect(environment, user);
}

void inspect(Element element, Environment? environment) {
  final buffer = StringBuffer();
  while (environment != null) {
    if (environment.keys.isNotEmpty) {
      buffer.write('<ul>');
      for (final symbol in environment.keys) {
        var object = environment[symbol];
        if (object is Function) {
          object = '($symbol ...)';
        }
        buffer.write('<li><b>$symbol</b>: $object</li>');
      }
      buffer.write('</ul>');
      buffer.write('<hr/>');
    }
    environment = environment.owner;
  }
  element.innerHTML = buffer.toString().toJS;
}

import 'dart:js_interop';

import 'package:petitparser/core.dart';
import 'package:petitparser_examples/lisp.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final input = document.querySelector('#input') as HTMLTextAreaElement;
final output = document.querySelector('#output') as HTMLElement;
final console = document.querySelector('#console') as HTMLElement;
final environment = document.querySelector('#environment') as HTMLElement;
final evaluate = document.querySelector('#evaluate') as HTMLButtonElement;

final root = NativeEnvironment();
final standard = StandardEnvironment(root);
final user = standard.create();

const presets = {
  'fib': '''(define (fib n)
  (if (<= n 1)
    1
    (+ (fib (- n 1)) (fib (- n 2)))))
(fib 10)''',
  'counter': '''(define (counter start)
  (let ((count start))
    (lambda ()
      (set! count (+ count 1)))))

(define c (counter 10))
(print "First: " (c))
(print "Second: " (c))
(print "Third: " (c))
(c)''',
  'map': '''(define (square x) (* x x))
(map '(1 2 3 4 5 6) square)''',
  'while': '''(define x 5)
(while (> x 0)
  (print "Countdown: " x)
  (set! x (- x 1)))
x''',
};

void main() {
  initShared();

  final presetFib = document.querySelector('#preset-fib') as HTMLButtonElement?;
  final presetCounter =
      document.querySelector('#preset-counter') as HTMLButtonElement?;
  final presetMap = document.querySelector('#preset-map') as HTMLButtonElement?;
  final presetWhile =
      document.querySelector('#preset-while') as HTMLButtonElement?;

  void loadPreset(String key) {
    final code = presets[key];
    if (code != null) {
      input.value = code;
      evaluate.click();
    }
  }

  presetFib?.onClick.listen((_) => loadPreset('fib'));
  presetCounter?.onClick.listen((_) => loadPreset('counter'));
  presetMap?.onClick.listen((_) => loadPreset('map'));
  presetWhile?.onClick.listen((_) => loadPreset('while'));

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
    } on ParserException catch (exception) {
      output.textContent =
          '${exception.failure.message} at ${exception.failure.toPositionString()}';
      output.classList.add('error');
    } on Object catch (exception) {
      output.textContent = exception.toString();
      output.classList.add('error');
    }
    inspect(environment, user);
  });
  inspect(environment, user);
  evaluate.click();
}

void inspect(Element element, Environment? environment) {
  final buffer = StringBuffer();
  while (environment != null) {
    if (buffer.isNotEmpty) {
      buffer.write('<hr/>');
    }
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
    }
    environment = environment.owner;
  }
  element.innerHTML = buffer.toString().toJS;
}

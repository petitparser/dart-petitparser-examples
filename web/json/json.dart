import 'dart:convert' as convert;

import 'package:petitparser_examples/json.dart';
import 'package:web/web.dart';

final parser = JsonDefinition().build();

void execute(
  String value,
  HTMLElement timingElement,
  HTMLElement outputElement,
  dynamic Function(String value) parse,
) {
  Object? result;
  var count = 0, elapsed = 0;
  final watch = Stopwatch()..start();
  while (elapsed < 100000) {
    try {
      result = parse(value);
    } on Exception catch (exception) {
      result = exception;
    }
    elapsed = watch.elapsedMicroseconds;
    count++;
  }
  final timing = (elapsed / count).round();

  timingElement.innerText = '$timingμs';
  if (result is Exception) {
    outputElement.classList.add('error');
    outputElement.innerText = result is FormatException
        ? result.message
        : result.toString();
  } else {
    outputElement.classList.remove('error');
    outputElement.innerText = convert.json.encode(result);
  }
}

final input = document.querySelector('#input') as HTMLTextAreaElement;
final action = document.querySelector('#action') as HTMLButtonElement;

final timingCustom = document.querySelector('#timing .custom') as HTMLElement;
final timingNative = document.querySelector('#timing .native') as HTMLElement;
final outputCustom = document.querySelector('#output .custom') as HTMLElement;
final outputNative = document.querySelector('#output .native') as HTMLElement;

void update() {
  execute(
    input.value,
    timingCustom,
    outputCustom,
    (input) => parser.parse(input).value,
  );
  execute(
    input.value,
    timingNative,
    outputNative,
    (input) => convert.json.decode(input),
  );
}

void main() {
  action.onClick.listen((event) => update());
  update();
}

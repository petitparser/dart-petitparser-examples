import 'dart:convert' as convert;
import 'dart:js_interop';

import 'package:petitparser_examples/json.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final parser = JsonDefinition().build();

void execute(
  String value,
  HTMLElement timingElement,
  HTMLElement outputElement,
  dynamic Function(String value) parse, {
  bool benchmark = false,
}) {
  Object? result;
  var count = 0, elapsed = 0;
  final watch = Stopwatch()..start();
  final targetDuration = benchmark ? 10_000 : 0;
  do {
    try {
      result = parse(value);
    } on Exception catch (exception) {
      result = exception;
    }
    elapsed = watch.elapsedMicroseconds;
    count++;
  } while (elapsed < targetDuration);
  final timing = (elapsed / count).round();

  timingElement.innerHTML = '$timing &micro;s'.toJS;
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

void update({bool benchmark = false}) {
  execute(
    input.value,
    timingCustom,
    outputCustom,
    (input) => parser.parse(input).value,
    benchmark: benchmark,
  );
  execute(
    input.value,
    timingNative,
    outputNative,
    (input) => convert.json.decode(input),
    benchmark: benchmark,
  );
}

const presets = {
  'user': '''{
  "firstName": "Ada",
  "lastName": "Lovelace",
  "pioneer": true,
  "year": 1843,
  "interests": [
    "mathematics",
    "computing",
    "analytical engine"
  ]
}''',
  'array': '''[
  {
    "id": 1,
    "name": "Alpha",
    "active": true,
    "score": 98.6
  },
  {
    "id": 2,
    "name": "Beta",
    "active": false,
    "score": 72.1
  },
  {
    "id": 3,
    "name": "Gamma",
    "active": true,
    "score": 85.0
  }
]''',
  'types': '''{
  "string": "Hello \u00a9 World",
  "integer": 42,
  "float": 3.14159,
  "scientific": 0.00001,
  "booleanTrue": true,
  "booleanFalse": false,
  "nullValue": null,
  "array": [
    1,
    2,
    3
  ],
  "nested": {
    "key": "value"
  }
}''',
};

void main() {
  initShared();

  final presetUser =
      document.querySelector('#preset-user') as HTMLButtonElement?;
  final presetArray =
      document.querySelector('#preset-array') as HTMLButtonElement?;
  final presetTypes =
      document.querySelector('#preset-types') as HTMLButtonElement?;

  void loadPreset(String key) {
    final value = presets[key];
    if (value != null) {
      input.value = value;
      update(benchmark: true);
    }
  }

  presetUser?.onClick.listen((_) => loadPreset('user'));
  presetArray?.onClick.listen((_) => loadPreset('array'));
  presetTypes?.onClick.listen((_) => loadPreset('types'));

  action.onClick.listen((event) => update(benchmark: true));
  input.onInput.listen((event) => update());
  update(benchmark: true);
}

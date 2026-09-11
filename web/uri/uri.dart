import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final output = document.querySelector('#output') as HTMLElement;

String _escapeHtml(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

void update() {
  final result = uri.parse(input.value);
  if (result is Success) {
    final parsed = result.value;
    final rows = <String>[];

    void addRow(String label, Object? value, {bool isSub = false}) {
      if (value == null) return;
      final str = value.toString();
      if (str.isEmpty) return;
      final subClass = isSub ? ' class="sub"' : '';
      rows.add(
        '<tr$subClass><th>${_escapeHtml(label)}</th><td>${_escapeHtml(str)}</td></tr>',
      );
    }

    addRow('Scheme', parsed.scheme);
    addRow('Authority', parsed.authority);
    addRow('Username', parsed.username, isSub: true);
    addRow('Password', parsed.password, isSub: true);
    addRow('Hostname', parsed.hostname, isSub: true);
    addRow('Port', parsed.port, isSub: true);
    addRow('Path', parsed.path);
    addRow('Query', parsed.query);
    for (final (key, val) in parsed.params) {
      if (key.isNotEmpty || (val != null && val.isNotEmpty)) {
        addRow(key.isEmpty ? 'Param' : key, val, isSub: true);
      }
    }
    addRow('Fragment', parsed.fragment);

    output.className = '';
    output.innerHTML = '<table>${rows.join()}</table>'.toJS;
  } else {
    output.className = 'error';
    output.textContent = '${result.message} at ${result.toPositionString()}';
  }
}

void main() {
  input.onInput.listen((event) => update());
  input.value = window.location.href;
  update();
}

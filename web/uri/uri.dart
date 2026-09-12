import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

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
  initShared();

  final presetHttp =
      document.querySelector('#preset-http') as HTMLButtonElement?;
  final presetAuth =
      document.querySelector('#preset-auth') as HTMLButtonElement?;
  final presetUrn = document.querySelector('#preset-urn') as HTMLButtonElement?;
  final presetMail =
      document.querySelector('#preset-mail') as HTMLButtonElement?;

  void setUri(String value) {
    input.value = value;
    update();
  }

  presetHttp?.onClick.listen(
    (_) => setUri(
      'https://petitparser.github.io/examples/dart/dart.html?mode=ast&view=full#records',
    ),
  );
  presetAuth?.onClick.listen(
    (_) => setUri(
      'https://admin:secret123@api.example.com:8443/v2/users?page=1&sort=desc#profile',
    ),
  );
  presetUrn?.onClick.listen((_) => setUri('urn:isbn:0-486-27557-4'));
  presetMail?.onClick.listen(
    (_) => setUri(
      'mailto:user@example.com?subject=PetitParser&body=Great%20library!',
    ),
  );

  input.onInput.listen((event) => update());
  input.value = window.location.href;
  update();
}

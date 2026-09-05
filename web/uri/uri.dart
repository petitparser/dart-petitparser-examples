import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final output = document.querySelector('#output') as HTMLElement;

void update() {
  final result = uri.parse(input.value);
  if (result is Success) {
    final parsed = result.value;
    output.innerHTML =
        '''
    <table>
      <tr>
        <th>Scheme</th>
        <td>${parsed.scheme}</td>
      </tr>
      <tr>  
        <th>Authority</th>
        <td>${parsed.authority}</td>
      </tr>
      <tr class="sub">  
        <th>Username</th>
        <td>${parsed.username}</td>
      </tr>
      <tr class="sub">  
        <th>Password</th>
        <td>${parsed.password}</td>
      </tr>
      <tr class="sub">  
        <th>Hostname</th>
        <td>${parsed.hostname}</td>
      </tr>
      <tr class="sub">  
        <th>Port</th>
        <td>${parsed.port}</td>
      </tr>
      <tr>  
        <th>Path</th>
        <td>${parsed.path}</td>
      </tr>
      <tr>  
        <th>Query</th>
        <td>${parsed.query}</td>
      </tr>
      ${parsed.params.map((each) => '''
      <tr class="sub">  
        <th>${each.$1}</th>
        <td>${each.$2}</td>
      </tr>
      ''').join()}
      <tr>  
        <th>Fragment</th>
        <td>${parsed.fragment}</td>
      </tr>
    </table>
    '''
            .toJS;
  } else {
    output.innerHTML =
        '''
    <span class="error">
      Error at ${result.position}: ${result.message}
    </span>
    '''
            .toJS;
  }
}

void main() {
  input.onInput.listen((event) => update());
  input.value = window.location.href;
  update();
}

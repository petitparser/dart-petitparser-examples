import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/uri.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final output = document.querySelector('#output') as HTMLElement;

void update() {
  final result = uri.parse(input.value);
  if (result is Success) {
    output.innerHTML = '''
    <table>
      <tr>
        <th>Scheme</th>
        <td>${result.value[#scheme]}</td>
      </tr>
      <tr>  
        <th>Authority</th>
        <td>${result.value[#authority]}</td>
      </tr>
      <tr class="sub">  
        <th>Username</th>
        <td>${result.value[#username]}</td>
      </tr>
      <tr class="sub">  
        <th>Password</th>
        <td>${result.value[#password]}</td>
      </tr>
      <tr class="sub">  
        <th>Hostname</th>
        <td>${result.value[#hostname]}</td>
      </tr>
      <tr class="sub">  
        <th>Port</th>
        <td>${result.value[#port]}</td>
      </tr>
      <tr>  
        <th>Path</th>
        <td>${result.value[#path]}</td>
      </tr>
      <tr>  
        <th>Query</th>
        <td>${result.value[#query]}</td>
      </tr>
      ${result.value[#params].map((each) => '''
      <tr class="sub">  
        <th>${each[0]}</th>
        <td>${each[1]}</td>
      </tr>
      ''').join()}
      <tr>  
        <th>Fragment</th>
        <td>${result.value[#fragment]}</td>
      </tr>
    </table>
    '''
        .toJS;
  } else {
    output.innerHTML = '''
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

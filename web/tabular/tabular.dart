import 'dart:js_interop';

import 'package:petitparser/core.dart';
import 'package:petitparser_examples/tabular.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final format = document.querySelector('#format') as HTMLSelectElement;
final action = document.querySelector('#action') as HTMLButtonElement;
final input = document.querySelector('#input') as HTMLTextAreaElement;
final stats = document.querySelector('#stats') as HTMLElement;
final output = document.querySelector('#output') as HTMLDivElement;

final presetCities =
    document.querySelector('#preset-cities') as HTMLButtonElement;
final presetIris = document.querySelector('#preset-iris') as HTMLButtonElement;
final presetQuotes =
    document.querySelector('#preset-quotes') as HTMLButtonElement;

const presets = {
  'cities':
      'Los Angeles,34°03′N,118°15′W\n'
      'New York City,40°42′46″N,74°00′21″W\n'
      'Paris,48°51′24″N,2°21′03″E',
  'iris':
      'Sepal length\tSepal width\tPetal length\tPetal width\tSpecies\n'
      '5.1\t3.5\t1.4\t0.2\tI. setosa\n'
      '4.9\t3.0\t1.4\t0.2\tI. setosa\n'
      '4.7\t3.2\t1.3\t0.2\tI. setosa\n'
      '4.6\t3.1\t1.5\t0.2\tI. setosa\n'
      '5.0\t3.6\t1.4\t0.2\tI. setosa',
  'quotes':
      '"Item","Description","Price"\n'
      '"Widget A","Standard issue, model ""Pro"" with extras",19.99\n'
      '"Widget B","Multi-line\ndescription\nwith commas, and quotes",49.95\n'
      '"Widget C","Simple item",9.50',
};

final parsers = {
  'CSV': TabularDefinition.csv().build(),
  'TSV': TabularDefinition.tsv().build(),
};

void parseData() {
  final parser = parsers[format.value] ?? parsers['CSV']!;
  final text = input.value;
  final watch = Stopwatch()..start();

  final result = parser.parse(text);
  final elapsed = watch.elapsedMicroseconds;

  if (result is Failure) {
    stats.innerHTML = 'Parse failed after <span>$elapsed &micro;s</span>.'.toJS;
    output.className = 'error';
    output.textContent = '${result.message} at ${result.toPositionString()}';
    return;
  }

  final rows = result.value;
  final totalCells = rows.fold<int>(0, (sum, r) => sum + r.length);
  stats.innerHTML =
      'Parsed <span>${rows.length}</span> rows and <span>$totalCells</span> cells in <span>$elapsed &micro;s</span>.'
          .toJS;

  final table = document.createElement('table');
  var isHeader = true;
  for (final row in rows) {
    final tableRow = document.createElement('tr');
    for (final cell in row) {
      final tableCell = document.createElement(isHeader ? 'th' : 'td');
      tableCell.textContent = cell;
      tableRow.appendChild(tableCell);
    }
    table.appendChild(tableRow);
    isHeader = false;
  }
  output.className = '';
  output.replaceChildren(table);
}

void loadPreset(String key, String fmt) {
  input.value = presets[key] ?? '';
  format.value = fmt;
  parseData();
}

void main() {
  initShared();

  presetCities.onClick.listen((_) => loadPreset('cities', 'CSV'));
  presetIris.onClick.listen((_) => loadPreset('iris', 'TSV'));
  presetQuotes.onClick.listen((_) => loadPreset('quotes', 'CSV'));

  format.onChange.listen((_) => parseData());
  action.onClick.listen((_) => parseData());
  input.onInput.listen((_) => parseData());

  loadPreset('cities', 'CSV');
}

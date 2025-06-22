import 'package:petitparser/core.dart';
import 'package:petitparser_examples/tabular.dart';
import 'package:web/web.dart';

final options = document.querySelector('#options') as HTMLSelectElement;
final example = document.querySelector('#example') as HTMLButtonElement;
final input = document.querySelector('#input') as HTMLTextAreaElement;
final output = document.querySelector('#output') as HTMLDivElement;

const examples = {
  'CSV':
      'Los Angeles,34°03′N,118°15′W\n'
      'New York City,40°42′46″N,74°00′21″W\n'
      'Paris,48°51′24″N,2°21′03″E',
  'TSV':
      'Sepal length	Sepal width	Petal length	Petal width	Species\n'
      '5.1	3.5	1.4	0.2	I. setosa\n'
      '4.9	3.0	1.4	0.2	I. setosa\n'
      '4.7	3.2	1.3	0.2	I. setosa\n'
      '4.6	3.1	1.5	0.2	I. setosa\n'
      '5.0	3.6	1.4	0.2	I. setosa',
};
final parsers = {
  'CSV': TabularDefinition.csv().build(),
  'TSV': TabularDefinition.tsv().build(),
};

T getOption<T>(Map<String, T> mapping) {
  for (final MapEntry(:key, :value) in mapping.entries) {
    if (options.value.startsWith(key)) {
      return value;
    }
  }
  throw ArgumentError.value(mapping, 'mapping');
}

void loadExample() {
  input.value = getOption(examples);
  updateOutput();
}

void updateOutput() {
  final parser = getOption(parsers);
  try {
    final result = parser.parse(input.value).value;
    final table = document.createElement('table');
    for (final row in result) {
      final tableRow = document.createElement('tr');
      for (final cell in row) {
        final tableCell = document.createElement('td');
        tableCell.textContent = cell;
        tableRow.appendChild(tableCell);
      }
      table.appendChild(tableRow);
    }
    output.textContent = '';
    output.appendChild(table);
    output.classList.remove('error');
  } on ParserException catch (exception) {
    output.textContent =
        '${exception.message} at ${exception.failure.toPositionString()}';
    output.classList.add('error');
  }
}

void main() {
  options.onChange.listen((_) => updateOutput());
  example.onClick.listen((_) => loadExample());
  input.onInput.listen((_) => updateOutput());
  loadExample();
}

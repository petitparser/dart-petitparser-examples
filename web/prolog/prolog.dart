import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/prolog.dart';
import 'package:web/web.dart';

final rulesElement = document.querySelector('#rules') as HTMLTextAreaElement;
final queryElement = document.querySelector('#query') as HTMLInputElement;
final askElement = document.querySelector('#ask') as HTMLButtonElement;
final outputElement = document.querySelector('#output') as HTMLElement;

void update() {
  outputElement.className = '';
  outputElement.innerText = '';

  final rulesResult = rulesParser.parse(rulesElement.value);
  if (rulesResult is Failure) {
    final div = document.createElement('div');
    div.textContent =
        'Rules Error: ${rulesResult.message} at ${rulesResult.toPositionString()}';
    outputElement.className = 'error';
    outputElement.append(div);
  }

  final queryResult = termParser.parse(queryElement.value);
  if (queryResult is Failure) {
    final div = document.createElement('div');
    div.textContent =
        'Query Error: ${queryResult.message} at ${queryResult.toPositionString()}';
    outputElement.className = 'error';
    outputElement.append(div);
  }

  if (rulesResult is Failure || queryResult is Failure) {
    return;
  }

  final db = Database(rulesResult.value);
  final query = queryResult.value;

  final solutions = <String>[];
  db.query(query).forEach((item) {
    solutions.add(item.toString());
  });

  if (solutions.isEmpty) {
    outputElement.textContent = 'No';
  } else {
    final list = document.createElement('ul') as HTMLUListElement;
    list.style.paddingLeft = '2rem';
    list.style.margin = '0';
    for (final sol in solutions) {
      final li = document.createElement('li');
      li.textContent = sol;
      list.append(li);
    }
    outputElement.append(list);
  }
}

void main() {
  askElement.onClick.listen((_) => update());
  update();
}

import 'package:petitparser_examples/prolog.dart';
import 'package:web/web.dart';

final rulesElement = document.querySelector('#rules') as HTMLInputElement;
final queryElement = document.querySelector('#query') as HTMLInputElement;
final askElement = document.querySelector('#ask') as HTMLButtonElement;
final answersElement = document.querySelector('#answers') as HTMLElement;

void main() {
  askElement.onClick.listen((event) async {
    answersElement.innerText = '';

    Database? db;
    try {
      db = Database.parse(rulesElement.value);
    } on Object catch (error) {
      appendMessage('Error parsing rules: $error', isError: true);
    }

    Term? query;
    try {
      query = Term.parse(queryElement.value);
    } on Object catch (error) {
      appendMessage('Error parsing query: $error', isError: true);
    }

    if (db == null || query == null) {
      return;
    }

    var hasResult = false;
    db.query(query).forEach((item) {
      appendMessage(item.toString());
      hasResult = true;
    });
    if (!hasResult) {
      appendMessage('No');
    }
  });
}

void appendMessage(String message, {bool isError = false}) {
  final element = document.createElement('li');
  element.textContent = message;
  if (isError) {
    element.classList.add('error');
  }
  answersElement.append(element);
}

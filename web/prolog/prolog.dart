import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/prolog.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

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
        'Rules: ${rulesResult.message} at ${rulesResult.toPositionString()}';
    outputElement.className = 'error';
    outputElement.append(div);
  }

  final queryResult = termParser.parse(queryElement.value);
  if (queryResult is Failure) {
    final div = document.createElement('div');
    div.textContent =
        'Query: ${queryResult.message} at ${queryResult.toPositionString()}';
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

const presets = {
  'family': (
    rules: '''father_child(massimo, ridge).
father_child(eric, thorne).
father_child(thorne, alexandria).

mother_child(stephanie, thorne).
mother_child(stephanie, kristen).
mother_child(stephanie, felicia).

parent_child(X, Y) :- father_child(X, Y).
parent_child(X, Y) :- mother_child(X, Y).

sibling(X, Y) :- parent_child(Z, X), parent_child(Z, Y).

ancestor(X, Y) :- parent_child(X, Y).
ancestor(X, Y) :- parent_child(X, Z), ancestor(Z, Y).''',
    query: 'sibling(X, felicia)',
  ),
  'graph': (
    rules: '''edge(a, b).
edge(b, c).
edge(c, d).
edge(b, e).

path(X, Y) :- edge(X, Y).
path(X, Y) :- edge(X, Z), path(Z, Y).''',
    query: 'path(a, Goal)',
  ),
  'einstein': (
    rules: '''exists(A, list(A, _, _, _, _)).
exists(A, list(_, A, _, _, _)).
exists(A, list(_, _, A, _, _)).
exists(A, list(_, _, _, A, _)).
exists(A, list(_, _, _, _, A)).

rightOf(R, L, list(L, R, _, _, _)).
rightOf(R, L, list(_, L, R, _, _)).
rightOf(R, L, list(_, _, L, R, _)).
rightOf(R, L, list(_, _, _, L, R)).

middle(A, list(_, _, A, _, _)).
first(A, list(A, _, _, _, _)).

nextTo(A, B, list(B, A, _, _, _)).
nextTo(A, B, list(_, B, A, _, _)).
nextTo(A, B, list(_, _, B, A, _)).
nextTo(A, B, list(_, _, _, B, A)).
nextTo(A, B, list(A, B, _, _, _)).
nextTo(A, B, list(_, A, B, _, _)).
nextTo(A, B, list(_, _, A, B, _)).
nextTo(A, B, list(_, _, _, A, B)).

puzzle(Houses) :-
  exists(house(red, british, _, _, _), Houses),
  exists(house(_, swedish, _, _, dog), Houses),
  exists(house(green, _, coffee, _, _), Houses),
  exists(house(_, danish, tea, _, _), Houses),
  rightOf(house(white, _, _, _, _), house(green, _, _, _, _), Houses),
  exists(house(_, _, _, pall_mall, bird), Houses),
  exists(house(yellow, _, _, dunhill, _), Houses),
  middle(house(_, _, milk, _, _), Houses),
  first(house(_, norwegian, _, _, _), Houses),
  nextTo(house(_, _, _, blend, _), house(_, _, _, _, cat), Houses),
  nextTo(house(_, _, _, dunhill, _), house(_, _, _, _, horse), Houses),
  exists(house(_, _, beer, bluemaster, _), Houses),
  exists(house(_, german, _, prince, _), Houses),
  nextTo(house(_, norwegian, _, _, _), house(blue, _, _, _, _), Houses),
  nextTo(house(_, _, _, blend, _), house(_, _, water, _, _), Houses).

solution(FishOwner) :-
  puzzle(Houses),
  exists(house(_, FishOwner, _, _, fish), Houses).''',
    query: 'solution(FishOwner)',
  ),
};

void main() {
  initShared();

  final presetFamily =
      document.querySelector('#preset-family') as HTMLButtonElement?;
  final presetGraph =
      document.querySelector('#preset-graph') as HTMLButtonElement?;
  final presetEinstein =
      document.querySelector('#preset-einstein') as HTMLButtonElement?;

  void loadPreset(String key) {
    final preset = presets[key];
    if (preset != null) {
      rulesElement.value = preset.rules;
      queryElement.value = preset.query;
      update();
    }
  }

  presetFamily?.onClick.listen((_) => loadPreset('family'));
  presetGraph?.onClick.listen((_) => loadPreset('graph'));
  presetEinstein?.onClick.listen((_) => loadPreset('einstein'));

  askElement.onClick.listen((_) => update());
  update();
}

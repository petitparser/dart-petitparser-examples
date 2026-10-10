import 'package:checks/checks.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/prolog.dart';
import 'package:test/scaffolding.dart';

void main() {
  group('database', () {
    test('linter', () {
      check(
        linter(
          rulesParser,
          excludedTypes: {},
          excludedRules: {'Duplicate parser'},
        ),
      ).isEmpty();
    });
    test('empty', () {
      final db = Database.parse('foo.');
      check(db.toString()).equals('foo :- true.');
    });
    test('single', () {
      final db = Database.parse('foo(a, b).');
      check(db.toString()).equals('foo(a, b) :- true.');
    });
    test('multiple', () {
      final db = Database.parse('''
        foo(X, Y) :- foo(Y, X).
        foo(X, Z) :- foo(X, Y), foo(Y, Z).
      ''');
      check(db.toString()).equals(
        'foo(X, Y) :- foo(Y, X).\n'
        'foo(X, Z) :- foo(X, Y), foo(Y, Z).',
      );
    });
    test('two', () {
      final db = Database.parse('''
        foo(a, b).
        foo(X, Y) :- foo(Y, X).
        foo(X, Z) :- foo(X, Y), foo(Y, Z).
      ''');
      check(db.toString()).equals(
        'foo(a, b) :- true.\n'
        'foo(X, Y) :- foo(Y, X).\n'
        'foo(X, Z) :- foo(X, Y), foo(Y, Z).',
      );
    });
    test('parse error', () {
      final error = check(() => Database.parse('1')).throws<ParserException>();
      error.has((e) => e.message, 'message').equals('end of input expected');
      error.has((e) => e.offset, 'offset').equals(0);
    });
  });
  group('term', () {
    test('linter', () {
      check(
        linter(
          termParser,
          excludedTypes: {},
          excludedRules: {'Duplicate parser'},
        ),
      ).isEmpty();
    });
    test('empty', () {
      final query = Term.parse('foo');
      check(query.toString()).equals('foo');
    });
    test('one', () {
      final query = Term.parse('foo(bar)');
      check(query.toString()).equals('foo(bar)');
    });
    test('two', () {
      final query = Term.parse('foo(bar, zork)');
      check(query.toString()).equals('foo(bar, zork)');
    });
    test('parse error', () {
      final error = check(() => Term.parse('1')).throws<ParserException>();
      error.has((e) => e.message, 'message').equals('Value expected');
      error.has((e) => e.offset, 'offset').equals(0);
    });
  });
  group('Forrester family', () {
    final db = Database.parse('''
      father_child(massimo, ridge).
      father_child(eric, thorne).
      father_child(thorne, alexandria).
      
      mother_child(stephanie, thorne).
      mother_child(stephanie, kristen).
      mother_child(stephanie, felicia).
      
      parent_child(X, Y) :- father_child(X, Y).
      parent_child(X, Y) :- mother_child(X, Y).
      
      sibling(X, Y) :- parent_child(Z, X), parent_child(Z, Y).
      
      ancestor(X, Y) :- parent_child(X, Y).
      ancestor(X, Y) :- parent_child(X, Z), ancestor(Z, Y).
    ''');
    test('eric son of thorne', () async {
      final query = Term.parse('father_child(eric, thorne)');
      check(db.query(query))
          .deepEquals([Term.parse('father_child(eric, thorne)')]);
    });
    test('children of stephanie', () async {
      final query = Term.parse('mother_child(stephanie, X)');
      check(db.query(query)).deepEquals([
        Term.parse('mother_child(stephanie, thorne)'),
        Term.parse('mother_child(stephanie, kristen)'),
        Term.parse('mother_child(stephanie, felicia)'),
      ]);
    });
    test('fathers and children', () async {
      final query = Term.parse('father_child(X, Y)');
      check(db.query(query)).deepEquals([
        Term.parse('father_child(massimo, ridge)'),
        Term.parse('father_child(eric, thorne)'),
        Term.parse('father_child(thorne, alexandria)'),
      ]);
    });
    test('parents of thorne', () async {
      final query = Term.parse('parent_child(X, thorne)');
      check(db.query(query)).deepEquals([
        Term.parse('parent_child(eric, thorne)'),
        Term.parse('parent_child(stephanie, thorne)'),
      ]);
    });
    test('parents and children', () async {
      final query = Term.parse('parent_child(X, Y)');
      check(db.query(query)).deepEquals([
        Term.parse('parent_child(massimo, ridge)'),
        Term.parse('parent_child(eric, thorne)'),
        Term.parse('parent_child(thorne, alexandria)'),
        Term.parse('parent_child(stephanie, thorne)'),
        Term.parse('parent_child(stephanie, kristen)'),
        Term.parse('parent_child(stephanie, felicia)'),
      ]);
    });
    test('siblings of felicia', () async {
      final query = Term.parse('sibling(X, felicia)');
      check(db.query(query)).deepEquals([
        Term.parse('sibling(thorne, felicia)'),
        Term.parse('sibling(kristen, felicia)'),
        Term.parse('sibling(felicia, felicia)'),
      ]);
    });
    test('ancestors of alexandria', () {
      final query = Term.parse('ancestor(X, alexandria)');
      check(db.query(query)).deepEquals([
        Term.parse('ancestor(thorne, alexandria)'),
        Term.parse('ancestor(eric, alexandria)'),
        Term.parse('ancestor(stephanie, alexandria)'),
      ]);
    });
  });
  group("Einstein's Problem", () {
    // https://mathforum.org/library/drmath/view/60971.html
    final db = Database.parse('''
      exists(A, list(A, _, _, _, _)).
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
        nextTo(house(_, _, _, dunhill, _),house(_, _, _, _, horse), Houses),
        exists(house(_, _, beer, bluemaster, _), Houses),
        exists(house(_, german, _, prince, _), Houses),
        nextTo(house(_, norwegian, _, _, _), house(blue, _, _, _, _), Houses),
        nextTo(house(_, _, _, blend, _), house(_, _, water_, _, _), Houses).
      
      solution(FishOwner) :-
        puzzle(Houses),
        exists(house(_, FishOwner, _, _, fish), Houses).
    ''');
    test('Who Owns the Fish?', () {
      final query = Term.parse('solution(FishOwner)');
      check(db.query(query)).deepEquals([Term.parse('solution(german)')]);
    });
  });
  group('AST nodes and evaluation methods', () {
    final db = Database.parse('foo(a).');

    test('Variable equality and hashCode', () {
      const v1 = Variable('X');
      const v2 = Variable('X');
      const v3 = Variable('Y');

      check(v1).equals(v2);
      check(v1.hashCode).equals(v2.hashCode);
      check(v1).not((it) => it.equals(v3));
      check(v1.hashCode).not((it) => it.equals(v3.hashCode));
      check(v1.toString()).equals('X');
    });

    test('Term equality and hashCode', () {
      final t1 = Term('parent', const [Variable('X'), Value('bob')]);
      final t2 = Term('parent', const [Variable('X'), Value('bob')]);
      final t3 = Term('parent', const [Variable('Y'), Value('bob')]);

      check(t1).equals(t2);
      check(t1.hashCode).equals(t2.hashCode);
      check(t1).not((it) => it.equals(t3));
      check(t1.toString()).equals('parent(X, bob)');
    });

    test('Value equality, hashCode and query', () {
      const val1 = Value('apple');
      const val2 = Value('apple');
      const val3 = Value('banana');

      check(val1).equals(val2);
      check(val1.hashCode).equals(val2.hashCode);
      check(val1).not((it) => it.equals(val3));
      check(val1.query(db)).deepEquals([val1]);
      check(val1.toString()).equals('apple');
    });

    test('Conjunction equality and hashCode', () {
      final c1 = Conjunction(const [Value('a'), Value('b')]);
      final c2 = Conjunction(const [Value('a'), Value('b')]);
      final c3 = Conjunction(const [Value('a'), Value('c')]);
      final c4 = Conjunction(const [Value('a')]);

      check(c1).equals(c2);
      check(c1.hashCode).equals(c2.hashCode);
      check(c1).not((it) => it.equals(c3));
      check(c1).not((it) => it.equals(c4));
      check(c1 as Object).not((it) => it.equals(const Value('a')));
      check(c1.toString()).equals('a, b');
    });
  });
}

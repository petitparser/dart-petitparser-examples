import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/lisp.dart';
import 'package:test/scaffolding.dart';

import 'lisp/lisp_checks.dart';
import 'utils/checks.dart';

void main() {
  final parserDefinition = LispParserDefinition();

  final native = NativeEnvironment();
  final standard = StandardEnvironment(native);

  dynamic exec(String value, [Environment? env]) =>
      evalString(lispParser, env ?? standard.create(), value);

  group('Cell', () {
    test('Name', () {
      final cell1 = Name('foo');
      final cell2 = Name('foo');
      final cell3 = Name('bar');
      check(cell1).equals(cell2);
      check(cell1).identicalTo(cell2);
      check(cell1).not((it) => it.equals(cell3));
      check(cell1).not((it) => it.identicalTo(cell3));
    });
    test('Cons', () {
      final cell = Cons(1, 2);
      check(cell.car).equals(1);
      check(cell.head).equals(1);
      check(cell.cdr).equals(2);
      check(() => cell.tail).throws<StateError>();
      cell.car = 3;
      check(cell.car).equals(3);
      check(cell.head).equals(3);
      check(cell.cdr).equals(2);
      check(() => cell.tail).throws<StateError>();
      cell.cdr = Cons(4, 5);
      check(cell.car).equals(3);
      check(cell.head).equals(3);
      check(cell.tail?.car).equals(4);
      check(cell.tail?.head).equals(4);
      check(cell.tail?.cdr).equals(5);
      check(cell == cell).isTrue();
      check(cell.hashCode).not((it) => it.equals(0));
      check(cell.toString()).equals('(3 4 . 5)');
    });
    test('Quote', () {
      final quote = Quote('datum_value');
      check(quote).isA<Quote>();
      check(quote.datum).equals('datum_value');

      quote.datum = 42;
      check(quote.datum).equals(42);

      quote.datum = null;
      check(quote.datum).isNull();

      quote.datum = ['nested', 'list'];
      check(quote.datum).isA<List<dynamic>>().deepEquals(['nested', 'list']);

      final innerQuote = Quote('inner');
      final outerQuote = Quote(innerQuote);
      check(outerQuote.datum).isA<Quote>();
      check((outerQuote.datum as Quote).datum).equals('inner');
    });
  });
  group('Environment', () {
    final env = standard.create();
    test('Standard', () {
      check(env.owner).isNotNull();
      check(env.keys).isEmpty();
      check(env.owner?.keys).isNotNull().isNotEmpty();
    });
    test('Create', () {
      final sub = env.create();
      check(sub.owner).identicalTo(env);
      check(sub.keys).isEmpty();
    });
    test('operator [] and []=', () {
      final root = Environment();
      final key = Name('x');
      root.define(key, 123);
      check(root[key]).equals(123);

      final nullKey = Name('n');
      root.define(nullKey, null);
      check(root[nullKey]).isNull();

      final child = root.create();
      check(child[key]).equals(123);

      child[key] = 456;
      check(child[key]).equals(456);
      check(root[key]).equals(456);

      final missingKey = Name('unbound');
      check(() => root[missingKey])
          .throws<ArgumentError>()
          .has((e) => e.message, 'message')
          .equals('Unknown binding for unbound');
      check(() => root[missingKey] = 1)
          .throws<ArgumentError>()
          .has((e) => e.message, 'message')
          .equals('Unknown binding for unbound');
    });
  });
  group('Parser', () {
    final parser = parserDefinition.build();
    final atom = parserDefinition.buildFrom(parserDefinition.atom());

    test('Linter', () {
      check(
        linter(parser, excludedRules: {'Duplicate parser'}, excludedTypes: {}),
      ).isEmpty();
      check(
        linter(atom, excludedRules: {'Duplicate parser'}, excludedTypes: {}),
      ).isEmpty();
    });
    test('Name', () {
      check(atom).isSuccess('foo', value: isName('foo'));
      check(parser).isSuccess('foo', value: [isName('foo')]);
    });
    test('Name for operator', () {
      check(atom).isSuccess('+', value: isName('+'));
    });
    test('Name for special', () {
      check(atom).isSuccess('set!', value: isName('set!'));
    });
    test('String', () {
      check(atom).isSuccess('"foo"', value: 'foo');
      check(parser).isSuccess('"foo"', value: ['foo']);
    });
    test('String with escape', () {
      check(atom).isSuccess('"\\""', value: '"');
    });
    test('Number integer', () {
      check(atom).isSuccess('123', value: 123);
      check(parser).isSuccess('123', value: [123]);
    });
    test('Number negative integer', () {
      check(atom).isSuccess('-123', value: -123);
    });
    test('Number positive integer', () {
      check(atom).isSuccess('+123', value: 123);
    });
    test('Number floating', () {
      check(atom).isSuccess('123.45', value: 123.45);
    });
    test('Number floating exponential', () {
      check(atom).isSuccess('1.23e4', value: 1.23e4);
    });
    test('List empty', () {
      check(atom).isSuccess('()', value: isNullValue);
      check(parser).isSuccess('()', value: [isNullValue]);
    });
    test('List empty []', () {
      check(atom).isSuccess('[]', value: isNullValue);
    });
    test('List empty {}', () {
      check(atom).isSuccess('{}', value: isNullValue);
    });
    test('List one element', () {
      check(atom).isSuccess('(1)', value: isCons(head: 1, tail: isNullValue));
      check(parser)
          .isSuccess('(1)', value: [isCons(head: 1, tail: isNullValue)]);
    });
    test('List two elements', () {
      check(atom).isSuccess(
        '(1 2)',
        value: isCons(head: 1, tail: isCons(head: 2, tail: isNullValue)),
      );
    });
    test('List three elements', () {
      check(atom).isSuccess(
        '(+ 1 2)',
        value: isCons(
          head: isName('+'),
          tail: isCons(head: 1, tail: isCons(head: 2, tail: isNullValue)),
        ),
      );
    });
    test('Negative cases', () {
      check(parser).isFailure('(');
      check(parser).isFailure(')');
      check(parser).isFailure('[');
      check(parser).isFailure(']');
      check(parser).isFailure('{');
      check(parser).isFailure('}');
      check(parser).isFailure('(+ 1 2');
      check(parser).isFailure('(+ 1 (+ 2 3)');
      check(parser).isFailure('[+ 1 2');
      check(parser).isFailure('{+ 1 2');
      check(parser).isFailure('(+ 1 2))');
      check(parser).isFailure('"unterminated');
      check(parser).isFailure(r'"escaped \"');
      check(parser).isFailure('(foo "bar');
      check(parser).isFailure("'");
      check(parser).isFailure('`');
      check(parser).isFailure(',');
      check(parser).isFailure(',@');
      check(parser).isFailure('`123');
    });
  });

  group('Natives', () {
    test('Define', () {
      check(exec('(define a 1)')).equals(1);
      check(exec('(define a 2) a')).equals(2);
      check(exec('((define (a) 3))')).equals(3);
      check(exec('(define (a) 4) (a)')).equals(4);
      check(exec('((define (a x) x) 5)')).equals(5);
      check(exec('(define (a x) x) (a 6)')).equals(6);
      check(() => exec('(define 12)')).throws<ArgumentError>();
    });
    test('Lambda', () {
      check(exec('((lambda () 1) 2)')).equals(1);
      check(exec('((lambda (x) x) 2)')).equals(2);
      check(exec('((lambda (x) (+ x x)) 2)')).equals(4);
      check(exec('((lambda (x y) (+ x y)) 2 4)')).equals(6);
      check(exec('((lambda (x y z) (+ x y z)) 2 4 6)')).equals(12);
    });
    test('Quote', () {
      check(exec('(quote 1)')).equals(1);
      check(exec('(quote a)')).equals(Name('a'));
      check(exec('(quote (+ 1))')).equals(Cons(Name('+'), Cons(1)));
    });
    test('Quote (syntax)', () {
      check(exec("'()")).equals(null);
      check(exec("'a")).equals(Name('a'));
      check(exec("'(1)")).equals(Cons(1));
      check(exec("'(+ 1)")).equals(Cons(Name('+'), Cons(1)));
    });
    test('Eval', () {
      check(exec('(eval (quote (+ 1 2)))')).equals(3);
    });
    test('Apply', () {
      check(exec('(apply + 1 2 3)')).equals(6);
      check(exec('(apply + 1 2 3 (+ 2 2))')).equals(10);
    });
    test('Let', () {
      check(exec('(let ((a 1)) a)')).equals(1);
      check(exec('(let ((a 1) (b 2)) a)')).equals(1);
      check(exec('(let ((a 1) (b 2)) b)')).equals(2);
      check(exec('(let ((a 1) (b 2)) (+ a b))')).equals(3);
      check(exec('(let ((a 1) (b 2)) (+ a b) 4)')).equals(4);
    });
    group('Print', () {
      final buffer = StringBuffer();
      setUp(() {
        printer = buffer.write;
      });
      tearDown(() {
        printer = print;
        buffer.clear();
      });
      test('empty', () {
        check(exec('(print)')).isNull();
        check(buffer.toString()).isEmpty();
      });
      test('elements', () {
        check(exec('(print 1 2 3)')).isNull();
        check(buffer.toString()).equals('123');
      });
      test('expression', () {
        check(exec('(print (+ 1 2) " " (+ 3 4))')).isNull();
        check(buffer.toString()).equals('3 7');
      });
    });
    test('Set!', () {
      final env = standard.create();
      env.define(Name('a'), null);
      check(exec('(set! a 1)', env)).equals(1);
      check(exec('(set! a (+ 1 2))', env)).equals(3);
      check(exec('(set! a (+ 1 2)) (+ a 1)', env)).equals(4);
    });
    test('Set! (undefined)', () {
      check(() => exec('(set! a 1)')).throws<ArgumentError>();
      check(() => standard[Name('a')]).throws<ArgumentError>();
    });
    test('If', () {
      check(exec('(if true)')).isNull();
      check(exec('(if false)')).isNull();
      check(exec('(if true 1)')).equals(1);
      check(exec('(if false 1)')).isNull();
      check(exec('(if true 1 2)')).equals(1);
      check(exec('(if false 1 2)')).equals(2);
    });
    test('If (laziness)', () {
      check(exec('(if (= 1 1) 3 4)')).equals(3);
      check(exec('(if (= 1 2) 3 4)')).equals(4);
    });
    test('While', () {
      final env = standard.create();
      env.define(Name('a'), 0);
      exec('(while (< a 3) (set! a (+ a 1)))', env);
      check(env[Name('a')]).equals(3);
    });
    test('True', () {
      check(exec('true')).isTrue();
    });
    test('False', () {
      check(exec('false')).isFalse();
    });
    test('And', () {
      check(exec('(and)')).isTrue();
      check(exec('(and true)')).isTrue();
      check(exec('(and false)')).isFalse();
      check(exec('(and true true)')).isTrue();
      check(exec('(and true false)')).isFalse();
      check(exec('(and false true)')).isFalse();
      check(exec('(and false false)')).isFalse();
      check(exec('(and true true true)')).isTrue();
      check(exec('(and true true false)')).isFalse();
      check(exec('(and true false true)')).isFalse();
      check(exec('(and true false false)')).isFalse();
      check(exec('(and false true true)')).isFalse();
      check(exec('(and false true false)')).isFalse();
      check(exec('(and false false true)')).isFalse();
      check(exec('(and false false false)')).isFalse();
    });
    test('And (laziness)', () {
      final env = standard.create();
      env.define(Name('a'), null);
      exec('(and false (set! a true))', env);
      check(env[Name('a')]).isNull();
      exec('(and true (set! a true))', env);
      check(env[Name('a')]).isTrue();
    });
    test('Or', () {
      check(exec('(or)')).isFalse();
      check(exec('(or true)')).isTrue();
      check(exec('(or false)')).isFalse();
      check(exec('(or true true)')).isTrue();
      check(exec('(or true false)')).isTrue();
      check(exec('(or false true)')).isTrue();
      check(exec('(or false false)')).isFalse();
      check(exec('(or true true true)')).isTrue();
      check(exec('(or true true false)')).isTrue();
      check(exec('(or true false true)')).isTrue();
      check(exec('(or true false false)')).isTrue();
      check(exec('(or false true true)')).isTrue();
      check(exec('(or false true false)')).isTrue();
      check(exec('(or false false true)')).isTrue();
      check(exec('(or false false false)')).isFalse();
    });
    test('Or (laziness)', () {
      final env = standard.create();
      env.define(Name('a'), null);
      exec('(or true (set! a true))', env);
      check(env[Name('a')]).isNull();
      exec('(or false (set! a true))', env);
      check(env[Name('a')]).isTrue();
    });
    test('Not', () {
      check(exec('(not true)')).isFalse();
      check(exec('(not false)')).isTrue();
    });
    test('Add', () {
      check(exec('(+ 1)')).equals(1);
      check(exec('(+ 1 2)')).equals(3);
      check(exec('(+ 1 2 3)')).equals(6);
      check(exec('(+ 1 2 3 4)')).equals(10);
    });
    test('Sub', () {
      check(exec('(- 1)')).equals(-1);
      check(exec('(- 1 2)')).equals(-1);
      check(exec('(- 1 2 3)')).equals(-4);
      check(exec('(- 1 2 3 4)')).equals(-8);
    });
    test('Mul', () {
      check(exec('(* 2)')).equals(2);
      check(exec('(* 2 3)')).equals(6);
      check(exec('(* 2 3 4)')).equals(24);
    });
    test('Div', () {
      check(exec('(/ 24)')).equals(24);
      check(exec('(/ 24 3)')).equals(8);
      check(exec('(/ 24 3 2)')).equals(4);
    });
    test('Mod', () {
      check(exec('(% 24)')).equals(24);
      check(exec('(% 24 5)')).equals(4);
      check(exec('(% 24 5 3)')).equals(1);
    });
    test('Less', () {
      check(exec('(< 1 2)')).isTrue();
      check(exec('(< 1 1)')).isFalse();
      check(exec('(< 2 1)')).isFalse();
      check(exec('(< "a" "b")')).isTrue();
      check(exec('(< "a" "a")')).isFalse();
      check(exec('(< "b" "a")')).isFalse();
    });
    test('Less equal', () {
      check(exec('(<= 1 2)')).isTrue();
      check(exec('(<= 1 1)')).isTrue();
      check(exec('(<= 2 1)')).isFalse();
      check(exec('(<= "a" "b")')).isTrue();
      check(exec('(<= "a" "a")')).isTrue();
      check(exec('(<= "b" "a")')).isFalse();
    });
    test('Equal', () {
      check(exec('(= 1 1)')).isTrue();
      check(exec('(= 1 2)')).isFalse();
      check(exec('(= 2 1)')).isFalse();
      check(exec('(= "a" "a")')).isTrue();
      check(exec('(= "a" "b")')).isFalse();
      check(exec('(= "b" "a")')).isFalse();
    });
    test('Not equal', () {
      check(exec('(!= 1 1)')).isFalse();
      check(exec('(!= 1 2)')).isTrue();
      check(exec('(!= 2 1)')).isTrue();
      check(exec('(!= "a" "a")')).isFalse();
      check(exec('(!= "a" "b")')).isTrue();
      check(exec('(!= "b" "a")')).isTrue();
    });
    test('Larger', () {
      check(exec('(> 1 1)')).isFalse();
      check(exec('(> 1 2)')).isFalse();
      check(exec('(> 2 1)')).isTrue();
      check(exec('(> "a" "a")')).isFalse();
      check(exec('(> "a" "b")')).isFalse();
      check(exec('(> "b" "a")')).isTrue();
    });
    test('Larger equal', () {
      check(exec('(>= 1 1)')).isTrue();
      check(exec('(>= 1 2)')).isFalse();
      check(exec('(>= 2 1)')).isTrue();
      check(exec('(>= "a" "a")')).isTrue();
      check(exec('(>= "a" "b")')).isFalse();
      check(exec('(>= "b" "a")')).isTrue();
    });
    test('Cons', () {
      check(exec('(cons 1 2)')).equals(Cons(1, 2));
      check(exec('(cons 1 null)')).equals(Cons(1));
      check(exec('(cons null 2)')).equals(Cons(null, 2));
      check(exec('(cons null null)')).equals(Cons());
      check(exec('(cons 1 (cons 2 (cons 3 null)))'))
          .equals(Cons(1, Cons(2, Cons(3))));
    });
    test('Car', () {
      check(exec('(car null)')).isNull();
      check(exec('(car (cons 1 2))')).equals(1);
    });
    test('Car!', () {
      check(exec('(car! null 3)')).isNull();
      check(exec('(car! (cons 1 2) 3)')).equals(Cons(3, 2));
    });
    test('Cdr', () {
      check(exec('(cdr null)')).isNull();
      check(exec('(cdr (cons 1 2))')).equals(2);
    });
    test('Cdr!', () {
      check(exec('(cdr! null 3)')).isNull();
      check(exec('(cdr! (cons 1 2) 3)')).equals(Cons(1, 3));
    });
  });
  group('Library', () {
    test('Null', () {
      check(exec('null')).isNull();
    });
    test('Null? (true)', () {
      check(exec("(null? '())")).isTrue();
      check(exec('(null? null)')).isTrue();
    });
    test('Null? (false)', () {
      check(exec('(null? 1)')).isFalse();
      check(exec('(null? "a")')).isFalse();
      check(exec('(null? (quote a))')).isFalse();
      check(exec('(null? true)')).isFalse();
      check(exec('(null? false)')).isFalse();
    });
    test('Length', () {
      check(exec("(length '())")).equals(0);
      check(exec("(length '(1))")).equals(1);
      check(exec("(length '(1 1))")).equals(2);
      check(exec("(length '(1 1 1))")).equals(3);
      check(exec("(length '(1 1 1 1))")).equals(4);
      check(exec("(length '(1 1 1 1 1))")).equals(5);
    });
    test('Append', () {
      check(exec("(append '() '())")).isNull();
      check(exec("(append '(1) '())")).equals(exec("'(1)"));
      check(exec("(append '() '(1))")).equals(exec("'(1)"));
      check(exec("(append '(1) '(2))")).equals(exec("'(1 2)"));
      check(exec("(append '(1 2) '(3))")).equals(exec("'(1 2 3)"));
      check(exec("(append '(1) '(2 3))")).equals(exec("'(1 2 3)"));
    });
    test('List Head', () {
      check(exec("(list-head '(5 6 7) 0)")).equals(5);
      check(exec("(list-head '(5 6 7) 1)")).equals(6);
      check(exec("(list-head '(5 6 7) 2)")).equals(7);
      check(exec("(list-head '(5 6 7) 3)")).isNull();
    });
    test('List Tail', () {
      check(exec("(list-tail '(5 6 7) 0)")).equals(exec("'(6 7)"));
      check(exec("(list-tail '(5 6 7) 1)")).equals(exec("'(7)"));
      check(exec("(list-tail '(5 6 7) 2)")).isNull();
    });
    test('Map', () {
      check(exec("(map '() (lambda (x) (* 2 x)))")).isNull();
      check(exec("(map '(2) (lambda (x) (* 2 x)))")).equals(exec("'(4)"));
      check(exec("(map '(2 3) (lambda (x) (* 2 x)))")).equals(exec("'(4 6)"));
      check(exec("(map '(2 3 4) (lambda (x) (* 2 x)))"))
          .equals(exec("'(4 6 8)"));
    });
    test('Inject', () {
      check(exec("(inject '() 5 (lambda (s e) (+ s e 1)))")).equals(5);
      check(exec("(inject '(2) 5 (lambda (s e) (+ s e 1)))")).equals(8);
      check(exec("(inject '(2 3) 5 (lambda (s e) (+ s e 1)))")).equals(12);
    });
  });
  group('Examples', () {
    test('Fibonacci', () {
      final env = standard.create();
      exec(
        '(define (fib n)'
        '  (if (<= n 1)'
        '    1'
        '    (+ (fib (- n 1)) (fib (- n 2)))))',
        env,
      );
      check(exec('(fib 0)', env)).equals(1);
      check(exec('(fib 1)', env)).equals(1);
      check(exec('(fib 2)', env)).equals(2);
      check(exec('(fib 3)', env)).equals(3);
      check(exec('(fib 4)', env)).equals(5);
      check(exec('(fib 5)', env)).equals(8);
    });
    test('Closure', () {
      final env = standard.create();
      exec(
        '(define (mul n)'
        '  (lambda (x) (* n x)))',
        env,
      );
      check(exec('((mul 2) 3)', env)).equals(6);
      check(exec('((mul 3) 4)', env)).equals(12);
      check(exec('((mul 4) 5)', env)).equals(20);
    });
    test('Object', () {
      final env = standard.create();
      exec(
        '(define (counter start)'
        '  (let ((count start))'
        '    (lambda ()'
        '      (set! count (+ count 1)))))',
        env,
      );
      exec('(define a (counter 10))', env);
      exec('(define b (counter 20))', env);
      check(exec('(a)', env)).equals(11);
      check(exec('(b)', env)).equals(21);
      check(exec('(a)', env)).equals(12);
      check(exec('(b)', env)).equals(22);
      check(exec('(a)', env)).equals(13);
      check(exec('(b)', env)).equals(23);
    });
  });
}

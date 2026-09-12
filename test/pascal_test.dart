import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:test/test.dart';

import 'utils/expect.dart';

final grammar = PascalGrammarDefinition();
final parser = grammar.build();

void main() {
  group('productions', () {
    test('program', () {
      final parser = grammar.buildFrom(grammar.program()).end();
      expect(parser, isSuccess('program foo; begin end.'));
      expect(parser, isSuccess('program foo(a); begin end.'));
      expect(parser, isSuccess('program foo(a, b); begin end.'));
    });
    test('statement', () {
      final parser = grammar.buildFrom(grammar.statement()).end();
      expect(parser, isSuccess('foo'));
      expect(parser, isSuccess('foo(1)'));
      expect(parser, isSuccess('123: a := 1'));
      expect(parser, isSuccess('123: a(1, 2)'));
    });
    test('statement assign', () {
      final parser = grammar.buildFrom(grammar.statementAssign()).end();
      expect(parser, isSuccess('a := 1'));
      expect(parser, isSuccess('a := b'));
      expect(parser, isSuccess('a := b + 1'));
    });
    test('statement call', () {
      final parser = grammar.buildFrom(grammar.statementCall()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('a(1)'));
      expect(parser, isSuccess('a(1, 2)'));
    });
    test('statement block', () {
      final parser = grammar.buildFrom(grammar.statementBlock()).end();
      expect(parser, isSuccess('begin foo end'));
      expect(parser, isSuccess('begin foo; bar end'));
    });
    test('statement if', () {
      final parser = grammar.buildFrom(grammar.statementIf()).end();
      expect(parser, isSuccess('if a then foo'));
      expect(parser, isSuccess('if a then foo else bar'));
    });
    test('statement repeat', () {
      final parser = grammar.buildFrom(grammar.statementRepeat()).end();
      expect(parser, isSuccess('repeat foo until a'));
      expect(parser, isSuccess('repeat foo; bar until a'));
    });
    test('statement while', () {
      final parser = grammar.buildFrom(grammar.statementWhile()).end();
      expect(parser, isSuccess('while a do foo'));
    });
    test('statement for', () {
      final parser = grammar.buildFrom(grammar.statementFor()).end();
      expect(parser, isSuccess('for i := a to b do foo'));
      expect(parser, isSuccess('for i := a downto b do foo'));
    });
    test('statement case', () {
      final parser = grammar.buildFrom(grammar.statementCase()).end();
      expect(parser, isSuccess('case a of 1: foo end'));
      expect(parser, isSuccess('case a of 1, 2: foo end'));
      expect(parser, isSuccess('case a of 1: foo; 2: bar end'));
    });
    test('statement with', () {
      final parser = grammar.buildFrom(grammar.statementWith()).end();
      expect(parser, isSuccess('with a do a := 1'));
      expect(parser, isSuccess('with a, b do a := 1'));
    });
    test('statement goto', () {
      final parser = grammar.buildFrom(grammar.statementGoto()).end();
      expect(parser, isSuccess('goto 1'));
    });
    test('statement exit', () {
      final parser = grammar.buildFrom(grammar.statementExit()).end();
      expect(parser, isSuccess('exit(program)'));
      expect(parser, isSuccess('exit(foo)'));
    });
    test('block', () {
      final parser = grammar.buildFrom(grammar.block()).end();
      expect(parser, isSuccess('begin end'));
      expect(parser, isSuccess('label 1; begin end'));
      expect(parser, isSuccess('const a = 1; begin end'));
      expect(parser, isSuccess('type a = b; begin end'));
      expect(parser, isSuccess('var a: b; begin end'));
      expect(parser, isSuccess('procedure foo; begin end; begin end'));
      expect(parser, isSuccess('function foo: a; begin end; begin end'));
    });
    test('block label', () {
      final parser = grammar.buildFrom(grammar.blockLabel()).end();
      expect(parser, isSuccess('label 1;'));
      expect(parser, isSuccess('label 1, 2;'));
    });
    test('block const', () {
      final parser = grammar.buildFrom(grammar.blockConst()).end();
      expect(parser, isSuccess('const a = 1;'));
      expect(parser, isSuccess('const a = 1; b = 2;'));
    });
    test('block type', () {
      final parser = grammar.buildFrom(grammar.blockType()).end();
      expect(parser, isSuccess('type a = b;'));
      expect(parser, isSuccess('type a = b; c = d;'));
    });
    test('block var', () {
      final parser = grammar.buildFrom(grammar.blockVar()).end();
      expect(parser, isSuccess('var a: b;'));
      expect(parser, isSuccess('var a, b: c;'));
      expect(parser, isSuccess('var a: b; c: d;'));
    });
    test('block procedure', () {
      final parser = grammar.buildFrom(grammar.blockProcedure()).end();
      expect(parser, isSuccess('procedure foo; begin end;'));
      expect(parser, isSuccess('procedure foo(a: b); begin end;'));
      expect(parser, isSuccess('procedure foo(a: b); var a: b; begin end;'));
    });
    test('block function', () {
      final parser = grammar.buildFrom(grammar.blockFunction()).end();
      expect(parser, isSuccess('function foo: a; begin end;'));
      expect(parser, isSuccess('function foo(a: b): c; begin end;'));
      expect(parser, isSuccess('function foo(a: b): c; var a: b; begin end;'));
    });
    test('block statement', () {
      final parser = grammar.buildFrom(grammar.blockStatement()).end();
      expect(parser, isSuccess('begin end'));
      expect(parser, isSuccess('begin foo end'));
      expect(parser, isSuccess('begin foo; bar end'));
    });
    test('type', () {
      final parser = grammar.buildFrom(grammar.type()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('^a'));
      expect(parser, isSuccess('packed set of a'));
      expect(parser, isSuccess('packed array [a] of b'));
      expect(parser, isSuccess('packed record a: b end'));
      expect(parser, isSuccess('packed file'));
    });
    test('type pointer', () {
      final parser = grammar.buildFrom(grammar.typePointer()).end();
      expect(parser, isSuccess('^a'));
    });
    test('type set', () {
      final parser = grammar.buildFrom(grammar.typeSet()).end();
      expect(parser, isSuccess('set of a'));
    });
    test('type array', () {
      final parser = grammar.buildFrom(grammar.typeArray()).end();
      expect(parser, isSuccess('array [a] of b'));
      expect(parser, isSuccess('array [a, b] of c'));
    });
    test('type record', () {
      final parser = grammar.buildFrom(grammar.typeRecord()).end();
      expect(parser, isSuccess('record a: b end'));
      expect(parser, isSuccess('record a, b: c end'));
      expect(parser, isSuccess('record case a of 1: (b: c) end'));
      expect(parser, isSuccess('record case a: b of 1: (a: b) end'));
      expect(parser, isSuccess('record case a of 1, 2: (a: b) end'));
      expect(parser, isSuccess('record case a of 1: (b: c); 2: (d: e) end'));
    });
    test('type file', () {
      final parser = grammar.buildFrom(grammar.typeFile()).end();
      expect(parser, isSuccess('file'));
      expect(parser, isSuccess('file of a'));
    });
    test('identifier', () {
      final parser = grammar.buildFrom(grammar.identifier()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('abc'));
      expect(parser, isSuccess('a123'));
    });
    test('variable', () {
      final parser = grammar.buildFrom(grammar.variable()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('a[1]'));
      expect(parser, isSuccess('a[1,2]'));
      expect(parser, isSuccess('a[1][2]'));
      expect(parser, isSuccess('a.b'));
      expect(parser, isSuccess('a.b.c'));
      expect(parser, isSuccess('a^'));
      expect(parser, isSuccess('a^^'));
    });
    test('unsigned number', () {
      final parser = grammar.buildFrom(grammar.unsignedNumber()).end();
      expect(parser, isSuccess('0', value: 0));
      expect(parser, isSuccess('123', value: 123));
      expect(parser, isSuccess('123.456', value: 123.456));
      expect(parser, isSuccess('123.456e7', value: 123.456e7));
      expect(parser, isSuccess('123.456e+7', value: 123.456e+7));
      expect(parser, isSuccess('123e-4', value: 123e-4));
    });
    test('string literal', () {
      final parser = grammar.buildFrom(grammar.stringLiteral()).end();
      expect(parser, isSuccess("''", value: "''"));
      expect(parser, isSuccess("'whatever'", value: "'whatever'"));
    });
    test('expression', () {
      final parser = grammar.buildFrom(grammar.expression()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('a = b'));
      expect(parser, isSuccess('1 in b'));
    });
    test('simple expression', () {
      final parser = grammar.buildFrom(grammar.simpleExpression()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('+ a'));
      expect(parser, isSuccess('- a'));
      expect(parser, isSuccess('a + b'));
      expect(parser, isSuccess('a - b - c'));
      expect(parser, isSuccess('a or b'));
      expect(parser, isSuccess('a or b or c'));
    });
    test('term', () {
      final parser = grammar.buildFrom(grammar.term()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('a * b'));
      expect(parser, isSuccess('a mod b'));
      expect(parser, isSuccess('a * b / c'));
      expect(parser, isSuccess('a and b and c'));
    });
    test('factor', () {
      final parser = grammar.buildFrom(grammar.factor()).end();
      expect(parser, isSuccess('1'));
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('a.b'));
      expect(parser, isSuccess('a.b.c'));
      expect(parser, isSuccess('a[1]'));
      expect(parser, isSuccess('a[1, 2]'));
      expect(parser, isSuccess('a^'));
      expect(parser, isSuccess('sin(a)'));
      expect(parser, isSuccess('arctan(a, b)'));
      expect(parser, isSuccess('not a'));
      expect(parser, isSuccess('[]'));
      expect(parser, isSuccess('[1]'));
      expect(parser, isSuccess('[1, 2]'));
      expect(parser, isSuccess('[1..2]'));
      expect(parser, isSuccess('[1..2, 3..4]'));
    });
    test('unsigned constant', () {
      final parser = grammar.buildFrom(grammar.unsignedConstant()).end();
      expect(parser, isSuccess('1'));
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess("''"));
      expect(parser, isSuccess('nil'));
    });
    test('parameter list', () {
      final parser = grammar.buildFrom(grammar.parameterList()).end();
      expect(parser, isSuccess(''));
      expect(parser, isSuccess('(a: b)'));
      expect(parser, isSuccess('(a: b; c: d)'));
      expect(parser, isSuccess('(a, b: c)'));
      expect(parser, isSuccess('(var a: b)'));
      expect(parser, isSuccess('(var a: b; var c: d)'));
      expect(parser, isSuccess('(var a, b: c)'));
    });
    test('unsigned integer', () {
      final parser = grammar.buildFrom(grammar.unsignedInteger()).end();
      expect(parser, isSuccess('0', value: 0));
      expect(parser, isSuccess('123', value: 123));
      expect(parser, isSuccess('12345', value: 12345));
    });
    test('constant', () {
      final parser = grammar.buildFrom(grammar.constant()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('+b'));
      expect(parser, isSuccess('-c'));
      expect(parser, isSuccess('1'));
      expect(parser, isSuccess('+2'));
      expect(parser, isSuccess('-3'));
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess("'hello'"));
      expect(parser, isSuccess('nil'));
    });
    test('simple type', () {
      final parser = grammar.buildFrom(grammar.simpleType()).end();
      expect(parser, isSuccess('a'));
      expect(parser, isSuccess('(a)'));
      expect(parser, isSuccess('(a, b)'));
      expect(parser, isSuccess('a..b'));
    });
    test('field list', () {
      final parser = grammar.buildFrom(grammar.fieldList()).end();
      expect(parser, isSuccess('a: b'));
      expect(parser, isSuccess('a: b;'));
      expect(parser, isSuccess('a, b: c'));
      expect(parser, isSuccess('a, b: c;'));
      expect(parser, isSuccess('a: b; c: d'));
      expect(parser, isSuccess('a: b; c: d;'));
      expect(parser, isSuccess('case a of b : (c: d)'));
      expect(parser, isSuccess('case a : b of c : (d: e)'));
      expect(parser, isSuccess('case a of b, c : (d: e)'));
      expect(parser, isSuccess('case a of b : (c: d); e : (f: g)'));
      expect(parser, isSuccess('a: b case c of d : (e: f)'));
    });
  });
  group('grammar', () {
    test('hello world', () {
      expect(
        parser,
        isSuccess(
          [
            "program simple;",
            "begin",
            "  writeln('Hello World!');",
            "end.",
          ].join('\n'),
        ),
      );
    });
    test('comparestrings', () {
      expect(
        parser,
        isSuccess(
          [
            "program comparestrings;",
            "var s: string;",
            "    t: string;"
                "begin",
            "  s := 'something';",
            "  t := 'something bigger';",
            "  if s = t then",
            "    writeln(s, ' is equal to ', t)"
                "  else",
            "    if s > t then",
            "      writeln(s, ' is greater than ', t)",
            "    else",
            "      if s < t then",
            "        writeln(s, ' is less than ', t);",
            "end.",
          ].join('\n'),
        ),
      );
    });
    test('calculate stats', () {
      const code = '''
program CalculateStats(input, output);
const
  MaxElements = 100;
  Threshold = 0.05;
type
  DataArray = array [1..MaxElements] of Real;
var
  data: DataArray;
  n, i: Integer;
  sum, mean: Real;

procedure LoadData(var count: Integer);
begin
  count := 10;
  for i := 1 to count do
    data[i] := i * 1.5;
end;

begin
  LoadData(n);
  sum := 0.0;
  for i := 1 to n do
    sum := sum + data[i];
  mean := sum / n;
  if mean > Threshold then
    WriteLn('Mean exceeds threshold: ', mean)
  else
    WriteLn('Mean is within limits');
end.''';
      expect(parser, isSuccess(code));
    });
    test('geometry demo', () {
      const code = '''
program GeometryDemo;
type
  Point = record
    x, y: Real;
  end;
  Circle = record
    center: Point;
    radius: Real;
  end;
var
  c: Circle;
begin
  c.center.x := 10.0;
  c.center.y := 20.0;
  c.radius := 5.0;
  WriteLn('Circle at (', c.center.x, ', ', c.center.y, ')');
end.''';
      expect(parser, isSuccess(code));
    });
    test('linter', () => expect(linter(parser), isEmpty));
  });

  group('ast parser', () {
    final astParser = PascalParserDefinition().build();

    test('simple program', () {
      final prog =
          astParser.parse('program test; begin writeln(42); end.').value
              as ProgramNode;
      expect(prog.name, 'test');
      expect(prog.parameters, isEmpty);
      expect(prog.block.statement.statements, hasLength(1));
      final stmt =
          prog.block.statement.statements.first as ProcedureStatementNode;
      expect(stmt.name, 'writeln');
      expect(stmt.arguments, hasLength(1));
      final arg = stmt.arguments.first as LiteralExpressionNode;
      expect(arg.value, 42);
    });

    test('program with vars and if', () {
      const code = '''
program calc;
var x, y: Integer;
begin
  x := 10;
  if x > 5 then
    y := x + 1
  else
    y := 0;
end.''';
      final prog = astParser.parse(code).value as ProgramNode;
      expect(prog.name, 'calc');
      expect(prog.block.variables, hasLength(1));
      expect(prog.block.variables.first.names, ['x', 'y']);
      expect(
        (prog.block.variables.first.type as SimpleTypeNode).name,
        'Integer',
      );
      expect(prog.block.statement.statements, hasLength(2));
    });

    test('calculate stats', () {
      const code = '''
program CalculateStats(input, output);
const
  MaxElements = 100;
  Threshold = 0.05;
type
  DataArray = array [1..MaxElements] of Real;
var
  data: DataArray;
  n, i: Integer;
  sum, mean: Real;

procedure LoadData(var count: Integer);
begin
  count := 10;
  for i := 1 to count do
    data[i] := i * 1.5;
end;

begin
  LoadData(n);
  sum := 0.0;
  for i := 1 to n do
    sum := sum + data[i];
  mean := sum / n;
  if mean > Threshold then
    WriteLn('Mean exceeds threshold: ', mean)
  else
    WriteLn('Mean is within limits');
end.''';
      final prog = astParser.parse(code).value as ProgramNode;
      expect(prog.name, 'CalculateStats');
      expect(prog.parameters, ['input', 'output']);
      expect(prog.block.constants, hasLength(2));
      expect(prog.block.types, hasLength(1));
      expect(prog.block.variables, hasLength(3));
      expect(prog.block.subroutines, hasLength(1));
      final proc = prog.block.subroutines.first as ProcedureNode;
      expect(proc.name, 'LoadData');
      expect(proc.parameters, hasLength(1));
      expect(proc.parameters.first.isVar, isTrue);
      expect(prog.block.statement.statements, hasLength(5));
    });

    test('geometry demo', () {
      const code = '''
program GeometryDemo;
type
  Point = record
    x, y: Real;
  end;
  Circle = record
    center: Point;
    radius: Real;
  end;
var
  c: Circle;
begin
  c.center.x := 10.0;
  c.center.y := 20.0;
  c.radius := 5.0;
  WriteLn('Circle at (', c.center.x, ', ', c.center.y, ')');
end.''';
      final prog = astParser.parse(code).value as ProgramNode;
      expect(prog.name, 'GeometryDemo');
      expect(prog.block.types, hasLength(2));
      final pointType = prog.block.types[0].type as RecordTypeNode;
      expect(pointType.fields, hasLength(1));
      expect(pointType.fields.first.names, ['x', 'y']);
      expect(prog.block.variables, hasLength(1));
      expect(prog.block.statement.statements, hasLength(4));
      final lastStmt =
          prog.block.statement.statements.last as ProcedureStatementNode;
      expect(lastStmt.name, 'WriteLn');
      expect(lastStmt.arguments, hasLength(5));
      expect(lastStmt.arguments[1], isA<FieldAccessExpressionNode>());
    });

    test('linter', () => expect(linter(astParser), isEmpty));

    test('failures', () {
      expect(astParser, isFailure(''));
      expect(astParser, isFailure('program;'));
      expect(astParser, isFailure('program foo; begin end'));
      expect(astParser, isFailure('program foo; begin writeln(42); end'));
    });
  });
}

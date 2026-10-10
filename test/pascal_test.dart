import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:test/scaffolding.dart';

import 'utils/checks.dart';

final definition = PascalParserDefinition();
final parser = definition.build();

void main() {
  group('productions', () {
    test('program', () {
      final parser = definition.buildFrom(definition.program()).end();
      check(parser).isSuccess('program foo; begin end.');
      check(parser).isSuccess('program foo(a); begin end.');
      check(parser).isSuccess('program foo(a, b); begin end.');
    });
    test('statement', () {
      final parser = definition.buildFrom(definition.statement()).end();
      check(parser).isSuccess('foo');
      check(parser).isSuccess('foo(1)');
      check(parser).isSuccess('123: a := 1');
      check(parser).isSuccess('123: a(1, 2)');
    });
    test('labelled statements', () {
      final parser = definition.buildFrom(definition.statement()).end();

      final compound =
          parser.parse('10: begin a := 1 end').value as CompoundStatementNode;
      check(compound.label).equals('10');
      check(compound.statements).length.equals(1);

      final ifStmt =
          parser.parse('20: if a > 0 then b := 1').value as IfStatementNode;
      check(ifStmt.label).equals('20');
      check(ifStmt.elseStatement).isNull();

      final caseStmt =
          parser.parse('30: case a of 1: b := 1 end').value
              as CaseStatementNode;
      check(caseStmt.label).equals('30');
      check(caseStmt.cases).length.equals(1);

      final whileStmt =
          parser.parse('40: while a > 0 do a := a - 1').value
              as WhileStatementNode;
      check(whileStmt.label).equals('40');

      final repeatStmt =
          parser.parse('50: repeat a := a + 1 until a > 10').value
              as RepeatStatementNode;
      check(repeatStmt.label).equals('50');

      final forStmt =
          parser.parse('60: for i := 1 to 10 do a := a + 1').value
              as ForStatementNode;
      check(forStmt.label).equals('60');

      final withStmt =
          parser.parse('70: with rec do a := 1').value as WithStatementNode;
      check(withStmt.label).equals('70');

      final gotoStmt = parser.parse('80: goto 99').value as GotoStatementNode;
      check(gotoStmt.label).equals('80');
      check(gotoStmt.targetLabel).equals('99');

      final emptyStmt = parser.parse('90:').value as EmptyStatementNode;
      check(emptyStmt.label).equals('90');
    });
    test('statement assign', () {
      final parser = definition.buildFrom(definition.statementAssign()).end();
      check(parser).isSuccess('a := 1');
      check(parser).isSuccess('a := b');
      check(parser).isSuccess('a := b + 1');
    });
    test('statement call', () {
      final parser = definition.buildFrom(definition.statementCall()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('a(1)');
      check(parser).isSuccess('a(1, 2)');
    });
    test('statement block', () {
      final parser = definition.buildFrom(definition.statementBlock()).end();
      check(parser).isSuccess('begin foo end');
      check(parser).isSuccess('begin foo; bar end');
    });
    test('statement if', () {
      final parser = definition.buildFrom(definition.statementIf()).end();
      check(parser).isSuccess('if a then foo');
      check(parser).isSuccess('if a then foo else bar');
    });
    test('statement repeat', () {
      final parser = definition.buildFrom(definition.statementRepeat()).end();
      check(parser).isSuccess('repeat foo until a');
      check(parser).isSuccess('repeat foo; bar until a');
    });
    test('statement while', () {
      final parser = definition.buildFrom(definition.statementWhile()).end();
      check(parser).isSuccess('while a do foo');
    });
    test('statement for', () {
      final parser = definition.buildFrom(definition.statementFor()).end();
      check(parser).isSuccess('for i := a to b do foo');
      check(parser).isSuccess('for i := a downto b do foo');
    });
    test('statement case', () {
      final parser = definition.buildFrom(definition.statementCase()).end();
      check(parser).isSuccess('case a of 1: foo end');
      check(parser).isSuccess('case a of 1, 2: foo end');
      check(parser).isSuccess('case a of 1: foo; 2: bar end');
    });
    test('statement with', () {
      final parser = definition.buildFrom(definition.statementWith()).end();
      check(parser).isSuccess('with a do a := 1');
      check(parser).isSuccess('with a, b do a := 1');
    });
    test('statement goto', () {
      final parser = definition.buildFrom(definition.statementGoto()).end();
      check(parser).isSuccess('goto 1');
    });
    test('statement exit', () {
      final parser = definition.buildFrom(definition.statementExit()).end();
      check(parser).isSuccess('exit(program)');
      check(parser).isSuccess('exit(foo)');
    });
    test('block', () {
      final parser = definition.buildFrom(definition.block()).end();
      check(parser).isSuccess('begin end');
      check(parser).isSuccess('label 1; begin end');
      check(parser).isSuccess('const a = 1; begin end');
      check(parser).isSuccess('type a = b; begin end');
      check(parser).isSuccess('var a: b; begin end');
      check(parser).isSuccess('procedure foo; begin end; begin end');
      check(parser).isSuccess('function foo: a; begin end; begin end');
    });
    test('block label', () {
      final parser = definition.buildFrom(definition.blockLabel()).end();
      check(parser).isSuccess('label 1;');
      check(parser).isSuccess('label 1, 2;');
    });
    test('block const', () {
      final parser = definition.buildFrom(definition.blockConst()).end();
      check(parser).isSuccess('const a = 1;');
      check(parser).isSuccess('const a = 1; b = 2;');
    });
    test('block type', () {
      final parser = definition.buildFrom(definition.blockType()).end();
      check(parser).isSuccess('type a = b;');
      check(parser).isSuccess('type a = b; c = d;');
    });
    test('block var', () {
      final parser = definition.buildFrom(definition.blockVar()).end();
      check(parser).isSuccess('var a: b;');
      check(parser).isSuccess('var a, b: c;');
      check(parser).isSuccess('var a: b; c: d;');
    });
    test('block procedure', () {
      final parser = definition.buildFrom(definition.blockProcedure()).end();
      check(parser).isSuccess('procedure foo; begin end;');
      check(parser).isSuccess('procedure foo(a: b); begin end;');
      check(parser).isSuccess('procedure foo(a: b); var a: b; begin end;');
    });
    test('block function', () {
      final parser = definition.buildFrom(definition.blockFunction()).end();
      check(parser).isSuccess('function foo: a; begin end;');
      check(parser).isSuccess('function foo(a: b): c; begin end;');
      check(parser).isSuccess('function foo(a: b): c; var a: b; begin end;');
    });
    test('block statement', () {
      final parser = definition.buildFrom(definition.blockStatement()).end();
      check(parser).isSuccess('begin end');
      check(parser).isSuccess('begin foo end');
      check(parser).isSuccess('begin foo; bar end');
    });
    test('type', () {
      final parser = definition.buildFrom(definition.type()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('^a');
      check(parser).isSuccess('packed set of a');
      check(parser).isSuccess('packed array [a] of b');
      check(parser).isSuccess('packed record a: b end');
      check(parser).isSuccess('packed file');
    });
    test('type pointer', () {
      final parser = definition.buildFrom(definition.typePointer()).end();
      check(parser).isSuccess('^a');
    });
    test('type set', () {
      final parser = definition.buildFrom(definition.typeSet()).end();
      check(parser).isSuccess('set of a');
    });
    test('type array', () {
      final parser = definition.buildFrom(definition.typeArray()).end();
      check(parser).isSuccess('array [a] of b');
      check(parser).isSuccess('array [a, b] of c');
    });
    test('type record', () {
      final parser = definition.buildFrom(definition.typeRecord()).end();
      check(parser).isSuccess('record a: b end');
      check(parser).isSuccess('record a, b: c end');
      check(parser).isSuccess('record case a of 1: (b: c) end');
      check(parser).isSuccess('record case a: b of 1: (a: b) end');
      check(parser).isSuccess('record case a of 1, 2: (a: b) end');
      check(parser).isSuccess('record case a of 1: (b: c); 2: (d: e) end');
    });
    test('type file', () {
      final parser = definition.buildFrom(definition.typeFile()).end();
      check(parser).isSuccess('file');
      check(parser).isSuccess('file of a');
    });
    test('identifier', () {
      final parser = definition.buildFrom(definition.identifier()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('abc');
      check(parser).isSuccess('a123');
    });
    test('variable', () {
      final parser = definition.buildFrom(definition.variable()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('a[1]');
      check(parser).isSuccess('a[1,2]');
      check(parser).isSuccess('a[1][2]');
      check(parser).isSuccess('a.b');
      check(parser).isSuccess('a.b.c');
      check(parser).isSuccess('a^');
      check(parser).isSuccess('a^^');
    });
    test('unsigned number', () {
      final parser = definition.buildFrom(definition.unsignedNumber()).end();
      check(parser).isSuccess('0', value: 0);
      check(parser).isSuccess('123', value: 123);
      check(parser).isSuccess('123.456', value: 123.456);
      check(parser).isSuccess('123.456e7', value: 123.456e7);
      check(parser).isSuccess('123.456e+7', value: 123.456e+7);
      check(parser).isSuccess('123e-4', value: 123e-4);
    });
    test('string literal', () {
      final parser = definition.buildFrom(definition.stringLiteral()).end();
      check(parser).isSuccess("''", value: "''");
      check(parser).isSuccess("'whatever'", value: "'whatever'");
      check(parser).isSuccess("'don''t'", value: "'don''t'");
    });
    test('expression', () {
      final parser = definition.buildFrom(definition.expression()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('a = b');
      check(parser).isSuccess('a <> b');
      check(parser).isSuccess('a < b');
      check(parser).isSuccess('a <= b');
      check(parser).isSuccess('a > b');
      check(parser).isSuccess('a >= b');
      check(parser).isSuccess('1 in b');
    });
    test('simple expression', () {
      final parser = definition.buildFrom(definition.simpleExpression()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('+ a');
      check(parser).isSuccess('- a');
      check(parser).isSuccess('a + b');
      check(parser).isSuccess('a - b - c');
      check(parser).isSuccess('a or b');
      check(parser).isSuccess('a or b or c');
    });
    test('term', () {
      final parser = definition.buildFrom(definition.term()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('a * b');
      check(parser).isSuccess('a mod b');
      check(parser).isSuccess('a * b / c');
      check(parser).isSuccess('a and b and c');
    });
    test('factor', () {
      final parser = definition.buildFrom(definition.factor()).end();
      check(parser).isSuccess('1');
      check(parser).isSuccess('a');
      check(parser).isSuccess('a.b');
      check(parser).isSuccess('a.b.c');
      check(parser).isSuccess('a[1]');
      check(parser).isSuccess('a[1, 2]');
      check(parser).isSuccess('a^');
      check(parser).isSuccess('sin(a)');
      check(parser).isSuccess('arctan(a, b)');
      check(parser).isSuccess('not a');
      check(parser).isSuccess('[]');
      check(parser).isSuccess('[1]');
      check(parser).isSuccess('[1, 2]');
      check(parser).isSuccess('[1..2]');
      check(parser).isSuccess('[1..2, 3..4]');
    });
    test('unsigned constant', () {
      final parser = definition.buildFrom(definition.unsignedConstant()).end();
      check(parser).isSuccess('1');
      check(parser).isSuccess('a');
      check(parser).isSuccess("''");
      check(parser).isSuccess('nil');

      final strLit = parser.parse("'Mean exceeds threshold: '").value;
      check(strLit.raw).equals("'Mean exceeds threshold: '");
      check(strLit.value).equals('Mean exceeds threshold: ');

      final escapedStrLit = parser.parse("'don''t'").value;
      check(escapedStrLit.raw).equals("'don''t'");
      check(escapedStrLit.value).equals("don't");
    });
    test('parameter list', () {
      final parser = definition.buildFrom(definition.parameterList()).end();
      check(parser).isSuccess('');
      check(parser).isSuccess('(a: b)');
      check(parser).isSuccess('(a: b; c: d)');
      check(parser).isSuccess('(a, b: c)');
      check(parser).isSuccess('(var a: b)');
      check(parser).isSuccess('(var a: b; var c: d)');
      check(parser).isSuccess('(var a, b: c)');
    });
    test('unsigned integer', () {
      final parser = definition.buildFrom(definition.unsignedInteger()).end();
      check(parser).isSuccess('0', value: 0);
      check(parser).isSuccess('123', value: 123);
      check(parser).isSuccess('12345', value: 12345);
    });
    test('constant', () {
      final parser = definition.buildFrom(definition.constant()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('+b');
      check(parser).isSuccess('-c');
      check(parser).isSuccess('1');
      check(parser).isSuccess('+2');
      check(parser).isSuccess('-3');
      check(parser).isSuccess('a');
      check(parser).isSuccess("'hello'");
      check(parser).isSuccess('nil');
    });
    test('simple type', () {
      final parser = definition.buildFrom(definition.simpleType()).end();
      check(parser).isSuccess('a');
      check(parser).isSuccess('(a)');
      check(parser).isSuccess('(a, b)');
      check(parser).isSuccess('a..b');
    });
    test('field list', () {
      final parser = definition.buildFrom(definition.fieldList()).end();
      check(parser).isSuccess('a: b');
      check(parser).isSuccess('a: b;');
      check(parser).isSuccess('a, b: c');
      check(parser).isSuccess('a, b: c;');
      check(parser).isSuccess('a: b; c: d');
      check(parser).isSuccess('a: b; c: d;');
      check(parser).isSuccess('case a of b : (c: d)');
      check(parser).isSuccess('case a : b of c : (d: e)');
      check(parser).isSuccess('case a of b, c : (d: e)');
      check(parser).isSuccess('case a of b : (c: d); e : (f: g)');
      check(parser).isSuccess('a: b case c of d : (e: f)');
    });
  });
  group('grammar', () {
    test('hello world', () {
      check(parser).isSuccess(
        [
          "program simple;",
          "begin",
          "  writeln('Hello World!');",
          "end.",
        ].join('\n'),
      );
    });
    test('comparestrings', () {
      check(parser).isSuccess(
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
      check(parser).isSuccess(code);
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
      check(parser).isSuccess(code);
    });
    test('linter', () => check(linter(parser)).isEmpty());
  });

  group('ast parser', () {
    test('simple program', () {
      final prog = parser.parse('program test; begin writeln(42); end.').value;
      check(prog.name).equals('test');
      check(prog.parameters).isEmpty();
      check(prog.block.statement.statements).length.equals(1);
      final stmt =
          prog.block.statement.statements.first as ProcedureStatementNode;
      check(stmt.name).equals('writeln');
      check(stmt.arguments).length.equals(1);
      final arg = stmt.arguments.first as LiteralExpressionNode;
      check(arg.value).equals(42);
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
      final prog = parser.parse(code).value;
      check(prog.name).equals('calc');
      check(prog.block.variables).length.equals(1);
      check(prog.block.variables.first.names).deepEquals(['x', 'y']);
      check((prog.block.variables.first.type as SimpleTypeNode).name)
          .equals('Integer');
      check(prog.block.statement.statements).length.equals(2);
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
      final prog = parser.parse(code).value;
      check(prog.name).equals('CalculateStats');
      check(prog.parameters).deepEquals(['input', 'output']);
      check(prog.block.constants).length.equals(2);
      check(prog.block.types).length.equals(1);
      check(prog.block.variables).length.equals(3);
      check(prog.block.subroutines).length.equals(1);
      final proc = prog.block.subroutines.first as ProcedureNode;
      check(proc.name).equals('LoadData');
      check(proc.parameters).length.equals(1);
      check(proc.parameters.first.isVar).isTrue();
      check(prog.block.statement.statements).length.equals(5);
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
      final prog = parser.parse(code).value;
      check(prog.name).equals('GeometryDemo');
      check(prog.block.types).length.equals(2);
      final pointType = prog.block.types[0].type as RecordTypeNode;
      check(pointType.fields).length.equals(1);
      check(pointType.fields.first.names).deepEquals(['x', 'y']);
      check(prog.block.variables).length.equals(1);
      check(prog.block.statement.statements).length.equals(4);
      final lastStmt =
          prog.block.statement.statements.last as ProcedureStatementNode;
      check(lastStmt.name).equals('WriteLn');
      check(lastStmt.arguments).length.equals(5);
      check(lastStmt.arguments[1]).isA<FieldAccessExpressionNode>();
    });

    test('linter', () => check(linter(parser)).isEmpty());

    test('failures', () {
      check(parser).isFailure('');
      check(parser).isFailure('program;');
      check(parser).isFailure('program foo; begin end');
      check(parser).isFailure('program foo; begin writeln(42); end');
    });
  });
}

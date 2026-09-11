import 'package:petitparser_examples/python.dart';
import 'package:test/test.dart';

void main() {
  group('Python AST verification', () {
    test('parsePython produces structured ModuleNode', () {
      final module = parsePython('''
import math

class Point:
    def __init__(self, x: float, y: float):
        self.x = x
        self.y = y

    def distance(self, other: Point) -> float:
        return math.hypot(self.x - other.x, self.y - other.y)

def main():
    p1 = Point(0.0, 0.0)
    p2 = Point(3.0, 4.0)
    print(p1.distance(p2))
''');

      expect(module.body, hasLength(3));

      // 1. Import
      expect(module.body[0], isA<ImportNode>());
      final importNode = module.body[0] as ImportNode;
      expect(importNode.names.first.name, 'math');

      // 2. Class
      expect(module.body[1], isA<ClassDefNode>());
      final classNode = module.body[1] as ClassDefNode;
      expect(classNode.name, 'Point');
      expect(classNode.body, hasLength(2));
      expect(classNode.body[0], isA<FunctionDefNode>());
      expect(classNode.body[1], isA<FunctionDefNode>());

      final initDef = classNode.body[0] as FunctionDefNode;
      expect(initDef.name, '__init__');
      expect(initDef.args.args, hasLength(3));
      expect(initDef.args.args[0].arg, 'self');
      expect(initDef.args.args[1].arg, 'x');
      expect(initDef.args.args[2].arg, 'y');

      final distDef = classNode.body[1] as FunctionDefNode;
      expect(distDef.name, 'distance');
      expect(distDef.returns, isA<NameNode>());
      expect((distDef.returns as NameNode).id, 'float');
      expect(distDef.body.first, isA<ReturnNode>());

      // 3. Function main
      expect(module.body[2], isA<FunctionDefNode>());
      final mainDef = module.body[2] as FunctionDefNode;
      expect(mainDef.name, 'main');
      expect(mainDef.body, hasLength(3));
      expect(mainDef.body[0], isA<AssignNode>());
      expect(mainDef.body[1], isA<AssignNode>());
      expect(mainDef.body[2], isA<ExprStatementNode>());
    });

    test('pattern matching AST', () {
      final module = parsePython('''
match command:
    case "quit":
        exit()
    case ["go", direction]:
        move(direction)
    case _:
        pass
''');
      expect(module.body, hasLength(1));
      expect(module.body.first, isA<MatchNode>());

      final matchNode = module.body.first as MatchNode;
      expect(matchNode.subject, isA<NameNode>());
      expect((matchNode.subject as NameNode).id, 'command');
      expect(matchNode.cases, hasLength(3));

      expect(matchNode.cases[0].pattern, isA<MatchValueNode>());
      expect(matchNode.cases[1].pattern, isA<MatchSequenceNode>());
      expect(matchNode.cases[2].pattern, isA<MatchStarNode>());
    });

    test('PEP 695 generic function AST', () {
      final module = parsePython('''
def identity[T: str](x: T) -> T:
    return x
''');
      expect(module.body, hasLength(1));
      final fn = module.body.first as FunctionDefNode;
      expect(fn.name, 'identity');
      expect(fn.typeParams, hasLength(1));
      expect(fn.typeParams.first, isA<TypeVarParamNode>());
      final tParam = fn.typeParams.first as TypeVarParamNode;
      expect(tParam.name, 'T');
      expect(tParam.bound, isA<NameNode>());
    });
  });
}

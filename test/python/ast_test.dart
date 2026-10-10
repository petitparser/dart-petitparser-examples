import 'package:checks/checks.dart';
import 'package:petitparser_examples/python.dart';
import 'package:test/scaffolding.dart';

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

      check(module.body).length.equals(3);

      // 1. Import
      check(module.body[0]).isA<ImportNode>();
      final importNode = module.body[0] as ImportNode;
      check(importNode.names.first.name).equals('math');

      // 2. Class
      check(module.body[1]).isA<ClassDefNode>();
      final classNode = module.body[1] as ClassDefNode;
      check(classNode.name).equals('Point');
      check(classNode.body).length.equals(2);
      check(classNode.body[0]).isA<FunctionDefNode>();
      check(classNode.body[1]).isA<FunctionDefNode>();

      final initDef = classNode.body[0] as FunctionDefNode;
      check(initDef.name).equals('__init__');
      check(initDef.args.args).length.equals(3);
      check(initDef.args.args[0].arg).equals('self');
      check(initDef.args.args[1].arg).equals('x');
      check(initDef.args.args[2].arg).equals('y');

      final distDef = classNode.body[1] as FunctionDefNode;
      check(distDef.name).equals('distance');
      check(distDef.returns).isA<NameNode>();
      check((distDef.returns as NameNode).id).equals('float');
      check(distDef.body.first).isA<ReturnNode>();

      // 3. Function main
      check(module.body[2]).isA<FunctionDefNode>();
      final mainDef = module.body[2] as FunctionDefNode;
      check(mainDef.name).equals('main');
      check(mainDef.body).length.equals(3);
      check(mainDef.body[0]).isA<AssignNode>();
      check(mainDef.body[1]).isA<AssignNode>();
      check(mainDef.body[2]).isA<ExprStatementNode>();
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
      check(module.body).length.equals(1);
      check(module.body.first).isA<MatchNode>();

      final matchNode = module.body.first as MatchNode;
      check(matchNode.subject).isA<NameNode>();
      check((matchNode.subject as NameNode).id).equals('command');
      check(matchNode.cases).length.equals(3);

      check(matchNode.cases[0].pattern).isA<MatchValueNode>();
      check(matchNode.cases[1].pattern).isA<MatchSequenceNode>();
      check(matchNode.cases[2].pattern).isA<MatchStarNode>();
    });

    test('PEP 695 generic function AST', () {
      final module = parsePython('''
def identity[T: str](x: T) -> T:
    return x
''');
      check(module.body).length.equals(1);
      final fn = module.body.first as FunctionDefNode;
      check(fn.name).equals('identity');
      check(fn.typeParams).length.equals(1);
      check(fn.typeParams.first).isA<TypeVarParamNode>();
      final tParam = fn.typeParams.first as TypeVarParamNode;
      check(tParam.name).equals('T');
      check(tParam.bound).isA<NameNode>();
    });

    group('root and module nodes', () {
      test('ModuleNode', () {
        const node = ModuleNode(body: [PassNode()]);
        check(node.body).length.equals(1);
        check(node.toString()).equals('ModuleNode(body: 1 statements)');
      });

      test('InteractiveNode', () {
        const node = InteractiveNode(body: [PassNode(), BreakNode()]);
        check(node.body).length.equals(2);
        check(node.toString()).equals('InteractiveNode(body: 2 statements)');
      });

      test('ExpressionModuleNode', () {
        const node = ExpressionModuleNode(ConstantNode(42));
        check(node.body).isA<ConstantNode>();
        check(node.toString()).contains('ExpressionModuleNode');
      });
    });

    group('statement nodes', () {
      test('AsyncFunctionDefNode', () {
        const node = AsyncFunctionDefNode(
          name: 'fetch',
          args: ArgumentsNode(),
          body: [PassNode()],
          decoratorList: [NameNode('dec')],
          returns: NameNode('int'),
        );
        check(node.name).equals('fetch');
        check(node.decoratorList).length.equals(1);
        check(node.returns).isA<NameNode>();
        check(node.toString()).contains('AsyncFunctionDefNode(name: fetch');
      });

      test('DeleteNode', () {
        const node = DeleteNode([NameNode('x')]);
        check(node.targets).length.equals(1);
        check(node.toString()).contains('DeleteNode');
      });

      test('AssignNode & AugAssignNode & AnnAssignNode', () {
        const assign = AssignNode(
          targets: [NameNode('x')],
          value: ConstantNode(1),
        );
        check(assign.targets).length.equals(1);
        check(assign.toString()).contains('AssignNode');

        const aug = AugAssignNode(
          target: NameNode('x'),
          operator: '+=',
          value: ConstantNode(2),
        );
        check(aug.operator).equals('+=');
        check(aug.toString())
            .contains('AugAssignNode(NameNode(x) += ConstantNode(2))');

        const ann = AnnAssignNode(
          target: NameNode('x'),
          annotation: NameNode('int'),
          value: ConstantNode(3),
        );
        check(ann.annotation).isA<NameNode>();
        check(ann.toString()).contains('AnnAssignNode');
      });

      test('TypeAliasNode', () {
        const node = TypeAliasNode(
          name: NameNode('Vector'),
          value: NameNode('list'),
          typeParams: [TypeVarParamNode('T')],
        );
        check(node.typeParams).length.equals(1);
        check(node.toString()).contains('TypeAliasNode(name: NameNode(Vector)');
      });

      test('ForNode & AsyncForNode', () {
        const forNode = ForNode(
          target: NameNode('i'),
          iter: NameNode('items'),
          body: [PassNode()],
          orelse: [BreakNode()],
        );
        check(forNode.orelse).length.equals(1);
        check(forNode.toString()).contains('ForNode(target: NameNode(i)');

        const asyncFor = AsyncForNode(
          target: NameNode('x'),
          iter: NameNode('stream'),
          body: [PassNode()],
        );
        check(asyncFor.body).length.equals(1);
        check(asyncFor.toString()).contains('AsyncForNode');
      });

      test('WhileNode & IfNode', () {
        const whileNode = WhileNode(
          test: ConstantNode(true),
          body: [PassNode()],
          orelse: [PassNode()],
        );
        check(whileNode.test).isA<ConstantNode>();
        check(whileNode.toString()).contains('WhileNode');

        const ifNode = IfNode(
          test: ConstantNode(false),
          body: [PassNode()],
          orelse: [ContinueNode()],
        );
        check(ifNode.orelse).length.equals(1);
        check(ifNode.toString()).contains('IfNode');
      });

      test('WithNode & AsyncWithNode', () {
        const withNode = WithNode(
          items: [WithItemNode(contextExpr: NameNode('lock'))],
          body: [PassNode()],
        );
        check(withNode.items).length.equals(1);
        check(withNode.toString()).contains('WithNode');

        const asyncWith = AsyncWithNode(
          items: [WithItemNode(contextExpr: NameNode('async_lock'))],
          body: [PassNode()],
        );
        check(asyncWith.items).length.equals(1);
        check(asyncWith.toString()).contains('AsyncWithNode');
      });

      test('RaiseNode', () {
        const node = RaiseNode(
          exc: NameNode('ValueError'),
          cause: NameNode('err'),
        );
        check(node.exc).isA<NameNode>();
        check(node.cause).isA<NameNode>();
        check(node.toString()).contains('RaiseNode');
      });

      test('TryNode & TryStarNode', () {
        const tryNode = TryNode(
          body: [PassNode()],
          handlers: [
            ExceptHandlerNode(type: NameNode('Exception'), body: [PassNode()]),
          ],
          orelse: [PassNode()],
          finalbody: [PassNode()],
        );
        check(tryNode.handlers).length.equals(1);
        check(tryNode.toString()).contains('TryNode');

        const tryStar = TryStarNode(
          body: [PassNode()],
          handlers: [
            ExceptHandlerNode(
              type: NameNode('ExceptionGroup'),
              body: [PassNode()],
            ),
          ],
        );
        check(tryStar.handlers).length.equals(1);
        check(tryStar.toString()).contains('TryStarNode');
      });

      test('AssertNode', () {
        const node = AssertNode(
          test: ConstantNode(true),
          msg: ConstantNode('failed'),
        );
        check(node.msg).isA<ConstantNode>();
        check(node.toString()).contains('AssertNode');
      });

      test('ImportFromNode', () {
        const node = ImportFromNode(
          module: 'math',
          names: [AliasNode(name: 'sqrt', asname: 'sq')],
          level: 0,
        );
        check(node.module).equals('math');
        check(node.names.first.asname).equals('sq');
        check(node.toString()).contains('ImportFromNode(module: math');
      });

      test('GlobalNode & NonlocalNode', () {
        const g = GlobalNode(['a', 'b']);
        check(g.names).deepEquals(['a', 'b']);
        check(g.toString()).equals('GlobalNode([a, b])');

        const nl = NonlocalNode(['c']);
        check(nl.names).deepEquals(['c']);
        check(nl.toString()).equals('NonlocalNode([c])');
      });

      test('PassNode, BreakNode, ContinueNode', () {
        const p = PassNode();
        const b = BreakNode();
        const c = ContinueNode();
        check(p.toString()).equals('PassNode()');
        check(b.toString()).equals('BreakNode()');
        check(c.toString()).equals('ContinueNode()');
      });
    });

    group('expression nodes', () {
      test('BoolOpNode & NamedExprNode', () {
        const boolOp = BoolOpNode(
          operator: 'and',
          values: [ConstantNode(true), ConstantNode(false)],
        );
        check(boolOp.operator).equals('and');
        check(boolOp.toString()).contains('BoolOpNode(and');

        const named = NamedExprNode(
          target: NameNode('x'),
          value: ConstantNode(10),
        );
        check((named.target as NameNode).id).equals('x');
        check(named.toString()).contains('NamedExprNode');
      });

      test('BinOpNode & UnaryOpNode', () {
        const bin = BinOpNode(
          left: ConstantNode(1),
          operator: '+',
          right: ConstantNode(2),
        );
        check(bin.operator).equals('+');
        check(bin.toString()).contains('BinOpNode');

        const unary = UnaryOpNode(operator: '-', operand: ConstantNode(5));
        check(unary.operator).equals('-');
        check(unary.toString()).contains('UnaryOpNode');
      });

      test('LambdaNode & IfExpNode', () {
        const lambda = LambdaNode(
          args: ArgumentsNode(),
          body: ConstantNode(42),
        );
        check(lambda.body).isA<ConstantNode>();
        check(lambda.toString()).contains('LambdaNode');

        const ifExp = IfExpNode(
          body: ConstantNode(1),
          test: ConstantNode(true),
          orelse: ConstantNode(2),
        );
        check(ifExp.test).isA<ConstantNode>();
        check(ifExp.toString()).contains('IfExpNode');
      });

      test('DictNode & SetNode', () {
        const dict = DictNode(
          keys: [ConstantNode('k')],
          values: [ConstantNode('v')],
        );
        check(dict.keys).length.equals(1);
        check(dict.toString()).contains('DictNode(pairs: 1)');

        const setNode = SetNode(elements: [ConstantNode(1), ConstantNode(2)]);
        check(setNode.elements).length.equals(2);
        check(setNode.toString()).contains('SetNode');
      });

      test('Comprehensions: ListCompNode, SetCompNode, DictCompNode, GeneratorExpNode', () {
        const comp = ComprehensionNode(
          target: NameNode('x'),
          iter: NameNode('xs'),
          ifs: [ConstantNode(true)],
          isAsync: false,
        );
        check(comp.ifs).length.equals(1);
        check(comp.toString()).contains('ComprehensionNode');

        const listComp = ListCompNode(
          element: NameNode('x'),
          generators: [comp],
        );
        check(listComp.generators).length.equals(1);
        check(listComp.toString()).contains('ListCompNode');

        const setComp = SetCompNode(element: NameNode('x'), generators: [comp]);
        check(setComp.generators).length.equals(1);
        check(setComp.toString()).contains('SetCompNode');

        const dictComp = DictCompNode(
          key: NameNode('k'),
          value: NameNode('v'),
          generators: [comp],
        );
        check(dictComp.generators).length.equals(1);
        check(dictComp.toString()).contains('DictCompNode');

        const genExp = GeneratorExpNode(
          element: NameNode('x'),
          generators: [comp],
        );
        check(genExp.generators).length.equals(1);
        check(genExp.toString()).contains('GeneratorExpNode');
      });

      test('AwaitNode, YieldNode, YieldFromNode', () {
        const a = AwaitNode(NameNode('f'));
        check(a.value).isA<NameNode>();
        check(a.toString()).equals('AwaitNode(NameNode(f))');

        const y = YieldNode(ConstantNode(1));
        check(y.value).isA<ConstantNode>();
        check(y.toString()).equals('YieldNode(ConstantNode(1))');

        const yf = YieldFromNode(NameNode('gen'));
        check(yf.value).isA<NameNode>();
        check(yf.toString()).equals('YieldFromNode(NameNode(gen))');
      });

      test('CompareNode', () {
        const cmp = CompareNode(
          left: ConstantNode(1),
          operators: ['<', '<='],
          comparators: [ConstantNode(2), ConstantNode(3)],
        );
        check(cmp.operators).length.equals(2);
        check(cmp.toString()).contains('CompareNode');
      });

      test('CallNode & KeywordNode', () {
        const call = CallNode(
          function: NameNode('func'),
          args: [ConstantNode(1)],
          keywords: [KeywordNode(arg: 'kw', value: ConstantNode(2))],
        );
        check(call.keywords.first.arg).equals('kw');
        check(call.keywords.first.toString())
            .equals('KeywordNode(kw=ConstantNode(2))');
        check(call.toString()).contains('CallNode');
      });

      test('FormattedValueNode & JoinedStrNode', () {
        const fv = FormattedValueNode(
          value: NameNode('x'),
          conversion: 'r',
          formatSpec: '.2f',
        );
        check(fv.conversion).equals('r');
        check(fv.formatSpec).equals('.2f');
        check(fv.toString()).contains('FormattedValueNode');

        const js = JoinedStrNode([ConstantNode('hello')]);
        check(js.values).length.equals(1);
        check(js.toString()).contains('JoinedStrNode');
      });

      test('AttributeNode, SubscriptNode, StarredNode, ListNode, TupleNode, SliceNode', () {
        const attr = AttributeNode(value: NameNode('obj'), attribute: 'prop');
        check(attr.attribute).equals('prop');
        check(attr.toString()).equals('AttributeNode(NameNode(obj).prop)');

        const sub = SubscriptNode(
          value: NameNode('lst'),
          slice: ConstantNode(0),
        );
        check(sub.slice).isA<ConstantNode>();
        check(sub.toString())
            .equals('SubscriptNode(NameNode(lst)[ConstantNode(0)])');

        const starred = StarredNode(NameNode('args'));
        check(starred.value).isA<NameNode>();
        check(starred.toString()).equals('StarredNode(*NameNode(args))');

        const listNode = ListNode(elements: [ConstantNode(1)]);
        check(listNode.elements).length.equals(1);
        check(listNode.toString()).equals('ListNode([ConstantNode(1)])');

        const tupleNode = TupleNode(elements: [ConstantNode(2)]);
        check(tupleNode.elements).length.equals(1);
        check(tupleNode.toString()).equals('TupleNode([ConstantNode(2)])');

        const slice = SliceNode(
          lower: ConstantNode(1),
          upper: ConstantNode(5),
          step: ConstantNode(2),
        );
        check(slice.step).isA<ConstantNode>();
        check(
          slice.toString(),
        ).equals('SliceNode(ConstantNode(1):ConstantNode(5):ConstantNode(2))');
      });
    });

    group('pattern matching nodes', () {
      test('MatchSingletonNode, MatchMappingNode, MatchClassNode, MatchAsNode, MatchOrNode', () {
        const singleton = MatchSingletonNode(null);
        check(singleton.value).isNull();
        check(singleton.toString()).equals('MatchSingletonNode(null)');

        const mapping = MatchMappingNode(
          keys: [ConstantNode('key')],
          patterns: [MatchValueNode(ConstantNode('val'))],
          rest: 'rest',
        );
        check(mapping.rest).equals('rest');
        check(mapping.toString()).contains('MatchMappingNode');

        const cls = MatchClassNode(
          cls: NameNode('Point'),
          patterns: [MatchValueNode(ConstantNode(0))],
          kwdAttrs: ['y'],
          kwdPatterns: [MatchValueNode(ConstantNode(0))],
        );
        check(cls.kwdAttrs).deepEquals(['y']);
        check(cls.toString()).contains('MatchClassNode');

        const asNode = MatchAsNode(
          pattern: MatchValueNode(ConstantNode(1)),
          name: 'x',
        );
        check(asNode.name).equals('x');
        check(asNode.toString()).contains('MatchAsNode');

        const orNode = MatchOrNode([
          MatchValueNode(ConstantNode(1)),
          MatchValueNode(ConstantNode(2)),
        ]);
        check(orNode.patterns).length.equals(2);
        check(orNode.toString()).contains('MatchOrNode');
      });
    });

    group('type parameters and helper nodes', () {
      test('ParamSpecNode & TypeVarTupleNode', () {
        const ps = ParamSpecNode('P', defaultValue: NameNode('int'));
        check(ps.name).equals('P');
        check(ps.defaultValue).isA<NameNode>();
        check(ps.toString()).equals('ParamSpecNode(P)');

        const tvt = TypeVarTupleNode('Ts');
        check(tvt.name).equals('Ts');
        check(tvt.toString()).equals('TypeVarTupleNode(Ts)');
      });

      test('WithItemNode & MatchCaseNode', () {
        const item = WithItemNode(
          contextExpr: NameNode('ctx'),
          optionalVars: NameNode('var'),
        );
        check(item.optionalVars).isA<NameNode>();
        check(item.toString()).contains('WithItemNode');

        const mc = MatchCaseNode(
          pattern: MatchValueNode(ConstantNode(1)),
          guard: ConstantNode(true),
          body: [PassNode()],
        );
        check(mc.guard).isA<ConstantNode>();
        check(mc.toString()).contains('MatchCaseNode');
      });
    });
  });
}

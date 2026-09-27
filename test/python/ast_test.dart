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

    group('root and module nodes', () {
      test('ModuleNode', () {
        const node = ModuleNode(body: [PassNode()]);
        expect(node.body, hasLength(1));
        expect(node.toString(), 'ModuleNode(body: 1 statements)');
      });

      test('InteractiveNode', () {
        const node = InteractiveNode(body: [PassNode(), BreakNode()]);
        expect(node.body, hasLength(2));
        expect(node.toString(), 'InteractiveNode(body: 2 statements)');
      });

      test('ExpressionModuleNode', () {
        const node = ExpressionModuleNode(ConstantNode(42));
        expect(node.body, isA<ConstantNode>());
        expect(node.toString(), contains('ExpressionModuleNode'));
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
        expect(node.name, 'fetch');
        expect(node.decoratorList, hasLength(1));
        expect(node.returns, isA<NameNode>());
        expect(node.toString(), contains('AsyncFunctionDefNode(name: fetch'));
      });

      test('DeleteNode', () {
        const node = DeleteNode([NameNode('x')]);
        expect(node.targets, hasLength(1));
        expect(node.toString(), contains('DeleteNode'));
      });

      test('AssignNode & AugAssignNode & AnnAssignNode', () {
        const assign = AssignNode(
          targets: [NameNode('x')],
          value: ConstantNode(1),
        );
        expect(assign.targets, hasLength(1));
        expect(assign.toString(), contains('AssignNode'));

        const aug = AugAssignNode(
          target: NameNode('x'),
          operator: '+=',
          value: ConstantNode(2),
        );
        expect(aug.operator, '+=');
        expect(
          aug.toString(),
          contains('AugAssignNode(NameNode(x) += ConstantNode(2))'),
        );

        const ann = AnnAssignNode(
          target: NameNode('x'),
          annotation: NameNode('int'),
          value: ConstantNode(3),
        );
        expect(ann.annotation, isA<NameNode>());
        expect(ann.toString(), contains('AnnAssignNode'));
      });

      test('TypeAliasNode', () {
        const node = TypeAliasNode(
          name: NameNode('Vector'),
          value: NameNode('list'),
          typeParams: [TypeVarParamNode('T')],
        );
        expect(node.typeParams, hasLength(1));
        expect(
          node.toString(),
          contains('TypeAliasNode(name: NameNode(Vector)'),
        );
      });

      test('ForNode & AsyncForNode', () {
        const forNode = ForNode(
          target: NameNode('i'),
          iter: NameNode('items'),
          body: [PassNode()],
          orelse: [BreakNode()],
        );
        expect(forNode.orelse, hasLength(1));
        expect(forNode.toString(), contains('ForNode(target: NameNode(i)'));

        const asyncFor = AsyncForNode(
          target: NameNode('x'),
          iter: NameNode('stream'),
          body: [PassNode()],
        );
        expect(asyncFor.body, hasLength(1));
        expect(asyncFor.toString(), contains('AsyncForNode'));
      });

      test('WhileNode & IfNode', () {
        const whileNode = WhileNode(
          test: ConstantNode(true),
          body: [PassNode()],
          orelse: [PassNode()],
        );
        expect(whileNode.test, isA<ConstantNode>());
        expect(whileNode.toString(), contains('WhileNode'));

        const ifNode = IfNode(
          test: ConstantNode(false),
          body: [PassNode()],
          orelse: [ContinueNode()],
        );
        expect(ifNode.orelse, hasLength(1));
        expect(ifNode.toString(), contains('IfNode'));
      });

      test('WithNode & AsyncWithNode', () {
        const withNode = WithNode(
          items: [WithItemNode(contextExpr: NameNode('lock'))],
          body: [PassNode()],
        );
        expect(withNode.items, hasLength(1));
        expect(withNode.toString(), contains('WithNode'));

        const asyncWith = AsyncWithNode(
          items: [WithItemNode(contextExpr: NameNode('async_lock'))],
          body: [PassNode()],
        );
        expect(asyncWith.items, hasLength(1));
        expect(asyncWith.toString(), contains('AsyncWithNode'));
      });

      test('RaiseNode', () {
        const node = RaiseNode(
          exc: NameNode('ValueError'),
          cause: NameNode('err'),
        );
        expect(node.exc, isA<NameNode>());
        expect(node.cause, isA<NameNode>());
        expect(node.toString(), contains('RaiseNode'));
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
        expect(tryNode.handlers, hasLength(1));
        expect(tryNode.toString(), contains('TryNode'));

        const tryStar = TryStarNode(
          body: [PassNode()],
          handlers: [
            ExceptHandlerNode(
              type: NameNode('ExceptionGroup'),
              body: [PassNode()],
            ),
          ],
        );
        expect(tryStar.handlers, hasLength(1));
        expect(tryStar.toString(), contains('TryStarNode'));
      });

      test('AssertNode', () {
        const node = AssertNode(
          test: ConstantNode(true),
          msg: ConstantNode('failed'),
        );
        expect(node.msg, isA<ConstantNode>());
        expect(node.toString(), contains('AssertNode'));
      });

      test('ImportFromNode', () {
        const node = ImportFromNode(
          module: 'math',
          names: [AliasNode(name: 'sqrt', asname: 'sq')],
          level: 0,
        );
        expect(node.module, 'math');
        expect(node.names.first.asname, 'sq');
        expect(node.toString(), contains('ImportFromNode(module: math'));
      });

      test('GlobalNode & NonlocalNode', () {
        const g = GlobalNode(['a', 'b']);
        expect(g.names, ['a', 'b']);
        expect(g.toString(), 'GlobalNode([a, b])');

        const nl = NonlocalNode(['c']);
        expect(nl.names, ['c']);
        expect(nl.toString(), 'NonlocalNode([c])');
      });

      test('PassNode, BreakNode, ContinueNode', () {
        const p = PassNode();
        const b = BreakNode();
        const c = ContinueNode();
        expect(p.toString(), 'PassNode()');
        expect(b.toString(), 'BreakNode()');
        expect(c.toString(), 'ContinueNode()');
      });
    });

    group('expression nodes', () {
      test('BoolOpNode & NamedExprNode', () {
        const boolOp = BoolOpNode(
          operator: 'and',
          values: [ConstantNode(true), ConstantNode(false)],
        );
        expect(boolOp.operator, 'and');
        expect(boolOp.toString(), contains('BoolOpNode(and'));

        const named = NamedExprNode(
          target: NameNode('x'),
          value: ConstantNode(10),
        );
        expect((named.target as NameNode).id, 'x');
        expect(named.toString(), contains('NamedExprNode'));
      });

      test('BinOpNode & UnaryOpNode', () {
        const bin = BinOpNode(
          left: ConstantNode(1),
          operator: '+',
          right: ConstantNode(2),
        );
        expect(bin.operator, '+');
        expect(bin.toString(), contains('BinOpNode'));

        const unary = UnaryOpNode(operator: '-', operand: ConstantNode(5));
        expect(unary.operator, '-');
        expect(unary.toString(), contains('UnaryOpNode'));
      });

      test('LambdaNode & IfExpNode', () {
        const lambda = LambdaNode(
          args: ArgumentsNode(),
          body: ConstantNode(42),
        );
        expect(lambda.body, isA<ConstantNode>());
        expect(lambda.toString(), contains('LambdaNode'));

        const ifExp = IfExpNode(
          body: ConstantNode(1),
          test: ConstantNode(true),
          orelse: ConstantNode(2),
        );
        expect(ifExp.test, isA<ConstantNode>());
        expect(ifExp.toString(), contains('IfExpNode'));
      });

      test('DictNode & SetNode', () {
        const dict = DictNode(
          keys: [ConstantNode('k')],
          values: [ConstantNode('v')],
        );
        expect(dict.keys, hasLength(1));
        expect(dict.toString(), contains('DictNode(pairs: 1)'));

        const setNode = SetNode(elements: [ConstantNode(1), ConstantNode(2)]);
        expect(setNode.elements, hasLength(2));
        expect(setNode.toString(), contains('SetNode'));
      });

      test('Comprehensions: ListCompNode, SetCompNode, DictCompNode, GeneratorExpNode', () {
        const comp = ComprehensionNode(
          target: NameNode('x'),
          iter: NameNode('xs'),
          ifs: [ConstantNode(true)],
          isAsync: false,
        );
        expect(comp.ifs, hasLength(1));
        expect(comp.toString(), contains('ComprehensionNode'));

        const listComp = ListCompNode(
          element: NameNode('x'),
          generators: [comp],
        );
        expect(listComp.generators, hasLength(1));
        expect(listComp.toString(), contains('ListCompNode'));

        const setComp = SetCompNode(element: NameNode('x'), generators: [comp]);
        expect(setComp.generators, hasLength(1));
        expect(setComp.toString(), contains('SetCompNode'));

        const dictComp = DictCompNode(
          key: NameNode('k'),
          value: NameNode('v'),
          generators: [comp],
        );
        expect(dictComp.generators, hasLength(1));
        expect(dictComp.toString(), contains('DictCompNode'));

        const genExp = GeneratorExpNode(
          element: NameNode('x'),
          generators: [comp],
        );
        expect(genExp.generators, hasLength(1));
        expect(genExp.toString(), contains('GeneratorExpNode'));
      });

      test('AwaitNode, YieldNode, YieldFromNode', () {
        const a = AwaitNode(NameNode('f'));
        expect(a.value, isA<NameNode>());
        expect(a.toString(), 'AwaitNode(NameNode(f))');

        const y = YieldNode(ConstantNode(1));
        expect(y.value, isA<ConstantNode>());
        expect(y.toString(), 'YieldNode(ConstantNode(1))');

        const yf = YieldFromNode(NameNode('gen'));
        expect(yf.value, isA<NameNode>());
        expect(yf.toString(), 'YieldFromNode(NameNode(gen))');
      });

      test('CompareNode', () {
        const cmp = CompareNode(
          left: ConstantNode(1),
          operators: ['<', '<='],
          comparators: [ConstantNode(2), ConstantNode(3)],
        );
        expect(cmp.operators, hasLength(2));
        expect(cmp.toString(), contains('CompareNode'));
      });

      test('CallNode & KeywordNode', () {
        const call = CallNode(
          function: NameNode('func'),
          args: [ConstantNode(1)],
          keywords: [KeywordNode(arg: 'kw', value: ConstantNode(2))],
        );
        expect(call.keywords.first.arg, 'kw');
        expect(
          call.keywords.first.toString(),
          'KeywordNode(kw=ConstantNode(2))',
        );
        expect(call.toString(), contains('CallNode'));
      });

      test('FormattedValueNode & JoinedStrNode', () {
        const fv = FormattedValueNode(
          value: NameNode('x'),
          conversion: 'r',
          formatSpec: '.2f',
        );
        expect(fv.conversion, 'r');
        expect(fv.formatSpec, '.2f');
        expect(fv.toString(), contains('FormattedValueNode'));

        const js = JoinedStrNode([ConstantNode('hello')]);
        expect(js.values, hasLength(1));
        expect(js.toString(), contains('JoinedStrNode'));
      });

      test('AttributeNode, SubscriptNode, StarredNode, ListNode, TupleNode, SliceNode', () {
        const attr = AttributeNode(value: NameNode('obj'), attribute: 'prop');
        expect(attr.attribute, 'prop');
        expect(attr.toString(), 'AttributeNode(NameNode(obj).prop)');

        const sub = SubscriptNode(
          value: NameNode('lst'),
          slice: ConstantNode(0),
        );
        expect(sub.slice, isA<ConstantNode>());
        expect(sub.toString(), 'SubscriptNode(NameNode(lst)[ConstantNode(0)])');

        const starred = StarredNode(NameNode('args'));
        expect(starred.value, isA<NameNode>());
        expect(starred.toString(), 'StarredNode(*NameNode(args))');

        const listNode = ListNode(elements: [ConstantNode(1)]);
        expect(listNode.elements, hasLength(1));
        expect(listNode.toString(), 'ListNode([ConstantNode(1)])');

        const tupleNode = TupleNode(elements: [ConstantNode(2)]);
        expect(tupleNode.elements, hasLength(1));
        expect(tupleNode.toString(), 'TupleNode([ConstantNode(2)])');

        const slice = SliceNode(
          lower: ConstantNode(1),
          upper: ConstantNode(5),
          step: ConstantNode(2),
        );
        expect(slice.step, isA<ConstantNode>());
        expect(
          slice.toString(),
          'SliceNode(ConstantNode(1):ConstantNode(5):ConstantNode(2))',
        );
      });
    });

    group('pattern matching nodes', () {
      test('MatchSingletonNode, MatchMappingNode, MatchClassNode, MatchAsNode, MatchOrNode', () {
        const singleton = MatchSingletonNode(null);
        expect(singleton.value, isNull);
        expect(singleton.toString(), 'MatchSingletonNode(null)');

        const mapping = MatchMappingNode(
          keys: [ConstantNode('key')],
          patterns: [MatchValueNode(ConstantNode('val'))],
          rest: 'rest',
        );
        expect(mapping.rest, 'rest');
        expect(mapping.toString(), contains('MatchMappingNode'));

        const cls = MatchClassNode(
          cls: NameNode('Point'),
          patterns: [MatchValueNode(ConstantNode(0))],
          kwdAttrs: ['y'],
          kwdPatterns: [MatchValueNode(ConstantNode(0))],
        );
        expect(cls.kwdAttrs, ['y']);
        expect(cls.toString(), contains('MatchClassNode'));

        const asNode = MatchAsNode(
          pattern: MatchValueNode(ConstantNode(1)),
          name: 'x',
        );
        expect(asNode.name, 'x');
        expect(asNode.toString(), contains('MatchAsNode'));

        const orNode = MatchOrNode([
          MatchValueNode(ConstantNode(1)),
          MatchValueNode(ConstantNode(2)),
        ]);
        expect(orNode.patterns, hasLength(2));
        expect(orNode.toString(), contains('MatchOrNode'));
      });
    });

    group('type parameters and helper nodes', () {
      test('ParamSpecNode & TypeVarTupleNode', () {
        const ps = ParamSpecNode('P', defaultValue: NameNode('int'));
        expect(ps.name, 'P');
        expect(ps.defaultValue, isA<NameNode>());
        expect(ps.toString(), 'ParamSpecNode(P)');

        const tvt = TypeVarTupleNode('Ts');
        expect(tvt.name, 'Ts');
        expect(tvt.toString(), 'TypeVarTupleNode(Ts)');
      });

      test('WithItemNode & MatchCaseNode', () {
        const item = WithItemNode(
          contextExpr: NameNode('ctx'),
          optionalVars: NameNode('var'),
        );
        expect(item.optionalVars, isA<NameNode>());
        expect(item.toString(), contains('WithItemNode'));

        const mc = MatchCaseNode(
          pattern: MatchValueNode(ConstantNode(1)),
          guard: ConstantNode(true),
          body: [PassNode()],
        );
        expect(mc.guard, isA<ConstantNode>());
        expect(mc.toString(), contains('MatchCaseNode'));
      });
    });
  });
}

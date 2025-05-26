import 'package:meta/meta.dart';
import 'package:petitparser/petitparser.dart';
import 'package:petitparser/reflection.dart';
import 'package:petitparser_examples/smalltalk.dart';
import 'package:test/test.dart';

final grammar = SmalltalkGrammarDefinition();
final parser = SmalltalkParserDefinition();

class NodeCollector extends Visitor {
  static List<Node> allNodes(Node node) {
    final visitor = NodeCollector();
    visitor.visit(node);
    return visitor.nodes;
  }

  final List<Node> nodes = [];

  @override
  void visit(Node node) {
    nodes.add(node);
    super.visit(node);
  }
}

dynamic parse(String source, Parser Function() production) {
  final parser = resolve(production()).end();
  final result = parser.parse(source);
  return result.value;
}

@isTest
void verify(
  String name,
  String source,
  Parser Function() grammarProduction,
  Parser Function() parserProduction,
  Matcher parseMatcher,
) {
  group(name, () {
    test('grammar', () => parse(source, grammarProduction));
    test('parser', () {
      final ast = parse(source, parserProduction);
      expect(NodeCollector.allNodes(ast), isNotEmpty);
      expect(ast, parseMatcher);
    });
  });
}

// Node matchers

TypeMatcher<LiteralNode> isLiteralNode(dynamic value) =>
    isA<LiteralNode>().having((node) => node.value, 'value', value);

TypeMatcher<VariableNode> isVariableNode(String name) =>
    isA<VariableNode>().having((node) => node.name, 'name', name);

TypeMatcher<MessageNode> isMessageNode(
  Matcher receiver,
  String selector,
  SelectorType selectorType, {
  List<Matcher> arguments = const [],
}) => isA<MessageNode>()
    .having((node) => node.receiver, 'receiver', receiver)
    .having((node) => node.selector, 'selector', selector)
    .having((node) => node.selectorType, 'selectorType', selectorType)
    .having((node) => node.arguments, 'arguments', arguments);

TypeMatcher<CascadeNode> isCascadeNode(List<Matcher> messages) =>
    isA<CascadeNode>().having((node) => node.messages, 'messages', messages);

TypeMatcher<AssignmentNode> isAssignmentNode(String name, Matcher value) =>
    isA<AssignmentNode>()
        .having((node) => node.variable, 'variable', isVariableNode(name))
        .having((node) => node.value, 'value', value);

TypeMatcher<ArrayNode> isArrayNode({List<Matcher> statements = const []}) =>
    isA<ArrayNode>().having(
      (node) => node.statements,
      'statements',
      statements,
    );

TypeMatcher<SequenceNode> isSequenceNode({
  List<String> temporaries = const [],
  List<Matcher> statements = const [],
}) => isA<SequenceNode>()
    .having(
      (node) => node.temporaries,
      'temporaries',
      temporaries.map(isVariableNode),
    )
    .having((node) => node.statements, 'statements', statements);

TypeMatcher<ReturnNode> isReturnNode(Matcher value) =>
    isA<ReturnNode>().having((node) => node.value, 'value', value);

TypeMatcher<BlockNode> isBlockNode({
  List<String> arguments = const [],
  List<String> temporaries = const [],
  List<Matcher> statements = const [],
}) => isA<BlockNode>()
    .having(
      (node) => node.arguments,
      'arguments',
      arguments.map(isVariableNode),
    )
    .having(
      (node) => node.body,
      'body',
      isSequenceNode(temporaries: temporaries, statements: statements),
    );

TypeMatcher<PragmaNode> isPragmaNode(
  String selector,
  SelectorType selectorType, {
  List<Matcher> arguments = const [],
}) => isA<PragmaNode>()
    .having((node) => node.selector, 'selector', selector)
    .having((node) => node.selectorType, 'selectorType', selectorType)
    .having((node) => node.arguments, 'arguments', arguments);

TypeMatcher<MethodNode> isMethodNode(
  String selector,
  SelectorType selectorType, {
  List<String> arguments = const [],
  List<Matcher> pragmas = const [],
  List<String> temporaries = const [],
  List<Matcher> statements = const [],
}) => isA<MethodNode>()
    .having((node) => node.selector, 'selector', selector)
    .having((node) => node.selectorType, 'selectorType', selectorType)
    .having(
      (node) => node.arguments,
      'arguments',
      arguments.map(isVariableNode),
    )
    .having((node) => node.pragmas, 'pragmas', pragmas)
    .having(
      (node) => node.body,
      'body',
      isSequenceNode(temporaries: temporaries, statements: statements),
    );

void main() {
  group('grammar', () {
    test('start', () {
      parse(r'''
exampleWithNumber: x
  "A method that illustrates every part of Smalltalk method syntax
  except primitives. It has unary, binary, and keyword messages,
  declares arguments and temporaries, accesses a global variable
  (but not and instance variable), uses literals (array, character,
  symbol, string, integer, float), uses the pseudo variables
  true false, nil, self, and super, and has sequence, assignment,
  return and cascade. It has both zero argument and one argument blocks."

  |y|
  y := true & false not & (nil isNil) ifFalse: [self halt].
  self size + super size.
  #($a #a "a" 1 1.0)
      do: [:each | Transcript show: (each class name);
                               show: ' '].
  ^ x < y''', grammar.start);
    });
    test('token', () {
      expect(() => grammar.token(123), throwsArgumentError);
    });
    test('linter', () {
      expect(linter(grammar.build()), isEmpty);
    });
    // All the productions and production actions of the grammar and parser.
    verify('Array1', '{}', grammar.array, parser.array, isArrayNode());
    verify(
      'Array2',
      '{1}',
      grammar.array,
      parser.array,
      isArrayNode(statements: [isLiteralNode(1)]),
    );
    verify(
      'Array3',
      '{1. 2}',
      grammar.array,
      parser.array,
      isArrayNode(statements: [isLiteralNode(1), isLiteralNode(2)]),
    );
    verify(
      'Array4',
      '{1. 2. }',
      grammar.array,
      parser.array,
      isArrayNode(statements: [isLiteralNode(1), isLiteralNode(2)]),
    );
    verify(
      'Assignment1',
      '1',
      grammar.expression,
      parser.expression,
      isLiteralNode(1),
    );
    verify(
      'Assignment2',
      'a := 1',
      grammar.expression,
      parser.expression,
      isAssignmentNode('a', isLiteralNode(1)),
    );
    verify(
      'Assignment3',
      'a := b := 1',
      grammar.expression,
      parser.expression,
      isAssignmentNode('a', isAssignmentNode('b', isLiteralNode(1))),
    );
    verify(
      'Assignment4',
      'a := (b := c)',
      grammar.expression,
      parser.expression,
      isAssignmentNode('a', isAssignmentNode('b', isVariableNode('c'))),
    );
    verify(
      'Comment1',
      '1"one"+2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'Comment2',
      '1 "one" +2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'Comment3',
      '1"one"+"two"2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'Comment4',
      '1"one""two"+2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'Comment5',
      '1"one" "two"+2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'Method1',
      'negated ^ 0 - self',
      grammar.method,
      parser.method,
      isMethodNode(
        'negated',
        SelectorType.unary,
        statements: [
          isReturnNode(
            isMessageNode(
              isLiteralNode(0),
              '-',
              SelectorType.binary,
              arguments: [isVariableNode('self')],
            ),
          ),
        ],
      ),
    );
    verify(
      'Method2',
      '   negated ^ 0 - self',
      grammar.method,
      parser.method,
      isMethodNode(
        'negated',
        SelectorType.unary,
        statements: [
          isReturnNode(
            isMessageNode(
              isLiteralNode(0),
              '-',
              SelectorType.binary,
              arguments: [isVariableNode('self')],
            ),
          ),
        ],
      ),
    );
    verify(
      'Method3',
      ' negated ^ 0 - self  ',
      grammar.method,
      parser.method,
      isMethodNode(
        'negated',
        SelectorType.unary,
        statements: [
          isReturnNode(
            isMessageNode(
              isLiteralNode(0),
              '-',
              SelectorType.binary,
              arguments: [isVariableNode('self')],
            ),
          ),
        ],
      ),
    );
    verify(
      'Sequence1',
      '| a | 1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(temporaries: ['a'], statements: [isLiteralNode(1)]),
    );
    verify(
      'Sequence2',
      '| a | ^ 1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        temporaries: ['a'],
        statements: [isReturnNode(isLiteralNode(1))],
      ),
    );
    verify(
      'Sequence3',
      '| a | 1. ^ 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        temporaries: ['a'],
        statements: [isLiteralNode(1), isReturnNode(isLiteralNode(2))],
      ),
    );
    verify(
      'Statements1',
      '1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1)]),
    );
    verify(
      'Statements2',
      '1 . 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1), isLiteralNode(2)]),
    );
    verify(
      'Statements3',
      '1 . 2 . 3',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        statements: [isLiteralNode(1), isLiteralNode(2), isLiteralNode(3)],
      ),
    );
    verify(
      'Statements4',
      '1 . 2 . 3 .',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        statements: [isLiteralNode(1), isLiteralNode(2), isLiteralNode(3)],
      ),
    );
    verify(
      'Statements5',
      '1 . . 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1), isLiteralNode(2)]),
    );
    verify(
      'Statements6',
      '1. 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1), isLiteralNode(2)]),
    );
    verify(
      'Statements7',
      '. 1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1)]),
    );
    verify(
      'Statements8',
      '.1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isLiteralNode(1)]),
    );
    verify(
      'Statements9',
      'a := 1. b := 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        statements: [
          isAssignmentNode('a', isLiteralNode(1)),
          isAssignmentNode('b', isLiteralNode(2)),
        ],
      ),
    );
    verify(
      'Sequence10',
      '^ 1',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(statements: [isReturnNode(isLiteralNode(1))]),
    );
    verify(
      'Sequence11',
      '1. ^ 2',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(
        statements: [isLiteralNode(1), isReturnNode(isLiteralNode(2))],
      ),
    );
    verify(
      'Temporaries1',
      '| a |',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(temporaries: ['a']),
    );
    verify(
      'Temporaries2',
      '| a b |',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(temporaries: ['a', 'b']),
    );
    verify(
      'Temporaries3',
      '| a b c |',
      grammar.sequence,
      parser.sequence,
      isSequenceNode(temporaries: ['a', 'b', 'c']),
    );
    verify(
      'Variable1',
      'trueBinding',
      grammar.primary,
      parser.primary,
      isVariableNode('trueBinding'),
    );
    verify(
      'Variable2',
      'falseBinding',
      grammar.primary,
      parser.primary,
      isVariableNode('falseBinding'),
    );
    verify(
      'Variable3',
      'nilly',
      grammar.primary,
      parser.primary,
      isVariableNode('nilly'),
    );
    verify(
      'Variable4',
      'selfish',
      grammar.primary,
      parser.primary,
      isVariableNode('selfish'),
    );
    verify(
      'Variable5',
      'superman',
      grammar.primary,
      parser.primary,
      isVariableNode('superman'),
    );
    verify(
      'Variable6',
      'super_nanny',
      grammar.primary,
      parser.primary,
      isVariableNode('super_nanny'),
    );
    verify(
      'Variable7',
      '_gen_var_123_',
      grammar.primary,
      parser.primary,
      isVariableNode('_gen_var_123_'),
    );
    verify(
      'ArgumentsBlock1',
      '[ :a | ]',
      grammar.block,
      parser.block,
      isBlockNode(arguments: ['a']),
    );
    verify(
      'ArgumentsBlock2',
      '[ :a :b | ]',
      grammar.block,
      parser.block,
      isBlockNode(arguments: ['a', 'b']),
    );
    verify(
      'ArgumentsBlock3',
      '[ :a :b :c | ]',
      grammar.block,
      parser.block,
      isBlockNode(arguments: ['a', 'b', 'c']),
    );
    verify(
      'ComplexBlock1',
      '[ :a | | b | c ]',
      grammar.block,
      parser.block,
      isBlockNode(
        arguments: ['a'],
        temporaries: ['b'],
        statements: [isVariableNode('c')],
      ),
    );
    verify(
      'ComplexBlock2',
      '[:a||b|c]',
      grammar.block,
      parser.block,
      isBlockNode(
        arguments: ['a'],
        temporaries: ['b'],
        statements: [isVariableNode('c')],
      ),
    );
    verify('SimpleBlock1', '[ ]', grammar.block, parser.block, isBlockNode());
    verify(
      'SimpleBlock2',
      '[ a ]',
      grammar.block,
      parser.block,
      isBlockNode(statements: [isVariableNode('a')]),
    );
    verify(
      'SimpleBlock3',
      '[ :a ]',
      grammar.block,
      parser.block,
      isBlockNode(arguments: ['a']),
    );
    verify(
      'StatementBlock1',
      '[ 1 ]',
      grammar.block,
      parser.block,
      isBlockNode(statements: [isLiteralNode(1)]),
    );
    verify(
      'StatementBlock2',
      '[ | a | 1 ]',
      grammar.block,
      parser.block,
      isBlockNode(temporaries: ['a'], statements: [isLiteralNode(1)]),
    );
    verify(
      'StatementBlock3',
      '[ | a b | 1 ]',
      grammar.block,
      parser.block,
      isBlockNode(temporaries: ['a', 'b'], statements: [isLiteralNode(1)]),
    );
    verify(
      'ArrayLiteral1',
      '#()',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([]),
    );
    verify(
      'ArrayLiteral2',
      '#(1)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([1]),
    );
    verify(
      'ArrayLiteral3',
      '#(1 2)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([1, 2]),
    );
    verify(
      'ArrayLiteral4',
      '#(true false nil)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([true, false, null]),
    );
    verify(
      'ArrayLiteral5',
      '#(\$a)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode(['a']),
    );
    verify(
      'ArrayLiteral6',
      '#(1.2)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([1.2]),
    );
    verify(
      'ArrayLiteral7',
      "#(size #at: at:put: #'==')",
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode(['size', 'at:', 'at:put:', '==']),
    );
    verify(
      'ArrayLiteral8',
      "#('baz')",
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode(['baz']),
    );
    verify(
      'ArrayLiteral9',
      '#((1) 2)',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([
        [1],
        2,
      ]),
    );
    verify(
      'ArrayLiteral10',
      '#((1 2) #(1 2 3))',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([
        [1, 2],
        [1, 2, 3],
      ]),
    );
    verify(
      'ArrayLiteral11',
      '#([1 2] #[1 2 3])',
      grammar.arrayLiteral,
      parser.arrayLiteral,
      isLiteralNode([
        [1, 2],
        [1, 2, 3],
      ]),
    );
    verify(
      'ByteLiteral1',
      '#[]',
      grammar.byteLiteral,
      parser.byteLiteral,
      isLiteralNode([]),
    );
    verify(
      'ByteLiteral2',
      '#[0]',
      grammar.byteLiteral,
      parser.byteLiteral,
      isLiteralNode([0]),
    );
    verify(
      'ByteLiteral3',
      '#[255]',
      grammar.byteLiteral,
      parser.byteLiteral,
      isLiteralNode([255]),
    );
    verify(
      'ByteLiteral4',
      '#[ 1 2 ]',
      grammar.byteLiteral,
      parser.byteLiteral,
      isLiteralNode([1, 2]),
    );
    verify(
      'ByteLiteral5',
      '#[ 2r1010 8r77 16rFF ]',
      grammar.byteLiteral,
      parser.byteLiteral,
      isLiteralNode([10, 63, 255]),
    );
    verify(
      'CharLiteral1',
      '\$a',
      grammar.characterLiteral,
      parser.characterLiteral,
      isLiteralNode('a'),
    );
    verify(
      'CharLiteral2',
      '\$ ',
      grammar.characterLiteral,
      parser.characterLiteral,
      isLiteralNode(' '),
    );
    verify(
      'CharLiteral3',
      '\$\$',
      grammar.characterLiteral,
      parser.characterLiteral,
      isLiteralNode('\$'),
    );
    verify(
      'NumberLiteral1',
      '0',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(0),
    );
    verify(
      'NumberLiteral2',
      '0.1',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(0.1),
    );
    verify(
      'NumberLiteral3',
      '123',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(123),
    );
    verify(
      'NumberLiteral4',
      '123.456',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(123.456),
    );
    verify(
      'NumberLiteral5',
      '-0',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(0),
    );
    verify(
      'NumberLiteral6',
      '-0.1',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(-0.1),
    );
    verify(
      'NumberLiteral7',
      '-123',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(-123),
    );
    verify(
      'NumberLiteral9',
      '-123.456',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(-123.456),
    );
    verify(
      'NumberLiteral10',
      '10r10',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(10),
    );
    verify(
      'NumberLiteral11',
      '8r777',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(511),
    );
    verify(
      'NumberLiteral12',
      '16rAF',
      grammar.numberLiteral,
      parser.numberLiteral,
      isLiteralNode(175),
    );
    verify(
      'SpecialLiteral1',
      'true',
      grammar.trueLiteral,
      parser.trueLiteral,
      isLiteralNode(true),
    );
    verify(
      'SpecialLiteral2',
      'false',
      grammar.falseLiteral,
      parser.falseLiteral,
      isLiteralNode(false),
    );
    verify(
      'SpecialLiteral3',
      'nil',
      grammar.nilLiteral,
      parser.nilLiteral,
      isLiteralNode(null),
    );
    verify(
      'StringLiteral1',
      "''",
      grammar.stringLiteral,
      parser.stringLiteral,
      isLiteralNode(''),
    );
    verify(
      'StringLiteral2',
      "'ab'",
      grammar.stringLiteral,
      parser.stringLiteral,
      isLiteralNode('ab'),
    );
    verify(
      'StringLiteral3',
      "'ab''cd'",
      grammar.stringLiteral,
      parser.stringLiteral,
      isLiteralNode("ab'cd"),
    );
    verify(
      'SymbolLiteral1',
      '#foo',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('foo'),
    );
    verify(
      'SymbolLiteral2',
      '#+',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('+'),
    );
    verify(
      'SymbolLiteral3',
      '#key:',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('key:'),
    );
    verify(
      'SymbolLiteral4',
      '#key:value:',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('key:value:'),
    );
    verify(
      'SymbolLiteral5',
      "#'ing-result'",
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('ing-result'),
    );
    verify(
      'SymbolLiteral6',
      '#_gen_binding',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('_gen_binding'),
    );
    verify(
      'SymbolLiteral7',
      '# foo',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('foo'),
    );
    verify(
      'SymbolLiteral8',
      '##foo',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('foo'),
    );
    verify(
      'SymbolLiteral9',
      '## foo',
      grammar.symbolLiteral,
      parser.symbolLiteral,
      isLiteralNode('foo'),
    );
    verify(
      'BinaryExpression1',
      '1 + 2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'BinaryExpression2',
      '1 + 2 + 3',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isMessageNode(
          isLiteralNode(1),
          '+',
          SelectorType.binary,
          arguments: [isLiteralNode(2)],
        ),
        '+',
        SelectorType.binary,
        arguments: [isLiteralNode(3)],
      ),
    );
    verify(
      'BinaryExpression3',
      '1 // 2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '//',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'BinaryExpression4',
      '1 -- 2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '--',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'BinaryExpression5',
      '1 ==> 2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        '==>',
        SelectorType.binary,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'BinaryMethod1',
      '+ a',
      grammar.method,
      parser.method,
      isMethodNode('+', SelectorType.binary, arguments: ['a']),
    );
    verify(
      'BinaryMethod2',
      '+ a | b |',
      grammar.method,
      parser.method,
      isMethodNode(
        '+',
        SelectorType.binary,
        arguments: ['a'],
        temporaries: ['b'],
      ),
    );
    verify(
      'BinaryMethod3',
      '+ a b',
      grammar.method,
      parser.method,
      isMethodNode(
        '+',
        SelectorType.binary,
        arguments: ['a'],
        statements: [isVariableNode('b')],
      ),
    );
    verify(
      'BinaryMethod4',
      '+ a | b | c',
      grammar.method,
      parser.method,
      isMethodNode(
        '+',
        SelectorType.binary,
        arguments: ['a'],
        temporaries: ['b'],
        statements: [isVariableNode('c')],
      ),
    );
    verify(
      'BinaryMethod5',
      '-- a',
      grammar.method,
      parser.method,
      isMethodNode('--', SelectorType.binary, arguments: ['a']),
    );
    verify(
      'BinaryPragma1',
      '<& true>',
      grammar.pragma,
      parser.pragma,
      isPragmaNode('&', SelectorType.binary, arguments: [isLiteralNode(true)]),
    );
    verify(
      'BinaryPragma2',
      '<// nil>',
      grammar.pragma,
      parser.pragma,
      isPragmaNode('//', SelectorType.binary, arguments: [isLiteralNode(null)]),
    );
    verify(
      'CascadeExpression1',
      '1 abs; negated',
      grammar.expression,
      parser.expression,
      isCascadeNode([
        isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
        isMessageNode(isLiteralNode(1), 'negated', SelectorType.unary),
      ]),
    );
    verify(
      'CascadeExpression2',
      '1 abs negated; raisedTo: 12; rounded',
      grammar.expression,
      parser.expression,
      isCascadeNode([
        isMessageNode(
          isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
          'negated',
          SelectorType.unary,
        ),
        isMessageNode(
          isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
          'raisedTo:',
          SelectorType.keyword,
          arguments: [isLiteralNode(12)],
        ),
        isMessageNode(
          isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
          'rounded',
          SelectorType.unary,
        ),
      ]),
    );
    verify(
      'CascadeExpression3',
      '1 + 2; - 3',
      grammar.expression,
      parser.expression,
      isCascadeNode([
        isMessageNode(
          isLiteralNode(1),
          '+',
          SelectorType.binary,
          arguments: [isLiteralNode(2)],
        ),
        isMessageNode(
          isLiteralNode(1),
          '-',
          SelectorType.binary,
          arguments: [isLiteralNode(3)],
        ),
      ]),
    );
    verify(
      'KeywordExpression1',
      '1 to: 2',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        'to:',
        SelectorType.keyword,
        arguments: [isLiteralNode(2)],
      ),
    );
    verify(
      'KeywordExpression2',
      '1 to: 2 by: 3',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        'to:by:',
        SelectorType.keyword,
        arguments: [isLiteralNode(2), isLiteralNode(3)],
      ),
    );
    verify(
      'KeywordExpression3',
      '1 to: 2 by: 3 do: 4',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isLiteralNode(1),
        'to:by:do:',
        SelectorType.keyword,
        arguments: [isLiteralNode(2), isLiteralNode(3), isLiteralNode(4)],
      ),
    );
    verify(
      'KeywordMethod1',
      'to: a',
      grammar.method,
      parser.method,
      isMethodNode('to:', SelectorType.keyword, arguments: ['a']),
    );
    verify(
      'KeywordMethod2',
      'to: a do: b | c |',
      grammar.method,
      parser.method,
      isMethodNode(
        'to:do:',
        SelectorType.keyword,
        arguments: ['a', 'b'],
        temporaries: ['c'],
      ),
    );
    verify(
      'KeywordMethod3',
      'to: a do: b by: c d',
      grammar.method,
      parser.method,
      isMethodNode(
        'to:do:by:',
        SelectorType.keyword,
        arguments: ['a', 'b', 'c'],
        statements: [isVariableNode('d')],
      ),
    );
    verify(
      'KeywordMethod4',
      'to: a do: b by: c | d | e',
      grammar.method,
      parser.method,
      isMethodNode(
        'to:do:by:',
        SelectorType.keyword,
        arguments: ['a', 'b', 'c'],
        temporaries: ['d'],
        statements: [isVariableNode('e')],
      ),
    );
    verify(
      'KeywordPragma1',
      '<primitive: 42>',
      grammar.pragma,
      parser.pragma,
      isPragmaNode(
        'primitive:',
        SelectorType.keyword,
        arguments: [isLiteralNode(42)],
      ),
    );
    verify(
      'KeywordPragma2',
      "<primitive: 'fileOpen' error: 0>",
      grammar.pragma,
      parser.pragma,
      isPragmaNode(
        'primitive:error:',
        SelectorType.keyword,
        arguments: [isLiteralNode('fileOpen'), isLiteralNode(0)],
      ),
    );
    verify(
      'UnaryExpression1',
      '1 abs',
      grammar.expression,
      parser.expression,
      isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
    );
    verify(
      'UnaryExpression2',
      '1 abs negated',
      grammar.expression,
      parser.expression,
      isMessageNode(
        isMessageNode(isLiteralNode(1), 'abs', SelectorType.unary),
        'negated',
        SelectorType.unary,
      ),
    );
    verify(
      'UnaryMethod1',
      'abs',
      grammar.method,
      parser.method,
      isMethodNode('abs', SelectorType.unary),
    );
    verify(
      'UnaryMethod2',
      'abs | a |',
      grammar.method,
      parser.method,
      isMethodNode('abs', SelectorType.unary, temporaries: ['a']),
    );
    verify(
      'UnaryMethod3',
      'abs a',
      grammar.method,
      parser.method,
      isMethodNode(
        'abs',
        SelectorType.unary,
        statements: [isVariableNode('a')],
      ),
    );
    verify(
      'UnaryMethod4',
      'abs | a | b',
      grammar.method,
      parser.method,
      isMethodNode(
        'abs',
        SelectorType.unary,
        temporaries: ['a'],
        statements: [isVariableNode('b')],
      ),
    );
    verify(
      'UnaryPragma1',
      '<menu>',
      grammar.pragma,
      parser.pragma,
      isPragmaNode('menu', SelectorType.unary),
    );
    verify(
      'Pragma1',
      'method <foo>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [isPragmaNode('foo', SelectorType.unary)],
      ),
    );
    verify(
      'Pragma2',
      'method <foo> <bar>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode('foo', SelectorType.unary),
          isPragmaNode('bar', SelectorType.unary),
        ],
      ),
    );
    verify(
      'Pragma3',
      'method | a | <foo>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [isPragmaNode('foo', SelectorType.unary)],
        temporaries: ['a'],
      ),
    );
    verify(
      'Pragma4',
      'method <foo> | a |',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [isPragmaNode('foo', SelectorType.unary)],
        temporaries: ['a'],
      ),
    );
    verify(
      'Pragma5',
      'method <foo> | a | <bar>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode('foo', SelectorType.unary),
          isPragmaNode('bar', SelectorType.unary),
        ],
        temporaries: ['a'],
      ),
    );
    verify(
      'Pragma6',
      'method <foo: 1>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode(1)],
          ),
        ],
      ),
    );
    verify(
      'Pragma7',
      'method <foo: 1.2>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode(1.2)],
          ),
        ],
      ),
    );
    verify(
      'Pragma8',
      "method <foo: 'bar'>",
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode('bar')],
          ),
        ],
      ),
    );
    verify(
      'Pragma9',
      "method <foo: #'bar'>",
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode('bar')],
          ),
        ],
      ),
    );
    verify(
      'Pragma10',
      'method <foo: bar>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode('bar')],
          ),
        ],
      ),
    );
    verify(
      'Pragma11',
      'method <foo: true>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode(true)],
          ),
        ],
      ),
    );
    verify(
      'Pragma12',
      'method <foo: false>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode(false)],
          ),
        ],
      ),
    );
    verify(
      'Pragma13',
      'method <foo: nil>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode(null)],
          ),
        ],
      ),
    );
    verify(
      'Pragma14',
      'method <foo: ()>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode([])],
          ),
        ],
      ),
    );
    verify(
      'Pragma15',
      'method <foo: #()>',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode(
            'foo:',
            SelectorType.keyword,
            arguments: [isLiteralNode([])],
          ),
        ],
      ),
    );
    verify(
      'Pragma16',
      'method < + 1 >',
      grammar.method,
      parser.method,
      isMethodNode(
        'method',
        SelectorType.unary,
        pragmas: [
          isPragmaNode('+', SelectorType.binary, arguments: [isLiteralNode(1)]),
        ],
      ),
    );
  });
}

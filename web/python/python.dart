import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/python.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final input = document.querySelector('#input') as HTMLTextAreaElement;
final production = document.querySelector('#production') as HTMLSelectElement;
final action = document.querySelector('#action') as HTMLButtonElement;
final stats = document.querySelector('#stats') as HTMLElement;
final output = document.querySelector('#output') as HTMLElement;

final btnClasses = document.querySelector('#btn-classes') as HTMLButtonElement;
final btnPatterns =
    document.querySelector('#btn-patterns') as HTMLButtonElement;
final btnAsync = document.querySelector('#btn-async') as HTMLButtonElement;
final btnComprehensions =
    document.querySelector('#btn-comprehensions') as HTMLButtonElement;

Parser<Object?> getParser(String prod) {
  final grammar = PythonGrammarDefinition();
  return switch (prod) {
    'statement' => grammar.buildFrom(grammar.statementLine()),
    'expression' => grammar.buildFrom(grammar.expression()),
    'pattern' => grammar.buildFrom(grammar.pythonPattern()),
    _ => grammar.build(),
  };
}

const presets = {
  'classes': '''class Stack[T]:
    """A generic LIFO stack (PEP 695)."""
    def __init__(self) -> None:
        self.items: list[T] = []

    def push(self, item: T) -> None:
        self.items.append(item)

    def pop(self) -> T:
        return self.items.pop()

type NumberList[T: (int, float)] = list[T]''',
  'patterns': '''match command.split():
    case ["quit" | "exit"]:
        print("Goodbye!")
    case ["go", ("north" | "south" | "east" | "west") as direction]:
        player.move(direction)
    case ["drop", *items] if len(items) > 0:
        for item in items:
            player.drop(item)
    case Point(x=0, y=0):
        print("At the origin")
    case {"status": 200, **rest}:
        handle_success(rest)
    case _:
        print("Unknown command")''',
  'async': '''@timed_cache(seconds=60)
@retry(attempts=3)
async def fetch_user_data(user_id: int) -> dict[str, Any]:
    async with aiohttp.ClientSession() as session:
        async for attempt in retries():
            try:
                async with session.get(f"/api/users/{user_id}") as resp:
                    return await resp.json()
            except* ConnectionError as eg:
                log.warning("Connection failure: %s", eg)
                await asyncio.sleep(1)''',
  'comprehensions': '''# Matrix operations & walrus operator
matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]
flattened = [val for row in matrix for val in row if val % 2 == 0]

counts = {word: n for word in words if (n := len(word)) > 3}
squares_gen = (x * x for x in range(100) if x > 10)''',
};

String _nodeName(PythonNode node) => switch (node) {
  ModuleNode() => 'Module',
  InteractiveNode() => 'Interactive',
  ExpressionModuleNode() => 'ExpressionModule',
  FunctionDefNode() => 'FunctionDef',
  AsyncFunctionDefNode() => 'AsyncFunctionDef',
  ClassDefNode() => 'ClassDef',
  ReturnNode() => 'Return',
  DeleteNode() => 'Delete',
  AssignNode() => 'Assign',
  AugAssignNode() => 'AugAssign',
  AnnAssignNode() => 'AnnAssign',
  TypeAliasNode() => 'TypeAlias',
  ForNode() => 'For',
  AsyncForNode() => 'AsyncFor',
  WhileNode() => 'While',
  IfNode() => 'If',
  WithNode() => 'With',
  AsyncWithNode() => 'AsyncWith',
  MatchNode() => 'Match',
  RaiseNode() => 'Raise',
  TryNode() => 'Try',
  TryStarNode() => 'TryStar',
  AssertNode() => 'Assert',
  ImportNode() => 'Import',
  ImportFromNode() => 'ImportFrom',
  GlobalNode() => 'Global',
  NonlocalNode() => 'Nonlocal',
  ExprStatementNode() => 'ExprStatement',
  PassNode() => 'Pass',
  BreakNode() => 'Break',
  ContinueNode() => 'Continue',
  BoolOpNode() => 'BoolOp',
  NamedExprNode() => 'NamedExpr',
  BinOpNode() => 'BinOp',
  UnaryOpNode() => 'UnaryOp',
  LambdaNode() => 'Lambda',
  IfExpNode() => 'IfExp',
  DictNode() => 'Dict',
  SetNode() => 'Set',
  ListCompNode() => 'ListComp',
  SetCompNode() => 'SetComp',
  DictCompNode() => 'DictComp',
  GeneratorExpNode() => 'GeneratorExp',
  AwaitNode() => 'Await',
  YieldNode() => 'Yield',
  YieldFromNode() => 'YieldFrom',
  CompareNode() => 'Compare',
  CallNode() => 'Call',
  FormattedValueNode() => 'FormattedValue',
  JoinedStrNode() => 'JoinedStr',
  ConstantNode() => 'Constant',
  AttributeNode() => 'Attribute',
  SubscriptNode() => 'Subscript',
  StarredNode() => 'Starred',
  NameNode() => 'Name',
  ListNode() => 'List',
  TupleNode() => 'Tuple',
  SliceNode() => 'Slice',
  MatchValueNode() => 'MatchValue',
  MatchSingletonNode() => 'MatchSingleton',
  MatchSequenceNode() => 'MatchSequence',
  MatchMappingNode() => 'MatchMapping',
  MatchClassNode() => 'MatchClass',
  MatchStarNode() => 'MatchStar',
  MatchAsNode() => 'MatchAs',
  MatchOrNode() => 'MatchOr',
  MatchCaseNode() => 'MatchCase',
  ArgumentsNode() => 'Arguments',
  ArgNode() => 'Arg',
  KeywordNode() => 'Keyword',
  AliasNode() => 'Alias',
  WithItemNode() => 'WithItem',
  ExceptHandlerNode() => 'ExceptHandler',
  ComprehensionNode() => 'Comprehension',
  TypeVarParamNode() => 'TypeVarParam',
  TypeVarTupleNode() => 'TypeVarTuple',
  ParamSpecNode() => 'ParamSpec',
};

String formatAst(Object? node, [int indent = 0]) {
  final pad = '  ' * indent;
  if (node == null) return '<span class="node-val">null</span>';
  if (node is num || node is bool) {
    return '<span class="node-val">$node</span>';
  }
  if (node is String) {
    return '<span class="node-str">"${_escape(node)}"</span>';
  }
  if (node is List) {
    if (node.isEmpty) return '[]';
    final items = node
        .map((e) {
          final childPad = '  ' * (indent + 1);
          final formatted = formatAst(e, indent + 1);
          return '$childPad$formatted';
        })
        .join(',\n');
    return '[\n$items\n$pad]';
  }
  if (node is PythonNode) {
    final typeName = _nodeName(node);
    final props = _nodeProperties(node);
    if (props.isEmpty) {
      return '<span class="node-type">$typeName</span>()';
    }
    final buffer = StringBuffer();
    buffer.write('<span class="node-type">$typeName</span>(\n');
    final propStrings = <String>[];
    for (final (name, value) in props) {
      final childPad = '  ' * (indent + 1);
      final formatted = formatAst(value, indent + 1);
      propStrings.add(
        '$childPad<span class="node-prop">$name:</span> $formatted',
      );
    }
    buffer.write(propStrings.join(',\n'));
    buffer.write('\n$pad)');
    return buffer.toString();
  }
  return _escape(node.toString());
}

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

List<(String, Object?)> _nodeProperties(PythonNode node) => switch (node) {
  final ModuleNode n => [('body', n.body)],
  final InteractiveNode n => [('body', n.body)],
  final ExpressionModuleNode n => [('body', n.body)],
  final FunctionDefNode n => [
    ('name', n.name),
    if (n.typeParams.isNotEmpty) ('typeParams', n.typeParams),
    ('args', n.args),
    if (n.returns != null) ('returns', n.returns),
    if (n.decoratorList.isNotEmpty) ('decoratorList', n.decoratorList),
    ('body', n.body),
  ],
  final AsyncFunctionDefNode n => [
    ('name', n.name),
    if (n.typeParams.isNotEmpty) ('typeParams', n.typeParams),
    ('args', n.args),
    if (n.returns != null) ('returns', n.returns),
    if (n.decoratorList.isNotEmpty) ('decoratorList', n.decoratorList),
    ('body', n.body),
  ],
  final ClassDefNode n => [
    ('name', n.name),
    if (n.typeParams.isNotEmpty) ('typeParams', n.typeParams),
    if (n.bases.isNotEmpty) ('bases', n.bases),
    if (n.keywords.isNotEmpty) ('keywords', n.keywords),
    if (n.decoratorList.isNotEmpty) ('decoratorList', n.decoratorList),
    ('body', n.body),
  ],
  final ReturnNode n => [if (n.value != null) ('value', n.value)],
  final DeleteNode n => [('targets', n.targets)],
  final AssignNode n => [('targets', n.targets), ('value', n.value)],
  final AugAssignNode n => [
    ('target', n.target),
    ('op', n.operator),
    ('value', n.value),
  ],
  final AnnAssignNode n => [
    ('target', n.target),
    ('annotation', n.annotation),
    if (n.value != null) ('value', n.value),
  ],
  final TypeAliasNode n => [
    ('name', n.name),
    if (n.typeParams.isNotEmpty) ('typeParams', n.typeParams),
    ('value', n.value),
  ],
  final ForNode n => [
    ('target', n.target),
    ('iter', n.iter),
    ('body', n.body),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
  ],
  final AsyncForNode n => [
    ('target', n.target),
    ('iter', n.iter),
    ('body', n.body),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
  ],
  final WhileNode n => [
    ('test', n.test),
    ('body', n.body),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
  ],
  final IfNode n => [
    ('test', n.test),
    ('body', n.body),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
  ],
  final WithNode n => [('items', n.items), ('body', n.body)],
  final AsyncWithNode n => [('items', n.items), ('body', n.body)],
  final MatchNode n => [('subject', n.subject), ('cases', n.cases)],
  final RaiseNode n => [
    if (n.exc != null) ('exc', n.exc),
    if (n.cause != null) ('cause', n.cause),
  ],
  final TryNode n => [
    ('body', n.body),
    if (n.handlers.isNotEmpty) ('handlers', n.handlers),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
    if (n.finalbody.isNotEmpty) ('finalbody', n.finalbody),
  ],
  final TryStarNode n => [
    ('body', n.body),
    if (n.handlers.isNotEmpty) ('handlers', n.handlers),
    if (n.orelse.isNotEmpty) ('orelse', n.orelse),
    if (n.finalbody.isNotEmpty) ('finalbody', n.finalbody),
  ],
  final AssertNode n => [('test', n.test), if (n.msg != null) ('msg', n.msg)],
  final ImportNode n => [('names', n.names)],
  final ImportFromNode n => [
    if (n.module != null) ('module', n.module),
    ('names', n.names),
    ('level', n.level),
  ],
  final GlobalNode n => [('names', n.names)],
  final NonlocalNode n => [('names', n.names)],
  final ExprStatementNode n => [('value', n.value)],
  final PassNode _ => const [],
  final BreakNode _ => const [],
  final ContinueNode _ => const [],
  final BoolOpNode n => [('op', n.operator), ('values', n.values)],
  final NamedExprNode n => [('target', n.target), ('value', n.value)],
  final BinOpNode n => [
    ('left', n.left),
    ('op', n.operator),
    ('right', n.right),
  ],
  final UnaryOpNode n => [('op', n.operator), ('operand', n.operand)],
  final LambdaNode n => [('args', n.args), ('body', n.body)],
  final IfExpNode n => [
    ('test', n.test),
    ('body', n.body),
    ('orelse', n.orelse),
  ],
  final DictNode n => [
    (
      'pairs',
      List.generate(
        n.values.length,
        (i) => {'key': n.keys[i], 'value': n.values[i]},
      ),
    ),
  ],
  final SetNode n => [('elements', n.elements)],
  final ListCompNode n => [
    ('element', n.element),
    ('generators', n.generators),
  ],
  final SetCompNode n => [('element', n.element), ('generators', n.generators)],
  final DictCompNode n => [
    ('key', n.key),
    ('value', n.value),
    ('generators', n.generators),
  ],
  final GeneratorExpNode n => [
    ('element', n.element),
    ('generators', n.generators),
  ],
  final AwaitNode n => [('value', n.value)],
  final YieldNode n => [if (n.value != null) ('value', n.value)],
  final YieldFromNode n => [('value', n.value)],
  final CompareNode n => [
    ('left', n.left),
    ('operators', n.operators),
    ('comparators', n.comparators),
  ],
  final CallNode n => [
    ('function', n.function),
    if (n.args.isNotEmpty) ('args', n.args),
    if (n.keywords.isNotEmpty) ('keywords', n.keywords),
  ],
  final FormattedValueNode n => [
    ('value', n.value),
    if (n.conversion != null) ('conversion', n.conversion),
    if (n.formatSpec != null) ('formatSpec', n.formatSpec),
  ],
  final JoinedStrNode n => [('values', n.values)],
  final ConstantNode n => [('value', n.value)],
  final AttributeNode n => [('value', n.value), ('attribute', n.attribute)],
  final SubscriptNode n => [('value', n.value), ('slice', n.slice)],
  final StarredNode n => [('value', n.value)],
  final NameNode n => [('id', n.id)],
  final ListNode n => [('elements', n.elements)],
  final TupleNode n => [('elements', n.elements)],
  final SliceNode n => [
    if (n.lower != null) ('lower', n.lower),
    if (n.upper != null) ('upper', n.upper),
    if (n.step != null) ('step', n.step),
  ],
  final MatchValueNode n => [('value', n.value)],
  final MatchSingletonNode n => [('value', n.value)],
  final MatchSequenceNode n => [('patterns', n.patterns)],
  final MatchMappingNode n => [
    ('keys', n.keys),
    ('patterns', n.patterns),
    if (n.rest != null) ('rest', n.rest),
  ],
  final MatchClassNode n => [
    ('cls', n.cls),
    if (n.patterns.isNotEmpty) ('patterns', n.patterns),
    if (n.kwdAttrs.isNotEmpty) ('kwdAttrs', n.kwdAttrs),
    if (n.kwdPatterns.isNotEmpty) ('kwdPatterns', n.kwdPatterns),
  ],
  final MatchStarNode n => [if (n.name != null) ('name', n.name)],
  final MatchAsNode n => [
    if (n.pattern != null) ('pattern', n.pattern),
    if (n.name != null) ('name', n.name),
  ],
  final MatchOrNode n => [('patterns', n.patterns)],
  final MatchCaseNode n => [
    ('pattern', n.pattern),
    if (n.guard != null) ('guard', n.guard),
    ('body', n.body),
  ],
  final ArgumentsNode n => [
    if (n.posonlyargs.isNotEmpty) ('posonlyargs', n.posonlyargs),
    if (n.args.isNotEmpty) ('args', n.args),
    if (n.vararg != null) ('vararg', n.vararg),
    if (n.kwonlyargs.isNotEmpty) ('kwonlyargs', n.kwonlyargs),
    if (n.kwDefaults.isNotEmpty) ('kwDefaults', n.kwDefaults),
    if (n.kwarg != null) ('kwarg', n.kwarg),
    if (n.defaults.isNotEmpty) ('defaults', n.defaults),
  ],
  final ArgNode n => [
    ('arg', n.arg),
    if (n.annotation != null) ('annotation', n.annotation),
  ],
  final KeywordNode n => [
    if (n.arg != null) ('arg', n.arg),
    ('value', n.value),
  ],
  final AliasNode n => [
    ('name', n.name),
    if (n.asname != null) ('asname', n.asname),
  ],
  final WithItemNode n => [
    ('contextExpr', n.contextExpr),
    if (n.optionalVars != null) ('optionalVars', n.optionalVars),
  ],
  final ExceptHandlerNode n => [
    if (n.type != null) ('type', n.type),
    if (n.name != null) ('name', n.name),
    ('body', n.body),
  ],
  final ComprehensionNode n => [
    ('target', n.target),
    ('iter', n.iter),
    if (n.ifs.isNotEmpty) ('ifs', n.ifs),
    if (n.isAsync) ('isAsync', true),
  ],
  final TypeVarParamNode n => [
    ('name', n.name),
    if (n.bound != null) ('bound', n.bound),
  ],
  final TypeVarTupleNode n => [('name', n.name)],
  final ParamSpecNode n => [('name', n.name)],
};

void parseCode() {
  final source = input.value;
  final prod = production.value;
  final parser = getParser(prod).end();

  final watch = Stopwatch()..start();
  final result = parser.parse(source);
  final elapsed = watch.elapsedMicroseconds;

  if (result is Failure) {
    stats.innerHTML = 'Parse failed after <span>$elapsed &micro;s</span>.'.toJS;
    output.className = 'error';
    output.textContent = '${result.message} at ${result.toPositionString()}';
    return;
  }

  final val = result.value;
  stats.innerHTML =
      'Parsed <span>${source.length}</span> characters in <span>$elapsed &micro;s</span>.'
          .toJS;
  output.className = '';
  output.innerHTML = formatAst(val).toJS;
}

void loadPreset(String key, String targetProd) {
  input.value = presets[key] ?? '';
  production.value = targetProd;
  parseCode();
}

void main() {
  initShared();

  btnClasses.onClick.listen((_) => loadPreset('classes', 'module'));
  btnPatterns.onClick.listen((_) => loadPreset('patterns', 'statement'));
  btnAsync.onClick.listen((_) => loadPreset('async', 'module'));
  btnComprehensions.onClick.listen(
    (_) => loadPreset('comprehensions', 'module'),
  );

  action.onClick.listen((_) => parseCode());
  production.onChange.listen((_) => parseCode());
  input.onInput.listen((_) => parseCode());

  // Default preset
  loadPreset('classes', 'module');
}

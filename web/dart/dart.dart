import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/dart.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLTextAreaElement;
final production = document.querySelector('#production') as HTMLSelectElement;
final action = document.querySelector('#action') as HTMLButtonElement;
final stats = document.querySelector('#stats') as HTMLElement;
final output = document.querySelector('#output') as HTMLElement;

final btnClass = document.querySelector('#btn-class') as HTMLButtonElement;
final btnPatterns =
    document.querySelector('#btn-patterns') as HTMLButtonElement;
final btnEnums = document.querySelector('#btn-enums') as HTMLButtonElement;
final btnRecords = document.querySelector('#btn-records') as HTMLButtonElement;

final grammar = DartGrammarDefinition();

Parser<Object?> getParser(String prod) => switch (prod) {
  'statement' => grammar.buildFrom(grammar.statement()),
  'expression' => grammar.buildFrom(grammar.expression()),
  'dartPattern' => grammar.buildFrom(grammar.dartPattern()),
  'type' => grammar.buildFrom(grammar.type()),
  _ => grammar.build(),
};

const presets = {
  'class': '''abstract class Shape<T extends num> {
  const Shape(this.id);

  final String id;
  T get area;

  @override
  String toString() => '\$id: \$area';
}

extension type Pixel(int value) implements int {}''',
  'patterns': '''switch (shape) {
  case Circle(radius: var r) when r > 0:
    print('Circle with radius \$r');
  case [var first, ...var rest] when rest.isNotEmpty:
    print('Multiple elements: \$first');
  case (x: final a, y: final b):
    print('Point(\$a, \$b)');
  default:
    break;
}''',
  'enums': '''enum Status implements Comparable<Status> {
  pending(100),
  active(200),
  completed(300);

  const Status(this.code);
  final int code;

  bool get isDone => this == completed;

  @override
  int compareTo(Status other) => code.compareTo(other.code);
}''',
  'records':
      '''(String, {int count, bool active}) processData(List<num> values) {
  final (sum, avg) = switch (values) {
    [] => (0, 0.0),
    [var single] => (single, single.toDouble()),
    _ => (values.reduce((a, b) => a + b), 0.0),
  };
  return ('Processed \$sum', count: values.length, active: true);
}''',
};

String _nodeName(DartNode node) => switch (node) {
  CompilationUnitNode() => 'CompilationUnit',
  LibraryDirectiveNode() => 'LibraryDirective',
  PartOfDirectiveNode() => 'PartOfDirective',
  PartDirectiveNode() => 'PartDirective',
  ConfigurationUriNode() => 'ConfigurationUri',
  ImportDirectiveNode() => 'ImportDirective',
  ExportDirectiveNode() => 'ExportDirective',
  ShowCombinatorNode() => 'ShowCombinator',
  HideCombinatorNode() => 'HideCombinator',
  ClassDeclarationNode() => 'ClassDeclaration',
  MixinDeclarationNode() => 'MixinDeclaration',
  ExtensionDeclarationNode() => 'ExtensionDeclaration',
  ExtensionTypeDeclarationNode() => 'ExtensionTypeDeclaration',
  EnumDeclarationNode() => 'EnumDeclaration',
  EnumConstantNode() => 'EnumConstant',
  FunctionDeclarationNode() => 'FunctionDeclaration',
  ConstructorDeclarationNode() => 'ConstructorDeclaration',
  SuperConstructorInitializerNode() => 'SuperConstructorInitializer',
  RedirectingConstructorInitializerNode() =>
    'RedirectingConstructorInitializer',
  FieldInitializerNode() => 'FieldInitializer',
  AssertInitializerNode() => 'AssertInitializer',
  FieldDeclarationNode() => 'FieldDeclaration',
  VariableDeclaratorNode() => 'VariableDeclarator',
  SimpleParameterNode() => 'SimpleParameter',
  FunctionTypedParameterNode() => 'FunctionTypedParameter',
  TypeParameterNode() => 'TypeParameter',
  NamedTypeNode() => 'NamedType',
  RecordTypeNode() => 'RecordType',
  RecordTypeFieldNode() => 'RecordTypeField',
  FunctionTypeNode() => 'FunctionType',
  TypeAliasDeclarationNode() => 'TypeAliasDeclaration',
  EmptyStatementNode() => 'EmptyStatement',
  BlockStatementNode() => 'BlockStatement',
  ExpressionStatementNode() => 'ExpressionStatement',
  FunctionDeclarationStatementNode() => 'FunctionDeclarationStatement',
  VariableDeclarationStatementNode() => 'VariableDeclarationStatement',
  PatternVariableDeclarationStatementNode() =>
    'PatternVariableDeclarationStatement',
  IfStatementNode() => 'IfStatement',
  SwitchStatementNode() => 'SwitchStatement',
  SwitchPatternCaseNode() => 'SwitchPatternCase',
  ForStatementNode() => 'ForStatement',
  ForInStatementNode() => 'ForInStatement',
  WhileStatementNode() => 'WhileStatement',
  DoWhileStatementNode() => 'DoWhileStatement',
  TryStatementNode() => 'TryStatement',
  CatchClauseNode() => 'CatchClause',
  ReturnStatementNode() => 'ReturnStatement',
  BreakStatementNode() => 'BreakStatement',
  ContinueStatementNode() => 'ContinueStatement',
  RethrowStatementNode() => 'RethrowStatement',
  YieldStatementNode() => 'YieldStatement',
  AssertStatementNode() => 'AssertStatement',
  LabeledStatementNode() => 'LabeledStatement',
  ConstantPatternNode() => 'ConstantPattern',
  VariablePatternNode() => 'VariablePattern',
  WildcardPatternNode() => 'WildcardPattern',
  RelationalPatternNode() => 'RelationalPattern',
  LogicalPatternNode() => 'LogicalPattern',
  CastPatternNode() => 'CastPattern',
  NullCheckPatternNode() => 'NullCheckPattern',
  NullAssertPatternNode() => 'NullAssertPattern',
  ParenthesizedPatternNode() => 'ParenthesizedPattern',
  ListPatternNode() => 'ListPattern',
  RestPatternNode() => 'RestPattern',
  MapPatternNode() => 'MapPattern',
  MapPatternEntryNode() => 'MapPatternEntry',
  RecordPatternNode() => 'RecordPattern',
  ObjectPatternNode() => 'ObjectPattern',
  PatternFieldNode() => 'PatternField',
  IntegerLiteralNode() => 'IntegerLiteral',
  DoubleLiteralNode() => 'DoubleLiteral',
  BooleanLiteralNode() => 'BooleanLiteral',
  StringLiteralNode() => 'StringLiteral',
  InterpolatedStringNode() => 'InterpolatedString',
  NullLiteralNode() => 'NullLiteral',
  SymbolLiteralNode() => 'SymbolLiteral',
  IdentifierNode() => 'Identifier',
  BinaryExpressionNode() => 'BinaryExpression',
  UnaryExpressionNode() => 'UnaryExpression',
  ConditionalExpressionNode() => 'ConditionalExpression',
  IfNullExpressionNode() => 'IfNullExpression',
  CascadeExpressionNode() => 'CascadeExpression',
  InvocationExpressionNode() => 'InvocationExpression',
  ArgumentNode() => 'Argument',
  PropertyAccessNode() => 'PropertyAccess',
  IndexExpressionNode() => 'IndexExpression',
  ParenthesizedExpressionNode() => 'ParenthesizedExpression',
  ThisExpressionNode() => 'ThisExpression',
  SuperExpressionNode() => 'SuperExpression',
  ThrowExpressionNode() => 'ThrowExpression',
  AwaitExpressionNode() => 'AwaitExpression',
  TypeTestExpressionNode() => 'TypeTestExpression',
  TypeCastExpressionNode() => 'TypeCastExpression',
  SwitchExpressionNode() => 'SwitchExpression',
  SwitchExpressionCaseNode() => 'SwitchExpressionCase',
  CollectionLiteralNode() => 'CollectionLiteral',
  ExpressionElementNode() => 'ExpressionElement',
  MapEntryElementNode() => 'MapEntryElement',
  SpreadElementNode() => 'SpreadElement',
  IfElementNode() => 'IfElement',
  ForElementNode() => 'ForElement',
  ForInElementNode() => 'ForInElement',
  RecordLiteralNode() => 'RecordLiteral',
  RecordLiteralFieldNode() => 'RecordLiteralField',
  FunctionExpressionNode() => 'FunctionExpression',
  BlockFunctionBodyNode() => 'BlockFunctionBody',
  ExpressionFunctionBodyNode() => 'ExpressionFunctionBody',
  EmptyFunctionBodyNode() => 'EmptyFunctionBody',
  AnnotationNode() => 'Annotation',
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
  if (node is DartNode) {
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

List<(String, Object?)> _nodeProperties(DartNode node) => switch (node) {
  final CompilationUnitNode n => [
    if (n.hashbang != null) ('hashbang', n.hashbang),
    if (n.directives.isNotEmpty) ('directives', n.directives),
    if (n.declarations.isNotEmpty) ('declarations', n.declarations),
  ],
  final ImportDirectiveNode n => [
    ('uri', n.uri),
    if (n.asName != null) ('as', n.asName),
    if (n.isDeferred) ('deferred', true),
    if (n.configurations.isNotEmpty) ('configurations', n.configurations),
    if (n.combinators.isNotEmpty) ('combinators', n.combinators),
  ],
  final ExportDirectiveNode n => [
    ('uri', n.uri),
    if (n.configurations.isNotEmpty) ('configurations', n.configurations),
    if (n.combinators.isNotEmpty) ('combinators', n.combinators),
  ],
  final PartDirectiveNode n => [('uri', n.uri)],
  final PartOfDirectiveNode n => [('library', n.library)],
  final LibraryDirectiveNode n => [if (n.name != null) ('name', n.name)],
  final ConfigurationUriNode n => [
    ('name', n.name),
    if (n.value != null) ('value', n.value),
    ('uri', n.uri),
  ],
  final ShowCombinatorNode n => [('identifiers', n.identifiers)],
  final HideCombinatorNode n => [('identifiers', n.identifiers)],
  final ClassDeclarationNode n => [
    ('name', n.name),
    if (n.modifiers.isNotEmpty) ('modifiers', n.modifiers),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    if (n.superclass != null) ('extends', n.superclass),
    if (n.mixins.isNotEmpty) ('with', n.mixins),
    if (n.interfaces.isNotEmpty) ('implements', n.interfaces),
    if (n.members.isNotEmpty) ('members', n.members),
  ],
  final MixinDeclarationNode n => [
    ('name', n.name),
    if (n.isBase) ('base', true),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    if (n.onTypes.isNotEmpty) ('on', n.onTypes),
    if (n.interfaces.isNotEmpty) ('implements', n.interfaces),
    if (n.members.isNotEmpty) ('members', n.members),
  ],
  final ExtensionDeclarationNode n => [
    if (n.name != null) ('name', n.name),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('onType', n.onType),
    if (n.members.isNotEmpty) ('members', n.members),
  ],
  final ExtensionTypeDeclarationNode n => [
    ('name', n.name),
    if (n.isConst) ('const', true),
    if (n.constructorName != null) ('constructorName', n.constructorName),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('representationType', n.representationType),
    ('representationName', n.representationName),
    if (n.interfaces.isNotEmpty) ('implements', n.interfaces),
    if (n.members.isNotEmpty) ('members', n.members),
  ],
  final EnumDeclarationNode n => [
    ('name', n.name),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    if (n.mixins.isNotEmpty) ('mixins', n.mixins),
    if (n.interfaces.isNotEmpty) ('implements', n.interfaces),
    ('constants', n.constants),
    if (n.members.isNotEmpty) ('members', n.members),
  ],
  final EnumConstantNode n => [
    ('name', n.name),
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    if (n.arguments.isNotEmpty) ('arguments', n.arguments),
  ],
  final FunctionDeclarationNode n => [
    ('name', n.name),
    if (n.returnType != null) ('returnType', n.returnType),
    if (n.isGetter) ('getter', true),
    if (n.isSetter) ('setter', true),
    if (n.isOperator) ('operator', true),
    if (n.isStatic) ('static', true),
    if (n.isExternal) ('external', true),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('parameters', n.parameters),
    ('body', n.body),
  ],
  final ConstructorDeclarationNode n => [
    ('name', n.name),
    if (n.constructorName != null) ('constructorName', n.constructorName),
    if (n.isConst) ('const', true),
    if (n.isFactory) ('factory', true),
    if (n.parameters.isNotEmpty) ('parameters', n.parameters),
    if (n.initializers.isNotEmpty) ('initializers', n.initializers),
    if (n.redirectedConstructor != null)
      ('redirected', n.redirectedConstructor),
    ('body', n.body),
  ],
  final SuperConstructorInitializerNode n => [
    if (n.constructorName != null) ('name', n.constructorName),
    if (n.arguments.isNotEmpty) ('arguments', n.arguments),
  ],
  final RedirectingConstructorInitializerNode n => [
    if (n.constructorName != null) ('name', n.constructorName),
    if (n.arguments.isNotEmpty) ('arguments', n.arguments),
  ],
  final FieldInitializerNode n => [
    ('fieldName', n.fieldName),
    if (n.hasThis) ('hasThis', true),
    ('value', n.value),
  ],
  final AssertInitializerNode n => [('assertion', n.assertStatement)],
  final FieldDeclarationNode n => [
    if (n.type != null) ('type', n.type),
    if (n.isStatic) ('static', true),
    if (n.isFinal) ('final', true),
    if (n.isConst) ('const', true),
    if (n.isLate) ('late', true),
    ('variables', n.variables),
  ],
  final VariableDeclaratorNode n => [
    ('name', n.name),
    if (n.initializer != null) ('initializer', n.initializer),
  ],
  final SimpleParameterNode n => [
    if (n.metadata.isNotEmpty) ('metadata', n.metadata),
    ('name', n.name),
    if (n.type != null) ('type', n.type),
    if (n.defaultValue != null) ('defaultValue', n.defaultValue),
    if (n.isNamed) ('named', true),
    if (n.isRequired) ('required', true),
    if (n.isFinal) ('final', true),
    if (n.isVar) ('var', true),
    if (n.isThis) ('this', true),
    if (n.isSuper) ('super', true),
  ],
  final FunctionTypedParameterNode n => [
    if (n.metadata.isNotEmpty) ('metadata', n.metadata),
    ('name', n.name),
    if (n.type != null) ('returnType', n.type),
    ('parameters', n.parameters),
    if (n.defaultValue != null) ('defaultValue', n.defaultValue),
    if (n.isNamed) ('named', true),
    if (n.isRequired) ('required', true),
  ],
  final TypeParameterNode n => [
    ('name', n.name),
    if (n.bound != null) ('bound', n.bound),
  ],
  final NamedTypeNode n => [
    ('name', n.name),
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    if (n.isNullable) ('nullable', true),
  ],
  final RecordTypeNode n => [
    if (n.positionalFields.isNotEmpty) ('positionalFields', n.positionalFields),
    if (n.namedFields.isNotEmpty) ('namedFields', n.namedFields),
    if (n.isNullable) ('nullable', true),
  ],
  final RecordTypeFieldNode n => [
    ('type', n.type),
    if (n.name != null) ('name', n.name),
  ],
  final FunctionTypeNode n => [
    if (n.returnType != null) ('returnType', n.returnType),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('parameters', n.parameters),
    if (n.isNullable) ('nullable', true),
  ],
  final TypeAliasDeclarationNode n => [
    ('name', n.name),
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('type', n.type),
  ],
  final EmptyStatementNode _ => const [],
  final BlockStatementNode n => [('statements', n.statements)],
  final ExpressionStatementNode n => [('expression', n.expression)],
  final FunctionDeclarationStatementNode n => [('declaration', n.declaration)],
  final VariableDeclarationStatementNode n => [
    if (n.type != null) ('type', n.type),
    if (n.isVar) ('var', true),
    if (n.isFinal) ('final', true),
    if (n.isConst) ('const', true),
    if (n.isLate) ('late', true),
    ('variables', n.variables),
  ],
  final PatternVariableDeclarationStatementNode n => [
    ('keyword', n.keyword),
    ('pattern', n.pattern),
    ('expression', n.expression),
  ],
  final IfStatementNode n => [
    ('condition', n.condition),
    if (n.casePattern != null) ('casePattern', n.casePattern),
    if (n.whenGuard != null) ('whenGuard', n.whenGuard),
    ('thenBranch', n.thenBranch),
    if (n.elseBranch != null) ('elseBranch', n.elseBranch),
  ],
  final SwitchStatementNode n => [
    ('expression', n.expression),
    ('cases', n.cases),
  ],
  final SwitchPatternCaseNode n => [
    if (n.labels.isNotEmpty) ('labels', n.labels),
    if (n.isDefault) ('default', true),
    if (n.patterns.isNotEmpty) ('patterns', n.patterns),
    if (n.whenGuard != null) ('whenGuard', n.whenGuard),
    ('statements', n.statements),
  ],
  final ForStatementNode n => [
    if (n.initialization != null) ('init', n.initialization),
    if (n.condition != null) ('condition', n.condition),
    if (n.updates.isNotEmpty) ('updates', n.updates),
    ('body', n.body),
  ],
  final ForInStatementNode n => [
    if (n.variable != null) ('variable', n.variable),
    if (n.pattern != null) ('pattern', n.pattern),
    ('iterable', n.iterable),
    ('body', n.body),
    if (n.isAsync) ('async', true),
  ],
  final WhileStatementNode n => [('condition', n.condition), ('body', n.body)],
  final DoWhileStatementNode n => [
    ('body', n.body),
    ('condition', n.condition),
  ],
  final TryStatementNode n => [
    ('body', n.body),
    if (n.catchClauses.isNotEmpty) ('catchClauses', n.catchClauses),
    if (n.finallyBlock != null) ('finallyBlock', n.finallyBlock),
  ],
  final CatchClauseNode n => [
    if (n.exceptionType != null) ('on', n.exceptionType),
    if (n.exceptionParameter != null) ('catch', n.exceptionParameter),
    if (n.stackTraceParameter != null) ('stack', n.stackTraceParameter),
    ('body', n.body),
  ],
  final ReturnStatementNode n => [
    if (n.expression != null) ('expression', n.expression),
  ],
  final BreakStatementNode n => [if (n.label != null) ('label', n.label)],
  final ContinueStatementNode n => [if (n.label != null) ('label', n.label)],
  final RethrowStatementNode _ => const [],
  final YieldStatementNode n => [
    ('expression', n.expression),
    if (n.isStar) ('star', true),
  ],
  final AssertStatementNode n => [
    ('condition', n.condition),
    if (n.message != null) ('message', n.message),
  ],
  final LabeledStatementNode n => [
    ('label', n.label),
    ('statement', n.statement),
  ],
  final ConstantPatternNode n => [('expression', n.expression)],
  final VariablePatternNode n => [
    ('name', n.name),
    if (n.type != null) ('type', n.type),
    if (n.isVar) ('var', true),
    if (n.isFinal) ('final', true),
  ],
  final WildcardPatternNode n => [if (n.type != null) ('type', n.type)],
  final RelationalPatternNode n => [
    ('operator', n.operator),
    ('operand', n.operand),
  ],
  final LogicalPatternNode n => [
    ('left', n.left),
    ('operator', n.operator),
    ('right', n.right),
  ],
  final CastPatternNode n => [('pattern', n.pattern), ('type', n.type)],
  final NullCheckPatternNode n => [('pattern', n.pattern)],
  final NullAssertPatternNode n => [('pattern', n.pattern)],
  final ParenthesizedPatternNode n => [('pattern', n.pattern)],
  final ListPatternNode n => [
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    ('elements', n.elements),
  ],
  final RestPatternNode n => [
    if (n.subPattern != null) ('subPattern', n.subPattern),
  ],
  final MapPatternNode n => [
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    ('entries', n.entries),
  ],
  final MapPatternEntryNode n => [('key', n.key), ('value', n.value)],
  final RecordPatternNode n => [('fields', n.fields)],
  final ObjectPatternNode n => [('type', n.type), ('fields', n.fields)],
  final PatternFieldNode n => [
    if (n.name != null) ('name', n.name),
    ('pattern', n.pattern),
  ],
  final IntegerLiteralNode n => [('value', n.value)],
  final DoubleLiteralNode n => [('value', n.value)],
  final BooleanLiteralNode n => [('value', n.value)],
  final StringLiteralNode n => [('value', n.value), if (n.isRaw) ('raw', true)],
  final InterpolatedStringNode n => [('parts', n.parts)],
  final NullLiteralNode _ => const [],
  final SymbolLiteralNode n => [('value', n.value)],
  final IdentifierNode n => [('name', n.name)],
  final BinaryExpressionNode n => [
    ('left', n.left),
    ('operator', n.operator),
    ('right', n.right),
  ],
  final UnaryExpressionNode n => [
    ('operator', n.operator),
    ('operand', n.operand),
    if (!n.isPrefix) ('isPrefix', false),
  ],
  final ConditionalExpressionNode n => [
    ('condition', n.condition),
    ('then', n.thenExpression),
    ('else', n.elseExpression),
  ],
  final IfNullExpressionNode n => [('left', n.left), ('right', n.right)],
  final CascadeExpressionNode n => [
    ('target', n.target),
    ('sections', n.cascadeSections),
    if (n.isNullAware) ('nullAware', true),
  ],
  final InvocationExpressionNode n => [
    ('target', n.target),
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    if (n.arguments.isNotEmpty) ('arguments', n.arguments),
  ],
  final ArgumentNode n => [
    if (n.name != null) ('name', n.name),
    ('value', n.value),
  ],
  final PropertyAccessNode n => [
    ('target', n.target),
    ('propertyName', n.propertyName),
    if (n.isNullAware) ('nullAware', true),
  ],
  final IndexExpressionNode n => [
    ('target', n.target),
    ('index', n.index),
    if (n.isNullAware) ('nullAware', true),
  ],
  final ParenthesizedExpressionNode n => [('expression', n.expression)],
  final ThisExpressionNode _ => const [],
  final SuperExpressionNode _ => const [],
  final ThrowExpressionNode n => [('expression', n.expression)],
  final AwaitExpressionNode n => [('expression', n.expression)],
  final TypeTestExpressionNode n => [
    ('expression', n.expression),
    ('type', n.type),
    if (n.isNegated) ('isNegated', true),
  ],
  final TypeCastExpressionNode n => [
    ('expression', n.expression),
    ('type', n.type),
  ],
  final SwitchExpressionNode n => [
    ('expression', n.expression),
    ('cases', n.cases),
  ],
  final SwitchExpressionCaseNode n => [
    ('pattern', n.pattern),
    if (n.whenGuard != null) ('whenGuard', n.whenGuard),
    ('body', n.body),
  ],
  final CollectionLiteralNode n => [
    if (n.isConst) ('const', true),
    if (n.typeArguments.isNotEmpty) ('typeArguments', n.typeArguments),
    ('elements', n.elements),
  ],
  final ExpressionElementNode n => [
    if (n.isNullAware) ('nullAware', true),
    ('expression', n.expression),
  ],
  final MapEntryElementNode n => [
    if (n.isKeyNullAware) ('keyNullAware', true),
    ('key', n.key),
    if (n.isValueNullAware) ('valueNullAware', true),
    ('value', n.value),
  ],
  final SpreadElementNode n => [
    if (n.isNullAware) ('nullAware', true),
    ('expression', n.expression),
  ],
  final IfElementNode n => [
    ('condition', n.condition),
    if (n.casePattern != null) ('casePattern', n.casePattern),
    if (n.whenGuard != null) ('whenGuard', n.whenGuard),
    ('then', n.thenElement),
    if (n.elseElement != null) ('else', n.elseElement),
  ],
  final ForElementNode n => [
    if (n.initialization != null) ('init', n.initialization),
    if (n.condition != null) ('condition', n.condition),
    if (n.updates.isNotEmpty) ('updates', n.updates),
    ('body', n.body),
  ],
  final ForInElementNode n => [
    if (n.variable != null) ('variable', n.variable),
    if (n.pattern != null) ('pattern', n.pattern),
    ('iterable', n.iterable),
    ('body', n.body),
    if (n.isAsync) ('async', true),
  ],
  final RecordLiteralNode n => [
    if (n.isConst) ('const', true),
    ('fields', n.fields),
  ],
  final RecordLiteralFieldNode n => [
    if (n.name != null) ('name', n.name),
    ('value', n.value),
  ],
  final FunctionExpressionNode n => [
    if (n.typeParameters.isNotEmpty) ('typeParameters', n.typeParameters),
    ('parameters', n.parameters),
    ('body', n.body),
  ],
  final BlockFunctionBodyNode n => [('block', n.block)],
  final ExpressionFunctionBodyNode n => [('expression', n.expression)],
  final EmptyFunctionBodyNode _ => const [],
  final AnnotationNode n => [
    ('name', n.name),
    if (n.arguments.isNotEmpty) ('arguments', n.arguments),
  ],
};

void parseCode() {
  final source = input.value;
  final prod = production.value;
  final parser = getParser(prod).end();

  final watch = Stopwatch()..start();
  final result = parser.parse(source);
  final elapsed = watch.elapsedMicroseconds;

  if (result is Failure) {
    stats.innerHTML = 'Parse failed in <span>$elapsedμs</span>'.toJS;
    output.innerHTML =
        '<div class="error">ParserException: ${result.message}\nat line ${result.toPositionString()}</div>'
            .toJS;
    return;
  }

  final val = result.value;
  stats.innerHTML =
      'Parsed successfully in <span>$elapsedμs</span> (Length: <span>${source.length}</span> chars)'
          .toJS;
  output.innerHTML = '<div id="ast-output">${formatAst(val)}</div>'.toJS;
}

void loadPreset(String key, String targetProd) {
  input.value = presets[key] ?? '';
  production.value = targetProd;
  parseCode();
}

void main() {
  btnClass.onClick.listen((_) => loadPreset('class', 'compilationUnit'));
  btnPatterns.onClick.listen((_) => loadPreset('patterns', 'statement'));
  btnEnums.onClick.listen((_) => loadPreset('enums', 'compilationUnit'));
  btnRecords.onClick.listen((_) => loadPreset('records', 'compilationUnit'));

  action.onClick.listen((_) => parseCode());
  production.onChange.listen((_) => parseCode());

  // Default preset
  loadPreset('class', 'compilationUnit');
}

import 'package:meta/meta.dart';

/// Base class for all Dart AST nodes.
@immutable
sealed class DartNode {
  const new();
}

/// An annotation / metadata (`@deprecated`, `@override`, `@Route('/path')`).
class AnnotationNode extends DartNode {
  const new({required this.name, this.arguments = const []});

  final String name;
  final List<ArgumentNode> arguments;

  @override
  String toString() =>
      'AnnotationNode(@$name${arguments.isNotEmpty ? '($arguments)' : ''})';
}

// ---------------------------------------------------------------------------
// Declarations & Directives
// ---------------------------------------------------------------------------

/// Base class for all top-level and class-level declarations.
sealed class DeclarationNode extends DartNode {
  const new();
}

/// A complete Dart compilation unit (source file).
class CompilationUnitNode extends DartNode {
  const new({
    this.hashbang,
    this.directives = const [],
    this.declarations = const [],
  });

  final String? hashbang;
  final List<DirectiveNode> directives;
  final List<DeclarationNode> declarations;

  @override
  String toString() =>
      'CompilationUnitNode(directives: ${directives.length}, declarations: ${declarations.length})';
}

/// Base class for library directives.
sealed class DirectiveNode extends DartNode {
  const new();
}

/// A library directive (`library;` or `library foo.bar;`).
class LibraryDirectiveNode extends DirectiveNode {
  const new([this.name]);
  final String? name;

  @override
  String toString() => 'LibraryDirectiveNode($name)';
}

/// A part-of directive (`part of foo;` or `part of 'foo.dart';`).
class PartOfDirectiveNode extends DirectiveNode {
  const new(this.library);
  final String library;

  @override
  String toString() => 'PartOfDirectiveNode($library)';
}

/// A part directive (`part 'foo.dart';`).
class PartDirectiveNode extends DirectiveNode {
  const new(this.uri);
  final String uri;

  @override
  String toString() => 'PartDirectiveNode($uri)';
}

/// A conditional configuration in a configurable URI (`if (dart.library.io) 'foo.dart'`).
class ConfigurationUriNode extends DartNode {
  const new({required this.name, this.value, required this.uri});

  final String name;
  final String? value;
  final String uri;

  @override
  String toString() =>
      'ConfigurationUriNode(if ($name${value != null ? ' == "$value"' : ''}) $uri)';
}

/// An import directive (`import 'foo.dart' deferred as f show a, b;`).
class ImportDirectiveNode extends DirectiveNode {
  const new({
    required this.uri,
    this.configurations = const [],
    this.isDeferred = false,
    this.asName,
    this.combinators = const [],
  });

  final String uri;
  final List<ConfigurationUriNode> configurations;
  final bool isDeferred;
  final String? asName;
  final List<CombinatorNode> combinators;

  @override
  String toString() => 'ImportDirectiveNode($uri, as: $asName)';
}

/// An export directive (`export 'foo.dart' show a, b;`).
class ExportDirectiveNode extends DirectiveNode {
  const new({
    required this.uri,
    this.configurations = const [],
    this.combinators = const [],
  });

  final String uri;
  final List<ConfigurationUriNode> configurations;
  final List<CombinatorNode> combinators;

  @override
  String toString() => 'ExportDirectiveNode($uri)';
}

/// Base class for import/export combinators (`show` and `hide`).
sealed class CombinatorNode extends DartNode {
  const new(this.identifiers);
  final List<String> identifiers;
}

/// A show combinator (`show a, b`).
class ShowCombinatorNode extends CombinatorNode {
  const new(super.identifiers);

  @override
  String toString() => 'ShowCombinatorNode($identifiers)';
}

/// A hide combinator (`hide a, b`).
class HideCombinatorNode extends CombinatorNode {
  const new(super.identifiers);

  @override
  String toString() => 'HideCombinatorNode($identifiers)';
}

/// A class declaration.
class ClassDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.modifiers = const [],
    this.typeParameters = const [],
    this.superclass,
    this.mixins = const [],
    this.interfaces = const [],
    this.members = const [],
  });

  final String name;
  final List<String> modifiers;
  final List<TypeParameterNode> typeParameters;
  final TypeNode? superclass;
  final List<TypeNode> mixins;
  final List<TypeNode> interfaces;
  final List<DeclarationNode> members;

  @override
  String toString() => 'ClassDeclarationNode($name, modifiers: $modifiers)';
}

/// A mixin declaration.
class MixinDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.isBase = false,
    this.typeParameters = const [],
    this.onTypes = const [],
    this.interfaces = const [],
    this.members = const [],
  });

  final String name;
  final bool isBase;
  final List<TypeParameterNode> typeParameters;
  final List<TypeNode> onTypes;
  final List<TypeNode> interfaces;
  final List<DeclarationNode> members;

  @override
  String toString() => 'MixinDeclarationNode($name)';
}

/// An extension declaration (`extension Foo<T> on Bar { ... }`).
class ExtensionDeclarationNode extends DeclarationNode {
  const new({
    this.name,
    this.typeParameters = const [],
    required this.onType,
    this.members = const [],
  });

  final String? name;
  final List<TypeParameterNode> typeParameters;
  final TypeNode onType;
  final List<DeclarationNode> members;

  @override
  String toString() => 'ExtensionDeclarationNode($name, on: $onType)';
}

/// An extension type declaration (`extension type Foo(int i) { ... }`).
class ExtensionTypeDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.constructorName,
    this.isConst = false,
    this.typeParameters = const [],
    required this.representationType,
    required this.representationName,
    this.interfaces = const [],
    this.members = const [],
  });

  final String name;
  final String? constructorName;
  final bool isConst;
  final List<TypeParameterNode> typeParameters;
  final TypeNode representationType;
  final String representationName;
  final List<TypeNode> interfaces;
  final List<DeclarationNode> members;

  @override
  String toString() =>
      'ExtensionTypeDeclarationNode($name${constructorName != null ? '.$constructorName' : ''}, rep: $representationType $representationName)';
}

/// An enum declaration (`enum Foo { a, b; void bar() {} }`).
class EnumDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.typeParameters = const [],
    this.mixins = const [],
    this.interfaces = const [],
    this.constants = const [],
    this.members = const [],
  });

  final String name;
  final List<TypeParameterNode> typeParameters;
  final List<TypeNode> mixins;
  final List<TypeNode> interfaces;
  final List<EnumConstantNode> constants;
  final List<DeclarationNode> members;

  @override
  String toString() => 'EnumDeclarationNode($name, constants: $constants)';
}

/// An enum constant entry.
class EnumConstantNode extends DartNode {
  const new({
    required this.name,
    this.arguments = const [],
    this.typeArguments = const [],
  });

  final String name;
  final List<ArgumentNode> arguments;
  final List<TypeNode> typeArguments;

  @override
  String toString() => 'EnumConstantNode($name)';
}

/// A function or method declaration.
class FunctionDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.returnType,
    this.typeParameters = const [],
    this.parameters = const [],
    this.body,
    this.isStatic = false,
    this.isAbstract = false,
    this.isExternal = false,
    this.isGetter = false,
    this.isSetter = false,
    this.isOperator = false,
  });

  final String name;
  final TypeNode? returnType;
  final List<TypeParameterNode> typeParameters;
  final List<ParameterNode> parameters;
  final FunctionBodyNode? body;
  final bool isStatic;
  final bool isAbstract;
  final bool isExternal;
  final bool isGetter;
  final bool isSetter;
  final bool isOperator;

  @override
  String toString() => 'FunctionDeclarationNode($name)';
}

/// A constructor declaration.
class ConstructorDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.constructorName,
    this.parameters = const [],
    this.initializers = const [],
    this.body,
    this.isConst = false,
    this.isFactory = false,
    this.isExternal = false,
    this.redirectedConstructor,
  });

  final String name;
  final String? constructorName;
  final List<ParameterNode> parameters;
  final List<ConstructorInitializerNode> initializers;
  final FunctionBodyNode? body;
  final bool isConst;
  final bool isFactory;
  final bool isExternal;
  final String? redirectedConstructor;

  @override
  String toString() =>
      'ConstructorDeclarationNode($name${constructorName != null ? '.$constructorName' : ''})';
}

/// Base class for constructor initializer list entries.
sealed class ConstructorInitializerNode extends DartNode {
  const new();
}

/// A super constructor call in an initializer list (`super(...)` or `super.named(...)`).
class SuperConstructorInitializerNode extends ConstructorInitializerNode {
  const new({this.constructorName, this.arguments = const []});

  final String? constructorName;
  final List<ArgumentNode> arguments;

  @override
  String toString() => 'SuperConstructorInitializerNode($constructorName)';
}

/// A redirecting constructor call in an initializer list (`this(...)` or `this.named(...)`).
class RedirectingConstructorInitializerNode extends ConstructorInitializerNode {
  const new({this.constructorName, this.arguments = const []});

  final String? constructorName;
  final List<ArgumentNode> arguments;

  @override
  String toString() =>
      'RedirectingConstructorInitializerNode($constructorName)';
}

/// A field initializer in an initializer list (`field = expr` or `this.field = expr`).
class FieldInitializerNode extends ConstructorInitializerNode {
  const new({
    required this.fieldName,
    required this.value,
    this.hasThis = false,
  });

  final String fieldName;
  final ExpressionNode value;
  final bool hasThis;

  @override
  String toString() => 'FieldInitializerNode($fieldName = $value)';
}

/// An assert statement in an initializer list (`assert(...)`).
class AssertInitializerNode extends ConstructorInitializerNode {
  const new(this.assertStatement);
  final AssertStatementNode assertStatement;

  @override
  String toString() => 'AssertInitializerNode($assertStatement)';
}

/// A field or top-level variable declaration.
class FieldDeclarationNode extends DeclarationNode {
  const new({
    required this.variables,
    this.type,
    this.isStatic = false,
    this.isFinal = false,
    this.isConst = false,
    this.isLate = false,
    this.isCovariant = false,
  });

  final List<VariableDeclaratorNode> variables;
  final TypeNode? type;
  final bool isStatic;
  final bool isFinal;
  final bool isConst;
  final bool isLate;
  final bool isCovariant;

  @override
  String toString() => 'FieldDeclarationNode($variables)';
}

/// An individual variable declarator with an optional initializer (`name = value`).
class VariableDeclaratorNode extends DartNode {
  const new({required this.name, this.initializer});

  final String name;
  final ExpressionNode? initializer;

  @override
  String toString() =>
      'VariableDeclaratorNode($name${initializer != null ? ' = $initializer' : ''})';
}

/// A type alias declaration (`typedef Name<T> = Type;`).
class TypeAliasDeclarationNode extends DeclarationNode {
  const new({
    required this.name,
    this.typeParameters = const [],
    required this.type,
  });

  final String name;
  final List<TypeParameterNode> typeParameters;
  final TypeNode type;

  @override
  String toString() => 'TypeAliasDeclarationNode($name = $type)';
}

// ---------------------------------------------------------------------------
// Parameters & Function Bodies
// ---------------------------------------------------------------------------

/// Base class for parameters.
sealed class ParameterNode extends DartNode {
  const new({
    required this.name,
    this.type,
    this.defaultValue,
    this.isNamed = false,
    this.isRequired = false,
    this.isFinal = false,
    this.isVar = false,
    this.isThis = false,
    this.isSuper = false,
  });

  final String name;
  final TypeNode? type;
  final ExpressionNode? defaultValue;
  final bool isNamed;
  final bool isRequired;
  final bool isFinal;
  final bool isVar;
  final bool isThis;
  final bool isSuper;

  @override
  String toString() => 'ParameterNode($name, type: $type)';
}

/// A simple parameter.
class SimpleParameterNode extends ParameterNode {
  const new({
    required super.name,
    super.type,
    super.defaultValue,
    super.isNamed,
    super.isRequired,
    super.isFinal,
    super.isVar,
    super.isThis,
    super.isSuper,
  });
}

/// A function-typed formal parameter (`void callback(int x)`).
class FunctionTypedParameterNode extends ParameterNode {
  const new({
    required super.name,
    super.type,
    this.parameters = const [],
    super.defaultValue,
    super.isNamed,
    super.isRequired,
  });

  final List<ParameterNode> parameters;

  @override
  String toString() => 'FunctionTypedParameterNode($name)';
}

/// Base class for function bodies.
sealed class FunctionBodyNode extends DartNode {
  const new({this.isAsync = false, this.isGenerator = false});

  final bool isAsync;
  final bool isGenerator;
}

/// A block function body (`{ ... }`).
class BlockFunctionBodyNode extends FunctionBodyNode {
  const new(this.block, {super.isAsync, super.isGenerator});
  final BlockStatementNode block;

  @override
  String toString() => 'BlockFunctionBodyNode()';
}

/// An expression (arrow) function body (`=> expr;`).
class ExpressionFunctionBodyNode extends FunctionBodyNode {
  const new(this.expression, {super.isAsync, super.isGenerator});
  final ExpressionNode expression;

  @override
  String toString() => 'ExpressionFunctionBodyNode($expression)';
}

/// An empty / native / abstract function body (`;`).
class EmptyFunctionBodyNode extends FunctionBodyNode {
  const new();

  @override
  String toString() => 'EmptyFunctionBodyNode()';
}

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

/// Base class for type annotations.
sealed class TypeNode extends DartNode {
  const new({this.isNullable = false});
  final bool isNullable;
}

/// A named type (`int`, `List<String>`, `prefix.Class?`).
class NamedTypeNode extends TypeNode {
  const new({
    required this.name,
    this.typeArguments = const [],
    super.isNullable,
  });

  final String name;
  final List<TypeNode> typeArguments;

  @override
  String toString() =>
      'NamedTypeNode($name${typeArguments.isNotEmpty ? '<$typeArguments>' : ''}${isNullable ? '?' : ''})';
}

/// A record type (`(int, String)`, `({int a, String b})`).
class RecordTypeNode extends TypeNode {
  const new({
    this.positionalFields = const [],
    this.namedFields = const [],
    super.isNullable,
  });

  final List<RecordTypeFieldNode> positionalFields;
  final List<RecordTypeFieldNode> namedFields;

  @override
  String toString() =>
      'RecordTypeNode(pos: $positionalFields, named: $namedFields)';
}

/// A field inside a record type.
class RecordTypeFieldNode extends DartNode {
  const new({required this.type, this.name});

  final TypeNode type;
  final String? name;

  @override
  String toString() =>
      'RecordTypeFieldNode($type${name != null ? ' $name' : ''})';
}

/// A function type (`int Function(String)`).
class FunctionTypeNode extends TypeNode {
  const new({
    this.returnType,
    this.typeParameters = const [],
    this.parameters = const [],
    super.isNullable,
  });

  final TypeNode? returnType;
  final List<TypeParameterNode> typeParameters;
  final List<ParameterNode> parameters;

  @override
  String toString() => 'FunctionTypeNode($returnType Function($parameters))';
}

/// A generic type parameter declaration (`T extends Object`).
class TypeParameterNode extends DartNode {
  const new({required this.name, this.bound});

  final String name;
  final TypeNode? bound;

  @override
  String toString() =>
      'TypeParameterNode($name${bound != null ? ' extends $bound' : ''})';
}

// ---------------------------------------------------------------------------
// Statements
// ---------------------------------------------------------------------------

/// Base class for statements.
sealed class StatementNode extends DartNode {
  const new();
}

/// An empty statement (`;`).
class EmptyStatementNode extends StatementNode {
  const new();

  @override
  String toString() => 'EmptyStatementNode()';
}

/// A block statement (`{ ... }`).
class BlockStatementNode extends StatementNode {
  const new(this.statements);
  final List<StatementNode> statements;

  @override
  String toString() => 'BlockStatementNode(${statements.length} statements)';
}

/// An expression statement (`expr;`).
class ExpressionStatementNode extends StatementNode {
  const new(this.expression);
  final ExpressionNode expression;

  @override
  String toString() => 'ExpressionStatementNode($expression)';
}

/// A function declaration statement (`void foo() {}`).
class FunctionDeclarationStatementNode extends StatementNode {
  const new(this.declaration);
  final FunctionDeclarationNode declaration;

  @override
  String toString() => 'FunctionDeclarationStatementNode($declaration)';
}

/// A variable declaration statement (`var x = 1;`, `int a, b;`).
class VariableDeclarationStatementNode extends StatementNode {
  const new({
    required this.variables,
    this.type,
    this.isFinal = false,
    this.isConst = false,
    this.isLate = false,
    this.isVar = false,
  });

  final List<VariableDeclaratorNode> variables;
  final TypeNode? type;
  final bool isFinal;
  final bool isConst;
  final bool isLate;
  final bool isVar;

  @override
  String toString() =>
      'VariableDeclarationStatementNode($variables, type: $type)';
}

/// A pattern variable declaration statement (`var (a, b) = pair;`).
class PatternVariableDeclarationStatementNode extends StatementNode {
  const new({
    required this.keyword,
    required this.pattern,
    required this.expression,
  });

  final String keyword;
  final PatternNode pattern;
  final ExpressionNode expression;

  @override
  String toString() =>
      'PatternVariableDeclarationStatementNode($keyword $pattern = $expression)';
}

/// An if statement, with optional pattern matching (`if (x case int y) ...`).
class IfStatementNode extends StatementNode {
  const new({
    required this.condition,
    this.casePattern,
    this.whenGuard,
    required this.thenBranch,
    this.elseBranch,
  });

  final ExpressionNode condition;
  final PatternNode? casePattern;
  final ExpressionNode? whenGuard;
  final StatementNode thenBranch;
  final StatementNode? elseBranch;

  @override
  String toString() => 'IfStatementNode(cond: $condition)';
}

/// A switch statement.
class SwitchStatementNode extends StatementNode {
  const new({required this.expression, this.cases = const []});

  final ExpressionNode expression;
  final List<SwitchPatternCaseNode> cases;

  @override
  String toString() =>
      'SwitchStatementNode($expression, ${cases.length} cases)';
}

/// A case group in a switch statement.
class SwitchPatternCaseNode extends DartNode {
  const new({
    this.labels = const [],
    this.patterns = const [],
    this.whenGuard,
    this.isDefault = false,
    required this.statements,
  });

  final List<String> labels;
  final List<PatternNode> patterns;
  final ExpressionNode? whenGuard;
  final bool isDefault;
  final List<StatementNode> statements;

  @override
  String toString() => 'SwitchPatternCaseNode(patterns: $patterns)';
}

/// A traditional for loop (`for (init; cond; update) body`).
class ForStatementNode extends StatementNode {
  const new({
    this.initialization,
    this.condition,
    this.updates = const [],
    required this.body,
  });

  final StatementNode? initialization;
  final ExpressionNode? condition;
  final List<ExpressionNode> updates;
  final StatementNode body;

  @override
  String toString() => 'ForStatementNode()';
}

/// A for-in loop (`for (var x in iterable) body`).
class ForInStatementNode extends StatementNode {
  const new({
    this.variable,
    this.pattern,
    required this.iterable,
    required this.body,
    this.isAsync = false,
  });

  final VariableDeclarationStatementNode? variable;
  final PatternNode? pattern;
  final ExpressionNode iterable;
  final StatementNode body;
  final bool isAsync;

  @override
  String toString() => 'ForInStatementNode()';
}

/// A while loop.
class WhileStatementNode extends StatementNode {
  const new({required this.condition, required this.body});

  final ExpressionNode condition;
  final StatementNode body;

  @override
  String toString() => 'WhileStatementNode($condition)';
}

/// A do-while loop.
class DoWhileStatementNode extends StatementNode {
  const new({required this.body, required this.condition});

  final StatementNode body;
  final ExpressionNode condition;

  @override
  String toString() => 'DoWhileStatementNode($condition)';
}

/// A try-catch-finally statement.
class TryStatementNode extends StatementNode {
  const new({
    required this.body,
    this.catchClauses = const [],
    this.finallyBlock,
  });

  final BlockStatementNode body;
  final List<CatchClauseNode> catchClauses;
  final BlockStatementNode? finallyBlock;

  @override
  String toString() => 'TryStatementNode()';
}

/// A catch or on clause in a try statement.
class CatchClauseNode extends DartNode {
  const new({
    this.exceptionType,
    this.exceptionParameter,
    this.stackTraceParameter,
    required this.body,
  });

  final TypeNode? exceptionType;
  final String? exceptionParameter;
  final String? stackTraceParameter;
  final BlockStatementNode body;

  @override
  String toString() => 'CatchClauseNode(on: $exceptionType)';
}

/// A return statement (`return expr;`).
class ReturnStatementNode extends StatementNode {
  const new([this.expression]);
  final ExpressionNode? expression;

  @override
  String toString() => 'ReturnStatementNode($expression)';
}

/// A break statement (`break [label];`).
class BreakStatementNode extends StatementNode {
  const new([this.label]);
  final String? label;

  @override
  String toString() => 'BreakStatementNode($label)';
}

/// A continue statement (`continue [label];`).
class ContinueStatementNode extends StatementNode {
  const new([this.label]);
  final String? label;

  @override
  String toString() => 'ContinueStatementNode($label)';
}

/// A rethrow statement (`rethrow;`).
class RethrowStatementNode extends StatementNode {
  const new();

  @override
  String toString() => 'RethrowStatementNode()';
}

/// A yield statement (`yield expr;` or `yield* expr;`).
class YieldStatementNode extends StatementNode {
  const new(this.expression, {this.isStar = false});
  final ExpressionNode expression;
  final bool isStar;

  @override
  String toString() => 'YieldStatementNode($expression, isStar: $isStar)';
}

/// An assert statement (`assert(cond, message);`).
class AssertStatementNode extends StatementNode {
  const new(this.condition, [this.message]);
  final ExpressionNode condition;
  final ExpressionNode? message;

  @override
  String toString() => 'AssertStatementNode($condition)';
}

/// A labeled statement (`label: statement`).
class LabeledStatementNode extends StatementNode {
  const new({required this.label, required this.statement});

  final String label;
  final StatementNode statement;

  @override
  String toString() => 'LabeledStatementNode($label)';
}

// ---------------------------------------------------------------------------
// Patterns (Dart 3)
// ---------------------------------------------------------------------------

/// Base class for Dart 3 patterns.
sealed class PatternNode extends DartNode {
  const new();
}

/// A constant pattern (literal, identifier, const expression).
class ConstantPatternNode extends PatternNode {
  const new(this.expression);
  final ExpressionNode expression;

  @override
  String toString() => 'ConstantPatternNode($expression)';
}

/// A variable pattern (`var x`, `final int x`, `int x`).
class VariablePatternNode extends PatternNode {
  const new({
    required this.name,
    this.type,
    this.isFinal = false,
    this.isVar = false,
  });

  final String name;
  final TypeNode? type;
  final bool isFinal;
  final bool isVar;

  @override
  String toString() => 'VariablePatternNode($name, type: $type)';
}

/// A wildcard pattern (`_` or `int _`).
class WildcardPatternNode extends PatternNode {
  const new([this.type]);
  final TypeNode? type;

  @override
  String toString() => 'WildcardPatternNode($type)';
}

/// A relational pattern (`> 5`, `<= 10`).
class RelationalPatternNode extends PatternNode {
  const new({required this.operator, required this.operand});

  final String operator;
  final ExpressionNode operand;

  @override
  String toString() => 'RelationalPatternNode($operator $operand)';
}

/// A logical-and or logical-or pattern (`p1 && p2`, `p1 || p2`).
class LogicalPatternNode extends PatternNode {
  const new({required this.left, required this.operator, required this.right});

  final PatternNode left;
  final String operator;
  final PatternNode right;

  @override
  String toString() => 'LogicalPatternNode($left $operator $right)';
}

/// A cast pattern (`pattern as Type`).
class CastPatternNode extends PatternNode {
  const new(this.pattern, this.type);
  final PatternNode pattern;
  final TypeNode type;

  @override
  String toString() => 'CastPatternNode($pattern as $type)';
}

/// A null-check pattern (`pattern?`).
class NullCheckPatternNode extends PatternNode {
  const new(this.pattern);
  final PatternNode pattern;

  @override
  String toString() => 'NullCheckPatternNode($pattern?)';
}

/// A null-assert pattern (`pattern!`).
class NullAssertPatternNode extends PatternNode {
  const new(this.pattern);
  final PatternNode pattern;

  @override
  String toString() => 'NullAssertPatternNode($pattern!)';
}

/// A parenthesized pattern (`(pattern)`).
class ParenthesizedPatternNode extends PatternNode {
  const new(this.pattern);
  final PatternNode pattern;

  @override
  String toString() => 'ParenthesizedPatternNode($pattern)';
}

/// A list pattern (`[a, b, ...rest]`).
class ListPatternNode extends PatternNode {
  const new({this.typeArguments = const [], this.elements = const []});

  final List<TypeNode> typeArguments;
  final List<PatternNode> elements;

  @override
  String toString() => 'ListPatternNode($elements)';
}

/// A rest element in a list pattern (`...` or `...rest`).
class RestPatternNode extends PatternNode {
  const new([this.subPattern]);
  final PatternNode? subPattern;

  @override
  String toString() => 'RestPatternNode($subPattern)';
}

/// A map pattern (`{'k': v}`).
class MapPatternNode extends PatternNode {
  const new({this.typeArguments = const [], this.entries = const []});

  final List<TypeNode> typeArguments;
  final List<MapPatternEntryNode> entries;

  @override
  String toString() => 'MapPatternNode($entries)';
}

/// A key-value pair in a map pattern.
class MapPatternEntryNode extends DartNode {
  const new({required this.key, required this.value});

  final ExpressionNode key;
  final PatternNode value;

  @override
  String toString() => 'MapPatternEntryNode($key: $value)';
}

/// A record pattern (`(a, b)`, `(name: a)`).
class RecordPatternNode extends PatternNode {
  const new({this.fields = const []});

  final List<PatternFieldNode> fields;

  @override
  String toString() => 'RecordPatternNode($fields)';
}

/// An object pattern (`Point(x: var x, y: 0)`).
class ObjectPatternNode extends PatternNode {
  const new({required this.type, this.fields = const []});

  final TypeNode type;
  final List<PatternFieldNode> fields;

  @override
  String toString() => 'ObjectPatternNode($type, fields: $fields)';
}

/// A field within an object or record pattern.
class PatternFieldNode extends DartNode {
  const new({this.name, required this.pattern});

  final String? name;
  final PatternNode pattern;

  @override
  String toString() =>
      'PatternFieldNode(${name != null ? '$name: ' : ''}$pattern)';
}

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

/// Base class for expressions.
sealed class ExpressionNode extends DartNode {
  const new();
}

/// Base class for literal values.
sealed class LiteralNode<T> extends ExpressionNode {
  const new(this.value);
  final T value;
}

/// An integer literal (`42`, `0xCAFE`).
class IntegerLiteralNode extends LiteralNode<int> {
  const new(super.value);

  @override
  String toString() => 'IntegerLiteralNode($value)';
}

/// A double literal (`3.14`, `1e-5`).
class DoubleLiteralNode extends LiteralNode<double> {
  const new(super.value);

  @override
  String toString() => 'DoubleLiteralNode($value)';
}

/// A boolean literal (`true`, `false`).
class BooleanLiteralNode extends LiteralNode<bool> {
  const new(super.value);

  @override
  String toString() => 'BooleanLiteralNode($value)';
}

/// A string literal (`'hello'`, `"world"`, `r'raw'`).
class StringLiteralNode extends LiteralNode<String> {
  const new(super.value, {this.isRaw = false});
  final bool isRaw;

  @override
  String toString() => 'StringLiteralNode($value, isRaw: $isRaw)';
}

/// An interpolated string (`'hello $name'`).
class InterpolatedStringNode extends ExpressionNode {
  const new(this.parts);
  final List<DartNode> parts;

  @override
  String toString() => 'InterpolatedStringNode($parts)';
}

/// A null literal (`null`).
class NullLiteralNode extends LiteralNode<void> {
  const new() : super(null);

  @override
  String toString() => 'NullLiteralNode()';
}

/// A symbol literal (`#foo`).
class SymbolLiteralNode extends LiteralNode<String> {
  const new(super.value);

  @override
  String toString() => 'SymbolLiteralNode(#$value)';
}

/// An identifier expression.
class IdentifierNode extends ExpressionNode {
  const new(this.name);
  final String name;

  @override
  String toString() => 'IdentifierNode($name)';
}

/// A binary expression (`a + b`, `x && y`, `a = b`).
class BinaryExpressionNode extends ExpressionNode {
  const new({required this.left, required this.operator, required this.right});

  final ExpressionNode left;
  final String operator;
  final ExpressionNode right;

  @override
  String toString() => 'BinaryExpressionNode($left $operator $right)';
}

/// A prefix or postfix unary expression (`-a`, `!b`, `c++`, `d--`).
class UnaryExpressionNode extends ExpressionNode {
  const new({
    required this.operator,
    required this.operand,
    this.isPrefix = true,
  });

  final String operator;
  final ExpressionNode operand;
  final bool isPrefix;

  @override
  String toString() =>
      'UnaryExpressionNode(${isPrefix ? '$operator$operand' : '$operand$operator'})';
}

/// A ternary conditional expression (`a ? b : c`).
class ConditionalExpressionNode extends ExpressionNode {
  const new({
    required this.condition,
    required this.thenExpression,
    required this.elseExpression,
  });

  final ExpressionNode condition;
  final ExpressionNode thenExpression;
  final ExpressionNode elseExpression;

  @override
  String toString() =>
      'ConditionalExpressionNode($condition ? $thenExpression : $elseExpression)';
}

/// An if-null expression (`a ?? b`).
class IfNullExpressionNode extends ExpressionNode {
  const new({required this.left, required this.right});

  final ExpressionNode left;
  final ExpressionNode right;

  @override
  String toString() => 'IfNullExpressionNode($left ?? $right)';
}

/// A cascade expression (`a..b()..c = 1`).
class CascadeExpressionNode extends ExpressionNode {
  const new({
    required this.target,
    required this.cascadeSections,
    this.isNullAware = false,
  });

  final ExpressionNode target;
  final List<ExpressionNode> cascadeSections;
  final bool isNullAware;

  @override
  String toString() => 'CascadeExpressionNode($target, $cascadeSections)';
}

/// An invocation expression (`foo(1, a: 2)` or `bar<T>()`).
class InvocationExpressionNode extends ExpressionNode {
  const new({
    required this.target,
    this.typeArguments = const [],
    this.arguments = const [],
  });

  final ExpressionNode target;
  final List<TypeNode> typeArguments;
  final List<ArgumentNode> arguments;

  @override
  String toString() => 'InvocationExpressionNode($target($arguments))';
}

/// A function call argument (`expr` or `name: expr`).
class ArgumentNode extends DartNode {
  const new({this.name, required this.value});

  final String? name;
  final ExpressionNode value;

  @override
  String toString() => 'ArgumentNode(${name != null ? '$name: ' : ''}$value)';
}

/// A property access expression (`a.b` or `a?.b`).
class PropertyAccessNode extends ExpressionNode {
  const new({
    required this.target,
    required this.propertyName,
    this.isNullAware = false,
  });

  final ExpressionNode target;
  final String propertyName;
  final bool isNullAware;

  @override
  String toString() =>
      'PropertyAccessNode($target${isNullAware ? '?.' : '.'}$propertyName)';
}

/// An index expression (`a[0]` or `a?[0]`).
class IndexExpressionNode extends ExpressionNode {
  const new({
    required this.target,
    required this.index,
    this.isNullAware = false,
  });

  final ExpressionNode target;
  final ExpressionNode index;
  final bool isNullAware;

  @override
  String toString() =>
      'IndexExpressionNode($target${isNullAware ? '?' : ''}[$index])';
}

/// A parenthesized expression (`(expr)`).
class ParenthesizedExpressionNode extends ExpressionNode {
  const new(this.expression);
  final ExpressionNode expression;

  @override
  String toString() => 'ParenthesizedExpressionNode($expression)';
}

/// A `this` expression.
class ThisExpressionNode extends ExpressionNode {
  const new();

  @override
  String toString() => 'ThisExpressionNode()';
}

/// A `super` expression.
class SuperExpressionNode extends ExpressionNode {
  const new();

  @override
  String toString() => 'SuperExpressionNode()';
}

/// A throw expression (`throw expr`).
class ThrowExpressionNode extends ExpressionNode {
  const new(this.expression);
  final ExpressionNode expression;

  @override
  String toString() => 'ThrowExpressionNode($expression)';
}

/// An await expression (`await expr`).
class AwaitExpressionNode extends ExpressionNode {
  const new(this.expression);
  final ExpressionNode expression;

  @override
  String toString() => 'AwaitExpressionNode($expression)';
}

/// A type test expression (`a is T` or `a is! T`).
class TypeTestExpressionNode extends ExpressionNode {
  const new({
    required this.expression,
    required this.type,
    this.isNegated = false,
  });

  final ExpressionNode expression;
  final TypeNode type;
  final bool isNegated;

  @override
  String toString() =>
      'TypeTestExpressionNode($expression is${isNegated ? '!' : ''} $type)';
}

/// A type cast expression (`a as T`).
class TypeCastExpressionNode extends ExpressionNode {
  const new({required this.expression, required this.type});

  final ExpressionNode expression;
  final TypeNode type;

  @override
  String toString() => 'TypeCastExpressionNode($expression as $type)';
}

/// A switch expression (`switch (x) { 1 => 'a', _ => 'b' }`).
class SwitchExpressionNode extends ExpressionNode {
  const new({required this.expression, required this.cases});

  final ExpressionNode expression;
  final List<SwitchExpressionCaseNode> cases;

  @override
  String toString() => 'SwitchExpressionNode($expression, cases: $cases)';
}

/// A case in a switch expression (`pattern [when guard] => body`).
class SwitchExpressionCaseNode extends DartNode {
  const new({required this.pattern, this.whenGuard, required this.body});

  final PatternNode pattern;
  final ExpressionNode? whenGuard;
  final ExpressionNode body;

  @override
  String toString() => 'SwitchExpressionCaseNode($pattern => $body)';
}

/// A collection literal (List, Set, or Map).
class CollectionLiteralNode extends ExpressionNode {
  const new({
    this.typeArguments = const [],
    this.elements = const [],
    this.isConst = false,
  });

  final List<TypeNode> typeArguments;
  final List<CollectionElementNode> elements;
  final bool isConst;

  @override
  String toString() => 'CollectionLiteralNode($elements)';
}

/// Base class for collection literal elements.
sealed class CollectionElementNode extends DartNode {
  const new();
}

/// An expression element in a collection (`[a, b]` or `[?a, ?b]`).
class ExpressionElementNode extends CollectionElementNode {
  const new(this.expression, {this.isNullAware = false});
  final ExpressionNode expression;
  final bool isNullAware;

  @override
  String toString() =>
      'ExpressionElementNode(${isNullAware ? '?' : ''}$expression)';
}

/// A key-value pair element in a map (`{'k': v}` or `{?k: ?v}`).
class MapEntryElementNode extends CollectionElementNode {
  const new({
    required this.key,
    required this.value,
    this.isKeyNullAware = false,
    this.isValueNullAware = false,
  });

  final ExpressionNode key;
  final ExpressionNode value;
  final bool isKeyNullAware;
  final bool isValueNullAware;

  @override
  String toString() =>
      'MapEntryElementNode(${isKeyNullAware ? '?' : ''}$key: ${isValueNullAware ? '?' : ''}$value)';
}

/// A spread element in a collection (`...list` or `...?list`).
class SpreadElementNode extends CollectionElementNode {
  const new({required this.expression, this.isNullAware = false});

  final ExpressionNode expression;
  final bool isNullAware;

  @override
  String toString() =>
      'SpreadElementNode(...${isNullAware ? '?' : ''}$expression)';
}

/// An if-element in a collection (`if (c) a else b` or `if (x case p) a`).
class IfElementNode extends CollectionElementNode {
  const new({
    required this.condition,
    this.casePattern,
    this.whenGuard,
    required this.thenElement,
    this.elseElement,
  });

  final ExpressionNode condition;
  final PatternNode? casePattern;
  final ExpressionNode? whenGuard;
  final CollectionElementNode thenElement;
  final CollectionElementNode? elseElement;

  @override
  String toString() => 'IfElementNode($condition)';
}

/// A for-element in a collection (`for (var x in list) x * 2`).
class ForElementNode extends CollectionElementNode {
  const new({
    this.variable,
    this.pattern,
    required this.iterable,
    required this.body,
    this.isAsync = false,
  });

  final VariableDeclarationStatementNode? variable;
  final PatternNode? pattern;
  final ExpressionNode iterable;
  final CollectionElementNode body;
  final bool isAsync;

  @override
  String toString() => 'ForElementNode()';
}

/// A record literal (`(1, 2)` or `(a: 1, b: 2)`).
class RecordLiteralNode extends ExpressionNode {
  const new({this.fields = const [], this.isConst = false});

  final List<RecordLiteralFieldNode> fields;
  final bool isConst;

  @override
  String toString() => 'RecordLiteralNode($fields)';
}

/// A field within a record literal.
class RecordLiteralFieldNode extends DartNode {
  const new({this.name, required this.value});

  final String? name;
  final ExpressionNode value;

  @override
  String toString() =>
      'RecordLiteralFieldNode(${name != null ? '$name: ' : ''}$value)';
}

/// An anonymous function / lambda expression (`(x) => x + 1` or `(x) { ... }`).
class FunctionExpressionNode extends ExpressionNode {
  const new({
    this.typeParameters = const [],
    this.parameters = const [],
    required this.body,
  });

  final List<TypeParameterNode> typeParameters;
  final List<ParameterNode> parameters;
  final FunctionBodyNode body;

  @override
  String toString() => 'FunctionExpressionNode($parameters)';
}

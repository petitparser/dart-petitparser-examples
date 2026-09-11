import 'package:meta/meta.dart';

/// Base class for all Python AST nodes.
@immutable
sealed class PythonNode {
  const new();
}

// ---------------------------------------------------------------------------
// Modules & Root Nodes
// ---------------------------------------------------------------------------

/// Base class for top-level Python modules.
sealed class ModNode extends PythonNode {
  const new();
}

/// A standard Python module consisting of a sequence of statements.
class ModuleNode extends ModNode {
  const new({this.body = const []});

  final List<StatementNode> body;

  @override
  String toString() => 'ModuleNode(body: ${body.length} statements)';
}

/// An interactive Python statement sequence.
class InteractiveNode extends ModNode {
  const new({this.body = const []});

  final List<StatementNode> body;

  @override
  String toString() => 'InteractiveNode(body: ${body.length} statements)';
}

/// An expression parsed as a top-level module (eval context).
class ExpressionModuleNode extends ModNode {
  const new(this.body);

  final ExpressionNode body;

  @override
  String toString() => 'ExpressionModuleNode($body)';
}

// ---------------------------------------------------------------------------
// Statements
// ---------------------------------------------------------------------------

/// Base class for all Python statements.
sealed class StatementNode extends PythonNode {
  const new();
}

/// Function definition statement (`def name(params): body`).
class FunctionDefNode extends StatementNode {
  const new({
    required this.name,
    required this.args,
    required this.body,
    this.decoratorList = const [],
    this.returns,
    this.typeParams = const [],
  });

  final String name;
  final ArgumentsNode args;
  final List<StatementNode> body;
  final List<ExpressionNode> decoratorList;
  final ExpressionNode? returns;
  final List<TypeParamNode> typeParams;

  @override
  String toString() =>
      'FunctionDefNode(name: $name, args: $args, body: ${body.length})';
}

/// Asynchronous function definition statement (`async def name(params): body`).
class AsyncFunctionDefNode extends StatementNode {
  const new({
    required this.name,
    required this.args,
    required this.body,
    this.decoratorList = const [],
    this.returns,
    this.typeParams = const [],
  });

  final String name;
  final ArgumentsNode args;
  final List<StatementNode> body;
  final List<ExpressionNode> decoratorList;
  final ExpressionNode? returns;
  final List<TypeParamNode> typeParams;

  @override
  String toString() =>
      'AsyncFunctionDefNode(name: $name, args: $args, body: ${body.length})';
}

/// Class definition statement (`class Name(bases): body`).
class ClassDefNode extends StatementNode {
  const new({
    required this.name,
    required this.body,
    this.bases = const [],
    this.keywords = const [],
    this.decoratorList = const [],
    this.typeParams = const [],
  });

  final String name;
  final List<ExpressionNode> bases;
  final List<KeywordNode> keywords;
  final List<StatementNode> body;
  final List<ExpressionNode> decoratorList;
  final List<TypeParamNode> typeParams;

  @override
  String toString() =>
      'ClassDefNode(name: $name, bases: $bases, body: ${body.length})';
}

/// Return statement (`return value`).
class ReturnNode extends StatementNode {
  const new([this.value]);

  final ExpressionNode? value;

  @override
  String toString() => 'ReturnNode($value)';
}

/// Delete statement (`del x, y`).
class DeleteNode extends StatementNode {
  const new(this.targets);

  final List<ExpressionNode> targets;

  @override
  String toString() => 'DeleteNode($targets)';
}

/// Assignment statement (`x = y = 1`).
class AssignNode extends StatementNode {
  const new({required this.targets, required this.value});

  final List<ExpressionNode> targets;
  final ExpressionNode value;

  @override
  String toString() => 'AssignNode(targets: $targets, value: $value)';
}

/// Augmented assignment statement (`x += 1`).
class AugAssignNode extends StatementNode {
  const new({
    required this.target,
    required this.operator,
    required this.value,
  });

  final ExpressionNode target;
  final String operator;
  final ExpressionNode value;

  @override
  String toString() => 'AugAssignNode($target $operator $value)';
}

/// Annotated assignment statement (`x: int = 1`).
class AnnAssignNode extends StatementNode {
  const new({required this.target, required this.annotation, this.value});

  final ExpressionNode target;
  final ExpressionNode annotation;
  final ExpressionNode? value;

  @override
  String toString() => 'AnnAssignNode($target: $annotation = $value)';
}

/// PEP 695 type alias statement (`type X[T] = int`).
class TypeAliasNode extends StatementNode {
  const new({
    required this.name,
    required this.value,
    this.typeParams = const [],
  });

  final ExpressionNode name;
  final ExpressionNode value;
  final List<TypeParamNode> typeParams;

  @override
  String toString() => 'TypeAliasNode(name: $name, value: $value)';
}

/// For loop statement (`for x in iter: body else: orelse`).
class ForNode extends StatementNode {
  const new({
    required this.target,
    required this.iter,
    required this.body,
    this.orelse = const [],
  });

  final ExpressionNode target;
  final ExpressionNode iter;
  final List<StatementNode> body;
  final List<StatementNode> orelse;

  @override
  String toString() =>
      'ForNode(target: $target, in: $iter, body: ${body.length})';
}

/// Async for loop statement (`async for x in iter: body else: orelse`).
class AsyncForNode extends StatementNode {
  const new({
    required this.target,
    required this.iter,
    required this.body,
    this.orelse = const [],
  });

  final ExpressionNode target;
  final ExpressionNode iter;
  final List<StatementNode> body;
  final List<StatementNode> orelse;

  @override
  String toString() =>
      'AsyncForNode(target: $target, in: $iter, body: ${body.length})';
}

/// While loop statement (`while test: body else: orelse`).
class WhileNode extends StatementNode {
  const new({required this.test, required this.body, this.orelse = const []});

  final ExpressionNode test;
  final List<StatementNode> body;
  final List<StatementNode> orelse;

  @override
  String toString() => 'WhileNode(test: $test, body: ${body.length})';
}

/// If statement (`if test: body elif ... else: orelse`).
class IfNode extends StatementNode {
  const new({required this.test, required this.body, this.orelse = const []});

  final ExpressionNode test;
  final List<StatementNode> body;
  final List<StatementNode> orelse;

  @override
  String toString() => 'IfNode(test: $test, body: ${body.length})';
}

/// With statement (`with item1, item2: body`).
class WithNode extends StatementNode {
  const new({required this.items, required this.body});

  final List<WithItemNode> items;
  final List<StatementNode> body;

  @override
  String toString() => 'WithNode(items: $items, body: ${body.length})';
}

/// Async with statement (`async with item1: body`).
class AsyncWithNode extends StatementNode {
  const new({required this.items, required this.body});

  final List<WithItemNode> items;
  final List<StatementNode> body;

  @override
  String toString() => 'AsyncWithNode(items: $items, body: ${body.length})';
}

/// Pattern match statement (`match subject: case ...`).
class MatchNode extends StatementNode {
  const new({required this.subject, required this.cases});

  final ExpressionNode subject;
  final List<MatchCaseNode> cases;

  @override
  String toString() => 'MatchNode(subject: $subject, cases: ${cases.length})';
}

/// Raise statement (`raise exc from cause`).
class RaiseNode extends StatementNode {
  const new({this.exc, this.cause});

  final ExpressionNode? exc;
  final ExpressionNode? cause;

  @override
  String toString() => 'RaiseNode(exc: $exc, cause: $cause)';
}

/// Try statement (`try: ... except: ... else: ... finally: ...`).
class TryNode extends StatementNode {
  const new({
    required this.body,
    this.handlers = const [],
    this.orelse = const [],
    this.finalbody = const [],
  });

  final List<StatementNode> body;
  final List<ExceptHandlerNode> handlers;
  final List<StatementNode> orelse;
  final List<StatementNode> finalbody;

  @override
  String toString() =>
      'TryNode(body: ${body.length}, handlers: ${handlers.length})';
}

/// Try-star statement (`try: ... except* ExceptionGroup: ...`).
class TryStarNode extends StatementNode {
  const new({
    required this.body,
    this.handlers = const [],
    this.orelse = const [],
    this.finalbody = const [],
  });

  final List<StatementNode> body;
  final List<ExceptHandlerNode> handlers;
  final List<StatementNode> orelse;
  final List<StatementNode> finalbody;

  @override
  String toString() =>
      'TryStarNode(body: ${body.length}, handlers: ${handlers.length})';
}

/// Assert statement (`assert test, msg`).
class AssertNode extends StatementNode {
  const new({required this.test, this.msg});

  final ExpressionNode test;
  final ExpressionNode? msg;

  @override
  String toString() => 'AssertNode(test: $test, msg: $msg)';
}

/// Import statement (`import foo, bar as baz`).
class ImportNode extends StatementNode {
  const new(this.names);

  final List<AliasNode> names;

  @override
  String toString() => 'ImportNode($names)';
}

/// From-import statement (`from foo import bar as baz`).
class ImportFromNode extends StatementNode {
  const new({this.module, this.names = const [], this.level = 0});

  final String? module;
  final List<AliasNode> names;
  final int level;

  @override
  String toString() =>
      'ImportFromNode(module: $module, names: $names, level: $level)';
}

/// Global statement (`global a, b`).
class GlobalNode extends StatementNode {
  const new(this.names);

  final List<String> names;

  @override
  String toString() => 'GlobalNode($names)';
}

/// Nonlocal statement (`nonlocal a, b`).
class NonlocalNode extends StatementNode {
  const new(this.names);

  final List<String> names;

  @override
  String toString() => 'NonlocalNode($names)';
}

/// An expression evaluated as a statement.
class ExprStatementNode extends StatementNode {
  const new(this.value);

  final ExpressionNode value;

  @override
  String toString() => 'ExprStatementNode($value)';
}

/// Pass statement (`pass`).
class PassNode extends StatementNode {
  const new();

  @override
  String toString() => 'PassNode()';
}

/// Break statement (`break`).
class BreakNode extends StatementNode {
  const new();

  @override
  String toString() => 'BreakNode()';
}

/// Continue statement (`continue`).
class ContinueNode extends StatementNode {
  const new();

  @override
  String toString() => 'ContinueNode()';
}

// ---------------------------------------------------------------------------
// Expressions
// ---------------------------------------------------------------------------

/// Base class for all Python expressions.
sealed class ExpressionNode extends PythonNode {
  const new();
}

/// Boolean binary operation (`a and b` or `a or b`).
class BoolOpNode extends ExpressionNode {
  const new({required this.operator, required this.values});

  final String operator;
  final List<ExpressionNode> values;

  @override
  String toString() => 'BoolOpNode($operator, $values)';
}

/// Walrus named expression assignment (`target := value`).
class NamedExprNode extends ExpressionNode {
  const new({required this.target, required this.value});

  final ExpressionNode target;
  final ExpressionNode value;

  @override
  String toString() => 'NamedExprNode($target := $value)';
}

/// Binary operation (`left + right`).
class BinOpNode extends ExpressionNode {
  const new({required this.left, required this.operator, required this.right});

  final ExpressionNode left;
  final String operator;
  final ExpressionNode right;

  @override
  String toString() => 'BinOpNode($left $operator $right)';
}

/// Unary operation (`-x`, `+x`, `~x`, `not x`).
class UnaryOpNode extends ExpressionNode {
  const new({required this.operator, required this.operand});

  final String operator;
  final ExpressionNode operand;

  @override
  String toString() => 'UnaryOpNode($operator $operand)';
}

/// Lambda expression (`lambda x, y: x + y`).
class LambdaNode extends ExpressionNode {
  const new({required this.args, required this.body});

  final ArgumentsNode args;
  final ExpressionNode body;

  @override
  String toString() => 'LambdaNode($args: $body)';
}

/// Ternary conditional expression (`body if test else orelse`).
class IfExpNode extends ExpressionNode {
  const new({required this.test, required this.body, required this.orelse});

  final ExpressionNode test;
  final ExpressionNode body;
  final ExpressionNode orelse;

  @override
  String toString() => 'IfExpNode($body if $test else $orelse)';
}

/// Dictionary literal (`{k1: v1, **rest}`).
class DictNode extends ExpressionNode {
  const new({this.keys = const [], this.values = const []});

  final List<ExpressionNode?> keys;
  final List<ExpressionNode> values;

  @override
  String toString() => 'DictNode(pairs: ${values.length})';
}

/// Set literal (`{1, 2, 3}`).
class SetNode extends ExpressionNode {
  const new({this.elements = const []});

  final List<ExpressionNode> elements;

  @override
  String toString() => 'SetNode($elements)';
}

/// List comprehension (`[x for x in data if cond]`).
class ListCompNode extends ExpressionNode {
  const new({required this.element, required this.generators});

  final ExpressionNode element;
  final List<ComprehensionNode> generators;

  @override
  String toString() => 'ListCompNode($element, $generators)';
}

/// Set comprehension (`{x for x in data if cond]`).
class SetCompNode extends ExpressionNode {
  const new({required this.element, required this.generators});

  final ExpressionNode element;
  final List<ComprehensionNode> generators;

  @override
  String toString() => 'SetCompNode($element, $generators)';
}

/// Dict comprehension (`{k: v for k, v in data}`).
class DictCompNode extends ExpressionNode {
  const new({required this.key, required this.value, required this.generators});

  final ExpressionNode key;
  final ExpressionNode value;
  final List<ComprehensionNode> generators;

  @override
  String toString() => 'DictCompNode($key: $value, $generators)';
}

/// Generator expression (`(x for x in data)`).
class GeneratorExpNode extends ExpressionNode {
  const new({required this.element, required this.generators});

  final ExpressionNode element;
  final List<ComprehensionNode> generators;

  @override
  String toString() => 'GeneratorExpNode($element, $generators)';
}

/// Await expression (`await coro`).
class AwaitNode extends ExpressionNode {
  const new(this.value);

  final ExpressionNode value;

  @override
  String toString() => 'AwaitNode($value)';
}

/// Yield expression (`yield value`).
class YieldNode extends ExpressionNode {
  const new([this.value]);

  final ExpressionNode? value;

  @override
  String toString() => 'YieldNode($value)';
}

/// Yield from expression (`yield from gen`).
class YieldFromNode extends ExpressionNode {
  const new(this.value);

  final ExpressionNode value;

  @override
  String toString() => 'YieldFromNode($value)';
}

/// Comparison expression with chaining support (`a < b <= c`).
class CompareNode extends ExpressionNode {
  const new({
    required this.left,
    required this.operators,
    required this.comparators,
  });

  final ExpressionNode left;
  final List<String> operators;
  final List<ExpressionNode> comparators;

  @override
  String toString() =>
      'CompareNode($left, ops: $operators, comps: $comparators)';
}

/// Function / method call expression (`f(a, b, c=1)`).
class CallNode extends ExpressionNode {
  const new({
    required this.function,
    this.args = const [],
    this.keywords = const [],
  });

  final ExpressionNode function;
  final List<ExpressionNode> args;
  final List<KeywordNode> keywords;

  @override
  String toString() => 'CallNode($function, args: $args, kw: $keywords)';
}

/// Formatted value inside an f-string (`{x!r:.2f}`).
class FormattedValueNode extends ExpressionNode {
  const new({required this.value, this.conversion, this.formatSpec});

  final ExpressionNode value;
  final String? conversion;
  final String? formatSpec;

  @override
  String toString() =>
      'FormattedValueNode($value, conv: $conversion, spec: $formatSpec)';
}

/// Joined f-string (`f"hello {name}"`).
class JoinedStrNode extends ExpressionNode {
  const new(this.values);

  final List<ExpressionNode> values;

  @override
  String toString() => 'JoinedStrNode($values)';
}

/// Literal constant (numbers, strings, booleans, None, Ellipsis).
class ConstantNode extends ExpressionNode {
  const new(this.value);

  final Object? value;

  @override
  String toString() => 'ConstantNode($value)';
}

/// Attribute access (`value.attr`).
class AttributeNode extends ExpressionNode {
  const new({required this.value, required this.attribute});

  final ExpressionNode value;
  final String attribute;

  @override
  String toString() => 'AttributeNode($value.$attribute)';
}

/// Subscript indexing or slicing (`value[slice]`).
class SubscriptNode extends ExpressionNode {
  const new({required this.value, required this.slice});

  final ExpressionNode value;
  final ExpressionNode slice;

  @override
  String toString() => 'SubscriptNode($value[$slice])';
}

/// Starred expression (`*args`).
class StarredNode extends ExpressionNode {
  const new(this.value);

  final ExpressionNode value;

  @override
  String toString() => 'StarredNode(*$value)';
}

/// Identifier variable name (`foo`).
class NameNode extends ExpressionNode {
  const new(this.id);

  final String id;

  @override
  String toString() => 'NameNode($id)';
}

/// List literal (`[a, b, c]`).
class ListNode extends ExpressionNode {
  const new({this.elements = const []});

  final List<ExpressionNode> elements;

  @override
  String toString() => 'ListNode($elements)';
}

/// Tuple literal (`(a, b, c)` or `a, b`).
class TupleNode extends ExpressionNode {
  const new({this.elements = const []});

  final List<ExpressionNode> elements;

  @override
  String toString() => 'TupleNode($elements)';
}

/// Slice expression used in subscripts (`lower:upper:step`).
class SliceNode extends ExpressionNode {
  const new({this.lower, this.upper, this.step});

  final ExpressionNode? lower;
  final ExpressionNode? upper;
  final ExpressionNode? step;

  @override
  String toString() => 'SliceNode($lower:$upper:$step)';
}

// ---------------------------------------------------------------------------
// Match Patterns (Python 3.10+)
// ---------------------------------------------------------------------------

/// Base class for pattern matching in `match` statements.
sealed class PatternNode extends PythonNode {
  const new();
}

/// Literal value pattern (`case 1:` or `case "abc":`).
class MatchValueNode extends PatternNode {
  const new(this.value);

  final ExpressionNode value;

  @override
  String toString() => 'MatchValueNode($value)';
}

/// Singleton pattern (`case None:` or `case True:` or `case False:`).
class MatchSingletonNode extends PatternNode {
  const new(this.value);

  final Object? value;

  @override
  String toString() => 'MatchSingletonNode($value)';
}

/// Sequence pattern (`case [x, y]:` or `case (x, y):`).
class MatchSequenceNode extends PatternNode {
  const new(this.patterns);

  final List<PatternNode> patterns;

  @override
  String toString() => 'MatchSequenceNode($patterns)';
}

/// Mapping pattern (`case {"name": name, **rest}:`).
class MatchMappingNode extends PatternNode {
  const new({this.keys = const [], this.patterns = const [], this.rest});

  final List<ExpressionNode> keys;
  final List<PatternNode> patterns;
  final String? rest;

  @override
  String toString() =>
      'MatchMappingNode(keys: $keys, patterns: $patterns, rest: $rest)';
}

/// Class pattern (`case Point(x, y, z=0):`).
class MatchClassNode extends PatternNode {
  const new({
    required this.cls,
    this.patterns = const [],
    this.kwdAttrs = const [],
    this.kwdPatterns = const [],
  });

  final ExpressionNode cls;
  final List<PatternNode> patterns;
  final List<String> kwdAttrs;
  final List<PatternNode> kwdPatterns;

  @override
  String toString() => 'MatchClassNode(cls: $cls, patterns: $patterns)';
}

/// Star pattern in sequences (`case [first, *rest]:` or wildcard `case _:`).
class MatchStarNode extends PatternNode {
  const new([this.name]);

  final String? name;

  @override
  String toString() => 'MatchStarNode($name)';
}

/// As-pattern (`case pattern as name:` or simple capture `case name:`).
class MatchAsNode extends PatternNode {
  const new({this.pattern, this.name});

  final PatternNode? pattern;
  final String? name;

  @override
  String toString() => 'MatchAsNode(pattern: $pattern, as: $name)';
}

/// Or-pattern (`case p1 | p2 | p3:`).
class MatchOrNode extends PatternNode {
  const new(this.patterns);

  final List<PatternNode> patterns;

  @override
  String toString() => 'MatchOrNode($patterns)';
}

// ---------------------------------------------------------------------------
// Auxiliary Elements
// ---------------------------------------------------------------------------

/// Function argument definition.
class ArgNode extends PythonNode {
  const new({required this.arg, this.annotation});

  final String arg;
  final ExpressionNode? annotation;

  @override
  String toString() =>
      'ArgNode($arg${annotation != null ? ': $annotation' : ''})';
}

/// Function parameter list (`def foo(a, b=1, *args, c=2, **kwargs):`).
class ArgumentsNode extends PythonNode {
  const new({
    this.posonlyargs = const [],
    this.args = const [],
    this.vararg,
    this.kwonlyargs = const [],
    this.kwDefaults = const [],
    this.kwarg,
    this.defaults = const [],
  });

  final List<ArgNode> posonlyargs;
  final List<ArgNode> args;
  final ArgNode? vararg;
  final List<ArgNode> kwonlyargs;
  final List<ExpressionNode?> kwDefaults;
  final ArgNode? kwarg;
  final List<ExpressionNode> defaults;

  @override
  String toString() => 'ArgumentsNode(pos: $args, defaults: $defaults)';
}

/// Keyword argument in calls or class headers (`name=value` or `**kw`).
class KeywordNode extends PythonNode {
  const new({this.arg, required this.value});

  final String? arg;
  final ExpressionNode value;

  @override
  String toString() => 'KeywordNode(${arg != null ? '$arg=' : '**'}$value)';
}

/// Comprehension clause (`for target in iter if cond`).
class ComprehensionNode extends PythonNode {
  const new({
    required this.target,
    required this.iter,
    this.ifs = const [],
    this.isAsync = false,
  });

  final ExpressionNode target;
  final ExpressionNode iter;
  final List<ExpressionNode> ifs;
  final bool isAsync;

  @override
  String toString() =>
      'ComprehensionNode(${isAsync ? 'async ' : ''}for $target in $iter)';
}

/// Except handler in `try` statement (`except Error as e:`).
class ExceptHandlerNode extends PythonNode {
  const new({this.type, this.name, required this.body});

  final ExpressionNode? type;
  final String? name;
  final List<StatementNode> body;

  @override
  String toString() => 'ExceptHandlerNode(type: $type, as: $name)';
}

/// Match case in `match` statement (`case pattern if guard: body`).
class MatchCaseNode extends PythonNode {
  const new({required this.pattern, this.guard, required this.body});

  final PatternNode pattern;
  final ExpressionNode? guard;
  final List<StatementNode> body;

  @override
  String toString() => 'MatchCaseNode(pattern: $pattern, guard: $guard)';
}

/// With item (`context_expr as optional_vars`).
class WithItemNode extends PythonNode {
  const new({required this.contextExpr, this.optionalVars});

  final ExpressionNode contextExpr;
  final ExpressionNode? optionalVars;

  @override
  String toString() => 'WithItemNode($contextExpr as $optionalVars)';
}

/// Import alias (`module as asname`).
class AliasNode extends PythonNode {
  const new({required this.name, this.asname});

  final String name;
  final String? asname;

  @override
  String toString() => 'AliasNode($name${asname != null ? ' as $asname' : ''})';
}

/// PEP 695 type parameter (`[T, *Ts, **P]`).
sealed class TypeParamNode extends PythonNode {
  const new(this.name);

  final String name;
}

/// Simple type variable (`T: str = int`).
class TypeVarParamNode extends TypeParamNode {
  const new(super.name, {this.bound, this.defaultValue});

  final ExpressionNode? bound;
  final ExpressionNode? defaultValue;

  @override
  String toString() => 'TypeVarParamNode($name)';
}

/// Parameter specification (`**P`).
class ParamSpecNode extends TypeParamNode {
  const new(super.name, {this.defaultValue});

  final ExpressionNode? defaultValue;

  @override
  String toString() => 'ParamSpecNode($name)';
}

/// Type variable tuple (`*Ts`).
class TypeVarTupleNode extends TypeParamNode {
  const new(super.name, {this.defaultValue});

  final ExpressionNode? defaultValue;

  @override
  String toString() => 'TypeVarTupleNode($name)';
}

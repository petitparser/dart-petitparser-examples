/// An abstract mathematical expression that can be evaluated.
abstract class Expression {
  /// Evaluates this expression using the variable bindings in [variables].
  num eval(Map<String, num> variables);
}

/// A literal numeric value expression.
class Value extends Expression {
  /// Creates a literal numeric [value] expression.
  new(this.value);

  /// The literal numeric value.
  final num value;

  @override
  num eval(Map<String, num> variables) => value;

  @override
  String toString() => 'Value{$value}';
}

/// A named variable expression resolved from a variable map.
class Variable extends Expression {
  /// Creates a variable expression referencing [name].
  new(this.name);

  /// The name of the variable to look up.
  final String name;

  @override
  num eval(Map<String, num> variables) =>
      variables[name] ?? (throw ArgumentError.value(name, 'Unknown variable'));

  @override
  String toString() => 'Variable{$name}';
}

/// A function or operator application expression.
class Application extends Expression {
  /// Creates a function application with [name], [arguments], and evaluation [function].
  new(this.name, this.arguments, this.function);

  /// The name of the operator or function.
  final String name;

  /// The argument expressions passed to the function.
  final List<Expression> arguments;

  /// The underlying Dart function used to evaluate this application.
  final Function function;

  @override
  num eval(Map<String, num> variables) => Function.apply(
    function,
    arguments.map((argument) => argument.eval(variables)).toList(),
  );

  @override
  String toString() => 'Application{$name}';
}

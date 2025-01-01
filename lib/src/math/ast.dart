/// An abstract expression that can be evaluated.
abstract class Expression {
  /// Evaluates the expression with the provided [variables].
  num eval(Map<String, num> variables);
}

/// A value expression.
class Value extends Expression {
  Value(this.value);

  final num value;

  @override
  num eval(Map<String, num> variables) => value;

  @override
  String toString() => 'Value{$value}';
}

/// A variable expression.
class Variable extends Expression {
  Variable(this.name);

  final String name;

  @override
  num eval(Map<String, num> variables) => variables.containsKey(name)
      ? variables[name]!
      : throw ArgumentError.value(name, 'Unknown variable');

  @override
  String toString() => 'Variable{$name}';
}

/// A function application.
class Application extends Expression {
  Application(this.name, this.arguments, this.function);

  final String name;
  final List<Expression> arguments;
  final Function function;

  @override
  num eval(Map<String, num> variables) => Function.apply(
      function, arguments.map((argument) => argument.eval(variables)).toList());

  @override
  String toString() => 'Application{$name}';
}

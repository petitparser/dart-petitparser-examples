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
      : throw 'Unknown variable $name';

  @override
  String toString() => 'Variable{$name}';
}

/// An unary expression.
class Unary extends Expression {
  Unary(this.name, this.value, this.function);

  final String name;
  final Expression value;
  final num Function(num value) function;

  @override
  num eval(Map<String, num> variables) => function(value.eval(variables));

  @override
  String toString() => 'Unary{$name}';
}

/// A binary expression.
class Binary extends Expression {
  Binary(this.name, this.left, this.right, this.function);

  final String name;
  final Expression left;
  final Expression right;
  final num Function(num left, num right) function;

  @override
  num eval(Map<String, num> variables) =>
      function(left.eval(variables), right.eval(variables));

  @override
  String toString() => 'Binary{$name}';
}

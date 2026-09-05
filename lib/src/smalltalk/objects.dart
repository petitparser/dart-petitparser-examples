// Basic classes
final objectBehavior = Behavior('Object');
final classBehavior = Behavior('Class');

// Native classes
final arrayBehavior = Behavior('Array');
final falseBehavior = Behavior('False');
final numberBehavior = Behavior('Number');
final stringBehavior = Behavior('String');
final trueBehavior = Behavior('True');
final undefinedBehavior = Behavior('Undefined');

extension BehaviorAccessor on Object? {
  Behavior get behavior => switch (this) {
    null => undefinedBehavior,
    true => trueBehavior,
    false => falseBehavior,
    num _ => numberBehavior,
    String _ => stringBehavior,
    List _ => arrayBehavior,
    final SmalltalkObject object => object.behavior,
    _ => throw UnsupportedError('Unsupported object type: $runtimeType'),
  };
}

class SmalltalkObject {
  new(this.behavior);

  Behavior behavior;
  Map<String, Object> fields = {};
}

class Behavior extends SmalltalkObject {
  new(this.name) : super(classBehavior);

  String name;
  Map<String, Function> methods = {};

  void addMethod(String selector, Function function) =>
      methods[selector] = function;
}

void bootstrap() {
  objectBehavior.addMethod('printString', (self) => self.toString());
  objectBehavior.addMethod('class', (self) => self.behavior);
  objectBehavior.addMethod('isNil', (self) => false);

  undefinedBehavior.addMethod('isNil', (self) => true);

  trueBehavior.addMethod('ifTrue:', (self, trueBranch) => trueBranch());
  trueBehavior.addMethod(
    'ifTrue:ifFalse:',
    (self, trueBranch, falseBranch) => trueBranch(),
  );
  trueBehavior.addMethod('ifFalse:', (self, falseBranch) => null);
  trueBehavior.addMethod(
    'ifFalse:ifTrue:',
    (self, falseBranch, trueBranch) => trueBranch(),
  );
  trueBehavior.addMethod('not', (self) => false);
  trueBehavior.addMethod('and:', (self, other) => other());
  trueBehavior.addMethod('or:', (self, other) => true);

  falseBehavior.addMethod('ifTrue:', (self, trueBranch) => null);
  falseBehavior.addMethod(
    'ifTrue:ifFalse:',
    (self, trueBranch, falseBranch) => falseBranch(),
  );
  falseBehavior.addMethod('ifFalse:', (self, falseBranch) => falseBranch());
  falseBehavior.addMethod(
    'ifFalse:ifTrue:',
    (self, falseBranch, trueBranch) => falseBranch(),
  );
  falseBehavior.addMethod('not', (self) => true);
  falseBehavior.addMethod('and:', (self, other) => false);
  falseBehavior.addMethod('or:', (self, other) => other());

  numberBehavior.addMethod('+', (self, other) => self + other);
  numberBehavior.addMethod('-', (self, other) => self - other);
  numberBehavior.addMethod('*', (self, other) => self * other);
  numberBehavior.addMethod('/', (self, other) => self / other);
  numberBehavior.addMethod('//', (self, other) => self ~/ other);
  numberBehavior.addMethod('\\', (self, other) => self % other);
  numberBehavior.addMethod('negate', (self) => -self);
  numberBehavior.addMethod('<', (self, other) => self < other);
  numberBehavior.addMethod('<=', (self, other) => self <= other);
  numberBehavior.addMethod('>', (self, other) => self > other);
  numberBehavior.addMethod('>=', (self, other) => self >= other);
  numberBehavior.addMethod('=', (self, other) => self < other);

  stringBehavior.addMethod('+', (self, other) => self + other);
  stringBehavior.addMethod('size', (self, other) => self.length);
  stringBehavior.addMethod('at:', (self, index) => self[index]);
  stringBehavior.addMethod('<', (self, other) => self < other);
  stringBehavior.addMethod('<=', (self, other) => self <= other);
  stringBehavior.addMethod('>', (self, other) => self > other);
  stringBehavior.addMethod('>=', (self, other) => self >= other);
  stringBehavior.addMethod('=', (self, other) => self < other);

  arrayBehavior.addMethod('size', (self) => self.length);
  arrayBehavior.addMethod('at:', (self, index) => self[index]);
  arrayBehavior.addMethod(
    'at:put:',
    (self, index, object) => self[index] = object,
  );

  classBehavior.addMethod('new', SmalltalkObject.new);
}

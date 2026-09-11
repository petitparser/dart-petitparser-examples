import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/smalltalk.dart';
import 'package:web/web.dart' hide Node;

final input = document.querySelector('#input') as HTMLTextAreaElement;
final production = document.querySelector('#production') as HTMLSelectElement;
final action = document.querySelector('#action') as HTMLButtonElement;
final stats = document.querySelector('#stats') as HTMLElement;
final output = document.querySelector('#output') as HTMLElement;

final btnComprehensive =
    document.querySelector('#btn-comprehensive') as HTMLButtonElement;
final btnBenchmark =
    document.querySelector('#btn-benchmark') as HTMLButtonElement;
final btnCascade = document.querySelector('#btn-cascade') as HTMLButtonElement;
final btnExpression =
    document.querySelector('#btn-expression') as HTMLButtonElement;

final parserDefinition = SmalltalkParserDefinition();

Parser<Object?> getParser(String prod) => switch (prod) {
  'expression' => parserDefinition.buildFrom(parserDefinition.expression()),
  'sequence' => parserDefinition.buildFrom(parserDefinition.sequence()),
  _ => parserDefinition.build(),
};

const presets = {
  'comprehensive': '''exampleWithNumber: x
  "A method that illustrates every part of Smalltalk method syntax
  except primitives. It has unary, binary, and keyword messages,
  declares arguments and temporaries, accesses a global variable
  (but not an instance variable), uses literals (array, character,
  symbol, string, integer, float), uses the pseudo variables
  true, false, nil, self, and super, and has sequence, assignment,
  return and cascade. It has both zero argument and one argument blocks."

  |y|
  y := true & false not & (nil isNil) ifFalse: [self halt].
  self size + super size.
  #(\$a #a "a" 1 1.0)
      do: [:each | Transcript show: (each class name); show: ' ' ]''',
  'benchmark': '''transform: aCollection with: aBlock filter: aPredicate
  <primitive: 123 error: ec>
  | result count item |
  result := Array new: aCollection size.
  count := 0.
  1 to: aCollection size do: [ :index |
    item := aCollection at: index.
    (aPredicate value: item) ifTrue: [
      count := count + 1.
      result at: count put: (aBlock value: item) ]
    ifFalse: [ Transcript show: 'skipped'; cr ] ].
  count = 0 ifTrue: [ ^ #() ].
  ^ result copyFrom: 1 to: count''',
  'cascade': '''drawOn: aCanvas
  aCanvas
    saveState;
    setFillColor: Color red;
    fillRectangle: (0@0 extent: 100@100);
    restoreState''',
  'expression': '''(matrix at: row and: col) * 3.14159 + (vector dotProduct: otherVector) abs''',
};

int countNodes(Node node) {
  final visitor = NodeCountVisitor();
  visitor.visit(node);
  return visitor.count;
}

class NodeCountVisitor extends Visitor {
  var count = 0;

  @override
  void visit(Node node) {
    count++;
    super.visit(node);
  }
}

class HtmlAstVisitor extends Visitor {
  final buffer = StringBuffer();
  var _indent = 0;

  void _writeIndent() {
    buffer.write('  ' * _indent);
  }

  void _writeNodeHeader(String type, [String? extra]) {
    _writeIndent();
    buffer.write('<span class="node-type">$type</span>');
    if (extra != null && extra.isNotEmpty) {
      buffer.write(' <span class="node-val">$extra</span>');
    }
    buffer.write('\n');
  }

  void _writeProperty(String name, [String? value]) {
    _writeIndent();
    buffer.write('  <span class="node-prop">$name:</span>');
    if (value != null) {
      buffer.write(' <span class="node-val">$value</span>\n');
    } else {
      buffer.write('\n');
    }
  }

  void _nested(void Function() callback) {
    _indent++;
    callback();
    _indent--;
  }

  @override
  void visitMethodNode(MethodNode node) {
    _writeNodeHeader('MethodNode', node.selector);
    _nested(() {
      if (node.arguments.isNotEmpty) {
        _writeProperty(
          'arguments',
          node.arguments.map((a) => a.name).join(', '),
        );
      }
      if (node.pragmas.isNotEmpty) {
        _writeProperty('pragmas');
        _nested(() {
          for (final pragma in node.pragmas) {
            visit(pragma);
          }
        });
      }
      _writeProperty('body');
      _nested(() => visit(node.body));
    });
  }

  @override
  void visitPragmaNode(PragmaNode node) {
    _writeNodeHeader('PragmaNode', node.selector);
    if (node.arguments.isNotEmpty) {
      _nested(() {
        _writeProperty('arguments');
        _nested(() {
          for (final arg in node.arguments) {
            visit(arg);
          }
        });
      });
    }
  }

  @override
  void visitReturnNode(ReturnNode node) {
    _writeNodeHeader('ReturnNode');
    _nested(() {
      _writeProperty('value');
      _nested(() => visit(node.value));
    });
  }

  @override
  void visitSequenceNode(SequenceNode node) {
    _writeNodeHeader('SequenceNode');
    _nested(() {
      if (node.temporaries.isNotEmpty) {
        _writeProperty(
          'temporaries',
          node.temporaries.map((t) => t.name).join(', '),
        );
      }
      if (node.statements.isNotEmpty) {
        _writeProperty('statements');
        _nested(() {
          for (final stmt in node.statements) {
            visit(stmt);
          }
        });
      }
    });
  }

  @override
  void visitArrayNode(ArrayNode node) {
    _writeNodeHeader('ArrayNode');
    if (node.statements.isNotEmpty) {
      _nested(() {
        _writeProperty('elements');
        _nested(() {
          for (final stmt in node.statements) {
            visit(stmt);
          }
        });
      });
    }
  }

  @override
  void visitAssignmentNode(AssignmentNode node) {
    _writeNodeHeader('AssignmentNode');
    _nested(() {
      _writeProperty('variable', node.variable.name);
      _writeProperty('value');
      _nested(() => visit(node.value));
    });
  }

  @override
  void visitBlockNode(BlockNode node) {
    _writeNodeHeader('BlockNode');
    _nested(() {
      if (node.arguments.isNotEmpty) {
        _writeProperty(
          'arguments',
          node.arguments.map((a) => a.name).join(', '),
        );
      }
      _writeProperty('body');
      _nested(() => visit(node.body));
    });
  }

  @override
  void visitCascadeNode(CascadeNode node) {
    _writeNodeHeader('CascadeNode');
    _nested(() {
      _writeProperty('receiver');
      _nested(() => visit(node.receiver));
      _writeProperty('messages');
      _nested(() {
        for (final msg in node.messages) {
          visit(msg);
        }
      });
    });
  }

  @override
  void visitLiteralArrayNode(LiteralArrayNode node) {
    _writeNodeHeader('LiteralArrayNode', node.value.toString());
  }

  @override
  void visitLiteralValueNode(LiteralValueNode node) {
    final valStr = node.value is String
        ? '<span class="node-str">\'${node.value}\'</span>'
        : node.value.toString();
    _writeNodeHeader('LiteralValueNode', valStr);
  }

  @override
  void visitMessageNode(MessageNode node) {
    _writeNodeHeader('MessageNode', node.selector);
    _nested(() {
      _writeProperty('receiver');
      _nested(() => visit(node.receiver));
      if (node.arguments.isNotEmpty) {
        _writeProperty('arguments');
        _nested(() {
          for (final arg in node.arguments) {
            visit(arg);
          }
        });
      }
    });
  }

  @override
  void visitVariableNode(VariableNode node) {
    _writeNodeHeader('VariableNode', node.name);
  }
}

void parseInput() {
  final text = input.value;
  final prod = production.value;
  final currentParser = getParser(prod);

  final stopwatch = Stopwatch()..start();
  final result = currentParser.end().parse(text);
  stopwatch.stop();

  if (result is Success) {
    final val = result.value;
    var nodeCount = 0;
    String formattedTree;

    if (val is Node) {
      nodeCount = countNodes(val);
      final visitor = HtmlAstVisitor();
      visitor.visit(val);
      formattedTree = visitor.buffer.toString();
    } else {
      formattedTree = '<span class="node-val">$val</span>';
    }

    stats.innerHTML =
        'Parsed <span>${text.length}</span> characters into <span>$nodeCount</span> AST nodes in <span>${stopwatch.elapsedMicroseconds} &micro;s</span>.'
            .toJS;
    output.className = '';
    output.innerHTML = formattedTree.toJS;
  } else {
    stats.innerHTML =
        'Parse failed after <span>${stopwatch.elapsedMicroseconds} &micro;s</span>.'
            .toJS;
    output.className = 'error';
    output.textContent = '${result.message} at ${result.toPositionString()}';
  }
}

void setPreset(String key, String prod) {
  input.value = presets[key]!;
  production.value = prod;
  parseInput();
}

void main() {
  action.onClick.listen((_) => parseInput());
  production.onChange.listen((_) => parseInput());
  input.onInput.listen((_) => parseInput());

  btnComprehensive.onClick.listen(
    (_) => setPreset('comprehensive', 'startMethod'),
  );
  btnBenchmark.onClick.listen((_) => setPreset('benchmark', 'startMethod'));
  btnCascade.onClick.listen((_) => setPreset('cascade', 'startMethod'));
  btnExpression.onClick.listen((_) => setPreset('expression', 'expression'));

  setPreset('comprehensive', 'startMethod');
}

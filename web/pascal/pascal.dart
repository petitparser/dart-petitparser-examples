import 'dart:js_interop';

import 'package:petitparser/petitparser.dart';
import 'package:petitparser_examples/pascal.dart';
import 'package:web/web.dart';

import '../shared/shared.dart';

final input = document.querySelector('#input') as HTMLTextAreaElement;
final production = document.querySelector('#production') as HTMLSelectElement;
final action = document.querySelector('#action') as HTMLButtonElement;
final stats = document.querySelector('#stats') as HTMLElement;
final output = document.querySelector('#output') as HTMLElement;

final btnProgram = document.querySelector('#btn-program') as HTMLButtonElement;
final btnStrings = document.querySelector('#btn-strings') as HTMLButtonElement;
final btnRecords = document.querySelector('#btn-records') as HTMLButtonElement;
final btnExpression =
    document.querySelector('#btn-expression') as HTMLButtonElement;

final parserDefinition = PascalParserDefinition();

Parser<Object?> getParser(String prod) => switch (prod) {
  'block' => parserDefinition.buildFrom(parserDefinition.block()).end(),
  'statement' => parserDefinition.buildFrom(parserDefinition.statement()).end(),
  'expression' =>
    parserDefinition.buildFrom(parserDefinition.expression()).end(),
  'type' => parserDefinition.buildFrom(parserDefinition.type()).end(),
  _ => parserDefinition.build(),
};

const presets = {
  'program': '''program CalculateStats(input, output);
const
  MaxElements = 100;
  Threshold = 0.05;
type
  DataArray = array [1..MaxElements] of Real;
var
  data: DataArray;
  n, i: Integer;
  sum, mean: Real;

procedure LoadData(var count: Integer);
begin
  count := 10;
  for i := 1 to count do
    data[i] := i * 1.5;
end;

begin
  LoadData(n);
  sum := 0.0;
  for i := 1 to n do
    sum := sum + data[i];
  mean := sum / n;
  if mean > Threshold then
    WriteLn('Mean exceeds threshold: ', mean)
  else
    WriteLn('Mean is within limits');
end.''',
  'strings': '''program CompareStrings;
var
  s, t: String;
begin
  s := 'something';
  t := 'something bigger';
  if s = t then
    WriteLn(s, ' is equal to ', t)
  else
    if s > t then
      WriteLn(s, ' is greater than ', t)
    else
      WriteLn(s, ' is less than ', t);
end.''',
  'records': '''program GeometryDemo;
type
  Point = record
    x, y: Real;
  end;
  Circle = record
    center: Point;
    radius: Real;
  end;
var
  c: Circle;
begin
  c.center.x := 10.0;
  c.center.y := 20.0;
  c.radius := 5.0;
  WriteLn('Circle at (', c.center.x, ', ', c.center.y, ')');
end.''',
  'expression':
      '''(matrix[i, j] + offset) * 2.5 <= threshold or (status = active)''',
};

int countNodes(PascalNode node) {
  var count = 1;
  for (final child in node.children) {
    count += countNodes(child);
  }
  return count;
}

class HtmlPascalAstVisitor implements PascalVisitor<void, void> {
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
    buffer.write('<span class="node-prop">$name:</span>');
    if (value != null) {
      buffer.write('<span class="node-val">$value</span>\n');
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
  void visitProgram(ProgramNode node, void context) {
    _writeNodeHeader('ProgramNode', node.name);
    _nested(() {
      if (node.parameters.isNotEmpty) {
        _writeProperty('parameters', node.parameters.join(', '));
      }
      _writeProperty('block');
      _nested(() => node.block.accept(this));
    });
  }

  @override
  void visitBlock(BlockNode node, void context) {
    _writeNodeHeader('BlockNode');
    _nested(() {
      if (node.labels.isNotEmpty) {
        _writeProperty('labels', node.labels.join(', '));
      }
      if (node.constants.isNotEmpty) {
        _writeProperty('constants');
        _nested(() {
          for (final c in node.constants) {
            c.accept(this);
          }
        });
      }
      if (node.types.isNotEmpty) {
        _writeProperty('types');
        _nested(() {
          for (final t in node.types) {
            t.accept(this);
          }
        });
      }
      if (node.variables.isNotEmpty) {
        _writeProperty('variables');
        _nested(() {
          for (final v in node.variables) {
            v.accept(this);
          }
        });
      }
      if (node.subroutines.isNotEmpty) {
        _writeProperty('subroutines');
        _nested(() {
          for (final s in node.subroutines) {
            s.accept(this);
          }
        });
      }
      _writeProperty('statement');
      _nested(() => node.statement.accept(this));
    });
  }

  @override
  void visitConstantDefinition(ConstantDefinitionNode node, void context) {
    _writeNodeHeader('ConstantDefinitionNode', node.name);
    _nested(() {
      _writeProperty('value');
      _nested(() => node.value.accept(this));
    });
  }

  @override
  void visitTypeDefinition(TypeDefinitionNode node, void context) {
    _writeNodeHeader('TypeDefinitionNode', node.name);
    _nested(() {
      _writeProperty('type');
      _nested(() => node.type.accept(this));
    });
  }

  @override
  void visitVariableDeclaration(VariableDeclarationNode node, void context) {
    _writeNodeHeader('VariableDeclarationNode', node.names.join(', '));
    _nested(() {
      _writeProperty('type');
      _nested(() => node.type.accept(this));
    });
  }

  @override
  void visitFormalParameter(FormalParameterNode node, void context) {
    final prefix = node.isVar ? 'var ' : '';
    _writeNodeHeader('FormalParameterNode', '$prefix${node.names.join(', ')}');
    if (node.type != null) {
      _nested(() {
        _writeProperty('type');
        _nested(() => node.type!.accept(this));
      });
    }
  }

  @override
  void visitProcedure(ProcedureNode node, void context) {
    _writeNodeHeader('ProcedureNode', node.name);
    _nested(() {
      if (node.parameters.isNotEmpty) {
        _writeProperty('parameters');
        _nested(() {
          for (final p in node.parameters) {
            p.accept(this);
          }
        });
      }
      _writeProperty('block');
      _nested(() => node.block.accept(this));
    });
  }

  @override
  void visitFunction(FunctionNode node, void context) {
    _writeNodeHeader('FunctionNode', node.name);
    _nested(() {
      if (node.parameters.isNotEmpty) {
        _writeProperty('parameters');
        _nested(() {
          for (final p in node.parameters) {
            p.accept(this);
          }
        });
      }
      _writeProperty('returnType');
      _nested(() => node.returnType.accept(this));
      _writeProperty('block');
      _nested(() => node.block.accept(this));
    });
  }

  @override
  void visitSimpleType(SimpleTypeNode node, void context) {
    _writeNodeHeader('SimpleTypeNode', node.name);
  }

  @override
  void visitSubrangeType(SubrangeTypeNode node, void context) {
    _writeNodeHeader('SubrangeTypeNode');
    _nested(() {
      _writeProperty('start');
      _nested(() => node.start.accept(this));
      _writeProperty('end');
      _nested(() => node.end.accept(this));
    });
  }

  @override
  void visitEnumeratedType(EnumeratedTypeNode node, void context) {
    _writeNodeHeader('EnumeratedTypeNode', '(${node.values.join(', ')})');
  }

  @override
  void visitPointerType(PointerTypeNode node, void context) {
    _writeNodeHeader('PointerTypeNode');
    _nested(() {
      _writeProperty('baseType');
      _nested(() => node.baseType.accept(this));
    });
  }

  @override
  void visitArrayType(ArrayTypeNode node, void context) {
    _writeNodeHeader('ArrayTypeNode');
    _nested(() {
      _writeProperty('indices');
      _nested(() {
        for (final idx in node.indices) {
          idx.accept(this);
        }
      });
      _writeProperty('elementType');
      _nested(() => node.elementType.accept(this));
    });
  }

  @override
  void visitRecordType(RecordTypeNode node, void context) {
    _writeNodeHeader('RecordTypeNode');
    _nested(() {
      _writeProperty('fields');
      _nested(() {
        for (final f in node.fields) {
          f.accept(this);
        }
      });
    });
  }

  @override
  void visitSetType(SetTypeNode node, void context) {
    _writeNodeHeader('SetTypeNode');
    _nested(() {
      _writeProperty('baseType');
      _nested(() => node.baseType.accept(this));
    });
  }

  @override
  void visitFileType(FileTypeNode node, void context) {
    _writeNodeHeader('FileTypeNode');
    if (node.baseType != null) {
      _nested(() {
        _writeProperty('baseType');
        _nested(() => node.baseType!.accept(this));
      });
    }
  }

  @override
  void visitCompoundStatement(CompoundStatementNode node, void context) {
    _writeNodeHeader('CompoundStatementNode', node.label);
    _nested(() {
      for (final stmt in node.statements) {
        stmt.accept(this);
      }
    });
  }

  @override
  void visitAssignmentStatement(AssignmentStatementNode node, void context) {
    _writeNodeHeader('AssignmentStatementNode', node.label);
    _nested(() {
      _writeProperty('variable');
      _nested(() => node.variable.accept(this));
      _writeProperty('value');
      _nested(() => node.value.accept(this));
    });
  }

  @override
  void visitProcedureStatement(ProcedureStatementNode node, void context) {
    _writeNodeHeader('ProcedureStatementNode', node.name);
    if (node.arguments.isNotEmpty) {
      _nested(() {
        _writeProperty('arguments');
        _nested(() {
          for (final arg in node.arguments) {
            arg.accept(this);
          }
        });
      });
    }
  }

  @override
  void visitIfStatement(IfStatementNode node, void context) {
    _writeNodeHeader('IfStatementNode', node.label);
    _nested(() {
      _writeProperty('condition');
      _nested(() => node.condition.accept(this));
      _writeProperty('thenStatement');
      _nested(() => node.thenStatement.accept(this));
      if (node.elseStatement != null) {
        _writeProperty('elseStatement');
        _nested(() => node.elseStatement!.accept(this));
      }
    });
  }

  @override
  void visitCaseStatement(CaseStatementNode node, void context) {
    _writeNodeHeader('CaseStatementNode', node.label);
    _nested(() {
      _writeProperty('expression');
      _nested(() => node.expression.accept(this));
      _writeProperty('cases');
      _nested(() {
        for (final c in node.cases) {
          c.accept(this);
        }
      });
    });
  }

  @override
  void visitCaseElement(CaseElementNode node, void context) {
    _writeNodeHeader('CaseElementNode');
    _nested(() {
      _writeProperty('constants');
      _nested(() {
        for (final c in node.constants) {
          c.accept(this);
        }
      });
      _writeProperty('statement');
      _nested(() => node.statement.accept(this));
    });
  }

  @override
  void visitWhileStatement(WhileStatementNode node, void context) {
    _writeNodeHeader('WhileStatementNode', node.label);
    _nested(() {
      _writeProperty('condition');
      _nested(() => node.condition.accept(this));
      _writeProperty('statement');
      _nested(() => node.statement.accept(this));
    });
  }

  @override
  void visitRepeatStatement(RepeatStatementNode node, void context) {
    _writeNodeHeader('RepeatStatementNode', node.label);
    _nested(() {
      _writeProperty('statements');
      _nested(() {
        for (final stmt in node.statements) {
          stmt.accept(this);
        }
      });
      _writeProperty('condition');
      _nested(() => node.condition.accept(this));
    });
  }

  @override
  void visitForStatement(ForStatementNode node, void context) {
    final dir = node.isDownTo ? 'downto' : 'to';
    _writeNodeHeader('ForStatementNode', '${node.variable} := ... $dir ...');
    _nested(() {
      _writeProperty('initialValue');
      _nested(() => node.initialValue.accept(this));
      _writeProperty('finalValue');
      _nested(() => node.finalValue.accept(this));
      _writeProperty('statement');
      _nested(() => node.statement.accept(this));
    });
  }

  @override
  void visitWithStatement(WithStatementNode node, void context) {
    _writeNodeHeader('WithStatementNode', node.label);
    _nested(() {
      _writeProperty('records');
      _nested(() {
        for (final r in node.records) {
          r.accept(this);
        }
      });
      _writeProperty('statement');
      _nested(() => node.statement.accept(this));
    });
  }

  @override
  void visitGotoStatement(GotoStatementNode node, void context) {
    _writeNodeHeader('GotoStatementNode', 'goto ${node.targetLabel}');
  }

  @override
  void visitEmptyStatement(EmptyStatementNode node, void context) {
    _writeNodeHeader('EmptyStatementNode', node.label);
  }

  @override
  void visitBinaryExpression(BinaryExpressionNode node, void context) {
    _writeNodeHeader('BinaryExpressionNode', node.operator);
    _nested(() {
      _writeProperty('left');
      _nested(() => node.left.accept(this));
      _writeProperty('right');
      _nested(() => node.right.accept(this));
    });
  }

  @override
  void visitUnaryExpression(UnaryExpressionNode node, void context) {
    _writeNodeHeader('UnaryExpressionNode', node.operator);
    _nested(() {
      _writeProperty('operand');
      _nested(() => node.operand.accept(this));
    });
  }

  @override
  void visitVariableExpression(VariableExpressionNode node, void context) {
    _writeNodeHeader('VariableExpressionNode', node.name);
  }

  @override
  void visitArrayAccessExpression(
    ArrayAccessExpressionNode node,
    void context,
  ) {
    _writeNodeHeader('ArrayAccessExpressionNode');
    _nested(() {
      _writeProperty('array');
      _nested(() => node.array.accept(this));
      _writeProperty('indices');
      _nested(() {
        for (final idx in node.indices) {
          idx.accept(this);
        }
      });
    });
  }

  @override
  void visitFieldAccessExpression(
    FieldAccessExpressionNode node,
    void context,
  ) {
    _writeNodeHeader('FieldAccessExpressionNode', node.field);
    _nested(() {
      _writeProperty('record');
      _nested(() => node.record.accept(this));
    });
  }

  @override
  void visitPointerDereferenceExpression(
    PointerDereferenceExpressionNode node,
    void context,
  ) {
    _writeNodeHeader('PointerDereferenceExpressionNode');
    _nested(() {
      _writeProperty('pointer');
      _nested(() => node.pointer.accept(this));
    });
  }

  @override
  void visitFunctionCallExpression(
    FunctionCallExpressionNode node,
    void context,
  ) {
    _writeNodeHeader('FunctionCallExpressionNode', node.name);
    if (node.arguments.isNotEmpty) {
      _nested(() {
        _writeProperty('arguments');
        _nested(() {
          for (final arg in node.arguments) {
            arg.accept(this);
          }
        });
      });
    }
  }

  @override
  void visitLiteralExpression(LiteralExpressionNode node, void context) {
    final valStr = node.value is String
        ? '<span class="node-str">\'${node.value}\'</span>'
        : node.raw;
    _writeNodeHeader('LiteralExpressionNode', valStr);
  }

  @override
  void visitSetExpression(SetExpressionNode node, void context) {
    _writeNodeHeader('SetExpressionNode');
    _nested(() {
      for (final el in node.elements) {
        el.accept(this);
      }
    });
  }

  @override
  void visitSetElement(SetElementNode node, void context) {
    _writeNodeHeader('SetElementNode');
    _nested(() {
      _writeProperty('start');
      _nested(() => node.start.accept(this));
      if (node.end != null) {
        _writeProperty('end');
        _nested(() => node.end!.accept(this));
      }
    });
  }
}

void parseInput() {
  final text = input.value;
  final prod = production.value;
  final currentParser = getParser(prod);

  final stopwatch = Stopwatch()..start();
  final result = currentParser.parse(text);
  stopwatch.stop();

  if (result is Success) {
    final val = result.value;
    var nodeCount = 0;
    String formattedTree;

    if (val is PascalNode) {
      nodeCount = countNodes(val);
      final visitor = HtmlPascalAstVisitor();
      val.accept(visitor);
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
  initShared();

  action.onClick.listen((_) => parseInput());
  production.onChange.listen((_) => parseInput());
  input.onInput.listen((_) => parseInput());

  btnProgram.onClick.listen((_) => setPreset('program', 'program'));
  btnStrings.onClick.listen((_) => setPreset('strings', 'program'));
  btnRecords.onClick.listen((_) => setPreset('records', 'program'));
  btnExpression.onClick.listen((_) => setPreset('expression', 'expression'));

  setPreset('program', 'program');
}

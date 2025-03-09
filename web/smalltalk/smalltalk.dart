import 'dart:js_interop';

import 'package:petitparser_examples/smalltalk.dart';
import 'package:web/web.dart';

final input = document.querySelector('#input') as HTMLInputElement;
final output = document.querySelector('#output') as HTMLElement;
final parse = document.querySelector('#parse') as HTMLButtonElement;

final parserDefinition = SmalltalkParserDefinition();
final methodParser = parserDefinition.build();

void main() {
  parse.onClick.listen((event) {
    output.textContent = 'Evaluating...';
    output.classList.value = '';
    try {
      final result = methodParser.parse(input.value);
      final visitor = PrintVisitor()..visit(result.value);
      output.innerHTML = visitor.buffer.toString().toJS;
    } on Object catch (exception) {
      output.textContent = exception.toString();
      output.classList.add('error');
    }
  });
}

class PrintVisitor extends Visitor {
  final buffer = StringBuffer();
  var _indent = '';

  void print(Object? object) => buffer.writeln('$_indent$object<br/>');

  void indent(void Function() callback) {
    final previous = _indent;
    _indent = '$previous&nbsp;&nbsp;';
    callback();
    _indent = previous;
  }

  String variable(VariableNode node) =>
      '<i title="${node.token}">${node.name}</i>';

  String selector(HasSelector node) =>
      '<i title="${node.selectorToken.join(', ')}">${node.selector}</i>';

  @override
  void visitMethodNode(MethodNode node) {
    print('<b>Method</b>: ${selector(node)}');
    indent(() {
      if (node.arguments.isNotEmpty) {
        print('Arguments: ${node.arguments.map(variable).join(', ')}');
      }
      if (node.pragmas.isNotEmpty) {
        print('Pragmas');
        indent(() => node.pragmas.forEach(visit));
      }
      visit(node.body);
    });
  }

  @override
  void visitPragmaNode(PragmaNode node) {
    print('<b>Pragma</b>: ${selector(node)}');
    indent(() => node.arguments.forEach(visit));
  }

  @override
  void visitReturnNode(ReturnNode node) {
    print('<b>Return</b>');
    indent(() => visit(node.value));
  }

  @override
  void visitSequenceNode(SequenceNode node) {
    print('<b>Sequence</b>');
    indent(() {
      if (node.temporaries.isNotEmpty) {
        print('Temporaries: ${node.temporaries.map(variable).join(', ')}');
      }
      node.statements.forEach(visit);
    });
  }

  @override
  void visitArrayNode(ArrayNode node) {
    print('<b>Array</b>');
    indent(() => node.statements.forEach(visit));
  }

  @override
  void visitAssignmentNode(AssignmentNode node) {
    print('<b>Assignment</b>: ${variable(node.variable)}');
    indent(() => visit(node.value));
  }

  @override
  void visitBlockNode(BlockNode node) {
    print('<b>Block</b>');
    indent(() {
      if (node.arguments.isNotEmpty) {
        print('Arguments: ${node.arguments.map(variable).join(', ')}');
      }
      visit(node.body);
    });
  }

  @override
  void visitCascadeNode(CascadeNode node) {
    print('<b>Cascade</b>');
    indent(() {
      visit(node.receiver);
      for (final message in node.messages) {
        print('Selector: ${selector(message)}');
        if (message.arguments.isNotEmpty) {
          print('Arguments');
          indent(() => message.arguments.forEach(visit));
        }
      }
    });
  }

  @override
  void visitLiteralArrayNode(LiteralArrayNode node) {
    print('<b>Literal Array</b>: <i>${node.value}</i>');
  }

  @override
  void visitLiteralValueNode(LiteralValueNode node) {
    print('<b>Literal Value</b>: <i>${node.value}</i>');
  }

  @override
  void visitMessageNode(MessageNode node) {
    print('<b>Message</b>: ${selector(node)}');
    indent(() {
      visit(node.receiver);
      if (node.arguments.isNotEmpty) {
        print('Arguments');
        indent(() => node.arguments.forEach(visit));
      }
    });
  }

  @override
  void visitVariableNode(VariableNode node) {
    print('<b>Variable</b>: ${variable(node)}');
  }
}

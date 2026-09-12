import 'package:petitparser/petitparser.dart';

import 'ast.dart';
import 'grammar.dart';

/// Parser definition for Pascal that produces typed AST nodes ([PascalNode]).
class PascalParserDefinition extends PascalGrammarDefinition {
  @override
  Parser<ProgramNode> program() => super.program().map((values) {
    final (_, name, rawParams, _, block, _) = values;
    final params = rawParams != null
        ? (rawParams.$2.elements as List<dynamic>).cast<String>()
        : const <String>[];
    return ProgramNode(
      name: name,
      parameters: params,
      block: block as BlockNode,
    );
  });

  @override
  Parser<BlockNode> block() => super.block().map((values) {
    final (rawLabels, rawConsts, rawTypes, rawVars, rawSubroutines, statement) =
        values;

    final labels = rawLabels != null
        ? (rawLabels.$2.elements as List<dynamic>)
              .map((e) => e.toString())
              .toList()
        : const <String>[];

    final constants =
        rawConsts as List<ConstantDefinitionNode>? ??
        const <ConstantDefinitionNode>[];

    final types =
        rawTypes as List<TypeDefinitionNode>? ?? const <TypeDefinitionNode>[];

    final variables =
        rawVars as List<VariableDeclarationNode>? ??
        const <VariableDeclarationNode>[];

    final subroutines = (rawSubroutines as List<dynamic>).cast<PascalNode>();

    return BlockNode(
      labels: labels,
      constants: constants,
      types: types,
      variables: variables,
      subroutines: subroutines,
      statement: statement as CompoundStatementNode,
    );
  });

  @override
  Parser<List<ConstantDefinitionNode>> blockConst() =>
      super.blockConst().map((values) {
        final list = values.$2 as List<dynamic>;
        return list.map((item) {
          final (name, _, value, _) =
              item as (String, dynamic, ExpressionNode, dynamic);
          return ConstantDefinitionNode(name: name, value: value);
        }).toList();
      });

  @override
  Parser<List<TypeDefinitionNode>> blockType() => super.blockType().map((
    values,
  ) {
    final list = values.$2 as List<dynamic>;
    return list.map((item) {
      final (name, _, type, _) = item as (String, dynamic, TypeNode, dynamic);
      return TypeDefinitionNode(name: name, type: type);
    }).toList();
  });

  @override
  Parser<List<VariableDeclarationNode>> blockVar() => super.blockVar().map((
    values,
  ) {
    final list = values.$2 as List<dynamic>;
    return list.map((item) {
      final (namesSep, _, type, _) =
          item as (SeparatedList<dynamic, dynamic>, dynamic, TypeNode, dynamic);
      return VariableDeclarationNode(
        names: namesSep.elements.cast<String>(),
        type: type,
      );
    }).toList();
  });

  @override
  Parser<ProcedureNode> blockProcedure() =>
      super.blockProcedure().map((values) {
        final (_, name, params, _, block, _) = values;
        return ProcedureNode(
          name: name,
          parameters: (params as List<FormalParameterNode>?) ?? const [],
          block: block as BlockNode,
        );
      });

  @override
  Parser<FunctionNode> blockFunction() => super.blockFunction().map((values) {
    final (_, name, params, _, returnTypeName, _, block, _) = values;
    return FunctionNode(
      name: name,
      parameters: (params as List<FormalParameterNode>?) ?? const [],
      returnType: SimpleTypeNode(returnTypeName),
      block: block as BlockNode,
    );
  });

  @override
  Parser<CompoundStatementNode> blockStatement() =>
      super.blockStatement().map((values) {
        final (_, stmtsSep, _) = values;
        final list = stmtsSep.elements.cast<StatementNode>();
        final stmts = list.where((s) => s is! EmptyStatementNode).toList();
        return CompoundStatementNode(statements: stmts.isEmpty ? list : stmts);
      });

  @override
  Parser<StatementNode> statement() => super.statement().map((values) {
    if (values == null) return const EmptyStatementNode();
    final (rawLabel, stmt) = values;
    final label = rawLabel?.$1.toString();
    if (stmt == null) return EmptyStatementNode(label: label);
    final s = stmt as StatementNode;
    if (label != null) {
      return switch (s) {
        final CompoundStatementNode cs => CompoundStatementNode(
          label: label,
          statements: cs.statements,
        ),
        final AssignmentStatementNode a => AssignmentStatementNode(
          label: label,
          variable: a.variable,
          value: a.value,
        ),
        final ProcedureStatementNode p => ProcedureStatementNode(
          label: label,
          name: p.name,
          arguments: p.arguments,
        ),
        final IfStatementNode i => IfStatementNode(
          label: label,
          condition: i.condition,
          thenStatement: i.thenStatement,
          elseStatement: i.elseStatement,
        ),
        final CaseStatementNode c => CaseStatementNode(
          label: label,
          expression: c.expression,
          cases: c.cases,
        ),
        final WhileStatementNode w => WhileStatementNode(
          label: label,
          condition: w.condition,
          statement: w.statement,
        ),
        final RepeatStatementNode r => RepeatStatementNode(
          label: label,
          statements: r.statements,
          condition: r.condition,
        ),
        final ForStatementNode f => ForStatementNode(
          label: label,
          variable: f.variable,
          initialValue: f.initialValue,
          isDownTo: f.isDownTo,
          finalValue: f.finalValue,
          statement: f.statement,
        ),
        final WithStatementNode wt => WithStatementNode(
          label: label,
          records: wt.records,
          statement: wt.statement,
        ),
        final GotoStatementNode g => GotoStatementNode(
          label: label,
          targetLabel: g.targetLabel,
        ),
        EmptyStatementNode _ => EmptyStatementNode(label: label),
      };
    }
    return s;
  });

  @override
  Parser<AssignmentStatementNode> statementAssign() =>
      super.statementAssign().map((values) {
        final (variable, _, value) = values;
        return AssignmentStatementNode(
          variable: variable as ExpressionNode,
          value: value as ExpressionNode,
        );
      });

  @override
  Parser<ProcedureStatementNode> statementCall() =>
      super.statementCall().map((values) {
        final (name, rawArgs) = values;
        final args = rawArgs != null
            ? (rawArgs.$2.elements as List<dynamic>).cast<ExpressionNode>()
            : const <ExpressionNode>[];
        return ProcedureStatementNode(name: name, arguments: args);
      });

  @override
  Parser<CompoundStatementNode> statementBlock() =>
      super.statementBlock().map((values) {
        final (_, stmtsSep, _) = values;
        return CompoundStatementNode(
          statements: stmtsSep.elements.cast<StatementNode>(),
        );
      });

  @override
  Parser<IfStatementNode> statementIf() => super.statementIf().map((values) {
    final (_, cond, _, thenBranch, rawElse) = values;
    final elseBranch = rawElse?.$2 as StatementNode?;
    return IfStatementNode(
      condition: cond as ExpressionNode,
      thenStatement: thenBranch as StatementNode,
      elseStatement: elseBranch,
    );
  });

  @override
  Parser<RepeatStatementNode> statementRepeat() =>
      super.statementRepeat().map((values) {
        final (_, stmtsSep, _, cond) = values;
        return RepeatStatementNode(
          statements: stmtsSep.elements.cast<StatementNode>(),
          condition: cond as ExpressionNode,
        );
      });

  @override
  Parser<WhileStatementNode> statementWhile() =>
      super.statementWhile().map((values) {
        final (_, cond, _, stmt) = values;
        return WhileStatementNode(
          condition: cond as ExpressionNode,
          statement: stmt as StatementNode,
        );
      });

  @override
  Parser<ForStatementNode> statementFor() => super.statementFor().map((values) {
    final (_, variable, _, initVal, dir, finalVal, _, stmt) = values;
    return ForStatementNode(
      variable: variable,
      initialValue: initVal as ExpressionNode,
      isDownTo: (dir as String).toLowerCase() == 'downto',
      finalValue: finalVal as ExpressionNode,
      statement: stmt as StatementNode,
    );
  });

  @override
  Parser<CaseStatementNode> statementCase() => super.statementCase().map((
    values,
  ) {
    final (_, expr, _, casesSep, _) = values;
    final cases = casesSep.elements.map((c) {
      final (constsSep, _, stmt) =
          c as (SeparatedList<dynamic, dynamic>, dynamic, dynamic);
      return CaseElementNode(
        constants: constsSep.elements.cast<ExpressionNode>(),
        statement: stmt as StatementNode,
      );
    }).toList();
    return CaseStatementNode(expression: expr as ExpressionNode, cases: cases);
  });

  @override
  Parser<WithStatementNode> statementWith() =>
      super.statementWith().map((values) {
        final (_, recsSep, _, stmt) = values;
        return WithStatementNode(
          records: recsSep.elements.cast<ExpressionNode>(),
          statement: stmt as StatementNode,
        );
      });

  @override
  Parser<GotoStatementNode> statementGoto() => super.statementGoto().map(
    (values) => GotoStatementNode(targetLabel: values.$2.toString()),
  );

  @override
  Parser<ProcedureStatementNode> statementExit() =>
      super.statementExit().map((values) {
        final target = values.$3.toString();
        return ProcedureStatementNode(
          name: 'exit',
          arguments: [VariableExpressionNode(target)],
        );
      });

  @override
  Parser<List<FormalParameterNode>?> parameterList() =>
      super.parameterList().map((values) {
        if (values == null) return null;
        final rawParamsSep = values.$2 as SeparatedList<dynamic, dynamic>;
        return [
          for (final p in rawParamsSep.elements)
            () {
              final (varKeyword, namesSep, _, typeName) =
                  p
                      as (
                        dynamic,
                        SeparatedList<dynamic, dynamic>,
                        dynamic,
                        String,
                      );
              return FormalParameterNode(
                names: namesSep.elements.cast<String>(),
                type: SimpleTypeNode(typeName),
                isVar: varKeyword != null,
              );
            }(),
        ];
      });

  @override
  Parser<TypeNode> type() => super.type().map((values) {
    if (values is TypeNode) return values;
    if (values is (dynamic, dynamic)) {
      return values.$2 as TypeNode;
    }
    throw StateError('Unknown type: $values');
  });

  @override
  Parser<PointerTypeNode> typePointer() => super.typePointer().map(
    (values) => PointerTypeNode(SimpleTypeNode(values.$2)),
  );

  @override
  Parser<SetTypeNode> typeSet() =>
      super.typeSet().map((values) => SetTypeNode(values.$3 as TypeNode));

  @override
  Parser<ArrayTypeNode> typeArray() => super.typeArray().map((values) {
    final (_, _, indicesSep, _, _, elementType) = values;
    return ArrayTypeNode(
      indices: indicesSep.elements.cast<TypeNode>(),
      elementType: elementType as TypeNode,
    );
  });

  @override
  Parser<RecordTypeNode> typeRecord() => super.typeRecord().map((values) {
    final (_, fields, _) = values;
    return RecordTypeNode(fields: fields as List<VariableDeclarationNode>);
  });

  @override
  Parser<FileTypeNode> typeFile() => super.typeFile().map((values) {
    final (_, rawOf) = values;
    final base = rawOf?.$2 as TypeNode?;
    return FileTypeNode(base);
  });

  @override
  Parser<TypeNode> simpleType() => super.simpleType().map((values) {
    if (values is String) return SimpleTypeNode(values);
    if (values is (dynamic, dynamic, dynamic)) {
      if (values.$2 == '..') {
        return SubrangeTypeNode(
          start: values.$1 as ExpressionNode,
          end: values.$3 as ExpressionNode,
        );
      }
      if (values.$1 == '(' && values.$3 == ')') {
        final namesSep = values.$2 as SeparatedList<dynamic, dynamic>;
        return EnumeratedTypeNode(namesSep.elements.cast<String>());
      }
    }
    throw StateError('Unknown simpleType: $values');
  });

  @override
  Parser<List<VariableDeclarationNode>> fieldList() =>
      super.fieldList().map((values) {
        if (values is List<VariableDeclarationNode>) return values;
        if (values is (dynamic, dynamic)) {
          final base = values.$1 as List<VariableDeclarationNode>;
          return base;
        }
        return const <VariableDeclarationNode>[];
      });

  @override
  Parser<List<VariableDeclarationNode>> fieldListBase() =>
      super.fieldListBase().map((values) {
        final listSep = values as SeparatedList<dynamic, dynamic>;
        return [
          for (final item in listSep.elements)
            () {
              final (namesSep, _, type) =
                  item as (SeparatedList<dynamic, dynamic>, dynamic, TypeNode);
              return VariableDeclarationNode(
                names: namesSep.elements.cast<String>(),
                type: type,
              );
            }(),
        ];
      });

  @override
  Parser<ExpressionNode> variable() => super.variable().map((values) {
    final (name, accessors) = values;
    ExpressionNode current = VariableExpressionNode(name);
    for (final acc in accessors) {
      if (acc == '^') {
        current = PointerDereferenceExpressionNode(current);
      } else if (acc is (dynamic, String)) {
        current = FieldAccessExpressionNode(record: current, field: acc.$2);
      } else if (acc is (dynamic, dynamic, dynamic)) {
        final indicesSep = acc.$2 as SeparatedList<dynamic, dynamic>;
        current = ArrayAccessExpressionNode(
          array: current,
          indices: indicesSep.elements.cast<ExpressionNode>(),
        );
      }
    }
    return current;
  });

  @override
  Parser<ExpressionNode> expression() => super.expression().map((values) {
    final (left, rightPart) = values;
    final leftExpr = left as ExpressionNode;
    if (rightPart != null) {
      final (op, right) = rightPart;
      return BinaryExpressionNode(
        operator: op as String,
        left: leftExpr,
        right: right as ExpressionNode,
      );
    }
    return leftExpr;
  });

  @override
  Parser<ExpressionNode> simpleExpression() =>
      super.simpleExpression().map((values) {
        final list = values;
        ExpressionNode? result;
        for (final item in list) {
          final (prefix, termsSep) = item;
          final terms = termsSep.elements.cast<ExpressionNode>();
          var termExpr = terms.first;
          for (var i = 1; i < terms.length; i++) {
            termExpr = BinaryExpressionNode(
              operator: 'or',
              left: termExpr,
              right: terms[i],
            );
          }
          if (prefix != null) {
            termExpr = UnaryExpressionNode(
              operator: prefix as String,
              operand: termExpr,
            );
          }
          if (result == null) {
            result = termExpr;
          } else {
            result = BinaryExpressionNode(
              operator: '+',
              left: result,
              right: termExpr,
            );
          }
        }
        return result!;
      });

  @override
  Parser<ExpressionNode> term() => super.term().map((values) {
    final factors = values.elements.cast<ExpressionNode>();
    final separators = values.separators.cast<String>();
    var result = factors.first;
    for (var i = 0; i < separators.length; i++) {
      result = BinaryExpressionNode(
        operator: separators[i],
        left: result,
        right: factors[i + 1],
      );
    }
    return result;
  });

  @override
  Parser<ExpressionNode> factor() => super.factor().map((values) {
    if (values is ExpressionNode) return values;
    if (values is (dynamic, dynamic, dynamic)) {
      if (values.$1 == '(' && values.$3 == ')') {
        return values.$2 as ExpressionNode;
      }
      if (values.$1 == '[' && values.$3 == ']') {
        final elementsSep = values.$2 as SeparatedList<dynamic, dynamic>;
        final elements = elementsSep.elements.map((e) {
          final (start, rawEnd) =
              e as (ExpressionNode, (dynamic, ExpressionNode)?);
          final end = rawEnd?.$2;
          return SetElementNode(start: start, end: end);
        }).toList();
        return SetExpressionNode(elements);
      }
    }
    if (values is (String, dynamic, dynamic, dynamic)) {
      final (name, _, argsSep, _) = values;
      final args = (argsSep as SeparatedList<dynamic, dynamic>).elements
          .cast<ExpressionNode>();
      return FunctionCallExpressionNode(name: name, arguments: args);
    }
    if (values is (String, dynamic) && values.$1 == 'not') {
      return UnaryExpressionNode(
        operator: 'not',
        operand: values.$2 as ExpressionNode,
      );
    }
    throw StateError('Unknown factor: $values');
  });

  @override
  Parser<LiteralExpressionNode> unsignedConstant() =>
      super.unsignedConstant().map(
        (value) => switch (value) {
          'nil' => const LiteralExpressionNode(raw: 'nil', value: null),
          final num n => LiteralExpressionNode(raw: n.toString(), value: n),
          final String s => LiteralExpressionNode(raw: s, value: s),
          _ => LiteralExpressionNode(raw: value.toString(), value: value),
        },
      );

  @override
  Parser<LiteralExpressionNode> constant() => super.constant().map((value) {
    if (value is LiteralExpressionNode) return value;
    if (value is (dynamic, dynamic)) {
      final sign = value.$1 as String;
      final n = value.$2;
      if (n is num) {
        final signedVal = sign == '-' ? -n : n;
        return LiteralExpressionNode(raw: '$sign$n', value: signedVal);
      }
      return LiteralExpressionNode(raw: '$sign$n', value: '$sign$n');
    }
    throw StateError('Unknown constant: $value');
  });
}

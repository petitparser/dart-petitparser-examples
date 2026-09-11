# Python 3.12+ Grammar & AST

## Architecture

The Python implementation is structured into two primary layers:

1. **Typed AST (`lib/src/python/ast.dart`)**:
   - Strongly-typed node hierarchy for Python 3.12+.
   - Root: `ModuleNode`.
   - Statements: definitions (`FunctionDefNode`, `AsyncFunctionDefNode`, `ClassDefNode`), control flow (`IfNode`, `ForNode`, `AsyncForNode`, `WhileNode`, `TryNode`, `MatchNode`), assignments (`AssignNode`, `AugAssignNode`, `AnnAssignNode`), type aliases (`TypeAliasNode`), and jump/simple statements (`ReturnNode`, `RaiseNode`, `AssertNode`, `ImportNode`, etc.).
   - Expressions: names, literals (`ConstantNode`, `FormattedValueNode`, `JoinedStrNode`), operators, collections, calls, subscriptions, lambdas, and comprehensions.
   - Pattern Matching: PEP 634 patterns (`MatchValueNode`, `MatchSequenceNode`, `MatchMappingNode`, `MatchClassNode`, `CaseClauseNode`, etc.).
   - Type Parameters: PEP 695 generics (`TypeVarNode`, `TypeVarTupleNode`, `ParamSpecNode`).

2. **Grammar & Mixins (`lib/src/python/grammar/`)**:
   - `PythonLexicalGrammar` (`lexical.dart`): Identifiers, keywords, string/bytes literals, numbers, comments, line continuations, newlines, blank lines, and indentation management using `package:petitparser/indent.dart` (`Indent`).
   - `PythonExpressionGrammar` (`expressions.dart`): Operator precedence using `ExpressionBuilder`, walrus operator, lambdas, calls, subscripts. Delimiter-enclosed expressions use `ignore()` to allow embedded newlines.
   - `PythonPatternGrammar` (`patterns.dart`): PEP 634 pattern matching syntax.
   - `PythonDeclarationGrammar` (`declarations.dart`): Functions, decorators, parameters, classes, PEP 695 type parameters.
   - `PythonStatementGrammar` (`statements.dart`): Simple statements, compound statements, indented suite blocks (`indent.increase` / `indent.decrease`).
   - `PythonGrammarDefinition` (`lib/src/python/grammar.dart`): Composes all mixins into the full grammar.
   - `parsePython(String)` (`lib/python.dart`): Public entry point returning `ModuleNode`.

## Conventions

- **Indentation**: 2 spaces in Dart code.
- **Typing**: Prefer `seq$N` over list sequence parsers for strong typing without casts.
- **Testing**:
  - Test individual productions in depth under `test/python/grammar/`.
  - Maintain 100% clean output with `dart test test/python/linter_test.dart` (PetitParser grammar linter).
  - All public APIs documented with triple-slash (`///`) comments and bracketed references.

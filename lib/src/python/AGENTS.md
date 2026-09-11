# Python 3.12+ Grammar & AST

## Architecture

The Python implementation is structured into three primary layers:

1. **Indentation Handling (`lib/src/python/indent.dart`)**:
   - `PythonIndent`: Encapsulates indentation state and combinators.
   - `guard<R>(Parser<R> parser)`: Scopes indentation levels, allowing nested blocks.
   - `increase`, `same`, `decrease`: Matches block transitions with strict indentation stack alignment.
   - Designed cleanly so it can be upstreamed into `package:petitparser/indent.dart`.

2. **Typed AST (`lib/src/python/ast.dart`)**:
   - Comprehensive strongly-typed node hierarchy for Python 3.12+.
   - Root: `ModuleNode`.
   - Statements:
     - `FunctionDefNode`, `AsyncFunctionDefNode`, `ClassDefNode`
     - `ReturnNode`, `AssignNode`, `AugAssignNode`, `AnnAssignNode`
     - `IfNode`, `ForNode`, `AsyncForNode`, `WhileNode`
     - `WithNode`, `AsyncWithNode`, `TryNode`, `MatchNode` (PEP 634)
     - `RaiseNode`, `AssertNode`, `ImportNode`, `ImportFromNode`
     - `GlobalNode`, `NonlocalNode`, `PassNode`, `BreakNode`, `ContinueNode`
     - `TypeAliasNode` (PEP 695)
   - Expressions:
     - `NameNode`, `ConstantNode`, `FormattedValueNode`, `JoinedStrNode`
     - `UnaryOpNode`, `BinOpNode`, `BoolOpNode`, `CompareNode`
     - `CallNode`, `AttributeNode`, `SubscriptNode`, `StarredNode`
     - `NamedExprNode` (`:=`), `ListLiteralNode`, `TupleLiteralNode`, `SetLiteralNode`, `DictLiteralNode`
     - `YieldNode`, `YieldFromNode`, `AwaitNode`, `LambdaNode`, `IfExpNode`
   - Comprehensions & Generators:
     - `ListCompNode`, `SetCompNode`, `DictCompNode`, `GeneratorExpNode`
   - Pattern Matching (PEP 634):
     - `MatchValueNode`, `MatchSingletonNode`, `MatchSequenceNode`, `MatchMappingNode`, `MatchClassNode`, `MatchStarNode`, `MatchAsNode`, `MatchOrNode`, `CaseClauseNode`
   - Type Parameters (PEP 695):
     - `TypeVarNode`, `TypeVarTupleNode`, `ParamSpecNode`

3. **Grammar & Mixins (`lib/src/python/grammar/`)**:
   - `PythonLexicalGrammar` (`lexical.dart`): Identifiers, keywords, string/bytes literals (single, double, triple-quoted, raw, f-strings, bytes), numbers (binary, octal, hex, float, complex), comments (`#`), line continuations (`\`), newlines.
   - `PythonExpressionGrammar` (`expressions.dart`): Operator precedence using `ExpressionBuilder`, walrus operator, ternary, lambdas, calls, subscripts, slices. All delimiter-enclosed expressions invoke `ignore()`.
   - `PythonPatternGrammar` (`patterns.dart`): PEP 634 pattern matching rules.
   - `PythonDeclarationGrammar` (`declarations.dart`): Functions, async functions, decorators, parameters (`/`, `*`, `**`), classes, PEP 695 type parameters.
   - `PythonStatementGrammar` (`statements.dart`): Simple statements, compound statements, top-level statements with `blankLines` handling.
   - `PythonGrammarDefinition` (`lib/src/python/grammar.dart`): Composes all mixins.
   - `parsePython(String)` (`lib/python.dart`): Top-level convenience entry point returning `Result<ModuleNode>`.

## Development & Maintenance Conventions

- **Indentation**: 2 spaces in Dart code.
- **Typing**: Prefer `seq$N` over list sequence parsers for strong typing without casts.
- **Testing**:
  - Test individual productions in depth under `test/python/grammar/`.
  - Maintain 100% clean output with `dart test test/python/linter_test.dart` (PetitParser grammar linter).
  - All public APIs documented with triple-slash (`///`) comments and bracketed references.

import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'lexical.dart';

/// Mixin for Dart type syntax: named types, generics, record types,
/// function types, and parameter lists.
mixin DartTypeGrammar
    on GrammarDefinition<CompilationUnitNode>, DartLexicalGrammar {
  /// Abstract expression reference needed for default parameter values.
  @override
  Parser<ExpressionNode> expression();

  /// Abstract metadata reference.
  Parser<List<AnnotationNode>> metadataList();

  // ---------------------------------------------------------------------------
  // Types
  // ---------------------------------------------------------------------------

  /// The main type production.
  Parser<TypeNode> type() => [
    // Standalone Function type without return type: Function(...)
    seq4(
      ref0(functionToken),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref1(token, '?').optional(),
    ).map4(
      (_, typeParams, params, q) => FunctionTypeNode(
        typeParameters: typeParams,
        parameters: params,
        isNullable: q != null,
      ),
    ),
    // Non-function base type with optional Function suffixes
    seq2(
      ref0(nonFunctionType),
      seq4(
        ref0(functionToken),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        ref0(formalParameters),
        ref1(token, '?').optional(),
      ).star(),
    ).map2((base, functionSuffixes) {
      var current = base;
      for (final suffix in functionSuffixes) {
        current = FunctionTypeNode(
          returnType: current,
          typeParameters: suffix.$2,
          parameters: suffix.$3,
          isNullable: suffix.$4 != null,
        );
      }
      return current;
    }),
  ].toChoiceParser();

  /// A type used in type tests and type casts (`is`, `is!`, `as`), where
  /// the outermost type can have a trailing `?` if not followed by an expression
  /// (disambiguating against ternary conditional `? :`).
  Parser<TypeNode> typeTestType() => [
    // Standalone Function type with optional guarded trailing nullability: Function(...)
    seq4(
      ref0(functionToken),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref0(typeTestNullableSuffix).optional(),
    ).map4(
      (_, typeParams, params, q) => FunctionTypeNode(
        typeParameters: typeParams,
        parameters: params,
        isNullable: q != null,
      ),
    ),
    // Non-function base type with function suffixes and optional guarded trailing nullability
    seq3(
      ref0(nonFunctionTypeWithoutNullable),
      seq3(
        ref0(functionToken),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        ref0(formalParameters),
      ).star(),
      ref0(typeTestNullableSuffix).optional(),
    ).map3((base, functionSuffixes, q) {
      var current = base;
      for (var i = 0; i < functionSuffixes.length; i++) {
        final suffix = functionSuffixes[i];
        final isLast = i == functionSuffixes.length - 1;
        current = FunctionTypeNode(
          returnType: current,
          typeParameters: suffix.$2,
          parameters: suffix.$3,
          isNullable: isLast && q != null,
        );
      }
      if (functionSuffixes.isEmpty && q != null) {
        current = current is NamedTypeNode
            ? NamedTypeNode(
                name: current.name,
                typeArguments: current.typeArguments,
                isNullable: true,
              )
            : (current is RecordTypeNode
                  ? RecordTypeNode(
                      positionalFields: current.positionalFields,
                      namedFields: current.namedFields,
                      isNullable: true,
                    )
                  : current);
      }
      return current;
    }),
  ].toChoiceParser();

  /// Lookahead for trailing `?` in `typeTestType` that is NOT part of a ternary `? :`.
  Parser<Token<dynamic>> typeTestNullableSuffix() =>
      (ref1(token, '?') &
              [
                ref1(token, ';'),
                ref1(token, ')'),
                ref1(token, ']'),
                ref1(token, '}'),
                ref1(token, ','),
                ref1(token, '=='),
                ref1(token, '!='),
                ref1(token, '&&'),
                ref1(token, '||'),
                ref1(token, '??'),
                ref1(token, '='),
              ].toChoiceParser().and())
          .map((l) => l[0] as Token<dynamic>);

  /// A type that is not an unparenthesized function type.
  Parser<TypeNode> nonFunctionType() =>
      [ref0(recordType), ref0(namedType), ref0(voidType)].toChoiceParser();

  /// A non-function type without a trailing `?`.
  Parser<TypeNode> nonFunctionTypeWithoutNullable() => [
    ref0(recordTypeWithoutNullable),
    ref0(namedTypeWithoutNullable),
    ref0(voidType),
  ].toChoiceParser();

  /// A `void` type.
  Parser<TypeNode> voidType() =>
      ref0(voidToken).map((_) => const NamedTypeNode(name: 'void'));

  /// A named type without trailing `?`.
  Parser<NamedTypeNode> namedTypeWithoutNullable() =>
      seq2(
        ref0(qualifiedIdentifier),
        ref0(typeArguments).optionalWith(const <TypeNode>[]),
      ).map2(
        (name, typeArgs) => NamedTypeNode(name: name, typeArguments: typeArgs),
      );

  /// A named type with optional generics and nullability (`int`, `List<String>?`).
  Parser<NamedTypeNode> namedType() =>
      seq2(ref0(namedTypeWithoutNullable), ref1(token, '?').optional()).map2(
        (type, q) => q != null
            ? NamedTypeNode(
                name: type.name,
                typeArguments: type.typeArguments,
                isNullable: true,
              )
            : type,
      );

  /// Type arguments list (`<int, String>`).
  Parser<List<TypeNode>> typeArguments() => seq3(
    ref1(token, '<'),
    ref0(type).plusSeparated(ref1(token, ',')).map((l) => l.elements),
    ref1(token, '>'),
  ).map3((_, types, _) => types);

  /// Type parameters declaration (`<T extends Object, U>`).
  Parser<List<TypeParameterNode>> typeParameters() => seq3(
    ref1(token, '<'),
    ref0(typeParameter).plusSeparated(ref1(token, ',')).map((l) => l.elements),
    ref1(token, '>'),
  ).map3((_, params, _) => params);

  /// A single type parameter (`T extends S`).
  Parser<TypeParameterNode> typeParameter() => seq2(
    ref0(identifier),
    (ref0(extendsToken) & ref0(type))
        .map((list) => list[1] as TypeNode)
        .optional(),
  ).map2((name, bound) => TypeParameterNode(name: name, bound: bound));

  // ---------------------------------------------------------------------------
  // Record Types
  // ---------------------------------------------------------------------------

  /// A record type without trailing `?`.
  Parser<RecordTypeNode> recordTypeWithoutNullable() =>
      seq3(
        ref1(token, '('),
        ref0(recordTypeFields).optional(),
        ref1(token, ')'),
      ).map3((_, fields, _) {
        if (fields == null) {
          return const RecordTypeNode();
        }
        return RecordTypeNode(
          positionalFields: fields.$1,
          namedFields: fields.$2,
        );
      });

  /// A record type (`(int, String)`, `({int a, String b})`, `()`).
  Parser<RecordTypeNode> recordType() =>
      seq2(ref0(recordTypeWithoutNullable), ref1(token, '?').optional()).map2(
        (type, q) => q != null
            ? RecordTypeNode(
                positionalFields: type.positionalFields,
                namedFields: type.namedFields,
                isNullable: true,
              )
            : type,
      );

  Parser<(List<RecordTypeFieldNode>, List<RecordTypeFieldNode>)>
  recordTypeFields() => [
    // Positional then optional named: int, String, {bool flag}
    seq3(
      ref0(recordTypePositionalField)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      (ref1(token, ',') & ref0(recordTypeNamedFields))
          .map((list) => list[1] as List<RecordTypeFieldNode>)
          .optionalWith(const <RecordTypeFieldNode>[]),
      ref1(token, ',').optional(),
    ).map3((pos, named, _) => (pos, named)),
    // Only named fields: {int a, String b}
    seq2(
      ref0(recordTypeNamedFields),
      ref1(token, ',').optional(),
    ).map2((named, _) => (const <RecordTypeFieldNode>[], named)),
  ].toChoiceParser();

  Parser<RecordTypeFieldNode> recordTypePositionalField() => seq2(
    ref0(type),
    ref0(identifier).optional(),
  ).map2((type, name) => RecordTypeFieldNode(type: type, name: name));

  Parser<List<RecordTypeFieldNode>> recordTypeNamedFields() => seq4(
    ref1(token, '{'),
    ref0(recordTypeNamedField)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements),
    ref1(token, ',').optional(),
    ref1(token, '}'),
  ).map4((_, fields, _, _) => fields);

  Parser<RecordTypeFieldNode> recordTypeNamedField() => seq2(
    ref0(type),
    ref0(identifier),
  ).map2((type, name) => RecordTypeFieldNode(type: type, name: name));

  // ---------------------------------------------------------------------------
  // Formal Parameters
  // ---------------------------------------------------------------------------

  /// Parameter list `(...)`.
  Parser<List<ParameterNode>> formalParameters() => seq3(
    ref1(token, '('),
    ref0(formalParameterListInternal).optionalWith(const <ParameterNode>[]),
    ref1(token, ')'),
  ).map3((_, params, _) => params);

  Parser<List<ParameterNode>> formalParameterListInternal() => [
    // 1. Positional + named: a, b, {c, d}
    seq3(
      ref0(normalFormalParameter)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ',') & ref0(optionalNamedFormalParameters),
      ref1(token, ',').optional(),
    ).map3(
      (normal, named, _) => [...normal, ...named[1] as List<ParameterNode>],
    ),
    // 2. Positional + optional positional: a, b, [c, d]
    seq3(
      ref0(normalFormalParameter)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ',') & ref0(optionalPositionalFormalParameters),
      ref1(token, ',').optional(),
    ).map3((normal, opt, _) => [...normal, ...opt[1] as List<ParameterNode>]),
    // 3. Only named: {a, b}
    seq2(
      ref0(optionalNamedFormalParameters),
      ref1(token, ',').optional(),
    ).map2((named, _) => named),
    // 4. Only optional positional: [a, b]
    seq2(
      ref0(optionalPositionalFormalParameters),
      ref1(token, ',').optional(),
    ).map2((opt, _) => opt),
    // 5. Only positional: a, b
    seq2(
      ref0(normalFormalParameter)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ',').optional(),
    ).map2((normal, _) => normal),
  ].toChoiceParser();

  Parser<List<ParameterNode>> optionalPositionalFormalParameters() => seq4(
    ref1(token, '['),
    ref0(defaultFormalParameter)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements),
    ref1(token, ',').optional(),
    ref1(token, ']'),
  ).map4((_, params, _, _) => params);

  Parser<List<ParameterNode>> optionalNamedFormalParameters() => seq4(
    ref1(token, '{'),
    ref0(defaultNamedFormalParameter)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements),
    ref1(token, ',').optional(),
    ref1(token, '}'),
  ).map4((_, params, _, _) => params);

  Parser<ParameterNode> normalFormalParameter() =>
      seq2(
        ref0(metadataList),
        [
          ref0(functionTypedFormalParameter),
          ref0(fieldFormalParameter),
          ref0(simpleFormalParameter),
        ].toChoiceParser(),
      ).map2((meta, param) {
        if (meta.isEmpty) return param;
        if (param is SimpleParameterNode) {
          return SimpleParameterNode(
            name: param.name,
            type: param.type,
            defaultValue: param.defaultValue,
            metadata: [...meta, ...param.metadata],
            isNamed: param.isNamed,
            isRequired: param.isRequired,
            isFinal: param.isFinal,
            isVar: param.isVar,
            isThis: param.isThis,
            isSuper: param.isSuper,
          );
        }
        if (param is FunctionTypedParameterNode) {
          return FunctionTypedParameterNode(
            name: param.name,
            type: param.type,
            parameters: param.parameters,
            defaultValue: param.defaultValue,
            metadata: [...meta, ...param.metadata],
            isNamed: param.isNamed,
            isRequired: param.isRequired,
          );
        }
        return param;
      });

  Parser<SimpleParameterNode> simpleFormalParameter() => [
    // Typed with name: int x
    seq5(
      ref0(covariantToken).optional(),
      [ref0(finalToken), ref0(varToken)].toChoiceParser().optional(),
      ref0(type),
      ref0(identifier),
      (ref1(token, '=') & ref0(expression))
          .map((l) => l[1] as ExpressionNode)
          .optional(),
    ).map5(
      (cov, finalOrVar, type, name, defaultVal) => SimpleParameterNode(
        name: name,
        type: type,
        defaultValue: defaultVal,
        isFinal: finalOrVar?.value == 'final',
        isVar: finalOrVar?.value == 'var',
      ),
    ),
    // Untyped name (e.g. `(x)`) or type-only parameter in function types (e.g. `(int)`)
    seq5(
      ref0(covariantToken).optional(),
      [ref0(finalToken), ref0(varToken)].toChoiceParser().optional(),
      epsilon(),
      ref0(type),
      (ref1(token, '=') & ref0(expression))
          .map((l) => l[1] as ExpressionNode)
          .optional(),
    ).map5((cov, finalOrVar, _, type, defaultVal) {
      if (type is NamedTypeNode &&
          !type.isNullable &&
          type.typeArguments.isEmpty) {
        return SimpleParameterNode(
          name: type.name,
          defaultValue: defaultVal,
          isFinal: finalOrVar?.value == 'final',
          isVar: finalOrVar?.value == 'var',
        );
      }
      return SimpleParameterNode(
        name: '',
        type: type,
        defaultValue: defaultVal,
        isFinal: finalOrVar?.value == 'final',
        isVar: finalOrVar?.value == 'var',
      );
    }),
  ].toChoiceParser();

  Parser<SimpleParameterNode> fieldFormalParameter() =>
      seq5(
        [ref0(finalToken), ref0(varToken)].toChoiceParser().optional(),
        ref0(type).optional(),
        [
          ref0(thisToken) & ref1(token, '.'),
          ref0(superToken) & ref1(token, '.'),
        ].toChoiceParser(),
        ref0(identifier),
        (ref1(token, '=') & ref0(expression))
            .map((l) => l[1] as ExpressionNode)
            .optional(),
      ).map5((finalOrVar, type, prefix, name, defaultVal) {
        final isThis = prefix[0].value == 'this';
        return SimpleParameterNode(
          name: name,
          type: type,
          defaultValue: defaultVal,
          isFinal: finalOrVar?.value == 'final',
          isVar: finalOrVar?.value == 'var',
          isThis: isThis,
          isSuper: !isThis,
        );
      });

  Parser<FunctionTypedParameterNode> functionTypedFormalParameter() =>
      seq4(
        ref0(type).optional(),
        ref0(identifier),
        ref0(formalParameters),
        ref1(token, '?').optional(),
      ).map4(
        (type, name, params, q) => FunctionTypedParameterNode(
          name: name,
          type: type,
          parameters: params,
        ),
      );

  Parser<ParameterNode> defaultFormalParameter() =>
      seq2(
        ref0(normalFormalParameter),
        (ref1(token, '=') & ref0(expression))
            .map((l) => l[1] as ExpressionNode)
            .optional(),
      ).map2((param, defaultVal) {
        if (defaultVal != null) {
          if (param is SimpleParameterNode) {
            return SimpleParameterNode(
              name: param.name,
              type: param.type,
              defaultValue: defaultVal,
              metadata: param.metadata,
              isFinal: param.isFinal,
              isVar: param.isVar,
              isThis: param.isThis,
              isSuper: param.isSuper,
            );
          }
          if (param is FunctionTypedParameterNode) {
            return FunctionTypedParameterNode(
              name: param.name,
              type: param.type,
              parameters: param.parameters,
              defaultValue: defaultVal,
              metadata: param.metadata,
            );
          }
        }
        return param;
      });

  Parser<ParameterNode> defaultNamedFormalParameter() =>
      seq4(
        ref0(metadataList),
        ref0(requiredToken).optional(),
        ref0(normalFormalParameter),
        ([ref1(token, '='), ref1(token, ':')].toChoiceParser() &
                ref0(expression))
            .map((l) => l[1] as ExpressionNode)
            .optional(),
      ).map4((meta, req, param, defaultVal) {
        final allMeta = [...meta, ...param.metadata];
        if (param is SimpleParameterNode) {
          return SimpleParameterNode(
            name: param.name,
            type: param.type,
            defaultValue: defaultVal ?? param.defaultValue,
            metadata: allMeta,
            isNamed: true,
            isRequired: req != null,
            isFinal: param.isFinal,
            isVar: param.isVar,
            isThis: param.isThis,
            isSuper: param.isSuper,
          );
        }
        if (param is FunctionTypedParameterNode) {
          return FunctionTypedParameterNode(
            name: param.name,
            type: param.type,
            parameters: param.parameters,
            defaultValue: defaultVal ?? param.defaultValue,
            metadata: allMeta,
            isNamed: true,
            isRequired: req != null,
          );
        }
        return param;
      });
}

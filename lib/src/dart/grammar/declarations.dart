import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'expressions.dart';
import 'lexical.dart';
import 'patterns.dart';
import 'statements.dart';
import 'types.dart';

/// Mixin for Dart declarations: compilation units, directives, classes,
/// mixins, enums, extensions, extension types, methods, and constructors.
mixin DartDeclarationGrammar
    on
        GrammarDefinition<CompilationUnitNode>,
        DartLexicalGrammar,
        DartTypeGrammar,
        DartPatternGrammar,
        DartExpressionGrammar,
        DartStatementGrammar {
  // ---------------------------------------------------------------------------
  // Compilation Unit
  // ---------------------------------------------------------------------------

  Parser<CompilationUnitNode> compilationUnit() =>
      seq5(
        ref0(hashbang).optional(),
        ref0(libraryDirective).optional(),
        ref0(directive).star(),
        ref0(topLevelDefinition).star(),
        ref0(hiddenStuffWhitespace).star(),
      ).map5(
        (hb, lib, directives, decls, _) => CompilationUnitNode(
          hashbang: hb,
          directives: [?lib, ...directives],
          declarations: decls,
        ),
      );

  // ---------------------------------------------------------------------------
  // Directives
  // ---------------------------------------------------------------------------

  Parser<DirectiveNode> directive() => seq2(
    ref0(metadataList),
    [
      ref0(importDirective),
      ref0(exportDirective),
      ref0(partOfDirective),
      ref0(partDirective),
    ].toChoiceParser(),
  ).map2((_, dir) => dir);

  Parser<LibraryDirectiveNode> libraryDirective() => seq4(
    ref0(metadataList),
    ref0(libraryToken),
    ref0(qualifiedIdentifier).optional(),
    ref1(token, ';'),
  ).map4((_, _, name, _) => LibraryDirectiveNode(name));

  Parser<PartOfDirectiveNode> partOfDirective() => seq4(
    ref0(partToken),
    ref0(ofToken),
    [
      ref0(simpleStringLiteral).map((s) => s.value),
      ref0(qualifiedIdentifier),
    ].toChoiceParser(),
    ref1(token, ';'),
  ).map4((_, _, lib, _) => PartOfDirectiveNode(lib));

  Parser<PartDirectiveNode> partDirective() => seq3(
    ref0(partToken),
    ref0(simpleStringLiteral),
    ref1(token, ';'),
  ).map3((_, uri, _) => PartDirectiveNode(uri.value));

  Parser<ConfigurationUriNode> configurationUri() =>
      seq4(
        ref0(ifToken),
        seq4(
          ref1(token, '('),
          ref0(qualifiedIdentifier),
          (ref1(token, '==') & ref0(simpleStringLiteral))
              .map((l) => (l[1] as StringLiteralNode).value)
              .optional(),
          ref1(token, ')'),
        ).map4((_, name, value, _) => (name: name, value: value)),
        ref0(simpleStringLiteral),
        epsilon(),
      ).map4(
        (_, test, uri, _) => ConfigurationUriNode(
          name: test.name,
          value: test.value,
          uri: uri.value,
        ),
      );

  Parser<ImportDirectiveNode> importDirective() =>
      seq7(
        ref0(importToken),
        ref0(simpleStringLiteral),
        ref0(configurationUri).star(),
        ref0(deferredToken).optional(),
        (ref0(asToken) & ref0(identifier))
            .map((l) => l[1] as String)
            .optional(),
        ref0(combinator).star(),
        ref1(token, ';'),
      ).map7(
        (_, uri, configs, deferred, asName, combinators, _) =>
            ImportDirectiveNode(
              uri: uri.value,
              configurations: configs,
              isDeferred: deferred != null,
              asName: asName,
              combinators: combinators,
            ),
      );

  Parser<ExportDirectiveNode> exportDirective() =>
      seq5(
        ref0(exportToken),
        ref0(simpleStringLiteral),
        ref0(configurationUri).star(),
        ref0(combinator).star(),
        ref1(token, ';'),
      ).map5(
        (_, uri, configs, combinators, _) => ExportDirectiveNode(
          uri: uri.value,
          configurations: configs,
          combinators: combinators,
        ),
      );

  Parser<CombinatorNode> combinator() => [
    (ref0(showToken) &
            ref0(identifier)
                .plusSeparated(ref1(token, ','))
                .map((l) => l.elements))
        .map((l) => ShowCombinatorNode(l[1] as List<String>)),
    (ref0(hideToken) &
            ref0(identifier)
                .plusSeparated(ref1(token, ','))
                .map((l) => l.elements))
        .map((l) => HideCombinatorNode(l[1] as List<String>)),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Top-Level Definitions
  // ---------------------------------------------------------------------------

  Parser<DeclarationNode> topLevelDefinition() => seq2(
    ref0(metadataList),
    [
      ref0(classDeclaration),
      ref0(mixinDeclaration),
      ref0(extensionDeclaration),
      ref0(extensionTypeDeclaration),
      ref0(enumDeclaration),
      ref0(typeAliasDeclaration),
      ref0(functionDeclaration),
      ref0(fieldDeclaration),
    ].toChoiceParser(),
  ).map2((_, decl) => decl);

  // ---------------------------------------------------------------------------
  // Class Declaration
  // ---------------------------------------------------------------------------

  Parser<ClassDeclarationNode> classDeclaration() =>
      seq8(
        ref0(classModifier).star(),
        ref0(classToken),
        ref0(identifier),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        (ref0(extendsToken) & ref0(type))
            .map((l) => l[1] as TypeNode)
            .optional(),
        (ref0(withToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        (ref0(implementsToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        [
          ref1(token, ';').map((_) => const <DeclarationNode>[]),
          seq3(
            ref1(token, '{'),
            ref0(classMemberDefinition).star(),
            ref1(token, '}'),
          ).map3((_, members, _) => members),
        ].toChoiceParser(),
      ).map8(
        (
          modifiers,
          _,
          name,
          typeParams,
          superclass,
          mixins,
          interfaces,
          members,
        ) => ClassDeclarationNode(
          name: name,
          modifiers: modifiers,
          typeParameters: typeParams,
          superclass: superclass,
          mixins: mixins,
          interfaces: interfaces,
          members: members,
        ),
      );

  Parser<String> classModifier() => [
    ref0(abstractToken),
    ref0(baseToken),
    ref0(interfaceToken),
    ref0(finalToken),
    ref0(sealedToken),
    ref0(mixinToken),
  ].toChoiceParser().map((t) => t.value);

  Parser<List<TypeNode>> typeList() =>
      ref0(type).plusSeparated(ref1(token, ',')).map((l) => l.elements);

  // ---------------------------------------------------------------------------
  // Mixin Declaration
  // ---------------------------------------------------------------------------

  Parser<MixinDeclarationNode> mixinDeclaration() =>
      seq7(
        ref0(baseToken).optional(),
        ref0(mixinToken),
        ref0(identifier),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        (ref0(onToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        (ref0(implementsToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        [
          ref1(token, ';').map((_) => const <DeclarationNode>[]),
          seq3(
            ref1(token, '{'),
            ref0(classMemberDefinition).star(),
            ref1(token, '}'),
          ).map3((_, members, _) => members),
        ].toChoiceParser(),
      ).map7(
        (base, _, name, typeParams, onTypes, interfaces, members) =>
            MixinDeclarationNode(
              name: name,
              isBase: base != null,
              typeParameters: typeParams,
              onTypes: onTypes,
              interfaces: interfaces,
              members: members,
            ),
      );

  // ---------------------------------------------------------------------------
  // Extension & Extension Type Declarations
  // ---------------------------------------------------------------------------

  Parser<ExtensionDeclarationNode> extensionDeclaration() =>
      seq6(
        ref0(extensionToken),
        ref0(identifier).where((id) => id != 'on').optional(),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        ref0(onToken),
        ref0(type),
        [
          ref1(token, ';').map((_) => const <DeclarationNode>[]),
          seq3(
            ref1(token, '{'),
            ref0(classMemberDefinition).star(),
            ref1(token, '}'),
          ).map3((_, members, _) => members),
        ].toChoiceParser(),
      ).map6(
        (_, name, typeParams, _, onType, members) => ExtensionDeclarationNode(
          name: name,
          typeParameters: typeParams,
          onType: onType,
          members: members,
        ),
      );

  Parser<ExtensionTypeDeclarationNode> extensionTypeDeclaration() =>
      seq8(
        seq3(
          ref0(extensionToken),
          ref0(typeToken),
          ref0(constToken).optional(),
        ),
        ref0(identifier),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        (ref1(token, '.') &
                [
                  ref0(identifier),
                  ref0(newToken).map((t) => t.value),
                ].toChoiceParser())
            .map((l) => l[1] as String)
            .optional(),
        seq4(
          ref1(token, '('),
          ref0(metadataList),
          seq2(ref0(type), ref0(identifier)),
          ref1(token, ')'),
        ).map4((_, _, rep, _) => rep),
        (ref0(implementsToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        [
          seq3(
            ref1(token, '{'),
            ref0(classMemberDefinition).star(),
            ref1(token, '}'),
          ).map3((_, members, _) => members),
          ref1(token, ';').map((_) => const <DeclarationNode>[]),
        ].toChoiceParser(),
        epsilon(),
      ).map8(
        (header, name, typeParams, ctorName, rep, interfaces, members, _) =>
            ExtensionTypeDeclarationNode(
              name: name,
              constructorName: ctorName,
              isConst: header.$3 != null,
              typeParameters: typeParams,
              representationType: rep.$1,
              representationName: rep.$2,
              interfaces: interfaces,
              members: members,
            ),
      );

  // ---------------------------------------------------------------------------
  // Enum Declaration
  // ---------------------------------------------------------------------------

  Parser<EnumDeclarationNode> enumDeclaration() =>
      seq8(
        ref0(enumToken),
        ref0(identifier),
        ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
        (ref0(withToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        (ref0(implementsToken) & ref0(typeList))
            .map((l) => l[1] as List<TypeNode>)
            .optionalWith(const <TypeNode>[]),
        ref1(token, '{'),
        ref0(enumBody),
        ref1(token, '}'),
      ).map8(
        (_, name, typeParams, mixins, interfaces, _, body, _) =>
            EnumDeclarationNode(
              name: name,
              typeParameters: typeParams,
              mixins: mixins,
              interfaces: interfaces,
              constants: body.$1,
              members: body.$2,
            ),
      );

  Parser<(List<EnumConstantNode>, List<DeclarationNode>)> enumBody() => seq3(
    ref0(enumConstant)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements)
        .optionalWith(const <EnumConstantNode>[]),
    ref1(token, ',').optional(),
    (ref1(token, ';') & ref0(classMemberDefinition).star())
        .map((l) => l[1] as List<DeclarationNode>)
        .optionalWith(const <DeclarationNode>[]),
  ).map3((constants, _, members) => (constants, members));

  Parser<EnumConstantNode> enumConstant() =>
      seq4(
        ref0(metadataList),
        ref0(identifier),
        ref0(typeArguments).optionalWith(const <TypeNode>[]),
        ref0(argumentList).optionalWith(const <ArgumentNode>[]),
      ).map4(
        (_, name, typeArgs, args) => EnumConstantNode(
          name: name,
          typeArguments: typeArgs,
          arguments: args,
        ),
      );

  // ---------------------------------------------------------------------------
  // Type Alias (typedef)
  // ---------------------------------------------------------------------------

  Parser<TypeAliasDeclarationNode> typeAliasDeclaration() => [
    // 1. New-style: typedef Name<T> = Type;
    seq5(
      ref0(typedefToken),
      ref0(identifier),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref1(token, '='),
      seq2(ref0(type), ref1(token, ';')),
    ).map5(
      (_, name, typeParams, _, typeAndSemi) => TypeAliasDeclarationNode(
        name: name,
        typeParameters: typeParams,
        type: typeAndSemi.$1,
      ),
    ),
    // 2. Old-style with return type: typedef Type Name<T>(params);
    seq6(
      ref0(typedefToken),
      ref0(type),
      ref0(identifier),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref1(token, ';'),
    ).map6(
      (_, returnType, name, typeParams, params, _) => TypeAliasDeclarationNode(
        name: name,
        typeParameters: typeParams,
        type: FunctionTypeNode(returnType: returnType, parameters: params),
      ),
    ),
    // 3. Old-style untyped: typedef Name<T>(params);
    seq5(
      ref0(typedefToken),
      ref0(identifier),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref1(token, ';'),
    ).map5(
      (_, name, typeParams, params, _) => TypeAliasDeclarationNode(
        name: name,
        typeParameters: typeParams,
        type: FunctionTypeNode(parameters: params),
      ),
    ),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Class Member Definitions
  // ---------------------------------------------------------------------------

  Parser<DeclarationNode> classMemberDefinition() => seq2(
    ref0(metadataList),
    [
      ref0(constructorDeclaration),
      ref0(functionDeclaration),
      ref0(fieldDeclaration),
    ].toChoiceParser(),
  ).map2((_, member) => member);

  // ---------------------------------------------------------------------------
  // Constructor Declaration
  Parser<String> constructorIdentifier() =>
      [ref0(identifier), ref0(newToken).map((t) => t.value)].toChoiceParser();

  Parser<ConstructorDeclarationNode> constructorDeclaration() => [
    // Shorthand constructor syntax: const new(...); or new.named(...);
    seq6(
      ref0(externalToken).optional(),
      ref0(constToken).optional(),
      ref0(newToken),
      ([ref1(token, '.'), epsilon()].toChoiceParser() &
              ref0(constructorIdentifier))
          .map((l) => l[1] as String)
          .optional(),
      ref0(formalParameters),
      ref0(constructorBodyOrInitializers),
    ).map6(
      (externalKw, constKw, _, ctorName, params, initsAndBody) =>
          ConstructorDeclarationNode(
            name: 'new',
            constructorName: ctorName,
            parameters: params,
            initializers: initsAndBody.$1,
            body: initsAndBody.$2,
            isConst: constKw != null,
            isExternal: externalKw != null,
            redirectedConstructor: initsAndBody.$3,
          ),
    ),
    // Standard constructor syntax: ClassName(...) or ClassName.identifier(...) or ClassName.new(...)
    // Also supports concise factory constructors: factory(...) or factory.identifier(...)
    seq7(
          ref0(externalToken).optional(),
          ref0(constToken).optional(),
          ref0(factoryToken).optional(),
          ref0(identifier).optional(),
          (ref1(token, '.') & ref0(constructorIdentifier))
              .map((l) => l[1] as String)
              .optional(),
          ref0(formalParameters),
          ref0(constructorBodyOrInitializers),
        )
        .where(
          (l) => l.$3 != null || l.$4 != null,
          message: 'constructor name expected',
        )
        .map7(
          (
            externalKw,
            constKw,
            factoryKw,
            name,
            ctorName,
            params,
            initsAndBody,
          ) => ConstructorDeclarationNode(
            name: name ?? 'factory',
            constructorName: ctorName,
            parameters: params,
            initializers: initsAndBody.$1,
            body: initsAndBody.$2,
            isConst: constKw != null,
            isFactory: factoryKw != null,
            isExternal: externalKw != null,
            redirectedConstructor: initsAndBody.$3,
          ),
        ),
  ].toChoiceParser();

  Parser<(List<ConstructorInitializerNode>, FunctionBodyNode?, String?)>
  constructorBodyOrInitializers() => [
    // Redirecting factory constructor: = OtherClass.name; or = OtherClass<T>.name;
    seq3(
      ref1(token, '='),
      seq2(
        ref0(type),
        (ref1(token, '.') & ref0(constructorIdentifier)).optional(),
      ).flatten(),
      ref1(token, ';'),
    ).map3(
      (_, target, _) => (
        const <ConstructorInitializerNode>[],
        const EmptyFunctionBodyNode(),
        target,
      ),
    ),
    // Initializers + body: : super(), a = 1 { ... } or ; or => expr;
    seq2(
      ref0(constructorInitializers)
          .optionalWith(const <ConstructorInitializerNode>[]),
      ref0(methodBody),
    ).map2((inits, body) => (inits, body, null)),
  ].toChoiceParser();

  Parser<List<ConstructorInitializerNode>> constructorInitializers() => seq2(
    ref1(token, ':'),
    ref0(constructorInitializer)
        .plusSeparated(ref1(token, ','))
        .map((l) => l.elements),
  ).map2((_, inits) => inits);

  Parser<ConstructorInitializerNode> constructorInitializer() => [
    ref0(superConstructorInitializer),
    ref0(redirectingConstructorInitializer),
    ref0(assertInitializer),
    ref0(fieldInitializer),
  ].toChoiceParser();

  Parser<SuperConstructorInitializerNode> superConstructorInitializer() =>
      seq3(
        ref0(superToken),
        (ref1(token, '.') & ref0(identifier))
            .map((l) => l[1] as String)
            .optional(),
        ref0(argumentList),
      ).map3(
        (_, name, args) => SuperConstructorInitializerNode(
          constructorName: name,
          arguments: args,
        ),
      );

  Parser<RedirectingConstructorInitializerNode>
  redirectingConstructorInitializer() =>
      seq3(
        ref0(thisToken),
        (ref1(token, '.') & ref0(identifier))
            .map((l) => l[1] as String)
            .optional(),
        ref0(argumentList),
      ).map3(
        (_, name, args) => RedirectingConstructorInitializerNode(
          constructorName: name,
          arguments: args,
        ),
      );

  Parser<FieldInitializerNode> fieldInitializer() =>
      seq4(
        (ref0(thisToken) & ref1(token, '.')).optional(),
        ref0(identifier),
        ref1(token, '='),
        ref0(expression),
      ).map4(
        (thisDot, name, _, val) => FieldInitializerNode(
          fieldName: name,
          value: val,
          hasThis: thisDot != null,
        ),
      );

  Parser<AssertInitializerNode> assertInitializer() =>
      seq5(
        ref0(assertToken),
        ref1(token, '('),
        ref0(expression),
        (ref1(token, ',') & ref0(expression))
            .map((l) => l[1] as ExpressionNode)
            .optional(),
        seq2(ref1(token, ',').optional(), ref1(token, ')')),
      ).map5(
        (_, _, cond, msg, _) =>
            AssertInitializerNode(AssertStatementNode(cond, msg)),
      );

  // ---------------------------------------------------------------------------
  // Function / Method Declaration
  // ---------------------------------------------------------------------------

  @override
  Parser<FunctionDeclarationNode> functionDeclaration() => [
    ref0(operatorDeclaration),
    ref0(getterDeclaration),
    ref0(setterDeclaration),
    ref0(methodOrFunctionDeclaration),
  ].toChoiceParser();

  Parser<FunctionDeclarationNode> operatorDeclaration() => [
    seq6(
      ref0(methodModifier).star(),
      ref0(operatorToken),
      ref0(userDefinableOperator),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map6(
      (modifiers, _, opName, params, asyncMod, body) => FunctionDeclarationNode(
        name: opName,
        parameters: params,
        body: body,
        isStatic: modifiers.contains('static'),
        isAbstract: modifiers.contains('abstract'),
        isExternal: modifiers.contains('external'),
        isOperator: true,
      ),
    ),
    seq7(
      ref0(methodModifier).star(),
      ref0(type),
      ref0(operatorToken),
      ref0(userDefinableOperator),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map7(
      (modifiers, returnType, _, opName, params, asyncMod, body) =>
          FunctionDeclarationNode(
            name: opName,
            returnType: returnType,
            parameters: params,
            body: body,
            isStatic: modifiers.contains('static'),
            isAbstract: modifiers.contains('abstract'),
            isExternal: modifiers.contains('external'),
            isOperator: true,
          ),
    ),
  ].toChoiceParser();

  Parser<FunctionDeclarationNode> getterDeclaration() => [
    seq5(
      ref0(methodModifier).star(),
      ref0(getToken),
      ref0(identifier),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map5(
      (modifiers, _, name, asyncMod, body) => FunctionDeclarationNode(
        name: name,
        body: body,
        isStatic: modifiers.contains('static'),
        isAbstract: modifiers.contains('abstract'),
        isExternal: modifiers.contains('external'),
        isGetter: true,
      ),
    ),
    seq6(
      ref0(methodModifier).star(),
      ref0(type),
      ref0(getToken),
      ref0(identifier),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map6(
      (modifiers, returnType, _, name, asyncMod, body) =>
          FunctionDeclarationNode(
            name: name,
            returnType: returnType,
            body: body,
            isStatic: modifiers.contains('static'),
            isAbstract: modifiers.contains('abstract'),
            isExternal: modifiers.contains('external'),
            isGetter: true,
          ),
    ),
  ].toChoiceParser();

  Parser<FunctionDeclarationNode> setterDeclaration() => [
    seq6(
      ref0(methodModifier).star(),
      ref0(setToken),
      ref0(identifier),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map6(
      (modifiers, _, name, params, asyncMod, body) => FunctionDeclarationNode(
        name: name,
        parameters: params,
        body: body,
        isStatic: modifiers.contains('static'),
        isAbstract: modifiers.contains('abstract'),
        isExternal: modifiers.contains('external'),
        isSetter: true,
      ),
    ),
    seq7(
      ref0(methodModifier).star(),
      ref0(type),
      ref0(setToken),
      ref0(identifier),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map7(
      (modifiers, returnType, _, name, params, asyncMod, body) =>
          FunctionDeclarationNode(
            name: name,
            returnType: returnType,
            parameters: params,
            body: body,
            isStatic: modifiers.contains('static'),
            isAbstract: modifiers.contains('abstract'),
            isExternal: modifiers.contains('external'),
            isSetter: true,
          ),
    ),
  ].toChoiceParser();

  Parser<FunctionDeclarationNode> methodOrFunctionDeclaration() => [
    // 1. Explicit return type: int foo() {}
    seq7(
      ref0(methodModifier).star(),
      ref0(type),
      ref0(identifier),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map7(
      (modifiers, returnType, name, typeParams, params, asyncMod, body) =>
          FunctionDeclarationNode(
            name: name,
            returnType: returnType,
            typeParameters: typeParams,
            parameters: params,
            body: body,
            isStatic: modifiers.contains('static'),
            isAbstract: modifiers.contains('abstract'),
            isExternal: modifiers.contains('external'),
          ),
    ),
    // 2. Untyped: foo() {} or foo<T>() {}
    seq6(
      ref0(methodModifier).star(),
      ref0(identifier),
      ref0(typeParameters).optionalWith(const <TypeParameterNode>[]),
      ref0(formalParameters),
      ref0(asyncOrSyncModifier).optional(),
      ref0(methodBody),
    ).map6(
      (modifiers, name, typeParams, params, asyncMod, body) =>
          FunctionDeclarationNode(
            name: name,
            typeParameters: typeParams,
            parameters: params,
            body: body,
            isStatic: modifiers.contains('static'),
            isAbstract: modifiers.contains('abstract'),
            isExternal: modifiers.contains('external'),
          ),
    ),
  ].toChoiceParser();

  Parser<FunctionBodyNode> methodBody() => [
    seq3(
      ref1(token, '=>'),
      ref0(expression),
      ref1(token, ';'),
    ).map3((_, expr, _) => ExpressionFunctionBodyNode(expr)),
    ref0(block).map(BlockFunctionBodyNode.new),
    ref1(token, ';').map((_) => const EmptyFunctionBodyNode()),
  ].toChoiceParser();

  Parser<String> methodModifier() => [
    ref0(staticToken),
    ref0(abstractToken),
    ref0(externalToken),
  ].toChoiceParser().map((t) => t.value);

  Parser<String> userDefinableOperator() => [
    ref1(token, '=='),
    ref1(token, '[]='),
    ref1(token, '[]'),
    ref1(token, '+'),
    ref1(token, '-'),
    ref1(token, '*'),
    ref1(token, '/'),
    ref1(token, '~/'),
    ref1(token, '%'),
    ref1(token, '<<'),
    ref1(token, '>>>'),
    ref1(token, '>>'),
    ref1(token, '<='),
    ref1(token, '>='),
    ref1(token, '<'),
    ref1(token, '>'),
    ref1(token, '&'),
    ref1(token, '^'),
    ref1(token, '|'),
    ref1(token, '~'),
  ].toChoiceParser().map((t) => t.value);

  Parser<FieldDeclarationNode> fieldDeclaration() => [
    // 1. var x = 1;
    seq4(
      ref0(fieldModifier).star(),
      ref0(varToken),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ';'),
    ).map4(
      (modifiers, _, vars, _) => FieldDeclarationNode(
        variables: vars,
        isStatic: modifiers.contains('static'),
        isLate: modifiers.contains('late'),
        isCovariant: modifiers.contains('covariant'),
      ),
    ),
    // 2. final / const with explicit type: static const int x = 1;
    seq5(
      ref0(fieldModifier).star(),
      [ref0(finalToken), ref0(constToken)].toChoiceParser(),
      ref0(type),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ';'),
    ).map5(
      (modifiers, modifier, type, vars, _) => FieldDeclarationNode(
        variables: vars,
        type: type,
        isStatic: modifiers.contains('static'),
        isFinal: modifier.value == 'final',
        isConst: modifier.value == 'const',
        isLate: modifiers.contains('late'),
        isCovariant: modifiers.contains('covariant'),
      ),
    ),
    // 3. final / const without explicit type: final x = 1;
    seq4(
      ref0(fieldModifier).star(),
      [ref0(finalToken), ref0(constToken)].toChoiceParser(),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ';'),
    ).map4(
      (modifiers, modifier, vars, _) => FieldDeclarationNode(
        variables: vars,
        isStatic: modifiers.contains('static'),
        isFinal: modifier.value == 'final',
        isConst: modifier.value == 'const',
        isLate: modifiers.contains('late'),
        isCovariant: modifiers.contains('covariant'),
      ),
    ),
    // 4. Type only (no final/const/var): int x = 1;
    seq4(
      ref0(fieldModifier).star(),
      ref0(type),
      ref0(variableDeclarator)
          .plusSeparated(ref1(token, ','))
          .map((l) => l.elements),
      ref1(token, ';'),
    ).map4(
      (modifiers, type, vars, _) => FieldDeclarationNode(
        variables: vars,
        type: type,
        isStatic: modifiers.contains('static'),
        isLate: modifiers.contains('late'),
        isCovariant: modifiers.contains('covariant'),
      ),
    ),
  ].toChoiceParser();

  Parser<String> fieldModifier() => [
    ref0(staticToken),
    ref0(lateToken),
    ref0(covariantToken),
  ].toChoiceParser().map((t) => t.value);

  // ---------------------------------------------------------------------------
  // Metadata
  // ---------------------------------------------------------------------------

  Parser<AnnotationNode> metadata() => seq3(
    char('@'),
    ref0(rawIdentifier).plusSeparated(char('.')).flatten(),
    [
      (seq2(pattern(' \t').star(), char('(')).and() & ref0(argumentList)).map(
        (l) => l[1] as List<ArgumentNode>,
      ),
      ref0(hiddenStuffWhitespace).star().map((_) => const <ArgumentNode>[]),
    ].toChoiceParser(),
  ).map3((_, name, args) => AnnotationNode(name: name, arguments: args));

  @override
  Parser<List<AnnotationNode>> metadataList() => ref0(metadata).star();
}

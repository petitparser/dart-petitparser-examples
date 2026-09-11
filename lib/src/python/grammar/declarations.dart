import 'package:petitparser/petitparser.dart';

import '../ast.dart';
import 'expressions.dart';
import 'lexical.dart';

/// Mixin for Python declarations: functions, classes, type parameters, decorators.
mixin PythonDeclarationGrammar
    on
        GrammarDefinition<ModuleNode>,
        PythonLexicalGrammar,
        PythonExpressionGrammar {
  /// Abstract suite production defined in PythonStatementGrammar.
  Parser<List<StatementNode>> suite();

  /// Main declaration parser (function or class definition).
  Parser<StatementNode> declaration() =>
      [ref0(functionDefinition), ref0(classDefinition)].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Function Definitions
  // ---------------------------------------------------------------------------

  Parser<StatementNode> functionDefinition() =>
      seq2(
        ref0(decorators).optional(),
        [ref0(syncFunctionDef), ref0(asyncFunctionDef)].toChoiceParser(),
      ).map2((decs, fn) {
        if (decs == null || decs.isEmpty) return fn;
        if (fn is FunctionDefNode) {
          return FunctionDefNode(
            name: fn.name,
            args: fn.args,
            body: fn.body,
            decoratorList: decs,
            returns: fn.returns,
            typeParams: fn.typeParams,
          );
        } else if (fn is AsyncFunctionDefNode) {
          return AsyncFunctionDefNode(
            name: fn.name,
            args: fn.args,
            body: fn.body,
            decoratorList: decs,
            returns: fn.returns,
            typeParams: fn.typeParams,
          );
        }
        return fn;
      });

  Parser<FunctionDefNode> syncFunctionDef() =>
      seq6(
        ref0(defToken),
        ref0(identifier),
        ref0(typeParams).optional(),
        ref0(parameters),
        seq2(ref1(token, '->'), ref0(expression)).map2((_, e) => e).optional(),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
      ).map6(
        (_, name, tParams, params, returns, body) => FunctionDefNode(
          name: name,
          args: params,
          body: body,
          returns: returns,
          typeParams: tParams ?? const [],
        ),
      );

  Parser<AsyncFunctionDefNode> asyncFunctionDef() =>
      seq7(
        ref0(asyncToken),
        ref0(defToken),
        ref0(identifier),
        ref0(typeParams).optional(),
        ref0(parameters),
        seq2(ref1(token, '->'), ref0(expression)).map2((_, e) => e).optional(),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
      ).map7(
        (_, _, name, tParams, params, returns, body) => AsyncFunctionDefNode(
          name: name,
          args: params,
          body: body,
          returns: returns,
          typeParams: tParams ?? const [],
        ),
      );

  // ---------------------------------------------------------------------------
  // Class Definitions
  // ---------------------------------------------------------------------------

  Parser<StatementNode> classDefinition() =>
      seq2(ref0(decorators).optional(), ref0(classDefRaw)).map2((decs, cls) {
        if (decs == null || decs.isEmpty) return cls;
        return ClassDefNode(
          name: cls.name,
          bases: cls.bases,
          keywords: cls.keywords,
          body: cls.body,
          decoratorList: decs,
          typeParams: cls.typeParams,
        );
      });

  Parser<ClassDefNode> classDefRaw() =>
      seq5(
        ref0(classToken),
        ref0(identifier),
        ref0(typeParams).optional(),
        seq3(
          ref1(token, '('),
          ignore(ref0(classArguments).optional()),
          ref1(token, ')'),
        ).map3((_, args, _) => args).optional(),
        seq2(ref1(token, ':'), ref0(suite)).map2((_, s) => s),
      ).map5((_, name, tParams, args, body) {
        final parsedArgs =
            args ?? (bases: <ExpressionNode>[], kw: <KeywordNode>[]);
        return ClassDefNode(
          name: name,
          bases: parsedArgs.bases,
          keywords: parsedArgs.kw,
          body: body,
          typeParams: tParams ?? const [],
        );
      });

  Parser<({List<ExpressionNode> bases, List<KeywordNode> kw})>
  classArguments() =>
      seq2(
        ref0(classArg).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final bases = <ExpressionNode>[];
        final kw = <KeywordNode>[];
        for (final item in seq.elements) {
          if (item is KeywordNode) {
            kw.add(item);
          } else {
            bases.add(item as ExpressionNode);
          }
        }
        return (bases: bases, kw: kw);
      });

  Parser<PythonNode> classArg() => [
    seq3(
      ref0(identifier),
      ref0(assignToken),
      ref0(singleExpression),
    ).map3((name, _, val) => KeywordNode(arg: name, value: val)),
    seq2(
      ref1(token, '**'),
      ref0(singleExpression),
    ).map2((_, val) => KeywordNode(value: val)),
    seq2(
      ref1(token, '*'),
      ref0(singleExpression),
    ).map2((_, val) => StarredNode(val)),
    ref0(singleExpression),
  ].toChoiceParser();

  // ---------------------------------------------------------------------------
  // Decorators
  // ---------------------------------------------------------------------------

  Parser<List<ExpressionNode>> decorators() =>
      ref0(decorator).plus().map((list) => list);

  Parser<ExpressionNode> decorator() => seq3(
    ref1(token, '@'),
    ref0(singleExpression),
    ref0(newlineToken),
  ).map3((_, expr, _) => expr);

  // ---------------------------------------------------------------------------
  // Parameters
  // ---------------------------------------------------------------------------

  Parser<ArgumentsNode> parameters() => seq3(
    ref1(token, '('),
    ignore(ref0(parameterList).optional()),
    ref1(token, ')'),
  ).map3((_, params, _) => params ?? const ArgumentsNode());

  @override
  Parser<ArgumentsNode> parameterList() =>
      seq2(
        ref0(paramItem).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final posonly = <ArgNode>[];
        final args = <ArgNode>[];
        ArgNode? vararg;
        final kwonly = <ArgNode>[];
        final kwDefaults = <ExpressionNode?>[];
        ArgNode? kwarg;
        final defaults = <ExpressionNode>[];

        var seenStar = false;

        for (final item in seq.elements) {
          if (item.isSlash) {
            posonly.addAll(args);
            args.clear();
          } else if (item.isBareStar) {
            seenStar = true;
          } else if (item.isVararg) {
            vararg = item.arg;
            seenStar = true;
          } else if (item.isKwarg) {
            kwarg = item.arg;
          } else {
            if (seenStar) {
              kwonly.add(item.arg!);
              kwDefaults.add(item.defaultVal);
            } else {
              args.add(item.arg!);
              if (item.defaultVal != null) {
                defaults.add(item.defaultVal!);
              }
            }
          }
        }

        return ArgumentsNode(
          posonlyargs: posonly,
          args: args,
          vararg: vararg,
          kwonlyargs: kwonly,
          kwDefaults: kwDefaults,
          kwarg: kwarg,
          defaults: defaults,
        );
      });

  Parser<
    ({
      ArgNode? arg,
      ExpressionNode? defaultVal,
      bool isSlash,
      bool isBareStar,
      bool isVararg,
      bool isKwarg,
    })
  >
  paramItem() => [
    ref1(token, '/').map(
      (_) => (
        arg: null,
        defaultVal: null,
        isSlash: true,
        isBareStar: false,
        isVararg: false,
        isKwarg: false,
      ),
    ),
    seq2(ref1(token, '**'), ref0(paramWithAnnotation)).map2(
      (_, param) => (
        arg: param,
        defaultVal: null,
        isSlash: false,
        isBareStar: false,
        isVararg: false,
        isKwarg: true,
      ),
    ),
    seq2(ref1(token, '*'), ref0(paramWithAnnotation)).map2(
      (_, param) => (
        arg: param,
        defaultVal: null,
        isSlash: false,
        isBareStar: false,
        isVararg: true,
        isKwarg: false,
      ),
    ),
    ref1(token, '*').map(
      (_) => (
        arg: null,
        defaultVal: null,
        isSlash: false,
        isBareStar: true,
        isVararg: false,
        isKwarg: false,
      ),
    ),
    seq2(
      ref0(paramWithAnnotation),
      seq2(
        ref0(assignToken),
        ref0(singleExpression),
      ).map2((_, e) => e).optional(),
    ).map2(
      (param, defVal) => (
        arg: param,
        defaultVal: defVal,
        isSlash: false,
        isBareStar: false,
        isVararg: false,
        isKwarg: false,
      ),
    ),
  ].toChoiceParser();

  Parser<ArgNode> paramWithAnnotation() => seq2(
    ref0(identifier),
    seq2(ref1(token, ':'), ref0(singleExpression)).map2((_, e) => e).optional(),
  ).map2((name, ann) => ArgNode(arg: name, annotation: ann));

  // ---------------------------------------------------------------------------
  // PEP 695 Type Parameters
  // ---------------------------------------------------------------------------

  Parser<List<TypeParamNode>> typeParams() => seq3(
    ref1(token, '['),
    ignore(ref0(typeParamList)),
    ref1(token, ']'),
  ).map3((_, list, _) => list);

  Parser<List<TypeParamNode>> typeParamList() => seq2(
    ref0(typeParamItem).plusSeparated(ref1(token, ',')),
    ref1(token, ',').optional(),
  ).map2((seq, _) => seq.elements);

  Parser<TypeParamNode> typeParamItem() => [
    seq2(
      ref1(token, '**'),
      ref0(identifier),
    ).map2((_, id) => ParamSpecNode(id)),
    seq2(
      ref1(token, '*'),
      ref0(identifier),
    ).map2((_, id) => TypeVarTupleNode(id)),
    seq3(
      ref0(identifier),
      seq2(
        ref1(token, ':'),
        ref0(singleExpression),
      ).map2((_, e) => e).optional(),
      seq2(
        ref0(assignToken),
        ref0(singleExpression),
      ).map2((_, e) => e).optional(),
    ).map3(
      (name, bound, defVal) =>
          TypeVarParamNode(name, bound: bound, defaultValue: defVal),
    ),
  ].toChoiceParser();
  @override
  Parser<ArgumentsNode> lambdaParameters() =>
      seq2(
        ref0(lambdaParamItem).plusSeparated(ref1(token, ',')),
        ref1(token, ',').optional(),
      ).map2((seq, _) {
        final posonly = <ArgNode>[];
        final args = <ArgNode>[];
        ArgNode? vararg;
        final kwonly = <ArgNode>[];
        final kwDefaults = <ExpressionNode?>[];
        ArgNode? kwarg;
        final defaults = <ExpressionNode>[];

        var seenStar = false;

        for (final item in seq.elements) {
          if (item.isSlash) {
            posonly.addAll(args);
            args.clear();
          } else if (item.isBareStar) {
            seenStar = true;
          } else if (item.isVararg) {
            vararg = item.arg;
            seenStar = true;
          } else if (item.isKwarg) {
            kwarg = item.arg;
          } else {
            if (seenStar) {
              kwonly.add(item.arg!);
              kwDefaults.add(item.defaultVal);
            } else {
              args.add(item.arg!);
              if (item.defaultVal != null) {
                defaults.add(item.defaultVal!);
              }
            }
          }
        }

        return ArgumentsNode(
          posonlyargs: posonly,
          args: args,
          vararg: vararg,
          kwonlyargs: kwonly,
          kwDefaults: kwDefaults,
          kwarg: kwarg,
          defaults: defaults,
        );
      });

  /// Like [paramItem] but without type annotations (for lambda params).
  Parser<
    ({
      ArgNode? arg,
      ExpressionNode? defaultVal,
      bool isSlash,
      bool isBareStar,
      bool isVararg,
      bool isKwarg,
    })
  >
  lambdaParamItem() => [
    ref1(token, '/').map(
      (_) => (
        arg: null,
        defaultVal: null,
        isSlash: true,
        isBareStar: false,
        isVararg: false,
        isKwarg: false,
      ),
    ),
    seq2(ref1(token, '**'), ref0(identifier)).map2(
      (_, name) => (
        arg: ArgNode(arg: name),
        defaultVal: null,
        isSlash: false,
        isBareStar: false,
        isVararg: false,
        isKwarg: true,
      ),
    ),
    seq2(ref1(token, '*'), ref0(identifier)).map2(
      (_, name) => (
        arg: ArgNode(arg: name),
        defaultVal: null,
        isSlash: false,
        isBareStar: false,
        isVararg: true,
        isKwarg: false,
      ),
    ),
    ref1(token, '*').map(
      (_) => (
        arg: null,
        defaultVal: null,
        isSlash: false,
        isBareStar: true,
        isVararg: false,
        isKwarg: false,
      ),
    ),
    seq2(
      ref0(identifier),
      seq2(
        ref0(assignToken),
        ref0(singleExpression),
      ).map2((_, e) => e).optional(),
    ).map2(
      (name, defVal) => (
        arg: ArgNode(arg: name),
        defaultVal: defVal,
        isSlash: false,
        isBareStar: false,
        isVararg: false,
        isKwarg: false,
      ),
    ),
  ].toChoiceParser();
}

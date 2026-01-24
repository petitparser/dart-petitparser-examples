/// This library contains a simple parser and evaluator for Regular Expressions.
///
/// Based on the following blog posts:
/// - http://xysun.github.io/posts/regex-parsing-thompsons-algorithm.html
/// - https://deniskyashif.com/2019/02/17/implementing-a-regular-expression-engine/.
///
/// For example:
///
/// ```dart
/// final parser = nodeParser;
/// final result = parser.parse('a*b+');
/// print(result.value);
/// ```
library;

export 'src/regexp/nfa.dart';
export 'src/regexp/node.dart';
export 'src/regexp/parser.dart';

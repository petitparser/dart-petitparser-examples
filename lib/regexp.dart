/// This package contains a simple parser and evaluator for Regular Expressions,
/// based on this blog post: https://tavianator.com/2023/irregex.html.

import 'src/regexp/parser.dart';

export 'src/regexp/matcher.dart';

final regexpParser = createParser();

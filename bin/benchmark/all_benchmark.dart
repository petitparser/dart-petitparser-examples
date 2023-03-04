import 'char_benchmark.dart' as char_benchmark;
import 'combinator_benchmark.dart' as combinator_benchmark;
import 'example_benchmark.dart' as example_benchmark;
import 'json_benchmark.dart' as json_benchmark;
import 'predicate_benchmark.dart' as predicate_benchmark;
import 'regexp_benchmark.dart' as regexp_benchmark;
import 'repeat_benchmark.dart' as repeat_benchmark;

void main() {
  char_benchmark.main();
  combinator_benchmark.main();
  example_benchmark.main();
  json_benchmark.main();
  predicate_benchmark.main();
  regexp_benchmark.main();
  repeat_benchmark.main();
}

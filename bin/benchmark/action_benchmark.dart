import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('action - cast', any().cast(), 255);
  runChars('action - castList', any().star().castList(), 255);
  runChars('action - flatten', any().flatten(), 255);
  runChars('action - map', any().map((_) {}), 255);
  runChars('action - permute', any().star().permute([0]), 255);
  runChars('action - pick', any().star().pick(0), 255);
  runChars('action - token', any().token(), 255);
  runChars('action - trim', any().trim(), 255);
  runChars('action - where', any().where((_) => true), 255);
}

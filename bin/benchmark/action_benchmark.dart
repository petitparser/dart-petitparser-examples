import 'package:petitparser/petitparser.dart';

import 'util/runner.dart';

void main() {
  runChars('cast', any().cast(), 255);
  runChars('castList', any().star().castList(), 255);
  runChars('flatten', any().flatten(), 255);
  runChars('map', any().map((_) {}), 255);
  runChars('permute', any().star().permute([0]), 255);
  runChars('pick', any().star().pick(0), 255);
  runChars('token', any().token(), 255);
  runChars('trim', any().trim(), 247);
  runChars('where', any().where((_) => true), 255);
}

import 'package:petitparser/petitparser.dart';

import '../utils/runner.dart';

void main() {
  runChars('action - cast', any().cast());
  runChars('action - castList', any().star().castList());
  runChars(
    'action - continuation',
    any().callCC((continuation, context) => continuation(context)),
  );
  runChars('action - flatten', any().flatten());
  runChars('action - map', any().map((_) {}));
  runChars('action - permute', any().star().permute([0]));
  runChars('action - pick', any().star().pick(0));
  runChars('action - token', any().token());
  runChars('action - trim', any().trim(), success: 351);
  runChars('action - where', any().where((_) => true));
}

/// Further parse the URI authority into username, password, hostname and port.
///
/// Accepts input of the form "[username[:password]@]hostname[:port]".
library authority;

import 'package:petitparser/petitparser.dart';

final authority = seq3(
  _credentials.optional(),
  _hostname.optional(),
  _port.optional(),
).map3((credentials, hostname, port) => {
      #username: credentials?.$1,
      #password: credentials?.$2?.$2,
      #hostname: hostname,
      #port: port?.$2,
    });

final _credentials =
    seq3(_username, seq2(':'.toParser(), _password).optional(), '@'.toParser());

final _username = pattern('^:@').plusString('username');

final _password = pattern('^@').plusString('password');

final _hostname = pattern('^:').plusString('hostname');

final _port = seq2(':'.toParser(), digit().plusString('port'));

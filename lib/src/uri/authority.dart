/// Further parse the URI authority into username, password, hostname and port.
///
/// Accepts input of the form "[username[:password]@]hostname[:port]".
import 'package:petitparser/petitparser.dart';

final authority = seq3(
  _credentials.optional(),
  _hostname.optional(),
  _port.optional(),
).map3((credentials, hostname, port) => {
      #username: credentials?.first,
      #password: credentials?.second?.second,
      #hostname: hostname,
      #port: port?.second,
    });

final _credentials =
    seq3(_username, seq2(':'.toParser(), _password).optional(), '@'.toParser());

final _username = pattern('^:@').plus().flatten('username');

final _password = pattern('^@').plus().flatten('password');

final _hostname = pattern('^:').plus().flatten('hostname');

final _port = seq2(':'.toParser(), digit().plus().flatten('port'));

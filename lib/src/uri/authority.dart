/// Further parse the URI authority into username, password, hostname and port.
///
/// Accepts input of the form "[username[:password]@]hostname[:port]".
library;

import 'package:petitparser/petitparser.dart';

/// A parser that decomposes a URI authority into user credentials, host, and port.
///
/// Accepts input formatted as `[username[:password]@]hostname[:port]` and
/// returns a record containing named fields `username`, `password`,
/// `hostname`, and `port`.
///
/// For example:
///
/// ```dart
/// final result = authority.parse('user:pass@example.com:8080');
/// print(result.value.username); // 'user'
/// print(result.value.hostname); // 'example.com'
/// print(result.value.port);     // '8080'
/// ```
final authority =
    seq3(_credentials.optional(), _hostname.optional(), _port.optional()).map3(
      (credentials, hostname, port) => (
        username: credentials?.$1,
        password: credentials?.$2,
        hostname: hostname,
        port: port,
      ),
    );

final _credentials = seq2(
  _username,
  _password.skip(before: ':'.toParser()).optional(),
).skip(after: '@'.toParser());

final _username = pattern('^:@').plusString(message: 'username');

final _password = pattern('^@').plusString(message: 'password');

final _hostname = pattern('^:').plusString(message: 'hostname');

final _port = digit().plusString(message: 'port').skip(before: ':'.toParser());
